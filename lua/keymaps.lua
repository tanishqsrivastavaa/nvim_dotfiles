-- Key mappings. Add new ones here.

local map = vim.keymap.set

-- File explorer (oil): "-" opens the parent dir, <C-n> toggles a floating oil.
map("n", "-", "<cmd>Oil<cr>", { desc = "Parent directory (oil)" })
map("n", "<C-n>", function() require("oil").toggle_float() end, { desc = "File explorer (oil float)" })

-- Find files: type part of a name, <Tab> to fuzzy-match, <CR> to open.
map("n", "<C-p>", ":find ", { desc = "Find file" })

-- Command-line autocompletion (Nvim 0.12+): pop the wildmenu as you type at
-- ":" / "/" / "?" instead of only on <Tab>. :help cmdline-autocompletion.
vim.api.nvim_create_autocmd("CmdlineChanged", {
    group = vim.api.nvim_create_augroup("user_cmdline_autocomplete", { clear = true }),
    pattern = { ":", "/", "?" },
    callback = function() vim.fn.wildtrigger() end,
})
-- Keep <Up>/<Down> as history navigation while the popup is open.
map("c", "<Up>", function() return vim.fn.wildmenumode() == 1 and "<C-e><Up>" or "<Up>" end, { expr = true })
map("c", "<Down>", function() return vim.fn.wildmenumode() == 1 and "<C-e><Down>" or "<Down>" end, { expr = true })

-- Grep project into the quickfix list. The trailing "." is required, else rg
-- reads (empty) stdin instead of the project. Walk results with ]q / [q.
map("n", "<C-g>", function()
    local query = vim.fn.input("Grep: ")
    if query == "" then return end
    vim.cmd("silent grep! " .. vim.fn.shellescape(query, true) .. " .")
    if vim.tbl_isempty(vim.fn.getqflist()) then
        vim.notify("Grep: no matches for " .. query, vim.log.levels.INFO)
    else
        vim.cmd("copen")
    end
end, { desc = "Grep project" })

-- Diagnostics: <leader>d = this file (loclist, ]l/[l), <leader>D = project (qf).
map("n", "<leader>d", function() vim.diagnostic.setloclist({ open = true }) end, { desc = "Diagnostics (file)" })
map("n", "<leader>D", function() vim.diagnostic.setqflist({ open = true }) end, { desc = "Diagnostics (project)" })

-- Run a TUI in a centered floating terminal. opts: { title, cwd, on_close }.
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
            if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
            if opts.on_close then opts.on_close() end
        end,
    })
    vim.cmd("startinsert")
end

-- lazygit in the current file's repo; reloads any files it changed on quit.
map("n", "<leader>g", function()
    if vim.fn.executable("lazygit") == 0 then
        vim.notify("lazygit is not on $PATH", vim.log.levels.ERROR)
        return
    end
    local dir = vim.fn.expand("%:p:h")
    if dir == "" then dir = vim.fn.getcwd() end
    float_term({ "lazygit" }, { title = " lazygit ", cwd = dir, on_close = function() vim.cmd("checktime") end })
end, { desc = "lazygit" })

-- Markdown preview: render the current buffer with glow (quit the pager with q).
map("n", "<leader>m", function()
    if vim.fn.executable("glow") == 0 then
        vim.notify("glow is not on $PATH", vim.log.levels.ERROR)
        return
    end
    local tmp = vim.fn.tempname() .. ".md"
    vim.fn.writefile(vim.api.nvim_buf_get_lines(0, 0, -1, false), tmp)
    float_term({ "glow", "-p", tmp }, { title = " markdown ", on_close = function() pcall(vim.fn.delete, tmp) end })
end, { desc = "Markdown preview (glow)" })
