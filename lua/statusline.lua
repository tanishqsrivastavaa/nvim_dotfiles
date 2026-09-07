-- Diagnostics-forward statusline (native): colored mode · file · error/warn
-- counts · (right) attached LSP clients · filetype · line:col.

-- Highlight groups (vague palette), re-applied on ColorScheme so they survive a
-- theme reload. Diagnostic counts reuse the built-in Diagnostic* groups.
local function set_hl()
    local dark = "#141415"
    local mode_bg = {
        StMNormal = "#6e94b2",
        StMInsert = "#7fa563",
        StMVisual = "#bb9dbd",
        StMReplace = "#d8647e",
        StMCommand = "#f3be7c",
    }
    for group, bg in pairs(mode_bg) do
        vim.api.nvim_set_hl(0, group, { fg = dark, bg = bg, bold = true })
    end
    vim.api.nvim_set_hl(0, "StLsp", { fg = "#9bb4bc" })
    vim.api.nvim_set_hl(0, "StMuted", { fg = "#8a8aa0" })
    vim.api.nvim_set_hl(0, "StModified", { fg = "#f3be7c" })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("user_statusline_hl", { clear = true }),
    callback = set_hl,
})

-- mode code -> { label, highlight group }
local modes = {
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

-- Global so the statusline "%{%v:lua.St.*%}" expressions can reach these.
_G.St = {}

function St.mode()
    local m = vim.api.nvim_get_mode().mode
    local e = modes[m] or modes[m:sub(1, 1)] or { m:upper(), "StMNormal" }
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
    if e > 0 then parts[#parts + 1] = "%#DiagnosticError#● " .. e .. "%*" end
    if w > 0 then parts[#parts + 1] = "%#DiagnosticWarn#▲ " .. w .. "%*" end
    if #parts == 0 then return "" end
    return "  " .. table.concat(parts, " ")
end

function St.lsp()
    local names = {}
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
        names[#names + 1] = c.name
    end
    if #names == 0 then return "" end
    return "%#StLsp#" .. table.concat(names, ", ") .. "%*  "
end

vim.o.statusline = table.concat({
    "%{%v:lua.St.mode()%}",
    " %t",
    "%{%v:lua.St.modified()%}",
    "%{%v:lua.St.diagnostics()%}",
    "%=",
    "%{%v:lua.St.lsp()%}",
    "%#StMuted#%{&filetype}%*  ",
    "%l:%c ",
})
