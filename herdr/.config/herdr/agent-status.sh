#!/usr/bin/env bash
# agent states for the herdr tab bar (tab_bar_right command entry)
# one "<icon> <name>·<workspace>" per agent (falls back to the agent kind when unnamed), matching the picker's status icons
# absolute paths because tab bar commands run on the herdr server, not in a login shell

herdr="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
jq=/opt/homebrew/bin/jq

$jq -rn --argjson ws "$($herdr workspace list)" --argjson ag "$($herdr agent list)" '
  ($ws.result.workspaces | map({(.workspace_id): .label}) | add) as $labels |
  {working: "◐", blocked: "◉", done: "✓", idle: "○"} as $icons |
  [$ag.result.agents[] | "\($icons[.agent_status] // "?") \(.name // .agent)·\($labels[.workspace_id])"] |
  join("  ")'
