return {
    "slugbyte/lackluster.nvim",
    lazy = false,
    priority = 1000,
    init = function()
        vim.cmd.colorscheme("lackluster-night")
        -- vim.cmd.colorscheme("lackluster-hack") -- my favorite
        -- vim.cmd.colorscheme("lackluster-mint")
    end,
}
