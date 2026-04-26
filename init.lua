local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

require("vim._core.ui2").enable({})
vim.g.python3_host_prog = '/home/thecedarprince/Programs/Miniconda3/envs/neovim/bin/python'

-- Set up paths BEFORE lazy so it can find all plugin specs
vim.o.runtimepath = vim.o.runtimepath .. ',' .. vim.fn.stdpath("config")
vim.o.runtimepath = vim.o.runtimepath .. ',' .. vim.fn.stdpath("config") .. "/lua/core"

local lazy_path = vim.fn.stdpath("data") .. "/lazy"
package.path = package.path .. ";" .. lazy_path .. "/nvim-treesitter/lua/?.lua"

require('lazy').setup({
    { import = "plugins" },
    { import = "core.lua.plugins" },
    { import = "core.lua.core.lua.plugins" },
})

-- Abundance layer modules
require("custom.latex").setup()

vim.env.WEZTERM_SHELL_SKIP_ALL = "1"
