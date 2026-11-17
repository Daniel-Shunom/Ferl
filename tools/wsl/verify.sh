#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
setup_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export ELP_VERIFY_ROOT="$HOME/.cache/nvim-elp-setup/verification-project"
export ELP_VERIFY_REPORT="$HOME/.cache/nvim-elp-setup/verification.json"
mkdir -p "$ELP_VERIFY_ROOT/src"
cp /mnt/c/Users/danie/ferl/src/ferl*.erl /mnt/c/Users/danie/ferl/src/ferl.app.src "$ELP_VERIFY_ROOT/src/"
cp /mnt/c/Users/danie/ferl/rebar.config "$ELP_VERIFY_ROOT/"
printf '[eqwalizer]\nenable_all = false\n' > "$ELP_VERIFY_ROOT/.elp.toml"
nvim --headless -n -c "luafile $setup_dir/verify.lua"
