#!/bin/sh
# Sync the rose-pine variant with the terminal's light/dark theme.
#
# Called (in the background) by the client-{light,dark}-theme hooks. A single
# theme switch fires a burst of both hooks, and client_theme can flip back and
# forth during it, so wait for the burst to settle and only let the last call act.

id=$$
tmux set -g @theme_sync_id "$id"
sleep 1
[ "$(tmux show -gv @theme_sync_id)" = "$id" ] || exit 0 # a newer call took over

case "$(tmux display -p '#{client_theme}')" in
  light) variant=dawn ;;
  dark) variant=moon ;;
  *) exit 0 ;; # theme unknown, leave as is
esac

[ "$(tmux show -gv @rose_pine_variant)" = "$variant" ] && exit 0
tmux set -g @rose_pine_variant "$variant"
tmux set -g @rose_pine_bar_bg_disabled_color_option "$(tmux show -gv "@bar_bg_$variant")"
~/.config/tmux/plugins/tmux/rose-pine.tmux
# the theme rewrites status-right, which drops continuum's autosave hook, so re-add it
~/.config/tmux/plugins/tmux-continuum/continuum.tmux >/dev/null 2>&1
