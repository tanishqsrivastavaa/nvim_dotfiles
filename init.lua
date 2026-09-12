-- Entry point. Each module under lua/ owns one concern; language servers live
-- under lsp/ (one file per server). Order matters: options sets <leader> first.
require("options")    -- editor settings
require("packages")   -- native packages (oil, colorscheme)
require("keymaps")    -- key mappings
require("lsp")        -- language servers, completion, format-on-save
require("statusline") -- statusline
vim.pack.add({ "https://github.com/dmtrKovalenko/fff" })

vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name == 'fff' and (kind == 'install' or kind == 'update') then
			if not ev.data.active then vim.cmd.packadd('fff') end
			require('fff.download').download_or_build_binary()
		end
	end,
})

vim.g.fff = {
	lazy_sync = true,
	debug = { enabled = true, show_scores = true }
}

vim.keymap.set('n', 'ff', function() require('fff').find_files_in_dir("~") end)

vim.pack.add({
	"https://github.com/ellisonleao/gruvbox.nvim"
})

require("gruvbox").setup()
vim.cmd.colorscheme("gruvbox")
