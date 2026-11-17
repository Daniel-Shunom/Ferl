#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
nvim --headless -n -c "luafile $setup_dir/install-editor-tools.lua"
nvim --headless -n \
  -c "lua require('lazy').load({plugins = {'nvim-treesitter'}})" \
  -c "lua assert(pcall(vim.treesitter.language.add, 'erlang'), 'Erlang parser is missing')" +qa
