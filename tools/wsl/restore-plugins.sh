#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
cp /mnt/c/Users/danie/AppData/Local/nvim/lazy-lock.json "$HOME/.config/nvim/lazy-lock.json"
nvim --headless -n '+Lazy! restore' +qa > "$HOME/.cache/nvim-elp-setup/plugins.log" 2>&1
tail -n 8 "$HOME/.cache/nvim-elp-setup/plugins.log"
