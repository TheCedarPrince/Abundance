return {
    "rachartier/tiny-cmdline.nvim",
    commit = "ad58747b955d0743ccfd56e97da1a4c1fac89f58",
    init = function()
        vim.o.cmdheight = 0
        vim.g.tiny_cmdline = {
            width = { value = "70%" },
	    border = nil,
	    native_types = {  },
        }
    end
}
