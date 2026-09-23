-- wezterm.lua（~/.wezterm.lua に配置する）
-- Windows / PowerShell / Neovim 向けの WezTerm 設定
--
-- 最初に覚えるキー:
--   Ctrl+Shift+H  簡易ヘルプ（頻出キーだけを画面に表示）
--   Ctrl+Shift+P  コマンドパレット（すべての操作を一覧から選べる。迷ったらまずこれ）
--                 F1 / Ctrl+Shift+Space でも開く
--   Ctrl+Shift+T  新しいタブ           Ctrl+Shift+W  タブを閉じる
--   Ctrl+Shift+D  ペインを左右に分割    Ctrl+Shift+E  ペインを上下に分割
--                 （Alt も足すとシェルを選んで分割）
--   Alt+h/j/k/l   ペイン移動（Alt+矢印も可）   Alt+1〜9  タブ切り替え
--   Ctrl+Shift+F  検索                 Ctrl+Shift+O  ブックマークのプロジェクトへ移動
--   右クリック     貼り付け
--
-- Leader キー（Ctrl+q）を押してからのキーは tmux 風のショートカット。
-- 詳細はファイル内の「キーバインド」セクションを参照。

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- 環境判定
--------------------------------------------------------------------------------

local is_windows = wezterm.target_triple:find("windows") ~= nil
local is_rdp = (os.getenv("SESSIONNAME") or ""):find("RDP") ~= nil

local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- 描画・パフォーマンス
--------------------------------------------------------------------------------

config.front_end = is_rdp and "Software" or "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = is_rdp and 30 or 120

config.animation_fps = 1
config.cursor_blink_rate = 0
config.default_cursor_style = "SteadyBar"

config.scrollback_lines = 20000
config.check_for_updates = false

--------------------------------------------------------------------------------
-- フォント
--------------------------------------------------------------------------------

-- 上から順に探索し、最初に見つかったものが等幅の主フォントになる。
-- 英数: JetBrainsMono Nerd Font → Cascadia Mono → Consolas
-- 日本語: BIZ UDGothic（等幅）→ Noto Sans JP → Yu Gothic UI（豆腐回避の最終手段）
-- Yu Gothic UI はプロポーショナルなので必ず最後に置くこと。
config.font = wezterm.font_with_fallback({
  { family = "JetBrainsMono Nerd Font", weight = "Regular" },
  { family = "Cascadia Mono", weight = "Regular" },
  { family = "Consolas", weight = "Regular" },
  { family = "BIZ UDGothic" },
  { family = "Noto Sans JP" },
  { family = "Symbols Nerd Font Mono", scale = 0.9 },
  { family = "Noto Color Emoji" },
  { family = "Yu Gothic UI" },
})
config.font_size = 11.0
config.line_height = 1.1
-- リガチャは使わない（=> や != がそのまま見えるほうがログを読みやすい）
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

config.treat_east_asian_ambiguous_width_as_wide = false
-- 日本語フォントを英字の大文字高さに合わせて拡大すると、行の高さを超えて
-- 下側が欠けるので、フォールバックの拡大はしない
config.use_cap_height_to_scale_fallback_fonts = false
config.warn_about_missing_glyphs = false

--------------------------------------------------------------------------------
-- 外観
--------------------------------------------------------------------------------

-- 配色はここだけで決める。タブバー・ステータスの色もこの名前から決まる。
-- 候補は `wezterm ls-schemes`、または https://wezterm.org/colorschemes/
local SCHEME = "Tokyo Night Moon"
config.color_scheme = SCHEME

-- タブバー・ステータス用の補助色。
-- 本体の 16 色には無い階調（背景の一段暗い色など）を使うので、
-- スキームが公式に定義しているものはここに書き、無いものは
-- スキームの背景色と ANSI 色から導出する。
local PALETTES = {
  ["Catppuccin Mocha"] = {
    base = "#1e1e2e", -- 選択中タブの背景
    mantle = "#181825", -- ホバー・パレットの背景
    crust = "#11111b", -- タブバーの地
    surface1 = "#45475a", -- 分割線・スクロールバー
    overlay0 = "#6c7086", -- 非選択タブの文字
    subtext0 = "#a6adc8", -- 控えめな文字
    text = "#cdd6f4", -- 通常の文字
    lavender = "#b4befe", -- 選択中タブの文字
    mauve = "#cba6f7", -- タブのアイコン
    peach = "#fab387", -- 未読出力の印
    red = "#f38ba8", -- LEADER 表示
    yellow = "#f9e2af", -- キーテーブル・ズーム表示
    teal = "#94e2d5", -- workspace 表示
  },
}

local function derive_palette(name)
  local s = wezterm.color.get_builtin_schemes()[name]
  if not s then
    return PALETTES["Catppuccin Mocha"]
  end
  local bg = wezterm.color.parse(s.background)
  local fg = wezterm.color.parse(s.foreground)
  -- ansi: 1=black 2=red 3=green 4=yellow 5=blue 6=magenta 7=cyan 8=white
  return {
    base = tostring(bg),
    mantle = tostring(bg:darken(0.15)),
    crust = tostring(bg:darken(0.3)),
    surface1 = tostring(bg:lighten(0.15)),
    overlay0 = s.brights[1],
    subtext0 = tostring(fg:darken(0.2):desaturate(0.3)),
    text = s.foreground,
    lavender = s.brights[5],
    mauve = s.ansi[6],
    peach = s.brights[4],
    red = s.ansi[2],
    yellow = s.ansi[4],
    teal = s.ansi[7],
  }
end

local C = PALETTES[SCHEME] or derive_palette(SCHEME)

config.colors = {
  tab_bar = {
    background = C.crust,
    active_tab = { bg_color = C.base, fg_color = C.lavender, intensity = "Bold" },
    inactive_tab = { bg_color = C.crust, fg_color = C.overlay0 },
    inactive_tab_hover = { bg_color = C.mantle, fg_color = C.subtext0 },
    new_tab = { bg_color = C.crust, fg_color = C.subtext0 },
    new_tab_hover = { bg_color = C.mantle, fg_color = C.text },
  },
  split = C.surface1,
  scrollbar_thumb = C.surface1,
}

-- タブバー: 閉じるボタン付きのタブ、＋ボタン、ウィンドウ操作ボタンを1行にまとめる
config.use_fancy_tab_bar = true
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.integrated_title_button_style = "Windows"
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = true
config.tab_max_width = 32
config.window_frame = {
  -- タブバーも日本語が出るようにフォールバックを付ける（タブ名やステータスに日本語を使うため）
  font = wezterm.font_with_fallback({
    { family = "JetBrainsMono Nerd Font", weight = "Bold" },
    { family = "Cascadia Mono", weight = "Bold" },
    { family = "BIZ UDGothic", weight = "Bold" },
    { family = "Noto Sans JP", weight = "Bold" },
    { family = "Yu Gothic UI", weight = "Bold" },
  }),
  font_size = 10.0,
  active_titlebar_bg = C.crust,
  inactive_titlebar_bg = C.crust,
}

config.enable_scroll_bar = true
config.min_scroll_bar_height = "2cell"

config.window_padding = { left = 6, right = 6, top = 6, bottom = 2 }
config.adjust_window_size_when_changing_font_size = false
config.initial_cols = 160
config.initial_rows = 44

-- 半透明 + Windows 11 の Acrylic（RDP では負荷になるので無効）
if is_windows and not is_rdp then
  config.window_background_opacity = 0.93
  config.win32_system_backdrop = "Acrylic"
end

-- アクティブpaneを目立たせる（VS Codeのフォーカス枠に相当）
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.65 }

-- コマンドパレットの見た目
config.command_palette_font_size = 12.0
config.command_palette_rows = 16
config.command_palette_bg_color = C.mantle
config.command_palette_fg_color = C.text

--------------------------------------------------------------------------------
-- シェル・入力
--------------------------------------------------------------------------------

if is_windows then
  config.default_prog = { "pwsh", "-NoLogo" }
end

-- ランチャー（＋ボタンの右クリック / Ctrl+Shift+P / Leader+s）から起動できるシェル一覧
config.launch_menu = {}
if is_windows then
  table.insert(config.launch_menu, { label = "PowerShell 7", args = { "pwsh", "-NoLogo" } })
  table.insert(config.launch_menu, { label = "Windows PowerShell", args = { "powershell", "-NoLogo" } })
  table.insert(config.launch_menu, { label = "Command Prompt", args = { "cmd.exe" } })
  for _, bash in ipairs({
    "C:\\Program Files\\Git\\bin\\bash.exe",
    (os.getenv("LOCALAPPDATA") or "") .. "\\Programs\\Git\\bin\\bash.exe",
  }) do
    if file_exists(bash) then
      table.insert(config.launch_menu, { label = "Git Bash", args = { bash, "-l" } })
      break
    end
  end
end

config.use_ime = true
config.allow_win32_input_mode = true
-- kitty keyboard protocol は IME の確定文字列を送らず生のキーイベントだけを流すため、
-- フルスクリーンの TUI で日本語入力が丸ごと落ちる。IME を使う間は無効にしておく。
config.enable_kitty_keyboard = false

config.window_close_confirmation = "NeverPrompt"
config.skip_close_confirmation_for_processes_named = {
  "pwsh.exe", "powershell.exe", "cmd.exe", "bash.exe", "zsh", "fish", "sh",
}
config.audible_bell = "Disabled"
config.automatically_reload_config = true

--------------------------------------------------------------------------------
-- ヘルパー
--------------------------------------------------------------------------------

-- パスの末尾要素を取り出す。current_working_dir はバージョンにより
-- 文字列だったり Url オブジェクトだったりするので両対応にしてある。
local function basename(cwd)
  if cwd == nil then
    return ""
  end
  local s
  local ok, path = pcall(function()
    return cwd.file_path
  end)
  if ok and type(path) == "string" then
    s = path
  else
    s = tostring(cwd)
  end
  s = s:gsub("[/\\]+$", "")
  return s:match("([^/\\]+)$") or s
end

-- 前面プロセス名（パス・拡張子を除いて小文字化）
local function process_name(pane)
  local ok, name = pcall(function()
    return pane:get_foreground_process_name()
  end)
  if not ok or type(name) ~= "string" then
    return ""
  end
  name = name:match("([^/\\]+)$") or name
  name = name:lower():gsub("%.exe$", "")
  return name
end

-- 前面プロセスがNeovimかどうか
local function is_nvim(pane)
  return process_name(pane):find("nvim", 1, true) ~= nil
end

-- プロセスごとのアイコン（Nerd Font）
local PROCESS_ICONS = {
  { "nvim", wezterm.nerdfonts.custom_vim },
  { "vim", wezterm.nerdfonts.custom_vim },
  { "pwsh", wezterm.nerdfonts.md_powershell },
  { "powershell", wezterm.nerdfonts.md_powershell },
  { "cmd", wezterm.nerdfonts.md_console },
  { "bash", wezterm.nerdfonts.cod_terminal_bash },
  { "zsh", wezterm.nerdfonts.cod_terminal_bash },
  { "git", wezterm.nerdfonts.dev_git },
  { "node", wezterm.nerdfonts.md_nodejs },
  { "python", wezterm.nerdfonts.dev_python },
  { "cargo", wezterm.nerdfonts.dev_rust },
  { "ssh", wezterm.nerdfonts.md_server_network },
  { "docker", wezterm.nerdfonts.md_docker },
}

local function process_icon(pane)
  local name = process_name(pane)
  for _, entry in ipairs(PROCESS_ICONS) do
    if name:find(entry[1], 1, true) then
      return entry[2]
    end
  end
  return wezterm.nerdfonts.md_console
end

--------------------------------------------------------------------------------
-- タブタイトル（VS Codeのように作業ディレクトリ名を出す）
--------------------------------------------------------------------------------

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
  local pane = tab.active_pane
  local title = tab.tab_title
  if title == nil or #title == 0 then
    title = basename(pane.current_working_dir)
  end
  if #title == 0 then
    title = pane.title or "shell"
  end

  local zoom = ""
  if pane.is_zoomed then
    zoom = " " .. wezterm.nerdfonts.md_magnify
  end

  -- 非アクティブタブに新しい出力があったら印を付ける
  local unseen = ""
  if not tab.is_active and pane.has_unseen_output then
    unseen = " " .. wezterm.nerdfonts.md_circle_medium
  end

  local text = string.format(" %d %s %s%s%s ", tab.tab_index + 1, process_icon(pane), title, zoom, unseen)

  if tab.is_active then
    return {
      { Foreground = { Color = C.mauve } },
      { Attribute = { Intensity = "Bold" } },
      { Text = text },
    }
  end

  local fg = hover and C.subtext0 or C.overlay0
  if #unseen > 0 then
    fg = C.peach
  end
  return {
    { Foreground = { Color = fg } },
    { Text = text },
  }
end)

--------------------------------------------------------------------------------
-- IDE風レイアウトの構築
--------------------------------------------------------------------------------

-- 左に広いメイン、右にサブ、下にターミナル、という3ペイン構成を作る。
-- 各ペインは空のシェルのまま（エディタなどは自分で起動する）。
--   +---------------------+--------+
--   |      main           |  sub   |
--   +---------------------+--------+
--   |        terminal              |
--   +------------------------------+
local function build_ide_layout(window, pane)
  -- 全ペインを元ペインの現在ディレクトリで開く
  -- （現在地を推定できない環境では、シェル側の OSC 7 通知が無いとホームになる）
  local cwd = pane:get_current_working_dir()
  local cwd_path = cwd and cwd.file_path or nil
  -- Windows では "/C:/Users/..." の形で返るので先頭のスラッシュを落とす
  if cwd_path and cwd_path:match("^/%a:") then
    cwd_path = cwd_path:sub(2)
  end
  pane:split({ direction = "Bottom", size = 0.25, cwd = cwd_path })
  pane:split({ direction = "Right", size = 0.28, cwd = cwd_path })
  -- 分割のたびにフォーカスが新しいペインへ移るので、最後に元のペインへ戻す。
  -- 下ペインから "Up" で戻す方式は、下ペインが全幅のためメインと右のどちらに
  -- 行くかがカーソル位置に左右されるので使わない。
  pane:activate()
end
wezterm.on("ide-layout", build_ide_layout)

--------------------------------------------------------------------------------
-- 簡易ヘルプ（Ctrl+Shift+H）: 頻出キーだけを現在のペインに表示する
--------------------------------------------------------------------------------

local HELP_LINES = {
  { "Ctrl+Shift+P", "コマンドパレット。迷ったらこれ（英字で絞り込み: split / tab / close ...）" },
  { "Ctrl+Shift+T", "新しいタブ" },
  { "Ctrl+Shift+D", "ペインを左右に分割" },
  { "Ctrl+Shift+E", "ペインを上下に分割" },
  { "Alt+矢印", "ペイン移動（クリックでも可）" },
  { "Alt+1〜9", "タブ番号で切り替え" },
  { "Ctrl+Shift+F", "画面内を検索" },
  { "右クリック", "貼り付け（左ドラッグで選択すると自動コピー）" },
  { "exit", "ペイン / タブを閉じる（タブの × でも可）" },
}

wezterm.on("show-help", function(window, pane)
  local esc = string.char(27)
  local bold, dim, reset = esc .. "[1;35m", esc .. "[2m", esc .. "[0m"
  local nl = "\r\n"
  local out = { nl .. bold .. " WezTerm 簡易ヘルプ" .. reset .. dim .. "  （全一覧は Ctrl+Shift+P）" .. reset .. nl }
  for _, item in ipairs(HELP_LINES) do
    table.insert(out, string.format("  %s%-14s%s %s%s", bold, item[1], reset, item[2], nl))
  end
  table.insert(out, nl)
  pane:inject_output(table.concat(out))
  -- シェルにプロンプトを引き直させる（Neovim 内なら何もしない）
  if not is_nvim(pane) then
    pane:send_text("\r")
  end
end)

--------------------------------------------------------------------------------
-- シェルを選んでペイン分割（launch_menu の一覧から選ぶ）
--------------------------------------------------------------------------------

local function split_with_shell(direction)
  return wezterm.action_callback(function(window, pane)
    local choices = {}
    for i, item in ipairs(config.launch_menu) do
      table.insert(choices, { id = tostring(i), label = item.label })
    end
    if #choices == 0 then
      window:perform_action(act.SplitPane({ direction = direction }), pane)
      return
    end
    window:perform_action(
      act.InputSelector({
        title = "分割先のシェルを選択",
        choices = choices,
        fuzzy = true,
        action = wezterm.action_callback(function(win, p, id)
          if not id then
            return
          end
          local item = config.launch_menu[tonumber(id)]
          win:perform_action(
            act.SplitPane({ direction = direction, command = { args = item.args } }),
            p
          )
        end),
      }),
      pane
    )
  end)
end

wezterm.on("split-right-shell", function(window, pane)
  window:perform_action(split_with_shell("Right"), pane)
end)
wezterm.on("split-down-shell", function(window, pane)
  window:perform_action(split_with_shell("Down"), pane)
end)

--------------------------------------------------------------------------------
-- キーバインド
--------------------------------------------------------------------------------

config.leader = { key = "q", mods = "CTRL", timeout_milliseconds = 1000 }

-- Alt+hjkl でNeovimの分割とWezTermのpaneをシームレスに行き来する。
-- 前面がNeovimならキーをそのまま渡し、そうでなければpane移動に使う。
local function smart_nav(key, dir)
  local event = "pane-nav-" .. dir:lower()
  wezterm.on(event, function(window, pane)
    if is_nvim(pane) then
      window:perform_action(act.SendKey({ key = key, mods = "ALT" }), pane)
    else
      window:perform_action(act.ActivatePaneDirection(dir), pane)
    end
  end)
  return { key = key, mods = "ALT", action = act.EmitEvent(event) }
end

-- Shift+Enter を改行にする。Windows の ConPTY は Shift+Enter を Enter と同じ CR に
-- 変換してしまうので（kitty キープロトコルを有効にしても同じ）、前面の TUI が
-- 改行として解釈する入力を代わりに送る。それ以外では通常の Enter。
-- 判定は前面プロセスのフルパスで行う。Codex は補助プロセス（node_repl.exe など）が
-- 前面に見えるが、いずれも OpenAI\Codex 配下にある。
local NEWLINE_INPUT = {
  { "codex", "\x1b\r" }, -- Alt+Enter
  { "claude", "\\\r" }, -- "\" + Enter
  { "copilot", "\\\r" },
  { "node", "\\\r" }, -- Copilot CLI は node として見える
}
wezterm.on("shift-enter", function(window, pane)
  local ok, path = pcall(function()
    return pane:get_foreground_process_name()
  end)
  path = (ok and type(path) == "string") and path:lower() or ""
  for _, entry in ipairs(NEWLINE_INPUT) do
    if path:find(entry[1], 1, true) then
      pane:send_text(entry[2])
      return
    end
  end
  window:perform_action(act.SendKey({ key = "Enter" }), pane)
end)

local rename_tab = act.PromptInputLine({
  description = "タブ名を入力",
  action = wezterm.action_callback(function(window, pane, line)
    if line then
      window:active_tab():set_title(line)
    end
  end),
})

local new_workspace = act.PromptInputLine({
  description = "新しい workspace 名を入力",
  action = wezterm.action_callback(function(window, pane, line)
    if line and #line > 0 then
      window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
    end
  end),
})

local launcher = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS|DOMAINS|WORKSPACES" })

config.keys = {
  ----------------------------------------------------------------------------
  -- Leader なしで使える基本操作（Windows Terminal / VS Code に近い配置）
  ----------------------------------------------------------------------------
  { key = "P", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
  { key = " ", mods = "CTRL|SHIFT", action = act.ActivateCommandPalette },
  { key = "F1", mods = "NONE", action = act.ActivateCommandPalette },
  { key = "H", mods = "CTRL|SHIFT", action = act.EmitEvent("show-help") },
  { key = "?", mods = "LEADER|SHIFT", action = act.EmitEvent("show-help") },
  { key = "D", mods = "CTRL|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "E", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "D", mods = "CTRL|SHIFT|ALT", action = act.EmitEvent("split-right-shell") },
  { key = "E", mods = "CTRL|SHIFT|ALT", action = act.EmitEvent("split-down-shell") },
  { key = "F", mods = "CTRL|SHIFT", action = act.Search({ CaseInSensitiveString = "" }) },
  { key = "O", mods = "CTRL|SHIFT", action = act.EmitEvent("open-bookmark") },
  { key = "L", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay },
  { key = "0", mods = "CTRL", action = act.ResetFontSize },
  { key = "Enter", mods = "SHIFT", action = act.EmitEvent("shift-enter") },

  -- pane移動（Neovimと共存）。Alt+矢印でも同じ
  smart_nav("h", "Left"),
  smart_nav("j", "Down"),
  smart_nav("k", "Up"),
  smart_nav("l", "Right"),
  { key = "LeftArrow", mods = "ALT", action = act.ActivatePaneDirection("Left") },
  { key = "DownArrow", mods = "ALT", action = act.ActivatePaneDirection("Down") },
  { key = "UpArrow", mods = "ALT", action = act.ActivatePaneDirection("Up") },
  { key = "RightArrow", mods = "ALT", action = act.ActivatePaneDirection("Right") },

  ----------------------------------------------------------------------------
  -- Leader（Ctrl+q）からの tmux 風操作
  ----------------------------------------------------------------------------
  -- IDE風レイアウトを現在のディレクトリで組む
  { key = "i", mods = "LEADER", action = act.EmitEvent("ide-layout") },

  -- pane
  { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
  { key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
  { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
  { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
  { key = "X", mods = "LEADER|SHIFT", action = act.EmitEvent("close-other-panes") },
  { key = "o", mods = "LEADER", action = act.RotatePanes("Clockwise") },
  { key = "S", mods = "LEADER|SHIFT", action = act.PaneSelect({ mode = "SwapWithActive" }) },
  { key = "!", mods = "LEADER|SHIFT", action = act.PaneSelect({ mode = "MoveToNewTab" }) },

  -- タブ
  { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
  { key = "Tab", mods = "LEADER", action = act.ActivateLastTab },
  { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
  { key = ",", mods = "LEADER", action = rename_tab },

  -- workspace（プロジェクトごとの作業空間）
  { key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
  { key = "W", mods = "LEADER|SHIFT", action = new_workspace },

  -- 検索・選択
  { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
  { key = " ", mods = "LEADER", action = act.QuickSelect },
  { key = "f", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },

  -- ランチャー（シェル / domain / workspace 切り替え）
  { key = "s", mods = "LEADER", action = launcher },

  { key = "R", mods = "LEADER|SHIFT", action = act.ReloadConfiguration },
  { key = "q", mods = "LEADER|CTRL", action = act.SendKey({ key = "q", mods = "CTRL" }) },
}

-- Alt+1〜9 でタブ直接切り替え
for i = 1, 9 do
  table.insert(config.keys, { key = tostring(i), mods = "ALT", action = act.ActivateTab(i - 1) })
end

config.key_tables = {
  resize_pane = {
    { key = "h", action = act.AdjustPaneSize({ "Left", 3 }) },
    { key = "j", action = act.AdjustPaneSize({ "Down", 3 }) },
    { key = "k", action = act.AdjustPaneSize({ "Up", 3 }) },
    { key = "l", action = act.AdjustPaneSize({ "Right", 3 }) },
    { key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 3 }) },
    { key = "DownArrow", action = act.AdjustPaneSize({ "Down", 3 }) },
    { key = "UpArrow", action = act.AdjustPaneSize({ "Up", 3 }) },
    { key = "RightArrow", action = act.AdjustPaneSize({ "Right", 3 }) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter", action = "PopKeyTable" },
  },
}

--------------------------------------------------------------------------------
-- 常に最前面の切り替え（Windows のみ）
-- WezTerm 本体に機能が無いので、WezTerm のウィンドウをクラス名で探して Win32 API を呼ぶ。
-- 複数ウィンドウがある場合は前面のものだけ、判別できなければ全部に適用する。
--------------------------------------------------------------------------------

local TOPMOST_SCRIPT = [[
Add-Type -Namespace W -Name U -MemberDefinition @"
public delegate bool EnumProc(IntPtr h, IntPtr l);
[DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
[DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, System.Text.StringBuilder s, int n);
[DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
"@
$wins = New-Object System.Collections.Generic.List[IntPtr]
[W.U]::EnumWindows({ param($h, $l)
  if ([W.U]::IsWindowVisible($h)) {
    $sb = New-Object System.Text.StringBuilder 256
    [void][W.U]::GetClassName($h, $sb, 256)
    if ($sb.ToString() -eq "org.wezfurlong.wezterm") { $wins.Add($h) }
  }
  $true
}, [IntPtr]::Zero) | Out-Null
$fg = [W.U]::GetForegroundWindow()
$targets = if ($wins.Contains($fg)) { @($fg) } else { $wins }
$after = if ($args[0] -eq "on") { [IntPtr]::new(-1) } else { [IntPtr]::new(-2) }
foreach ($h in $targets) { [W.U]::SetWindowPos($h, $after, 0, 0, 0, 0, 0x0003) | Out-Null }
]]

-- -Command に本文と引数を同時に渡すと引数が本文に連結されて壊れるので、
-- 一時ファイルに書き出して -File で呼ぶ
local function write_topmost_script()
  local dir = os.getenv("TEMP") or os.getenv("TMP") or wezterm.home_dir
  local path = dir .. "/wezterm-topmost.ps1"
  local f = io.open(path, "w")
  if not f then
    return nil
  end
  f:write(TOPMOST_SCRIPT)
  f:close()
  return path
end

wezterm.on("toggle-always-on-top", function(window, pane)
  if not is_windows then
    window:toast_notification("WezTerm", "常に最前面は Windows のみ対応です", nil, 3000)
    return
  end
  local script = write_topmost_script()
  if not script then
    window:toast_notification("WezTerm", "常に最前面: スクリプトを書き出せませんでした", nil, 4000)
    return
  end
  local on = not wezterm.GLOBAL.always_on_top
  local ok, _, stderr = wezterm.run_child_process({
    "powershell", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass",
    "-WindowStyle", "Hidden", "-File", script, on and "on" or "off",
  })
  if not ok then
    wezterm.log_error("always-on-top failed: " .. tostring(stderr))
    window:toast_notification("WezTerm", "常に最前面: 切り替えに失敗しました（Ctrl+Shift+L でログ確認）", nil, 4000)
    return
  end
  wezterm.GLOBAL.always_on_top = on
  window:toast_notification("WezTerm", on and "常に最前面: ON" or "常に最前面: OFF", nil, 2000)
end)

--------------------------------------------------------------------------------
-- アクティブ以外のペインをまとめて閉じる（確認あり）
--------------------------------------------------------------------------------

wezterm.on("close-other-panes", function(window, pane)
  local tab = window:active_tab()
  if not tab then
    return
  end
  local others = {}
  for _, p in ipairs(tab:panes()) do
    if p:pane_id() ~= pane:pane_id() then
      table.insert(others, p)
    end
  end
  if #others == 0 then
    window:toast_notification("WezTerm", "このタブにはほかのペインがありません", nil, 2000)
    return
  end
  window:perform_action(
    act.InputSelector({
      title = string.format("ほかの %d ペインを閉じますか？", #others),
      choices = {
        { id = "yes", label = "閉じる" },
        { id = "no", label = "やめる" },
      },
      action = wezterm.action_callback(function(win, _, id)
        if id ~= "yes" then
          return
        end
        for _, p in ipairs(others) do
          win:perform_action(act.CloseCurrentPane({ confirm = false }), p)
        end
      end),
    }),
    pane
  )
end)

--------------------------------------------------------------------------------
-- ブックマークディレクトリ（プロジェクトを選んで、いまのペインでそこへ cd する）
--
-- 追加はパレットの「add bookmark」でその場でできる（~/.wezterm-bookmarks.json に保存）。
-- まとめて登録したい場合は ~/.wezterm.local.lua でも指定できる:
--   return function(config, local_opts)
--     local_opts.bookmarks = {
--       { name = "myapp", path = "C:/src/myapp" },
--       { name = "notes", path = "~/Documents/notes" },
--     }
--     -- このフォルダ直下のサブディレクトリを全部ブックマークにする
--     local_opts.bookmark_roots = { "~/src" }
--   end
--------------------------------------------------------------------------------

local local_opts = { bookmarks = {}, bookmark_roots = {} }

-- パレットから追加した分の保存先
local BOOKMARKS_FILE = wezterm.home_dir .. "/.wezterm-bookmarks.json"

-- "~" を展開し、Windows で file URL 由来の "/C:/..." になっているパスを "C:/..." に直す
local function normalize_path(path)
  path = path:gsub("^~", wezterm.home_dir)
  path = path:gsub("^/(%a:)", "%1")
  path = path:gsub("([^/:])[/\\]+$", "%1")
  return path
end

-- 現在の作業ディレクトリを文字列で返す
local function pane_cwd(pane)
  local cwd = pane:get_current_working_dir()
  if cwd == nil then
    return nil
  end
  local ok, path = pcall(function()
    return cwd.file_path
  end)
  if ok and type(path) == "string" then
    return normalize_path(path)
  end
  return normalize_path((tostring(cwd):gsub("^file://", "")))
end

local function load_saved_bookmarks()
  local f = io.open(BOOKMARKS_FILE, "r")
  if not f then
    return {}
  end
  local text = f:read("*a")
  f:close()
  local ok, data = pcall(wezterm.json_parse, text)
  if ok and type(data) == "table" then
    return data
  end
  return {}
end

local function save_bookmarks(list)
  local f = io.open(BOOKMARKS_FILE, "w")
  if not f then
    return false
  end
  f:write(wezterm.json_encode(list))
  f:close()
  return true
end

-- 保存ファイル + ローカル設定の個別指定 + ルートフォルダ走査 をまとめる
local function collect_bookmarks()
  local list = {}
  for _, bm in ipairs(load_saved_bookmarks()) do
    table.insert(list, { name = bm.name, path = normalize_path(bm.path), saved = true })
  end
  for _, bm in ipairs(local_opts.bookmarks) do
    table.insert(list, { name = bm.name or basename(bm.path), path = normalize_path(bm.path) })
  end
  for _, root in ipairs(local_opts.bookmark_roots) do
    local ok, entries = pcall(wezterm.read_dir, normalize_path(root))
    if ok then
      table.sort(entries)
      for _, entry in ipairs(entries) do
        local name = basename(entry)
        if not name:match("^%.") then
          table.insert(list, { name = name, path = entry })
        end
      end
    end
  end
  return list
end

-- パスを確定したあと、名前を聞いて保存する
local function prompt_bookmark_name(window, pane, path)
  window:perform_action(
    act.PromptInputLine({
      description = "ブックマークの名前（空なら " .. basename(path) .. "）: " .. path,
      action = wezterm.action_callback(function(win, _, line)
        if line == nil then
          return
        end
        local name = #line > 0 and line or basename(path)
        local list = load_saved_bookmarks()
        for _, bm in ipairs(list) do
          if bm.path == path then
            win:toast_notification("WezTerm", "すでに登録済みです: " .. bm.name, nil, 3000)
            return
          end
        end
        table.insert(list, { name = name, path = path })
        if save_bookmarks(list) then
          win:toast_notification("WezTerm", "ブックマークに追加: " .. name, nil, 2000)
        else
          win:toast_notification("WezTerm", "保存に失敗しました: " .. BOOKMARKS_FILE, nil, 4000)
        end
      end),
    }),
    pane
  )
end

-- いまのディレクトリをブックマークに追加（名前を聞く。空なら末尾のフォルダ名）。
-- WezTerm が現在地を取得できない環境（プロセス情報を読めない、OSC 7 通知が無い）では
-- タブを開いた場所（通常ホーム）が返ってくるので、その場合はパスを手で入力してもらう。
wezterm.on("add-bookmark", function(window, pane)
  local cwd = pane_cwd(pane)
  local home = normalize_path(wezterm.home_dir)
  if cwd and cwd ~= home then
    prompt_bookmark_name(window, pane, cwd)
    return
  end
  window:perform_action(
    act.PromptInputLine({
      description = "現在地を取得できませんでした（シェルが OSC 7 を出していない可能性）。登録するパスを入力（空ならホーム）: ",
      action = wezterm.action_callback(function(win, p, line)
        if line == nil then
          return
        end
        local path = #line > 0 and normalize_path(line) or home
        prompt_bookmark_name(win, p, path)
      end),
    }),
    pane
  )
end)

-- パレットから追加した分を選んで削除（ローカル設定由来のものは対象外）。
-- 選択 UI は 1 件ずつしか選べないので、消したあと一覧を開き直して続けて消せる。
-- Esc で終了。
local function prompt_remove_bookmark(window, pane, removed_count)
  local list = load_saved_bookmarks()
  if #list == 0 then
    if removed_count == 0 then
      window:toast_notification("WezTerm", "削除できるブックマークがありません", nil, 2000)
    end
    return
  end
  local choices = {}
  for i, bm in ipairs(list) do
    table.insert(choices, { id = tostring(i), label = string.format("%s    %s", bm.name, bm.path) })
  end
  local title = "削除するブックマークを選択（続けて選べます。Esc で終了）"
  if removed_count > 0 then
    title = string.format("%d 件削除しました。続けて選択するか Esc で終了", removed_count)
  end
  window:perform_action(
    act.InputSelector({
      title = title,
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(win, p, id)
        if not id then
          return
        end
        table.remove(list, tonumber(id))
        save_bookmarks(list)
        prompt_remove_bookmark(win, p, removed_count + 1)
      end),
    }),
    pane
  )
end

wezterm.on("remove-bookmark", function(window, pane)
  prompt_remove_bookmark(window, pane, 0)
end)

-- いまのペインのシェルで cd する。シェル以外（Neovim など）が前面なら新しいタブで開く
local SHELLS = { pwsh = true, powershell = true, cmd = true, bash = true, zsh = true, sh = true, fish = true }

local function detect_shell(pane)
  local name = process_name(pane)
  if SHELLS[name] then
    return name
  end
  -- 前面プロセス名が取れない環境向けに、ペインのタイトル（既定はプロセス名）でも判定する
  local title = (pane:get_title() or ""):lower():gsub("%.exe$", "")
  if SHELLS[title] then
    return title
  end
  return name
end

local function cd_in_pane(window, pane, path)
  local shell = detect_shell(pane)
  local cmd
  if shell == "pwsh" or shell == "powershell" then
    -- 自分で打ったように見える短い形にする。[ ] などワイルドカード文字を
    -- 含むパスだけ -LiteralPath で保護する
    local win_path = is_windows and (path:gsub("/", "\\")) or path
    if win_path:find("[%[%]%*%?]") then
      cmd = string.format('cd -LiteralPath "%s"', win_path)
    else
      cmd = string.format('cd "%s"', win_path)
    end
  elseif shell == "cmd" then
    cmd = string.format('cd /d "%s"', (path:gsub("/", "\\")))
  elseif shell == "bash" or shell == "zsh" or shell == "sh" or shell == "fish" then
    -- Git Bash / MSYS 向けに C:/foo を /c/foo に直す
    local posix = path:gsub("^(%a):", function(drive)
      return "/" .. drive:lower()
    end)
    cmd = string.format('cd "%s"', posix)
  else
    window:perform_action(act.SpawnCommandInNewTab({ cwd = path }), pane)
    return
  end
  pane:send_text(cmd .. "\r")
end

wezterm.on("open-bookmark", function(window, pane)
  local bookmarks = collect_bookmarks()
  if #bookmarks == 0 then
    window:toast_notification("WezTerm", "ブックマークがありません。パレットの add bookmark で追加できます", nil, 4000)
    return
  end
  local choices = {}
  for i, bm in ipairs(bookmarks) do
    table.insert(choices, { id = tostring(i), label = string.format("%s    %s", bm.name, bm.path) })
  end
  window:perform_action(
    act.InputSelector({
      title = "プロジェクトへ移動（いまのペインで cd）",
      choices = choices,
      fuzzy = true,
      fuzzy_description = "プロジェクト名で絞り込み: ",
      action = wezterm.action_callback(function(win, p, id)
        if not id then
          return
        end
        local bm = bookmarks[tonumber(id)]
        cd_in_pane(win, p, bm.path)
      end),
    }),
    pane
  )
end)

--------------------------------------------------------------------------------
-- コマンドパレット（Ctrl+Shift+P）
--
-- 操作をグループにまとめてある。パレットで pane / tab / shell / view と打つと
-- グループが出て、Enter でそのグループの操作一覧（サブメニュー）が開く。
-- 個別の操作も "- " 付きで直接出てくる（split, close, zoom などで絞り込める）。
--
-- ・一覧はアルファベット順なので、グループは "* "、個別は "- " を付けて上に集めている
-- ・入力欄は IME が効かないので、[ ] 内の英語で絞り込む
-- ・英語だけの項目は WezTerm がキーバインドから自動生成するもので、非表示にはできない
--------------------------------------------------------------------------------

local split_right = act.SplitHorizontal({ domain = "CurrentPaneDomain" })
local split_down = act.SplitVertical({ domain = "CurrentPaneDomain" })

-- グループ定義。items の各要素は { 表示名, キーワード, action, 補足キー }
local PALETTE_GROUPS = {
  {
    key = "pane", label = "ペイン操作", icon = "md_view_dashboard",
    items = {
      { "左右に分割", "split right", split_right, "Ctrl+Shift+D" },
      { "上下に分割", "split down", split_down, "Ctrl+Shift+E" },
      { "シェルを選んで左右に分割", "split right shell", act.EmitEvent("split-right-shell"), "Ctrl+Shift+Alt+D" },
      { "シェルを選んで上下に分割", "split down shell", act.EmitEvent("split-down-shell"), "Ctrl+Shift+Alt+E" },
      { "最大化 / 元に戻す", "zoom", act.TogglePaneZoomState, "Ctrl+q z" },
      { "番号で選んで移動", "select pane", act.PaneSelect({}), "" },
      { "番号で選んで入れ替え", "swap pane", act.PaneSelect({ mode = "SwapWithActive" }), "Ctrl+q S" },
      { "番号で選んで新しいタブに切り出す", "move pane to tab", act.PaneSelect({ mode = "MoveToNewTab" }), "Ctrl+q !" },
      { "サイズ変更（h/j/k/l か矢印、Esc で終了）", "resize", act.ActivateKeyTable({ name = "resize_pane", one_shot = false }), "Ctrl+q r" },
      { "配置を回転", "rotate", act.RotatePanes("Clockwise"), "Ctrl+q o" },
      { "IDE風レイアウト（メイン + サブ + 下にターミナル）", "ide layout", act.EmitEvent("ide-layout"), "Ctrl+q i" },
      { "閉じる", "close pane", act.CloseCurrentPane({ confirm = true }), "Ctrl+q x" },
      { "ほかのペインをすべて閉じる", "close other panes", act.EmitEvent("close-other-panes"), "Ctrl+q X" },
    },
  },
  {
    key = "tab", label = "タブ操作", icon = "md_tab",
    items = {
      { "新しいタブ", "new tab", act.SpawnTab("CurrentPaneDomain"), "Ctrl+Shift+T" },
      { "名前を変更", "rename tab", rename_tab, "Ctrl+q ," },
      { "次のタブ", "next tab", act.ActivateTabRelative(1), "Ctrl+Tab" },
      { "前のタブ", "prev tab", act.ActivateTabRelative(-1), "Ctrl+Shift+Tab" },
      { "直前のタブに戻る", "last tab", act.ActivateLastTab, "Ctrl+q Tab" },
      { "閉じる", "close tab", act.CloseCurrentTab({ confirm = true }), "Ctrl+Shift+W" },
    },
  },
  {
    key = "shell", label = "シェル / workspace", icon = "md_rocket_launch",
    items = {
      { "ブックマークのプロジェクトへ移動", "project bookmark", act.EmitEvent("open-bookmark"), "Ctrl+Shift+O" },
      { "いまのディレクトリをブックマークに追加", "add bookmark", act.EmitEvent("add-bookmark"), "" },
      { "ブックマークから削除", "remove bookmark", act.EmitEvent("remove-bookmark"), "" },
      { "シェルを選んで新しいタブで起動", "launcher shell", launcher, "Ctrl+q s" },
      { "新しい workspace を作る", "new workspace", new_workspace, "Ctrl+q W" },
      { "workspace を切り替え", "switch workspace", act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }), "Ctrl+q w" },
    },
  },
  {
    key = "view", label = "表示 / 検索 / コピー", icon = "md_magnify",
    items = {
      { "画面内を検索", "search find", act.Search({ CaseInSensitiveString = "" }), "Ctrl+Shift+F" },
      { "コピーモード（vim キーで選択、y でコピー）", "copy mode", act.ActivateCopyMode, "Ctrl+q [" },
      { "クイック選択（パスやハッシュを1キーでコピー）", "quick select", act.QuickSelect, "Ctrl+q Space" },
      { "スクロールバック全体をクリア", "clear", act.ClearScrollback("ScrollbackAndViewport"), "" },
      { "文字サイズを元に戻す", "reset font", act.ResetFontSize, "Ctrl+0" },
      { "常に最前面を切り替え（Windows）", "always on top", act.EmitEvent("toggle-always-on-top"), "" },
    },
  },
  {
    key = "config", label = "設定 / ヘルプ", icon = "md_cog",
    items = {
      { "簡易ヘルプを表示", "help", act.EmitEvent("show-help"), "Ctrl+Shift+H" },
      { "ショートカット一覧を新しいタブで開く", "keys help", act.SpawnCommandInNewTab({
        args = is_windows and { "pwsh", "-NoLogo", "-NoExit", "-Command", "wezterm show-keys" }
          or { "sh", "-c", "wezterm show-keys; exec $SHELL" },
      }), "" },
      { "設定を再読み込み", "reload config", act.ReloadConfiguration, "Ctrl+q R" },
      { "デバッグ画面（設定エラーの確認）", "debug", act.ShowDebugOverlay, "Ctrl+Shift+L" },
    },
  },
}

-- グループのサブメニュー（InputSelector）を開く action を作る
local function group_menu(group)
  return wezterm.action_callback(function(window, pane)
    local choices = {}
    -- 日本語は 1 文字 2 列なので、バイト数ではなく表示幅で右側のキー表記を揃える
    local label_width = 0
    for _, item in ipairs(group.items) do
      label_width = math.max(label_width, wezterm.column_width(item[1]))
    end
    for i, item in ipairs(group.items) do
      local label = item[1]
      if item[4] ~= "" then
        local pad = label_width - wezterm.column_width(label) + 3
        label = label .. string.rep(" ", pad) .. item[4]
      end
      table.insert(choices, { id = tostring(i), label = label })
    end
    window:perform_action(
      act.InputSelector({
        title = group.label,
        choices = choices,
        fuzzy = true,
        fuzzy_description = "操作を選択（英字で絞り込み可）: ",
        action = wezterm.action_callback(function(win, p, id)
          if id then
            win:perform_action(group.items[tonumber(id)][3], p)
          end
        end),
      }),
      pane
    )
  end)
end

wezterm.on("augment-command-palette", function(window, pane)
  local entries = {}
  for _, group in ipairs(PALETTE_GROUPS) do
    table.insert(entries, {
      brief = string.format("* %s → 一覧を開く（%d 件）  [%s]", group.label, #group.items, group.key),
      icon = group.icon,
      action = group_menu(group),
    })
    for _, item in ipairs(group.items) do
      table.insert(entries, {
        brief = string.format("- %s: %s  [%s]", group.label, item[1], item[2]),
        icon = group.icon,
        action = item[3],
      })
    end
  end
  return entries
end)

--------------------------------------------------------------------------------
-- マウス
--------------------------------------------------------------------------------

config.mouse_bindings = {
  -- 右クリックで貼り付け（Windows Terminal と同じ挙動）
  { event = { Down = { streak = 1, button = "Right" } }, mods = "NONE", action = act.PasteFrom("Clipboard") },
  -- 左ドラッグで選択すると同時にコピー。リンクは Ctrl+クリックで開く（誤クリック防止）
  { event = { Up = { streak = 1, button = "Left" } }, mods = "NONE", action = act.CompleteSelection("ClipboardAndPrimarySelection") },
  { event = { Up = { streak = 1, button = "Left" } }, mods = "CTRL", action = act.OpenLinkAtMouseCursor },
  -- Ctrl+ホイールで文字サイズ変更
  { event = { Down = { streak = 1, button = { WheelUp = 1 } } }, mods = "CTRL", action = act.IncreaseFontSize },
  { event = { Down = { streak = 1, button = { WheelDown = 1 } } }, mods = "CTRL", action = act.DecreaseFontSize },
}

--------------------------------------------------------------------------------
-- ファイルパス:行番号 の Ctrl+クリックでNeovimへ飛ばす
--------------------------------------------------------------------------------

local FILE_LINE_PATTERN = [[[A-Za-z0-9_.\\/-]+\.(?:c|h|cpp|hpp|go|lua|ts|tsx|js|jsx|py|rs|md|json|yaml|yml|toml):\d+]]

config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = "\\b(" .. FILE_LINE_PATTERN .. ")\\b",
  format = "nvim://$1",
})

config.quick_select_patterns = {
  FILE_LINE_PATTERN,
  [[[0-9a-f]{7,40}]],
}

-- Neovim側で以下を実行しておくと既存インスタンスに飛ぶ（init.lua に書いてもよい）:
--   Windows: :call serverstart('\\.\pipe\nvim-wezterm')
--   その他:  :call serverstart('/tmp/nvim-wezterm.sock')
local NVIM_SERVER = is_windows and [[\\.\pipe\nvim-wezterm]] or "/tmp/nvim-wezterm.sock"

wezterm.on("open-uri", function(window, pane, uri)
  local target = uri:match("^nvim://(.+)$")
  if not target then
    return
  end

  local file, line = target:match("^(.*):(%d+)$")
  if not file then
    file, line = target, "1"
  end

  local ok = pcall(wezterm.background_child_process, {
    "nvim", "--server", NVIM_SERVER, "--remote-send",
    string.format("<C-\\><C-N>:edit +%s %s<CR>", line, file),
  })

  if not ok then
    pane:split({
      direction = "Right",
      args = { "nvim", string.format("+%s", line), file },
    })
  end

  return false
end)

--------------------------------------------------------------------------------
-- 完了通知: ベル（ビルドやテストの終了など）が鳴ったら
-- そのペインがフォーカス外のときだけ OS の通知を出す
--------------------------------------------------------------------------------

wezterm.on("bell", function(window, pane)
  local active = window:active_pane()
  if active and active:pane_id() == pane:pane_id() and window:is_focused() then
    return
  end
  local title = basename(pane:get_current_working_dir())
  if #title == 0 then
    title = pane:get_title()
  end
  window:toast_notification("WezTerm", "処理が終わりました: " .. title, nil, 4000)
end)

--------------------------------------------------------------------------------
-- ステータス表示（右側。通常はヘルプ案内のみ、モード中は状態を色付きで出す）
--------------------------------------------------------------------------------

wezterm.on("update-right-status", function(window, pane)
  local segments = {}

  if window:leader_is_active() then
    table.insert(segments, { text = " LEADER ", fg = C.crust, bg = C.red, bold = true })
  end

  local key_table = window:active_key_table()
  if key_table then
    table.insert(segments, { text = " " .. key_table:upper() .. " ", fg = C.crust, bg = C.yellow, bold = true })
  end

  if wezterm.GLOBAL.always_on_top then
    table.insert(segments, { text = " " .. wezterm.nerdfonts.md_pin .. " 最前面 ", fg = C.crust, bg = C.peach })
  end

  -- ズーム中は隠れているペインがあることを出す（例: 1/3 ペイン）
  local tab = window:active_tab()
  if tab then
    local panes = tab:panes_with_info()
    for _, info in ipairs(panes) do
      if info.is_zoomed then
        table.insert(segments, {
          text = string.format(" %s ズーム中 1/%d ペイン ", wezterm.nerdfonts.md_magnify, #panes),
          fg = C.crust, bg = C.yellow, bold = true,
        })
        break
      end
    end
  end

  -- workspace が複数あるときは、default にいても現在地と総数を出す（例: main (1/3)）
  local ws = window:active_workspace()
  local names = wezterm.mux.get_workspace_names()
  if ws and (#names > 1 or ws ~= "default") then
    local index = 0
    for i, name in ipairs(names) do
      if name == ws then
        index = i
      end
    end
    local text = " " .. wezterm.nerdfonts.cod_window .. " " .. ws
    if #names > 1 then
      text = text .. string.format(" (%d/%d)", index, #names)
    end
    table.insert(segments, { text = text .. " ", fg = C.crust, bg = C.teal })
  end

  -- 作業ディレクトリはタブ名に、時刻は OS のタスクバーにあるので出さない
  table.insert(segments, { text = " Ctrl+Shift+H: ヘルプ ", fg = C.subtext0, bg = C.crust })

  local out = {}
  for _, seg in ipairs(segments) do
    table.insert(out, { Background = { Color = seg.bg } })
    table.insert(out, { Foreground = { Color = seg.fg } })
    table.insert(out, { Attribute = { Intensity = seg.bold and "Bold" or "Normal" } })
    table.insert(out, { Text = seg.text })
  end

  window:set_right_status(wezterm.format(out))
end)

--------------------------------------------------------------------------------
-- ローカル設定の読み込み
-- SSH 接続先やマシン固有の設定は ~/.wezterm.local.lua に書く（git には入れない）。
-- 例:
--   return function(config, local_opts)
--     table.insert(config.ssh_domains, {
--       name = "desktop", remote_address = "192.168.1.10", username = "me",
--       multiplexing = "WezTerm",
--     })
--     local_opts.bookmark_roots = { "~/src" }   -- ブックマークディレクトリ
--   end
--------------------------------------------------------------------------------

config.ssh_domains = config.ssh_domains or {}
local local_config = wezterm.home_dir .. "/.wezterm.local.lua"
if file_exists(local_config) then
  local ok, apply = pcall(dofile, local_config)
  if ok and type(apply) == "function" then
    apply(config, local_opts)
  elseif not ok then
    wezterm.log_error("wezterm.local.lua の読み込みに失敗: " .. tostring(apply))
  end
end

return config
