local root = assert(vim.env.ELP_VERIFY_ROOT, 'Missing verification project')
local report = { project = root }
vim.cmd.cd(root)
vim.cmd.edit(root .. '/src/ferl_app.erl')
vim.schedule(function()
  local ok, err = xpcall(function()
    local buffer = vim.api.nvim_get_current_buf()
    local client
    assert(vim.wait(30000, function()
      client = vim.lsp.get_clients({ bufnr = buffer, name = 'elp' })[1]
      return client and client.initialized
    end, 100), 'ELP did not initialize')
    assert(#vim.lsp.get_clients({ bufnr = buffer }) == 1, 'Expected ELP as the only Erlang client')
    assert(client.root_dir == root, 'Incorrect project root: ' .. tostring(client.root_dir))
    local original = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
    local original_disk = vim.fn.readfile(root .. '/src/ferl_app.erl')
    client:notify('textDocument/didSave', { textDocument = { uri = vim.uri_from_bufnr(buffer) } })
    assert(vim.wait(30000, function() return #vim.diagnostic.get(buffer) > 0 end, 100),
      'No baseline diagnostics received')
    vim.wait(700, function() return false end, 50)
    for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
      assert(diagnostic.code ~= 'L0003', 'Unknown application persists')
      assert(not diagnostic.message:find('ferl_sup:start_link/0', 1, true),
        'Valid supervisor function is incorrectly undefined')
    end
    report.application_recognized = true
    local function request(method, position)
      local done, result, request_error
      assert(client:request(method, {
        textDocument = { uri = vim.uri_from_bufnr(buffer) }, position = position,
      }, function(e, r)
        request_error, result, done = e, r, true
      end, buffer), 'Request rejected: ' .. method)
      assert(vim.wait(15000, function() return done end, 100), 'Request timed out: ' .. method)
      assert(not request_error, vim.inspect(request_error))
      return result
    end
    local call_line, stop_line
    for index, line in ipairs(original) do
      if line:find('ferl_sup:start_link', 1, true) then call_line = index end
      if line:match('^%s*ok%.') then stop_line = index end
    end
    assert(call_line and stop_line, 'Unexpected fixture content')
    local definition = request('textDocument/definition', { line = call_line - 1, character = 16 })
    assert(definition and not vim.tbl_isempty(definition), 'Definition lookup returned no result')
    local location = definition[1] or definition
    assert((location.uri or location.targetUri):find('ferl_sup.erl', 1, true), 'Incorrect definition target')
    report.go_to_definition = true
    local completion = request('textDocument/completion', { line = call_line - 1, character = 13 })
    local found_completion = false
    for _, item in ipairs((completion and (completion.items or completion)) or {}) do
      if item.label:find('start_link', 1, true) then found_completion = true end
    end
    assert(found_completion, 'Completion did not include start_link')
    report.lsp_completion = true
    vim.api.nvim_exec_autocmds('InsertEnter', { buffer = buffer })
    local completion_source = false
    for _, source in ipairs(require('cmp').get_config().sources) do
      if source.name == 'nvim_lsp' then completion_source = true end
    end
    assert(completion_source, 'nvim-cmp is missing its LSP source')
    report.completion_menu_configured = true

    local function wait_for_message(fragment)
      assert(vim.wait(20000, function()
        for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
          if diagnostic.message:lower():find(fragment:lower(), 1, true) then return true end
        end
        return false
      end, 100), 'Missing unsaved diagnostic: ' .. fragment .. '\n' .. vim.inspect(vim.diagnostic.get(buffer)))
      assert(vim.bo[buffer].modified, 'Probe must stay unsaved')
    end
    vim.api.nvim_buf_set_lines(buffer, -1, -1, false, { '', 'live_probe() -> .' })
    wait_for_message('Missing')
    report.unsaved_syntax_diagnostics = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, original)
    vim.api.nvim_buf_set_lines(buffer, call_line - 1, call_line, false, { '    ferl_sup:missing_live_probe().' })
    wait_for_message('missing_live_probe')
    report.unsaved_undefined_function_diagnostics = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, original)
    vim.api.nvim_buf_set_lines(buffer, stop_line - 1, stop_line, false, { '    MissingLiveVariable.' })
    wait_for_message('MissingLiveVariable')
    report.unsaved_unbound_variable_diagnostics = true
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, original)
    assert(vim.wait(20000, function()
      for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
        if diagnostic.code == 'L0003'
          or diagnostic.message:find('MissingLiveVariable', 1, true)
          or diagnostic.message:find('missing_live_probe', 1, true) then return false end
      end
      return true
    end, 100), 'Diagnostics did not clear after correcting the buffer')
    report.diagnostics_clear_without_saving = true
    assert(vim.deep_equal(original_disk, vim.fn.readfile(root .. '/src/ferl_app.erl')),
      'The diagnostic probe must not write to disk')
    report.no_auto_save = true
    assert(pcall(vim.treesitter.language.add, 'erlang'), 'Erlang parser missing')
    report.erlang_syntax_highlighting = true
  end, debug.traceback)
  report.success = ok
  if not ok then report.error = err; vim.api.nvim_err_writeln(err) end
  vim.fn.writefile({ vim.json.encode(report) }, assert(vim.env.ELP_VERIFY_REPORT))
  print(vim.json.encode(report))
  for _, client in ipairs(vim.lsp.get_clients()) do client:stop() end
  vim.wait(3000, function() return #vim.lsp.get_clients() == 0 end, 100)
  vim.cmd(ok and 'qa!' or 'cquit 1')
end)
