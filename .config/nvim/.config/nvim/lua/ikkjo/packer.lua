-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.2',
        -- or                            , branch = '0.1.x',
        requires = { { 'nvim-lua/plenary.nvim' } }
    }

    use({
        'rose-pine/neovim',
        as = 'rose-pine',
        config = function()
            vim.cmd('colorscheme rose-pine')
        end
    })

    use('nvim-treesitter/nvim-treesitter', { run = ':TSUpdate' })
    use('nvim-treesitter/playground')
    use('theprimeagen/harpoon')
    use('mbbill/undotree')
    use('tpope/vim-fugitive')
    use { "chrisgrieser/nvim-spider" }

    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },
            { 'hrsh7th/cmp-buffer' },
            { 'hrsh7th/cmp-path' },
            { 'saadparwaiz1/cmp_luasnip' },
            { 'hrsh7th/cmp-nvim-lsp' },
            { 'hrsh7th/cmp-nvim-lua' },

            -- Snippets
            { 'L3MON4D3/LuaSnip' },
            { 'rafamadriz/friendly-snippets' },
        }
    }

    use {
        'nvim-lualine/lualine.nvim',
        requires = { 'nvim-tree/nvim-web-devicons', opt = true }
    }

    use {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup(
                {
                    ---Add a space b/w comment and the line
                    padding = true,
                    ---Whether the cursor should stay at its position
                    sticky = true,
                    ---Lines to be ignored while (un)comment
                    ignore = nil,
                    ---LHS of toggle mappings in NORMAL mode
                    toggler = {
                        ---Line-comment toggle keymap
                        line = 'gcc',
                        ---Block-comment toggle keymap
                        block = 'gbc',
                    },
                    ---LHS of operator-pending mappings in NORMAL and VISUAL mode
                    opleader = {
                        ---Line-comment keymap
                        line = 'gc',
                        ---Block-comment keymap
                        block = 'gb',
                    },
                    ---LHS of extra mappings
                    extra = {
                        ---Add comment on the line above
                        above = 'gcO',
                        ---Add comment on the line below
                        below = 'gco',
                        ---Add comment at the end of line
                        eol = 'gcA',
                    },
                    ---Enable keybindings
                    ---NOTE: If given `false` then the plugin won't create any mappings
                    mappings = {
                        ---Operator-pending mapping; `gcc` `gbc` `gc[count]{motion}` `gb[count]{motion}`
                        basic = true,
                        ---Extra mapping; `gco`, `gcO`, `gcA`
                        extra = true,
                    },
                    ---Function to call before (un)comment
                    pre_hook = nil,
                    ---Function to call after (un)comment
                    post_hook = nil,
                }
            )
        end
    }

    use { "rcarriga/nvim-dap-ui", requires = { "mfussenegger/nvim-dap" } }
    use {"eckon/treesitter-current-functions",
  requires = { "nvim-treesitter/nvim-treesitter", "nvim-telescope/telescope.nvim" }}
  use { "nvim-neotest/nvim-nio" }
  use {
  "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    requires = { 
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
    }
  }
end)
