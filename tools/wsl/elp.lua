return {
  cmd = { vim.fn.expand('~/.local/bin/elp'), 'server' },
  filetypes = { 'erlang' },
  root_markers = { '.elp.toml', 'rebar.config', 'erlang.mk', '.git' },
  flags = { debounce_text_changes = 200 },
  settings = {
    elp = { diagnostics = { onSave = { enable = false } } },
  },
  handlers = {
    ['window/showMessage'] = function(err, params, context, config)
      if params and params.type and params.type >= vim.lsp.protocol.MessageType.Info then
        return
      end
      return vim.lsp.handlers['window/showMessage'](err, params, context, config)
    end,
  },
  on_attach = function(client, buffer)
    -- ELP's compiler checks use the in-memory document, but are triggered by
    -- didSave. Request them after a short editing pause without writing files.
    -- This notification only schedules diagnostics for an already-open file.
    local timer = assert(vim.uv.new_timer())
    local function close_timer()
      if not timer:is_closing() then timer:stop(); timer:close() end
    end
    vim.api.nvim_buf_attach(buffer, false, {
      on_lines = function()
        if timer:is_closing() then return true end
        timer:start(600, 0, vim.schedule_wrap(function()
          if client:is_stopped() or not vim.api.nvim_buf_is_valid(buffer)
            or not vim.lsp.buf_is_attached(buffer, client.id) then
            close_timer()
            return
          end
          client:notify('textDocument/didSave', {
            textDocument = { uri = vim.uri_from_bufnr(buffer) },
          })
        end))
      end,
      on_detach = close_timer,
    })
    vim.api.nvim_create_autocmd('LspDetach', {
      buffer = buffer,
      callback = function(event)
        if event.data.client_id == client.id then close_timer(); return true end
      end,
    })
  end,
}
