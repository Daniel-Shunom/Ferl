return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      require('configs.lspconfig')
    end,
  },
  {
    'mason-org/mason.nvim',
    lazy = false,
    priority = 1000,
    opts = { PATH = 'prepend' },
    config = true,
    build = ':MasonUpdate',
  },
}
