return {
    "slugbyte/lackluster.nvim",
    commit = "70dd682e564784893b984deb51dd5ddd263c8cc7",
    lazy = false,
    priority = 1000,
    init = function()
        vim.cmd.colorscheme("lackluster-night")
	tweak_background = { normal = "none" }
    end,
}
