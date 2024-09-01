vim.keymap.set("n", "<leader>vf",
    function()
        require('neo-tree.command').execute({
            toggle = true,
            source = 'filesystem',
            position = 'right',
        })
    end
)
