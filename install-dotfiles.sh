#!/bin/bash

# Dotfiles Installation Script with GNU Stow
# Repository: https://github.com/Ikkjo/dotfiles.git
# This script installs all dotfiles and required programs for Ubuntu/Debian

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# Variables
DOTFILES_REPO="https://github.com/Ikkjo/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Check if running on Ubuntu/Debian
check_os() {
    if ! command -v apt &> /dev/null; then
        print_error "This script is designed for Ubuntu/Debian systems with apt package manager"
        exit 1
    fi
    print_success "Running on Ubuntu/Debian system"
}

# Update system
update_system() {
    print_header "Updating System"
    sudo apt update
    sudo apt upgrade -y
    print_success "System updated"
}

# Install essential tools
install_essentials() {
    print_header "Installing Essential Tools"
    
    local packages=(
        git
        curl
        wget
        build-essential
        stow
        zsh
        tmux
        neovim
        fonts-powerline
        ripgrep
        fd-find
        bat
        fzf
        zoxide
    )
    
    print_info "Installing: ${packages[*]}"
    sudo apt install -y "${packages[@]}"
    print_success "Essential tools installed"
}

# Clone dotfiles repository
clone_dotfiles() {
    print_header "Cloning Dotfiles Repository"
    
    if [ -d "$DOTFILES_DIR" ]; then
        print_warning "Dotfiles directory already exists at $DOTFILES_DIR"
        read -p "Do you want to remove it and re-clone? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$DOTFILES_DIR"
        else
            print_info "Using existing dotfiles directory"
            return
        fi
    fi
    
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    print_success "Dotfiles cloned to $DOTFILES_DIR"
}

# Backup existing dotfiles
backup_existing() {
    print_header "Backing Up Existing Dotfiles"
    
    local files=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.tmux.conf"
        "$HOME/.config/nvim"
    )
    
    mkdir -p "$BACKUP_DIR"
    
    for file in "${files[@]}"; do
        if [ -e "$file" ]; then
            print_info "Backing up $file"
            cp -r "$file" "$BACKUP_DIR/"
        fi
    done
    
    if [ "$(ls -A $BACKUP_DIR)" ]; then
        print_success "Backup created at $BACKUP_DIR"
    else
        print_info "No existing dotfiles to backup"
        rmdir "$BACKUP_DIR"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    print_header "Installing Oh My Zsh"
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        print_warning "Oh My Zsh already installed"
    else
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        print_success "Oh My Zsh installed"
    fi
}

# Install Powerlevel10k theme
install_powerlevel10k() {
    print_header "Installing Powerlevel10k Theme"
    
    local P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    
    if [ -d "$P10K_DIR" ]; then
        print_warning "Powerlevel10k already installed"
    else
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
        print_success "Powerlevel10k installed"
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    print_header "Installing Zsh Plugins"
    
    local PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
    
    # zsh-autosuggestions
    if [ -d "$PLUGINS_DIR/zsh-autosuggestions" ]; then
        print_warning "zsh-autosuggestions already installed"
    else
        git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGINS_DIR/zsh-autosuggestions"
        print_success "zsh-autosuggestions installed"
    fi
    
    # zsh-syntax-highlighting
    if [ -d "$PLUGINS_DIR/zsh-syntax-highlighting" ]; then
        print_warning "zsh-syntax-highlighting already installed"
    else
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGINS_DIR/zsh-syntax-highlighting"
        print_success "zsh-syntax-highlighting installed"
    fi
}

# Install Tmux Plugin Manager
install_tmux_plugin_manager() {
    print_header "Installing Tmux Plugin Manager (TPM)"
    
    local TPM_DIR="$HOME/.tmux/plugins/tpm"
    
    if [ -d "$TPM_DIR" ]; then
        print_warning "TPM already installed"
    else
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
        print_success "TPM installed"
    fi
}

# Install Neovim dependencies
install_neovim_deps() {
    print_header "Installing Neovim Dependencies"
    
    # Install Node.js (for Neovim LSP)
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt install -y nodejs
    fi
    
    # Install Python support
    if ! command -v pip3 &> /dev/null; then
        sudo apt install -y python3-pip
    fi
    
    pip3 install --user pynvim
    
    # Install additional language servers and tools
    sudo npm install -g neovim
    
    print_success "Neovim dependencies installed"
}

# Install additional fonts
install_fonts() {
    print_header "Installing Nerd Fonts"
    
    local FONTS_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONTS_DIR"
    
    # Install MesloLGS NF (recommended for Powerlevel10k)
    if [ ! -f "$FONTS_DIR/MesloLGS NF Regular.ttf" ]; then
        print_info "Downloading MesloLGS NF fonts..."
        cd "$FONTS_DIR"
        wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
        wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
        wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
        wget -q https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
        fc-cache -fv
        print_success "MesloLGS NF fonts installed"
    else
        print_warning "MesloLGS NF fonts already installed"
    fi
}

# Stow dotfiles
stow_dotfiles() {
    print_header "Symlinking Dotfiles with GNU Stow"
    
    cd "$DOTFILES_DIR"
    
    # Remove existing files that would conflict
    local files=(
        "$HOME/.zshrc"
        "$HOME/.bashrc"
        "$HOME/.tmux.conf"
    )
    
    for file in "${files[@]}"; do
        if [ -e "$file" ] && [ ! -L "$file" ]; then
            print_info "Removing $file (backed up earlier)"
            rm -f "$file"
        fi
    done
    
    # Remove .config/nvim if it exists and is not a symlink
    if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
        print_info "Removing $HOME/.config/nvim (backed up earlier)"
        rm -rf "$HOME/.config/nvim"
    fi
    
    # Stow all dotfiles
    print_info "Creating symlinks with stow..."
    stow -v --adopt .
    
    # Restore dotfiles from repo (in case --adopt modified them)
    git restore .
    
    print_success "Dotfiles symlinked successfully"
}

# Install Lazy.nvim (Neovim plugin manager)
install_lazy_nvim() {
    print_header "Setting Up Lazy.nvim"
    
    local LAZY_DIR="$HOME/.local/share/nvim/lazy/lazy.nvim"
    
    if [ -d "$LAZY_DIR" ]; then
        print_warning "Lazy.nvim already installed"
    else
        git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable "$LAZY_DIR"
        print_success "Lazy.nvim installed"
    fi
    
    print_info "Run 'nvim' and plugins will be installed automatically"
}

# Change default shell to Zsh
change_shell() {
    print_header "Setting Zsh as Default Shell"
    
    if [ "$SHELL" = "$(which zsh)" ]; then
        print_warning "Zsh is already the default shell"
    else
        print_info "Changing default shell to Zsh..."
        chsh -s "$(which zsh)"
        print_success "Default shell changed to Zsh (restart terminal to apply)"
    fi
}

# Post-installation instructions
post_install() {
    print_header "Installation Complete!"
    
    echo ""
    print_info "Please complete the following steps:"
    echo ""
    echo "  1. Restart your terminal or run: exec zsh"
    echo "  2. Configure Powerlevel10k by running: p10k configure"
    echo "  3. Open tmux and press Ctrl+A then Shift+I to install tmux plugins"
    echo "  4. Open Neovim (nvim) to automatically install plugins"
    echo "  5. Set your terminal font to 'MesloLGS NF' for best experience"
    echo ""
    
    if [ -d "$BACKUP_DIR" ]; then
        print_info "Your old dotfiles are backed up at: $BACKUP_DIR"
    fi
    
    echo ""
    print_success "Enjoy your new setup! 🚀"
    echo ""
}

# Main installation flow
main() {
    print_header "Dotfiles Installation Script"
    print_info "This script will install and configure dotfiles from:"
    print_info "$DOTFILES_REPO"
    echo ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Installation cancelled"
        exit 0
    fi
    
    check_os
    update_system
    install_essentials
    clone_dotfiles
    backup_existing
    install_oh_my_zsh
    install_powerlevel10k
    install_zsh_plugins
    install_tmux_plugin_manager
    install_neovim_deps
    install_lazy_nvim
    install_fonts
    stow_dotfiles
    change_shell
    post_install
}

# Run main function
main
