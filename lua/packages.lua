-- Native packages (installed under ~/.local/share/nvim/site/pack/*/start, no
-- plugin manager). Add one by dropping it in a pack/*/start dir, then configure
-- it here.

-- oil.nvim: edit the filesystem like a buffer; :w applies create/rename/delete.
require("oil").setup({
    default_file_explorer = true,
    view_options = { show_hidden = true },
})

-- Colorscheme.
vim.cmd.colorscheme("vague")

-- Experimental Nvim 0.12 UI (nicer cmdline / popupmenu rendering).
require("vim._core.ui2").enable({})
