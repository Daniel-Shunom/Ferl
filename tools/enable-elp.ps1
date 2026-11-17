$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path $PSScriptRoot -Parent
$elpConfigPath = Join-Path $workspaceRoot '.tools\elp\neovim.lua'
$elpBinaryPath = Join-Path $workspaceRoot '.tools\elp\elp.exe'
if (!(Test-Path -LiteralPath $elpBinaryPath)) { throw "ELP is missing: $elpBinaryPath" }
if (!(Test-Path -LiteralPath $elpConfigPath)) { throw "ELP config is missing: $elpConfigPath" }
$configBase = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:LOCALAPPDATA }
$appName = if ($env:NVIM_APPNAME) { $env:NVIM_APPNAME } else { 'nvim' }
$configPath = Join-Path $configBase "$appName\lua\configs\lspconfig.lua"
if (!(Test-Path -LiteralPath $configPath)) { throw "Neovim LSP config is missing: $configPath" }
$installDirectory = Join-Path $env:LOCALAPPDATA 'Programs\ELP'
$moduleDirectory = Join-Path $configBase "$appName\lua\configs\lsp"
$modulePath = Join-Path $moduleDirectory 'elp.lua'
$backupStamp = Get-Date -Format yyyyMMdd-HHmmss-fff
New-Item -ItemType Directory -Path $installDirectory, $moduleDirectory -Force | Out-Null
$installedBinary = Join-Path $installDirectory 'elp.exe'
$binaryMatches = (Test-Path -LiteralPath $installedBinary) -and
    ((Get-FileHash -LiteralPath $elpBinaryPath).Hash -eq (Get-FileHash -LiteralPath $installedBinary).Hash)
if (!$binaryMatches) {
    Copy-Item -LiteralPath $elpBinaryPath -Destination $installedBinary -Force
}
$moduleContents = [IO.File]::ReadAllText($elpConfigPath)
$moduleContents = $moduleContents.Replace("'C:/Users/danie/ferl/.tools/elp/elp.exe'", "vim.fs.joinpath(vim.env.LOCALAPPDATA, 'Programs', 'ELP', 'elp.exe')")
if ($moduleContents.Contains('C:/Users/danie/ferl')) { throw 'ELP module still refers to the staging project.' }
if (Test-Path -LiteralPath $modulePath) {
    Copy-Item -LiteralPath $modulePath -Destination "$modulePath.before-elp-$backupStamp.bak"
}
[IO.File]::WriteAllText($modulePath, $moduleContents, [Text.UTF8Encoding]::new($false))
$contents = [IO.File]::ReadAllText($configPath)
$oldBlock = '(?m)^-- Local ELP live diagnostics \(Windows\)\r?\n--[^\r\n]*\r?\nvim\.lsp\.config\("elp",[^\r\n]*\)\r?\nvim\.lsp\.enable\("elp"\)\r?\n?'
$updated = [regex]::Replace($contents, $oldBlock, '')
$marker = '-- User-wide ELP live diagnostics (Windows)'
$managedBlock = '(?ms)^-- User-wide ELP live diagnostics \(Windows\)\r?\n.*?^-- End user-wide ELP configuration\r?\n?'
$updated = [regex]::Replace($updated, $managedBlock, '')
$previousBlock = '(?m)^-- User-wide ELP live diagnostics \(Windows\)\r?\n--[^\r\n]*\r?\nvim\.lsp\.config\("elp",[^\r\n]*\)\r?\nvim\.lsp\.enable\("elp"\)\r?\n?'
$updated = [regex]::Replace($updated, $previousBlock, '')
if ($updated.Contains($marker)) { throw 'Unrecognized existing ELP block; no LSP config changes made.' }
$addition = @"

$marker
local elp_config = require("configs.lsp.elp")
-- One diagnostic source; Erlang LS retains navigation and completion.
vim.lsp.config("erlangls", {
  handlers = {
    ["textDocument/publishDiagnostics"] = function() end,
    ["window/showMessage"] = elp_config.handlers["window/showMessage"],
  },
})
vim.lsp.config("elp", elp_config)
vim.lsp.enable("elp")
-- End user-wide ELP configuration
"@
$enableServers = 'vim.lsp.enable(servers)'
if ($updated.Contains($enableServers)) {
    $updated = $updated.Replace($enableServers, $addition + "`n`n" + $enableServers)
} else {
    throw 'Cannot find the server enable call; no LSP config changes made.'
}
if ($updated -ne $contents) {
    $backupPath = "$configPath.before-elp-$backupStamp.bak"
    Copy-Item -LiteralPath $configPath -Destination $backupPath
    [IO.File]::WriteAllText($configPath, $updated, [Text.UTF8Encoding]::new($false))
    Write-Host "Enabled user-wide ELP live diagnostics. Backup: $backupPath"
} else {
    Write-Host 'ELP is already enabled.'
}
Write-Host "ELP installed for all projects: $installDirectory\elp.exe"
Write-Host 'Restart Neovim and open an Erlang file. :LspInfo should list elp and erlangls.'
