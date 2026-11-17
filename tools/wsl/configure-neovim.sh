#!/usr/bin/env bash
set -euo pipefail
test "$(id -u)" -ne 0
setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
windows_config=/mnt/c/Users/danie/AppData/Local/nvim
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
timestamp=$(date +%Y%m%d-%H%M%S)
if test -e "$config_dir"; then
  mv -- "$config_dir" "$config_dir.before-wsl-elp-$timestamp"
fi
mkdir -p "$config_dir"
tar -C "$windows_config" --exclude=.git --exclude=.vscode --exclude='*.bak' \
  --exclude='*.before-*' --exclude=.nvimlog -cf - . | tar -C "$config_dir" -xf -
install -m 644 "$setup_dir/elp.lua" "$config_dir/lua/configs/lsp/elp.lua"
install -m 644 "$setup_dir/lspconfig.lua" "$config_dir/lua/configs/lspconfig.lua"
install -m 644 "$setup_dir/plugins-lsp.lua" "$config_dir/lua/plugins/lsp.lua"
python3 - "$config_dir" <<'PY'
from pathlib import Path
import sys

config = Path(sys.argv[1])
init = config / 'init.lua'
text = init.read_text(encoding='utf-8')
init.write_text('vim.env.PATH = vim.fn.expand("~/.local/bin") .. ":" .. (vim.env.PATH or "")\n' + text, encoding='utf-8')
treesitter = config / 'lua/plugins/treesitter.lua'
text = treesitter.read_text(encoding='utf-8')
treesitter.write_text(text.replace('"cpp"', '"cpp", "erlang"'), encoding='utf-8')
# Match the stock Ubuntu Python executable used by the existing formatter.
conform = config / 'lua/configs/conform.lua'
text = conform.read_text(encoding='utf-8')
conform.write_text(text.replace('command = "python"', 'command = "python3"'), encoding='utf-8')
PY
for directory in backup swp undo; do mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/nvim/$directory"; done
printf 'Copied NvChad configuration to %s\n' "$config_dir"
export PATH="$HOME/.local/bin:$PATH"
nvim --headless -n '+Lazy! restore' +qa > "$HOME/.cache/nvim-elp-setup/plugins.log" 2>&1
