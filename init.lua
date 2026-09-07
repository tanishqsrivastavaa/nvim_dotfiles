-- Entry point. Each module under lua/ owns one concern; language servers live
-- under lsp/ (one file per server). Order matters: options sets <leader> first.
require("options")    -- editor settings
require("packages")   -- native packages (oil, colorscheme)
require("keymaps")    -- key mappings
require("lsp")        -- language servers, completion, format-on-save
require("statusline") -- statusline
