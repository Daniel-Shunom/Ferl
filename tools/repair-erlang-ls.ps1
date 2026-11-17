$ErrorActionPreference = 'Stop'
$nvim = (Get-Command nvim -ErrorAction Stop).Source
$gitTools = 'C:\Program Files\Git\usr\bin'
if (!(Test-Path "$gitTools\rm.exe")) { throw "Git's rm.exe is missing at $gitTools" }
$originalPath = $env:Path
$luaPath = Join-Path $PSScriptRoot 'repair-erlang-ls.lua'
try {
    $env:Path = "$originalPath;$gitTools"
    & $nvim --headless -i NONE -c "lua dofile([[$($luaPath.Replace('\', '/'))]])"
    if ($LASTEXITCODE -ne 0) { throw 'Mason installation failed; see output above.' }

    $configRoot = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { $env:LOCALAPPDATA }
    $appName = if ($env:NVIM_APPNAME) { $env:NVIM_APPNAME } else { 'nvim' }
    $configPath = Join-Path $configRoot "$appName\lua\configs\lspconfig.lua"
    if (Test-Path $configPath) {
        $contents = [IO.File]::ReadAllText($configPath)
        $updated = $contents.Replace('"erlang_ls"', '"erlangls"').Replace("'erlang_ls'", "'erlangls'")
        if ($contents -ne $updated) {
            $backupPath = "$configPath.before-erlang-repair-$(Get-Date -Format yyyyMMdd-HHmmss).bak"
            Copy-Item -LiteralPath $configPath -Destination $backupPath
            [IO.File]::WriteAllText($configPath, $updated, [Text.UTF8Encoding]::new($false))
            Write-Host "Corrected LSP name; backup: $backupPath"
        }
    }
    Write-Host 'Erlang LS installed. Restart Neovim and open an Erlang file.'
} finally {
    $env:Path = $originalPath
}
