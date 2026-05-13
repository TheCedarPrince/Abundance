
return {
	"jeff-dh/expJABS.nvim",
	commit = "7bfb4cc71a2f44d3199580152f23c88757d65957",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
	},
	opts = {
		sort_mru = true,
		split_filename = true,
		split_filename_path_width = 0,
		position = { "right", "center" },
		    preview_position = "left",
		    preview = {
		      width = 70,
		      height = 20,
		      border = "rounded",
		    },
		        offset = { -- window position offset
        top = 0, -- default 0
        bottom = 0, -- default 0
        left = 2, -- default 0
        right = 0, -- default 0
    },
		width = 50,
		height = 8,
		border = "rounded",
		symbols = {
			current = "󰊍",
			split = "S",
			alternate = "A",
			hidden = "󰘓",
			locked = "",
			ro = "R",
			edited = "",
			terminal_symbol = ">_",
		},
	},
	keys = {
		{ "<leader>b", "<cmd>JABSOpen<CR>", desc = "Open JABS Buffer Switcher" },
	},
}
