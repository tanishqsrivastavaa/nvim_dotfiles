-- Language servers. To add one: create lsp/<name>.lua returning a
-- vim.lsp.Config table, then add "<name>" to the enable list below.
vim.lsp.enable({
    "lua_ls",       -- Lua
    "basedpyright", -- Python: type-checking, diagnostics, completion
    "ruff",         -- Python: linting + formatting
    "clangd",       -- C / C++ / Objective-C
})

-- Autotrigger native completion as you type. The server's trigger characters
-- (".", etc.) open the menu natively; the InsertCharPre handler extends that to
-- identifier characters so the menu also opens mid-word.
local completion_group = vim.api.nvim_create_augroup("user_lsp_completion", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
    group = completion_group,
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client == nil or not client:supports_method("textDocument/completion") then
            return
        end
        vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })

        if vim.b[ev.buf].user_completion_autotrigger then return end
        vim.b[ev.buf].user_completion_autotrigger = true
        vim.api.nvim_create_autocmd("InsertCharPre", {
            group = completion_group,
            buffer = ev.buf,
            callback = function()
                if vim.fn.pumvisible() == 1 then return end
                if vim.v.char:match("[%w_]") == nil then return end
                vim.schedule(function()
                    if vim.fn.mode() == "i" then vim.lsp.completion.get() end
                end)
            end,
        })
    end,
})

-- Format on save via any attached server that supports it (ruff for Python).
vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("user_format_on_save", { clear = true }),
    callback = function(ev)
        local clients = vim.lsp.get_clients({ bufnr = ev.buf, method = "textDocument/formatting" })
        if #clients > 0 then
            vim.lsp.buf.format({ bufnr = ev.buf, timeout_ms = 2000 })
        end
    end,
})
