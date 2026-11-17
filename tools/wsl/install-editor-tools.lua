vim.schedule(function()
  local ok, err = xpcall(function()
    local registry = require('mason-registry')
    local refreshed = false
    registry.refresh(function() refreshed = true end)
    assert(vim.wait(120000, function() return refreshed end, 100), 'Mason registry refresh timed out')
    for _, name in ipairs({ 'lua-language-server', 'stylua' }) do
      local package = registry.get_package(name)
      if not package:is_installed() then
        local done = false
        package:install():once('closed', function() done = true end)
        assert(vim.wait(120000, function() return done end, 100), name .. ' installation timed out')
        assert(package:is_installed(), name .. ' installation failed')
      end
      print('Installed ' .. name)
    end
  end, debug.traceback)
  if not ok then vim.api.nvim_err_writeln(err) end
  vim.cmd(ok and 'qa!' or 'cquit 1')
end)
