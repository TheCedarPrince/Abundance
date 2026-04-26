return {
    "slugbyte/lackluster.nvim",
    lazy = false,
    priority = 1000,
    init = function()
        vim.cmd.colorscheme("lackluster-night")
	tweak_background = { normal = "none" }
    end,
}
