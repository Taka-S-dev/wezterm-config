# wezterm.lua をホームディレクトリに .wezterm.lua としてコピーする。
# 既存のファイルがある場合は .bak を付けて退避する。

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "wezterm.lua"
$target = Join-Path $HOME ".wezterm.lua"

if (-not (Test-Path $source)) {
    Write-Error "wezterm.lua が見つかりません: $source"
}

if (Test-Path $target) {
    $backup = "$target.bak"
    Copy-Item $target $backup -Force
    Write-Host "既存の設定を退避しました: $backup"
}

Copy-Item $source $target -Force
Write-Host "配置しました: $target"

if (-not (Get-Command wezterm -ErrorAction SilentlyContinue)) {
    Write-Host "WezTerm が見つかりません。次のコマンドでインストールできます:"
    Write-Host "  winget install wez.wezterm"
}

$fontInstalled = Get-ChildItem "$env:WINDIR\Fonts", "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "JetBrainsMonoNerdFont*" } |
    Select-Object -First 1
if (-not $fontInstalled) {
    Write-Host "JetBrainsMono Nerd Font が入っていません。入れると意図通りの見た目になります:"
    Write-Host "  winget install DEVCOM.JetBrainsMonoNerdFont"
}
