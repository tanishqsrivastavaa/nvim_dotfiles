---@brief
---
--- https://github.com/astral-sh/ruff
---
--- Ruff's built-in language server (`ruff server`): Python *formatter* + *linter*.
--- Pyright still handles type diagnostics; ruff adds lint diagnostics (pyflakes
--- F-codes, pycodestyle E-codes, etc. — its default rule set, or whatever a
--- project pyproject.toml / ruff.toml specifies). To silence ruff's linter and
--- keep it formatter-only, set `lint = { enable = false }` below.

---@type vim.lsp.Config
return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'ruff.toml',
    '.ruff.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    '.git',
  },
  init_options = {
    settings = {
      -- Lint + format. Pyright owns type diagnostics; ruff adds lint diagnostics.
      lint = { enable = true },
    },
  },
}
