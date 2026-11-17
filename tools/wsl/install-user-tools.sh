#!/usr/bin/env bash
set -euo pipefail
test "$(id -u)" -ne 0
test "$(uname -m)" = x86_64
mkdir -p "$HOME/.local/bin" "$HOME/.local/opt" "$HOME/.cache/nvim-elp-setup"
cache="$HOME/.cache/nvim-elp-setup"
curl --fail --silent --show-error --location --retry 3 \
  https://github.com/neovim/neovim/releases/download/v0.11.5/nvim-linux-x86_64.tar.gz \
  --output "$cache/nvim.tar.gz"
mkdir -p "$HOME/.local/opt/nvim-0.11.5"
tar -xzf "$cache/nvim.tar.gz" --strip-components=1 -C "$HOME/.local/opt/nvim-0.11.5"
ln -sfn "$HOME/.local/opt/nvim-0.11.5/bin/nvim" "$HOME/.local/bin/nvim"
curl --fail --silent --show-error --location --retry 3 \
  https://github.com/WhatsApp/erlang-language-platform/releases/download/2026-10-14/elp-linux-x86_64-unknown-linux-gnu-otp-27.3.tar.gz \
  --output "$cache/elp.tar.gz"
mkdir -p "$HOME/.local/opt/elp-2026-10-14"
tar -xzf "$cache/elp.tar.gz" -C "$HOME/.local/opt/elp-2026-10-14"
chmod +x "$HOME/.local/opt/elp-2026-10-14/elp"
ln -sfn "$HOME/.local/opt/elp-2026-10-14/elp" "$HOME/.local/bin/elp"
curl --fail --silent --show-error --location --retry 3 \
  https://github.com/erlang/rebar3/releases/download/3.27.0/rebar3 \
  --output "$HOME/.local/bin/rebar3"
chmod +x "$HOME/.local/bin/rebar3"
printf '%s\n' 'Installed native Linux Neovim, ELP, and rebar3 in ~/.local.'
