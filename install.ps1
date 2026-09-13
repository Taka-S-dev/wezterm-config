# wezterm.lua をホームディレクトリに .wezterm.lua としてコピーする。
# 既存のファイルがある場合は .bak を付けて退避する。
# 配置先がシンボリックリンクのときはコピーしない（リンクを実体ファイルに
# 置き換えると、リポジトリを編集しても設定に反映されなくなる）。
# Windows PowerShell 5.1 でも日本語が化けないよう、このファイルは UTF-8 BOM 付きで保存する。

$ErrorActionPreference = "Stop"

$source = Join-Path $PSScriptRoot "wezterm.lua"
$target = Join-Path $HOME ".wezterm.lua"

if (-not (Test-Path $source)) {
    Write-Error "wezterm.lua が見つかりません: $source"
}

$sourcePath = (Resolve-Path -LiteralPath $source).Path

$existing = $null
if (Test-Path $target) {
    $existing = Get-Item -LiteralPath $target -Force
}

if ($existing -and $existing.LinkType -eq "SymbolicLink") {
    $linkTarget = @($existing.Target)[0]
    $linkPath = $linkTarget
    try { $linkPath = (Resolve-Path -LiteralPath $linkTarget -ErrorAction Stop).Path } catch { }
    if ($linkPath -eq $sourcePath) {
        Write-Host "すでにこのリポジトリへのリンクなので、コピーしません: $target"
    } else {
        Write-Error "$target は別の場所へのシンボリックリンクです ($linkPath)。上書きするとリンクが失われるため中止しました。入れ替えるなら手動で削除してから実行してください。"
    }
} else {
    if ($existing) {
        $backup = "$target.bak"
        Copy-Item -LiteralPath $target -Destination $backup -Force
        Write-Host "既存の設定を退避しました: $backup"
    }
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Host "配置しました: $target"
}

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
