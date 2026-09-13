# wezterm.lua をホームディレクトリに .wezterm.lua としてコピーする。
# 既存のファイルがある場合は .bak を付けて退避する。
# Windows PowerShell 5.1 でも日本語が化けないよう、このファイルは UTF-8 BOM 付きで保存する。

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

# WezTerm 本体と pwsh は無いと起動できない。フォントは見た目だけなので数には入れない。
$missing = 0

if (-not (Get-Command wezterm -ErrorAction SilentlyContinue)) {
    Write-Warning "WezTerm が見つかりません。次のコマンドでインストールできます:`n  winget install wez.wezterm"
    $missing++
}

if (-not (Get-Command pwsh -ErrorAction SilentlyContinue)) {
    Write-Warning "PowerShell 7 (pwsh) が見つかりません。既定シェルに指定しているので入れてください:`n  winget install Microsoft.PowerShell"
    $missing++
}

$fontInstalled = Get-ChildItem "$env:WINDIR\Fonts", "$env:LOCALAPPDATA\Microsoft\Windows\Fonts" -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "JetBrainsMonoNerdFont*" } |
    Select-Object -First 1
if (-not $fontInstalled) {
    Write-Warning "JetBrainsMono Nerd Font が入っていません（任意）。入れると意図通りの見た目になります:`n  winget install DEVCOM.JetBrainsMonoNerdFont"
}

if ($missing -gt 0) {
    Write-Warning ("WezTerm の起動に必要なものが {0} 件足りません。上の案内どおりインストールしてから WezTerm を起動してください。" -f $missing)
}
