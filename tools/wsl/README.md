# WSL Neovim and ELP

Installed for user `danie` in the `Ubuntu` WSL2 distribution.

- NvChad configuration: `~/.config/nvim`, copied from the Windows config with
  its plugin lockfile, mappings, theme, completion setup, and formatter settings.
- Neovim 0.11.5: `~/.local/opt/nvim-0.11.5`, linked from `~/.local/bin/nvim`.
- Linux ELP 1.1.0+build-2026-10-14: `~/.local/opt/elp-2026-10-14`, linked from
  `~/.local/bin/elp`.
- rebar3 3.27.0: `~/.local/bin/rebar3`.
- Erlang/OTP 27.3.4.19 and its sources/headers: Ubuntu packages from the signed
  Team RabbitMQ Erlang repository. No RabbitMQ server was installed.
- Native Lua language server and Stylua installed with Mason. Erlang Tree-sitter
  highlighting is installed. Other existing language configurations are kept;
  only servers whose executable is available are enabled.

`~/.local/bin` is prepended in `.bashrc` and `.profile`; both files were backed
up before editing. Existing Homebrew installations remain present. The normal
interactive shell can select Homebrew's Erlang independently of `/usr/bin/erl`.

## Use

Open Ubuntu, then run:

```sh
cd /mnt/c/Users/danie/ferl
nvim src/ferl_app.erl
```

The server is configured for all Erlang projects. Only ELP is enabled for
Erlang; the Windows Erlang LS/ELP combination and URI workaround are absent
from this WSL configuration. Informational server popups are filtered while
warnings and errors retain their normal handler.

ELP's compiler diagnostics normally require a save notification. The Linux
config requests these checks after a 600 ms editing pause. The server uses
the open document's text; this does not save or auto-save the file.

## Verification

`verify.sh` tests a separate fixture; `verify-current-project.sh` tests the
existing `ferl` project using unsaved buffer edits. Both use the full installed
NvChad config. Tests cover application detection (including absence of L0003),
definition navigation, completion, live syntax/undefined-function/unbound-variable
diagnostics, clearing diagnostics after corrections, and unchanged source files
on disk. Reports are saved in `~/.cache/nvim-elp-setup/verification*.json`.

The Windows setup has not been removed or modified by this migration.
