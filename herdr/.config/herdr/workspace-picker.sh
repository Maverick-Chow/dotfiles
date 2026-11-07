#!/usr/bin/env bash
# sesh-style floating picker for herdr (bound in config.toml as popups)
# lists herdr workspaces, agents and zoxide dirs; picking a dir opens a new workspace there
# usage: workspace-picker.sh [--start agents]

list_workspaces() {
  herdr workspace list | jq -r '.result.workspaces[] |
    "\(if .focused then "●" else "○" end) \(.workspace_id)\t\(.label)  \u001b[2m\(.tab_count) tabs · \(.agent_status)\u001b[0m"'
}

list_agents() {
  # join each agent with its workspace label; colour the status like the herdr sidebar
  jq -rn --argjson ws "$(herdr workspace list)" --argjson ag "$(herdr agent list)" '
    ($ws.result.workspaces | map({(.workspace_id): .label}) | add) as $labels |
    {working: "\u001b[33m◐", blocked: "\u001b[31m◉", done: "\u001b[32m✓", idle: "\u001b[34m○"} as $icons |
    $ag.result.agents[] |
    "\($icons[.agent_status] // "\u001b[2m?")\u001b[0m \(.pane_id)\t\(.name // .agent)  \u001b[2m\($labels[.workspace_id]) · \(.agent_status)\u001b[0m  \(.terminal_title_stripped // "")"'
}

list_dirs() {
  # \xef\x81\xbb is the nerd font folder icon (U+F07B)
  zoxide query -l | sed "s|^$HOME|~|" | awk '{ printf "\033[34m\xef\x81\xbb\033[0m dir\t%s\n", $0 }'
}

list_all() { list_workspaces; list_agents; list_dirs; }

# column 1 is "<icon> <key>": a workspace id (w1), a pane id for agents (w1:p1) or "dir";
# take the last word so it still works when fzf strips the colour codes around the icon
key_of() { cut -f1 <<< "$1" | awk '{ print $NF }'; }
dir_of() { cut -f2 <<< "$1" | sed 's|^~|'"$HOME"'|'; }

case "$1" in
  --workspaces) list_workspaces; exit ;;
  --agents) list_agents; exit ;;
  --dirs) list_dirs; exit ;;
  --all) list_all; exit ;;
  --preview)
    key=$(key_of "$2")
    if [ "$key" = dir ]; then
      ls -A --color=always "$(dir_of "$2")"
    elif [[ "$key" == *:* ]]; then
      herdr pane read "$key" --source visible --ansi
    else
      pane=$(herdr pane list --workspace "$key" | jq -r '[.result.panes[] | select(.focused)][0].pane_id // .result.panes[0].pane_id')
      herdr pane read "$pane" --source visible --ansi
    fi
    exit ;;
esac

self="$0"
prompt='all ❯ '; start=--all
if [ "$1 $2" = "--start agents" ]; then prompt='agents ❯ '; start=--agents; fi

# fzf colours use ANSI numbers so they follow ghostty's rose pine palette in both modes
choice=$("$self" $start | fzf \
  --no-sort --ansi --layout reverse --border none \
  --delimiter '\t' --with-nth 1,2 \
  --prompt "$prompt" --pointer '▌' \
  --header '^j/^k move  ^a all  ^w workspaces  ^g agents  ^x zoxide' \
  --color 'fg:7,bg:-1,hl:6,fg+:7:bold,bg+:0,hl+:6,gutter:-1' \
  --color 'border:8,label:6,header:8,info:4,prompt:5,pointer:5,marker:1,spinner:3,separator:8,scrollbar:8' \
  --bind 'tab:down,btab:up,ctrl-j:down,ctrl-k:up' \
  --bind "ctrl-a:change-prompt(all ❯ )+reload($self --all)" \
  --bind "ctrl-w:change-prompt(workspaces ❯ )+reload($self --workspaces)" \
  --bind "ctrl-g:change-prompt(agents ❯ )+reload($self --agents)" \
  --bind "ctrl-x:change-prompt(zoxide ❯ )+reload($self --dirs)" \
  --preview-window 'right,55%,border-left' \
  --preview "$self --preview {}") || exit 0

key=$(key_of "$choice")
if [ "$key" = dir ]; then
  dir=$(dir_of "$choice")
  herdr workspace create --cwd "$dir" --label "$(basename "$dir")" --focus >/dev/null
elif [[ "$key" == *:* ]]; then
  herdr agent focus "$key" >/dev/null
else
  herdr workspace focus "$key" >/dev/null
fi
