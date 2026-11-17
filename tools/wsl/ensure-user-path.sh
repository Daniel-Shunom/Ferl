#!/usr/bin/env bash
set -euo pipefail
python3 - <<'PY'
from pathlib import Path
from datetime import datetime
import shutil

marker = '# Native WSL Neovim and Erlang tools'
addition = '''
# Native WSL Neovim and Erlang tools
case "$PATH" in
  "$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
'''
for name in ('.bashrc', '.profile'):
    path = Path.home() / name
    contents = path.read_text() if path.exists() else ''
    if marker in contents:
        continue
    if path.exists():
        shutil.copy2(path, path.with_name(name + '.before-nvim-elp-' + datetime.now().strftime('%Y%m%d-%H%M%S')))
    path.write_text(contents + addition)
PY
