#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export ELP_VERIFY_ROOT=/mnt/c/Users/danie/ferl
export ELP_VERIFY_REPORT="$HOME/.cache/nvim-elp-setup/verification-ferl.json"
nvim --headless -n -c "luafile $setup_dir/verify.lua"
