-- Editor settings. Add new options here.

-- Leader must be set before any <leader> mapping is defined (see keymaps.lua).
vim.g.mapleader = " "

vim.o.number = true
vim.o.relativenumber = true
vim.o.tabstop = 2
vim.o.softtabstop = 2
vim.o.signcolumn = "yes"
vim.o.undofile = true
vim.o.autoread = true
vim.o.laststatus = 3
vim.o.cmdheight = 0
vim.o.termguicolors = true

vim.diagnostic.config({ virtual_text = true })
vim.opt.completeopt = { "menuone", "noselect", "popup" }

-- Find/grep: ":find" searches 'path'; "**" recurses from cwd, fuzzy in cmdline.
vim.opt.path:append("**")
vim.opt.wildoptions:append("fuzzy")
-- "noselect" keeps cmdline autocompletion from pre-inserting the first match.
vim.o.wildmode = "noselect:lastused,full"

-- Grep with ripgrep if present (respects .gitignore), else recursive grep.
if vim.fn.executable("rg") == 1 then
    vim.o.grepprg = "rg --vimgrep --smart-case"
    vim.o.grepformat = "%f:%l:%c:%m"
else
    vim.o.grepprg = "grep -rn --exclude-dir=.git"
    vim.o.grepformat = "%f:%l:%m"
end
