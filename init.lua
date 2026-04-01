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

vim.g.python3_host_prog = '/home/thecedarprince/Programs/Miniconda3/envs/neovim/bin/python'

-- Set up paths BEFORE lazy so it can find all plugin specs
vim.o.runtimepath = vim.o.runtimepath .. ',' .. vim.fn.stdpath("config")
vim.o.runtimepath = vim.o.runtimepath .. ',' .. vim.fn.stdpath("config") .. "/lua/core"
package.path = package.path .. ';' .. vim.fn.stdpath("config") .. '/lua/?.lua'
package.path = package.path .. ';' .. vim.fn.stdpath("config") .. '/?.lua'

require('lazy').setup({
    { import = "plugins" },
    { import = "core.lua.plugins" },
    { import = "core.lua.core.lua.plugins" },
})

-- Middle layer modules
require("core.autocommands")

-- Abundance layer modules
require("custom.latex").setup()
