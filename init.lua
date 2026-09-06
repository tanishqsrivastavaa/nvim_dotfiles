-- Leader must be set before any <leader> mappings are defined.
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
vim.o.termguicolors = true -- required for truecolor colorschemes (vague)


vim.diagnostic.config({ virtual_text = true })
vim.opt.completeopt = { "menuone", "noselect", "popup" }

-- File tree: netrw as a left sidebar (built in, no plugins).
vim.g.netrw_banner = 0        -- hide the top help banner
vim.g.netrw_liststyle = 3     -- expandable tree-style listing
vim.g.netrw_winsize = 25      -- sidebar takes 25% of the window width
vim.g.netrw_browse_split = 4  -- open picked files in the previous (main) window
vim.g.netrw_altv = 1          -- vertical splits open to the right of the tree

-- Toggle the tree with Ctrl-n. Mapped in NORMAL mode only, so it does not
-- touch <C-n> ("next item") in the insert-mode completion popup.
vim.keymap.set("n", "<C-n>", "<Cmd>Lexplore<CR>", { desc = "Toggle file tree (netrw)" })

-- Find & Grep (native, no plugins).
-- FIND files: :find searches 'path'; "**" makes it recurse from the cwd, and
-- fuzzy cmdline completion in a popup gives a CtrlP-like picker.
vim.opt.path:append("**")
vim.opt.wildoptions:append("fuzzy") -- fuzzy matching in cmdline completion
-- <C-p> opens the :find prompt (normal mode only). Type part of a name, then
-- <Tab> to fuzzy-match, <CR> to open.
vim.keymap.set("n", "<C-p>", ":find ", { desc = "Find file (native :find)" })

-- GREP: ripgrep if available (fast, respects .gitignore), else recursive grep.
if vim.fn.executable("rg") == 1 then
    vim.o.grepprg = "rg --vimgrep --smart-case"
    vim.o.grepformat = "%f:%l:%c:%m"
else
    vim.o.grepprg = "grep -rn --exclude-dir=.git"
    vim.o.grepformat = "%f:%l:%m"
end

-- <C-g> prompts for a pattern and lists matches in the quickfix window.
-- The trailing "." is REQUIRED: with no path, ripgrep searches stdin (which
-- Nvim leaves empty) instead of the project. Navigate results with ]q / [q.
vim.keymap.set("n", "<C-g>", function()
    local query = vim.fn.input("Grep: ")
    if query == "" then
        return
    end
    vim.cmd("silent grep! " .. vim.fn.shellescape(query, true) .. " .")
    if vim.tbl_isempty(vim.fn.getqflist()) then
        vim.notify("Grep: no matches for " .. query, vim.log.levels.INFO)
    else
        vim.cmd("copen")
    end
end, { desc = "Grep project -> quickfix" })

-- Diagnostics list (native, no plugins): collect diagnostics into a list window
-- and open it (like the example). setloclist/setqflist open the window by default.
-- <leader>d = THIS file (location list); walk it with ]l / [l, <CR> to jump.
-- <leader>D = WHOLE project (quickfix);   walk it with ]q / [q.
vim.keymap.set("n", "<leader>d", function()
    vim.diagnostic.setloclist({ open = true })
end, { desc = "Diagnostics (this file) -> location list" })
vim.keymap.set("n", "<leader>D", function()
    vim.diagnostic.setqflist({ open = true })
end, { desc = "Diagnostics (project) -> quickfix" })

-- Run an external TUI in a centered floating terminal (native, no plugins).
-- opts: { title, cwd, on_close }. Esc is left unmapped so it reaches the program.
local function float_term(cmd, opts)
    opts = opts or {}
    local width = math.floor(vim.o.columns * 0.9)
    local height = math.floor(vim.o.lines * 0.9)
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        style = "minimal",
        border = "rounded",
        title = opts.title,
        title_pos = "center",
    })
    vim.fn.jobstart(cmd, {
        term = true,
        cwd = opts.cwd,
        on_exit = function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
            if opts.on_close then
                opts.on_close()
            end
        end,
    })
    vim.cmd("startinsert")
end

-- lazygit: <leader>g opens it in a float rooted at the current file's repo;
-- quitting (q) closes the float and reloads any files it changed on disk.
vim.keymap.set("n", "<leader>g", function()
    if vim.fn.executable("lazygit") == 0 then
        vim.notify("lazygit is not on $PATH", vim.log.levels.ERROR)
        return
    end
    local dir = vim.fn.expand("%:p:h")
    if dir == "" then
        dir = vim.fn.getcwd()
    end
    float_term({ "lazygit" }, {
        title = " lazygit ",
        cwd = dir,
        on_close = function()
            vim.cmd("checktime")
        end,
    })
end, { desc = "lazygit (floating terminal)" })

-- Markdown viewer: <leader>m renders the current buffer (unsaved edits included)
-- with glow in a floating pager. Not a plugin — the standalone `glow` binary in
-- a native :terminal. Quit the pager with q.
vim.keymap.set("n", "<leader>m", function()
    if vim.fn.executable("glow") == 0 then
        vim.notify("glow is not on $PATH", vim.log.levels.ERROR)
        return
    end
    local tmp = vim.fn.tempname() .. ".md"
    vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), tmp)
    float_term({ "glow", "-p", tmp }, {
        title = " markdown ",
        on_close = function()
            pcall(vim.fn.delete, tmp)
        end,
    })
end, { desc = "Markdown preview (glow, floating)" })

local completion_group = vim.api.nvim_create_augroup("user_lsp_completion", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
    group = completion_group,
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client == nil or not client:supports_method("textDocument/completion") then
            return
        end

        -- Native autotrigger only opens the menu on the server's
        -- triggerCharacters (for pyright: "." "[" "\"" "'"). It never fires on
        -- identifier characters.
        vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })

        -- To also pop the menu while typing an identifier, request completion
        -- ourselves on word characters. See :help vim.lsp.completion.enable
        -- ("If you want to trigger completion on other characters ...").
        -- Register the InsertCharPre handler once per buffer, even if several
        -- clients attach to it.
        if vim.b[ev.buf].user_completion_autotrigger then
            return
        end
        vim.b[ev.buf].user_completion_autotrigger = true

        vim.api.nvim_create_autocmd("InsertCharPre", {
            group = completion_group,
            buffer = ev.buf,
            callback = function()
                -- Menu already open: native code handles refiltering and
                -- re-requesting incomplete results, so stay out of its way.
                if vim.fn.pumvisible() == 1 then
                    return
                end
                -- Only identifier chars. Trigger characters (".", etc.) are not
                -- word chars, so the native handler still owns them; no overlap.
                if vim.v.char:match("[%w_]") == nil then
                    return
                end
                -- Defer so the just-typed character is in the buffer before we
                -- ask the server (in InsertCharPre it has not been inserted yet).
                vim.schedule(function()
                    if vim.fn.mode() == "i" then
                        vim.lsp.completion.get()
                    end
                end)
            end,
        })
    end,
})

vim.lsp.enable({
    "lua_ls",
    "pyright",
    "ruff", -- Python formatter (ruff server); pyright still owns diagnostics
})

-- Format on save (native LSP). vim.lsp.buf.format() is synchronous by default,
-- so the formatted result is written. Guarded so it only runs when a client
-- that actually supports formatting is attached (ruff for Python) — otherwise
-- Nvim would warn "no matching language servers" on every save.
vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("user_format_on_save", { clear = true }),
    callback = function(ev)
        local clients = vim.lsp.get_clients({ bufnr = ev.buf, method = "textDocument/formatting" })
        if #clients > 0 then
            vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
        end
    end,
})

-- Colorscheme: vague.nvim, installed as a native package at
-- ~/.local/share/nvim/site/pack/themes/start/vague.nvim (no plugin manager).
-- setup() is optional; call it before colorscheme only to customize.
-- require("vague").setup({ transparent = false })
vim.cmd.colorscheme("vague")

-- ===================================================================
-- Statusline: "Diagnostics-forward" (native, no plugins).
-- Mode block (recolors per mode) · file · live error/warn counts ·
-- (right) attached LSP clients · filetype · line:col.
-- ===================================================================

-- Custom highlight groups. Colors are the vague palette; re-applied on
-- ColorScheme so they survive a theme reload. Diagnostic counts reuse the
-- built-in Diagnostic* groups, so they stay correct under any theme.
local function set_statusline_hl()
    local dark = "#141415"
    local mode_bg = {
        StMNormal = "#6e94b2", -- blue
        StMInsert = "#7fa563", -- green
        StMVisual = "#bb9dbd", -- purple
        StMReplace = "#d8647e", -- red
        StMCommand = "#f3be7c", -- yellow
    }
    for group, bg in pairs(mode_bg) do
        vim.api.nvim_set_hl(0, group, { fg = dark, bg = bg, bold = true })
    end
    vim.api.nvim_set_hl(0, "StLsp", { fg = "#9bb4bc" }) -- type color
    vim.api.nvim_set_hl(0, "StMuted", { fg = "#8a8aa0" })
    vim.api.nvim_set_hl(0, "StModified", { fg = "#f3be7c" })
end
set_statusline_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("user_statusline_hl", { clear = true }),
    callback = set_statusline_hl,
})

-- mode code -> { label, highlight group }
local st_modes = {
    n = { "NORMAL", "StMNormal" },
    niI = { "NORMAL", "StMNormal" },
    no = { "O-PEND", "StMNormal" },
    v = { "VISUAL", "StMVisual" },
    V = { "V-LINE", "StMVisual" },
    ["\22"] = { "V-BLOCK", "StMVisual" }, -- <C-v>
    s = { "SELECT", "StMVisual" },
    S = { "S-LINE", "StMVisual" },
    i = { "INSERT", "StMInsert" },
    ic = { "INSERT", "StMInsert" },
    R = { "REPLACE", "StMReplace" },
    Rv = { "V-REPL", "StMReplace" },
    c = { "COMMAND", "StMCommand" },
    cv = { "EX", "StMCommand" },
    r = { "PROMPT", "StMCommand" },
    ["!"] = { "SHELL", "StMCommand" },
    t = { "TERMINAL", "StMInsert" },
}

_G.St = {}

function St.mode()
    local m = vim.api.nvim_get_mode().mode
    local e = st_modes[m] or st_modes[m:sub(1, 1)] or { m:upper(), "StMNormal" }
    return "%#" .. e[2] .. "# " .. e[1] .. " %*"
end

function St.modified()
    return vim.bo.modified and " %#StModified#●%*" or ""
end

function St.diagnostics()
    local counts = vim.diagnostic.count(0)
    local e = counts[vim.diagnostic.severity.ERROR] or 0
    local w = counts[vim.diagnostic.severity.WARN] or 0
    local parts = {}
    if e > 0 then
        parts[#parts + 1] = "%#DiagnosticError#● " .. e .. "%*"
    end
    if w > 0 then
        parts[#parts + 1] = "%#DiagnosticWarn#▲ " .. w .. "%*"
    end
    if #parts == 0 then
        return ""
    end
    return "  " .. table.concat(parts, " ")
end

function St.lsp()
    local names = {}
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        names[#names + 1] = c.name
    end
    if #names == 0 then
        return ""
    end
    return "%#StLsp#" .. table.concat(names, ", ") .. "%*  "
end

vim.o.statusline = table.concat({
    "%{%v:lua.St.mode()%}", -- colored mode block
    " %t", -- filename (tail)
    "%{%v:lua.St.modified()%}", -- ● when modified
    "%{%v:lua.St.diagnostics()%}", -- errors / warnings (hidden when clean)
    "%=", -- right-align everything after this
    "%{%v:lua.St.lsp()%}", -- attached LSP client names
    "%#StMuted#%{&filetype}%*  ", -- filetype
    "%l:%c ", -- line:col
})

