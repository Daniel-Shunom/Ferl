vim.schedule(function()
  local ok, err = pcall(function()
    require('lazy').load({ plugins = { 'mason.nvim' } })
    require('mason').setup()
    assert(vim.fn.executable('rm') == 1, 'rm.exe is not visible to Neovim')
    local pkg = require('mason-registry').get_package('erlang-ls')
    if pkg:is_installed() then
      print('Erlang LS is already installed')
      return
    end
    local done, success = false, false
    pkg:install():once('closed', function()
      success = pkg:is_installed()
      done = true
    end)
    assert(vim.wait(600000, function() return done end, 200), 'Installation timed out')
    assert(success, 'Installation failed. Check :MasonLog for details.')
    print('Erlang LS installation succeeded')
  end)
  if not ok then
    vim.api.nvim_err_writeln(tostring(err))
    vim.cmd('cquit 1')
  else
    vim.cmd('qa!')
  end
end)
