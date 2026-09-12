-- Native packages (installed under ~/.local/share/vim/site/pack/*/start, no
-- plugin manager). Add one by dropping it in a pack/*/start dir, then configure
-- it here.

-- oil.nvim: edit the filesystem like a buffer; :w applies create/rename/delete.
require("oil").setup({
	default_file_explorer = true,
	view_options = { show_hidden = true },
})

-- Colorscheme.
-- vim.cmd.colorscheme("vague")

-- Experimental Nvim 0.12 UI (nicer cmdline / popupmenu rendering).
require("vim._core.ui2").enable({})
-- flash.nvim: jump anywhere via labeled search motions (folke's recommended maps).
vim.pack.add({ "https://github.com/folke/flash.nvim" })
require("flash").setup({
	-- Set modes.char.enabled = false here if you don't want f/t/F/T labelled.
})
-- s: jump  S: treesitter select  (normal / visual / operator-pending)
vim.keymap.set({ "n", "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash jump" })
vim.keymap.set({ "n", "x", "o" }, "S", function() require("flash").treesitter() end, { desc = "Flash treesitter" })
-- r (operator-pending): act on a remote location, e.g. yr<label> to yank there.
vim.keymap.set("o", "r", function() require("flash").remote() end, { desc = "Remote flash" })
vim.keymap.set({ "o", "x" }, "R", function() require("flash").treesitter_search() end, { desc = "Treesitter search" })
-- <C-s> while searching (/ or ?): toggle flash labels on the search.
vim.keymap.set("c", "<C-s>", function() require("flash").toggle() end, { desc = "Toggle flash search" })
