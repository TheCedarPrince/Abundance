return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },
    event = "VeryLazy",
    config = function()
        require("lualine").setup({
            options = {
                disabled_filetypes   = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
                icons_enabled        = true,
                theme                = "auto",
		component_separators = { left = "", right = "" }, -- Rounded separators
		section_separators = { left = "", right = "" }, -- Rounded corners
                ignore_focus         = {},
                always_divide_middle = true,
                globalstatus         = true,
            },
            sections = {
                lualine_a = {
                    { "mode", separator = { left = "", right = "" }, right_padding = 10, color = {gui = "bold"} },
                },
                lualine_b = {
			{"branch", padding={left=1}, icon_only = true, component_separators = {left = " ", right = " "}},
			{"diff", padding={left=0}}
		},
		lualine_c = {},
		lualine_x = {},
		lualine_y = {},
                lualine_z = {
			{"progress", padding={right=1}, icon_only = true, separator = { left = "█", right = "" }},
			{"searchcount", padding={right=1}, icon_only = true, separator = { left = "", right = "" }},
			{"selectioncount", padding={left=0, right = 1}, separator = { left = "", right = "" }}
                },
            },
            tabline    = {},
	      extensions = { "oil", "ctrlspace" },
        })

        vim.o.laststatus = vim.g.lualine_laststatus
	vim.cmd([[
	      hi lualine_c_normal guibg=#101010 ctermbg=NONE
	      hi lualine_x_normal guibg=#101010 ctermbg=NONE
	      hi lualine_c_visual guibg=#101010 ctermbg=NONE
	      hi lualine_x_visual guibg=#101010 ctermbg=NONE
	      hi lualine_c_command guibg=#101010 ctermbg=NONE
	      hi lualine_x_command guibg=#101010 ctermbg=NONE
	      hi lualine_c_insert guibg=#101010 ctermbg=NONE
	      hi lualine_x_insert guibg=#101010 ctermbg=NONE
	    ]])
    end,
}
