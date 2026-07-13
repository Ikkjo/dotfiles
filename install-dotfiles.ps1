[CmdletBinding()]
param(
    [string]$DotfilesDir,
    [switch]$SkipPackages,
    [switch]$SkipPlugins
)

$ErrorActionPreference = 'Stop'
$Repository = 'https://github.com/Ikkjo/dotfiles.git'
$BackupDir = Join-Path $HOME ('.dotfiles-backup-' + (Get-Date -Format 'yyyyMMdd_HHmmss'))

function Write-Info([string]$Message) {
    Write-Host "[INFO] $Message" -ForegroundColor Blue
}

function Write-Success([string]$Message) {
    Write-Host "[SUCCESS] $Message" -ForegroundColor Green
}

function Write-WarningMessage([string]$Message) {
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Install-WingetPackage([string]$Id, [string]$Command) {
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Info "$Command is already installed"
        return
    }

    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget is required to install $Command. Install App Installer or rerun with -SkipPackages."
    }

    Write-Info "Installing $Command ($Id)"
    winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "winget could not install $Id (exit code $LASTEXITCODE)"
    }
}

function Backup-Path([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    if (-not (Test-Path -LiteralPath $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }

    $Name = Split-Path -Leaf $Path
    Write-Info "Backing up $Path"
    Copy-Item -LiteralPath $Path -Destination (Join-Path $BackupDir $Name) -Recurse -Force
    Remove-Item -LiteralPath $Path -Recurse -Force
}

function Install-FileLink([string]$Source, [string]$Destination) {
    $Parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $Parent)) {
        New-Item -ItemType Directory -Path $Parent | Out-Null
    }

    if (Test-Path -LiteralPath $Destination) {
        $DestinationItem = Get-Item -LiteralPath $Destination -Force
        if ($DestinationItem.LinkType -eq 'SymbolicLink' -and
            $DestinationItem.Target -contains $Source) {
            Write-Info "$Destination already links to the repository"
            return
        }
        Backup-Path $Destination
    }

    try {
        New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
        Write-Success "Linked $Destination -> $Source"
    }
    catch {
        # File symlinks require Developer Mode or elevation on some Windows systems.
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
        Write-WarningMessage "Could not create a file symlink; copied $Source to $Destination instead"
    }
}

function Install-DirectoryLink([string]$Source, [string]$Destination) {
    $Parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $Parent)) {
        New-Item -ItemType Directory -Path $Parent | Out-Null
    }

    if (Test-Path -LiteralPath $Destination) {
        $DestinationItem = Get-Item -LiteralPath $Destination -Force
        if ($DestinationItem.LinkType -in @('Junction', 'SymbolicLink') -and
            $DestinationItem.Target -contains $Source) {
            Write-Info "$Destination already links to the repository"
            return
        }
        Backup-Path $Destination
    }

    # Directory junctions work without GNU Stow, elevation, or Developer Mode.
    New-Item -ItemType Junction -Path $Destination -Target $Source | Out-Null
    Write-Success "Linked $Destination -> $Source"
}

Write-Host '========================================' -ForegroundColor Green
Write-Host 'Windows Dotfiles Installation' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green

if (-not $SkipPackages) {
    Install-WingetPackage 'Git.Git' 'git'
    Install-WingetPackage 'marlocarlo.psmux' 'psmux'
    Install-WingetPackage 'Neovim.Neovim' 'nvim'
}

if (-not $DotfilesDir) {
    $ScriptRootConfig = Join-Path $PSScriptRoot '.psmux.conf'
    if (Test-Path -LiteralPath $ScriptRootConfig) {
        $DotfilesDir = $PSScriptRoot
    }
    else {
        $DotfilesDir = Join-Path $HOME '.dotfiles'
    }
}
$DotfilesDir = [IO.Path]::GetFullPath($DotfilesDir)

if (-not (Test-Path -LiteralPath (Join-Path $DotfilesDir '.git'))) {
    if (Test-Path -LiteralPath $DotfilesDir) {
        throw "$DotfilesDir exists but is not a Git checkout. Move it or pass -DotfilesDir."
    }
    Write-Info "Cloning $Repository to $DotfilesDir"
    git clone $Repository $DotfilesDir
    if ($LASTEXITCODE -ne 0) {
        throw "Could not clone the dotfiles repository (exit code $LASTEXITCODE)"
    }
}
else {
    Write-Info "Using dotfiles repository at $DotfilesDir"
}

$PsmuxSource = Join-Path $DotfilesDir '.psmux.conf'
$NvimSource = Join-Path $DotfilesDir '.config\nvim\.config\nvim'
if (-not (Test-Path -LiteralPath $PsmuxSource)) {
    throw "Missing psmux configuration: $PsmuxSource"
}
if (-not (Test-Path -LiteralPath (Join-Path $NvimSource 'init.lua'))) {
    throw "Missing Neovim configuration: $NvimSource"
}

Install-FileLink $PsmuxSource (Join-Path $HOME '.psmux.conf')
$NvimConfigHome = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME 'AppData\Local' }
Install-DirectoryLink $NvimSource (Join-Path $NvimConfigHome 'nvim')

if (-not $SkipPlugins) {
    $NvimDataHome = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { Join-Path $HOME 'AppData\Local' }
    $PackerDir = Join-Path $NvimDataHome 'nvim-data\site\pack\packer\start\packer.nvim'
    if (Test-Path -LiteralPath $PackerDir) {
        Write-Info 'packer.nvim is already installed'
    }
    else {
        Write-Info 'Installing packer.nvim'
        New-Item -ItemType Directory -Path (Split-Path -Parent $PackerDir) -Force | Out-Null
        git clone --depth 1 https://github.com/wbthomason/packer.nvim $PackerDir
        if ($LASTEXITCODE -ne 0) {
            throw "Could not install packer.nvim (exit code $LASTEXITCODE)"
        }
    }

    Write-Info 'Synchronizing Neovim plugins'
    nvim --headless '+autocmd User PackerComplete quitall' '+PackerSync'
    if ($LASTEXITCODE -ne 0) {
        throw "Neovim plugin synchronization failed (exit code $LASTEXITCODE)"
    }
}

Write-Success 'psmux and Neovim configurations are installed'
Write-Info 'Start a new psmux server to load ~/.psmux.conf.'
if (-not $SkipPlugins) {
    Write-Info 'Neovim plugins were synchronized. Mason and Treesitter may finish installing tools on first launch.'
}
if (Test-Path -LiteralPath $BackupDir) {
    Write-Info "Previous configuration was backed up to $BackupDir"
}
