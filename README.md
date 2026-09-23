# wezterm-config

Windows / PowerShell / Neovim 向けの [WezTerm](https://wezfurlong.org/wezterm/) 設定です。
キーを覚えていなくてもコマンドパレットとマウスで一通り操作できることを優先しています。

## 特徴

- **コマンドパレット中心の操作**。`Ctrl+Shift+P` でペイン / タブ / シェル / 表示 / 設定のグループが出て、Enter でその中の操作一覧が開きます。英字（`split`、`tab`、`close` など）で絞り込めます
- **簡易ヘルプ**。`Ctrl+Shift+H` で頻出キーだけを画面に表示します
- **GUI 操作**。タブの × と ＋、＋の右クリックでシェル選択、スクロールバー、右クリック貼り付け、ドラッグ選択で自動コピー、Ctrl+ホイールで文字サイズ変更
- **ペイン**。左右 / 上下分割、シェルを選んで分割、`Alt+矢印` または `Alt+h/j/k/l` で移動、番号で移動・入れ替え、最大化、3ペインの IDE 風レイアウト
- **タブ**。作業ディレクトリ名と前面プロセスのアイコンを表示。別タブに新しい出力があると印が付きます
- **workspace**。プロジェクト単位の作業空間の作成と切り替え。複数あるときは右上に現在地と総数を表示
- **ブックマークディレクトリ**。パレットの「add bookmark」でいまの場所を登録し、`Ctrl+Shift+O` で選ぶと、いまのペインでそのディレクトリへ移動します（PowerShell / cmd / Git Bash 対応）
- **隠れているものの表示**。ペインを最大化中は右上に「ズーム中 1/N ペイン」と出るので、裏に他のペインがあることが分かります
- **完了通知**。フォーカス外のペインでベルが鳴ると OS の通知を出します（長いビルドやテストの終了を別タブで待つときに）
- **Neovim 連携**。`file.ts:42` 形式のパスを Ctrl+クリックすると既存の Neovim で開きます。`Alt+h/j/k/l` は Neovim 内では Neovim に渡します
- **環境対応**。リモートデスクトップ接続時は描画を軽量化。Windows 以外でも動作します
- **配色**。Tokyo Night Moon（LazyVim 既定の Neovim 配色と同じ）。半透明 + Acrylic。タブバーとステータスの色もスキームに追従します
- **常に最前面**。パレットの「always on top」で切り替え（Windows のみ）

## インストール

1. WezTerm をインストールします

   ```powershell
   winget install wez.wezterm
   ```

2. `wezterm.lua` をホームディレクトリに `.wezterm.lua` として置きます

   ```powershell
   git clone https://github.com/Taka-S-dev/wezterm-config.git
   cd wezterm-config
   .\install.ps1
   ```

   `install.ps1` がするのは設定のコピーと、足りない前提（WezTerm、PowerShell 7、フォント）の報告だけで、何かをインストールすることはありません。手動なら `Copy-Item wezterm.lua ~\.wezterm.lua` で同じです。

   `~/.wezterm.lua` をこのリポジトリへのシンボリックリンクにしている場合は、リンクを保ったまま何もしません（編集がそのまま設定に反映される状態を壊さないため）。別の場所へのリンクなら中止します。

3. フォントを入れます（任意）

   ```powershell
   winget install DEVCOM.JetBrainsMonoNerdFont
   ```

   無くても動きます。その場合は Cascadia Mono か Consolas に落ち、アイコンは WezTerm 内蔵の記号で表示されます。
   日本語は Windows 標準の BIZ UDGothic を使います。Windows 以外では Noto Sans JP など等幅の日本語フォントを入れてください。

## 最初に覚えるキー

| キー | 動作 |
|---|---|
| `Ctrl+Shift+P` | コマンドパレット。迷ったらこれ |
| `Ctrl+Shift+H` | 簡易ヘルプ |
| `Ctrl+Shift+T` | 新しいタブ |
| `Ctrl+Shift+D` | ペインを左右に分割 |
| `Ctrl+Shift+E` | ペインを上下に分割 |
| `Alt+矢印` | ペイン移動（クリックでも可） |
| `Alt+1`〜`9` | タブ番号で切り替え |
| `Ctrl+Shift+F` | 画面内を検索 |
| `Ctrl+Shift+O` | ブックマークのプロジェクトへ移動 |
| `Shift+Enter` | Claude Code / Copilot CLI / Codex CLI で改行（各 CLI が改行として受け付ける入力に変換） |
| 右クリック | 貼り付け |

分割キーに `Alt` を足す（`Ctrl+Shift+Alt+D` など）と、シェルを選んでから分割します。

### Leader キー（tmux 風）

`Ctrl+q` を押してから 1 秒以内に次のキーを押します。慣れるまでは不要です。

| キー | 動作 |
|---|---|
| `\|` / `-` | 左右 / 上下に分割 |
| `h` `j` `k` `l` | ペイン移動 |
| `r` | サイズ変更モード（h/j/k/l か矢印、Esc で終了） |
| `z` | ペイン最大化 / 元に戻す |
| `x` | ペインを閉じる |
| `X` | ほかのペインをすべて閉じる（確認あり） |
| `o` | ペインの配置を回転 |
| `S` | 番号で選んでペイン入れ替え |
| `i` | IDE 風レイアウト（メイン + サブ + 下にターミナル） |
| `c` / `n` / `p` / `,` | タブの新規 / 次 / 前 / 名前変更 |
| `w` / `W` | workspace の切り替え / 新規作成 |
| `s` | シェル / workspace のランチャー |
| `[` / `Space` / `f` | コピーモード / クイック選択 / 検索 |
| `R` | 設定を再読み込み |
| `?` | 簡易ヘルプ |
| `Ctrl+q` | 本来の Ctrl+q をアプリに送る |

全キーバインドは `wezterm show-keys`、またはパレットの「keys help」で確認できます。

## カスタマイズ

- **マシン固有の設定**は `~/.wezterm.local.lua` に書きます。存在すれば自動で読み込まれ、リポジトリには含まれません

  ```lua
  return function(config, local_opts)
    -- SSH 接続先
    table.insert(config.ssh_domains, {
      name = "server",
      remote_address = "192.168.1.10",
      username = "me",
      multiplexing = "WezTerm",
    })
    -- ブックマークディレクトリ（Ctrl+Shift+O）をまとめて登録したい場合。
    -- 1 件ずつならパレットの「add bookmark」で追加でき、こちらは不要です
    local_opts.bookmarks = {
      { name = "myapp", path = "C:/src/myapp" },
      { name = "notes", path = "~/Documents/notes" },
    }
    local_opts.bookmark_roots = { "~/src" }
  end
  ```

- **配色**は先頭付近の `SCHEME` を書き換えます（候補は `wezterm ls-schemes`）。タブバーとステータスの色はスキームから自動で決まります。Catppuccin Mocha は公式の補助色を `PALETTES` に持っていて、それ以外は背景色と ANSI 色から導出します。導出は暗い配色向けなので、明るいスキームではタブバーの階調が見づらいことがあります
- **パレットの項目**は `PALETTE_GROUPS` に 1 行足すと、グループのサブメニューと個別項目の両方に出ます
- **簡易ヘルプの内容**は `HELP_LINES` を編集します
- **既定のシェル**は `default_prog`、＋ボタンのメニューは `launch_menu` です
- **半透明が不要**なら `window_background_opacity` の周辺を削除します

## Neovim へのジャンプを使う

Neovim 側でサーバーを起動しておくと、Ctrl+クリックで既存のインスタンスにファイルが開きます。init.lua に次を追加します。

```lua
-- Windows
vim.fn.serverstart([[\\.\pipe\nvim-wezterm]])
-- macOS / Linux
vim.fn.serverstart("/tmp/nvim-wezterm.sock")
```

サーバーが無い場合は右側に新しい Neovim のペインが開きます。

## 新しいペインを今いるディレクトリで開く

分割や IDE 風レイアウトで開くペイン、ブックマークの登録、タブに出る作業ディレクトリ名は、いずれも元のペインの現在地を使います。Windows のローカルペインでは WezTerm がプロセス情報から現在地を推定するので、多くの環境ではそのままで動きます。推定できない環境（SSH 先やマルチプレクサ経由、プロセス情報を読み取れない場合など）では、シェルが現在地を通知している（OSC 7）必要があります。通知が無いと、新しいペインはホームディレクトリで開き、ブックマーク登録はパスの手入力を求めます。

PowerShell では `$PROFILE` に次を足します。

```powershell
if ($env:WEZTERM_PANE) {
    $script:WezOrigPrompt = $function:prompt
    function prompt {
        $loc = $ExecutionContext.SessionState.Path.CurrentLocation
        if ($loc.Provider.Name -eq 'FileSystem') {
            $esc  = [char]27
            $path = [uri]::EscapeUriString(($loc.ProviderPath -replace '\\', '/'))
            $Host.UI.Write("$esc]7;file://$env:COMPUTERNAME/$path$esc\")
        }
        & $script:WezOrigPrompt
    }
}
```

bash / zsh は WezTerm 同梱の [shell integration](https://wezterm.org/shell-integration.html) を読み込めば同じ通知が出ます。

## 動作確認環境

- WezTerm 20240203-110809-5046fc22
- Windows 11
- PowerShell 7

## License

MIT
