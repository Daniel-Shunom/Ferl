-- Preserve NvChad mappings/capabilities and the existing per-server settings.
require('nvchad.configs.lspconfig').defaults()
require('configs.diagnostics')

vim.lsp.config('elp', require('configs.lsp.elp'))
local servers = {
  'html', 'cssls', 'bashls', 'pyright', 'gleam', 'elp', 'cmake',
  'tailwindcss', 'hls',
}
for _, name in ipairs({ 'ts_ls', 'clangd', 'rust_analyzer' }) do
  vim.lsp.config(name, require('configs.lsp.' .. name))
  servers[#servers + 1] = name
end

-- Servers installed later through Mason become available on the next restart.
-- This keeps fresh WSL sessions free of missing-executable startup errors.
for _, name in ipairs(servers) do
  local config = vim.lsp.config[name]
  local cmd = config and config.cmd
  if type(cmd) == 'function'
    or (type(cmd) == 'table' and vim.fn.executable(cmd[1]) == 1) then
    vim.lsp.enable(name)
  end
end
