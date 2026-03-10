#!/bin/bash
TIMER_FILE="/tmp/sketchybar_timer"
source "$HOME/.config/sketchybar/colors.sh"

if [ -f "/tmp/sketchybar_timer_paused" ]; then
  REMAINING=$(awk 'NR==1' /tmp/sketchybar_timer_paused)
  NAME=$(awk 'NR==2' /tmp/sketchybar_timer_paused)
  MINS=$((REMAINING / 60))
  SECS=$((REMAINING % 60))
  sketchybar --set timer \
    label="⏸ $NAME $(printf '%02d:%02d' $MINS $SECS)" \
    label.color="$GREY" \
    drawing=on
elif [ -f "$TIMER_FILE" ]; then
  # Read end time and name from file
  END_TIME=$(awk 'NR==1' "$TIMER_FILE")
  NAME=$(awk 'NR==2' "$TIMER_FILE")
  NOW=$(date +%s)
  REMAINING=$((END_TIME - NOW))

  if [ $REMAINING -le 0 ]; then
    rm "$TIMER_FILE"
    sketchybar --set timer drawing=off
    osascript -e "display notification \"Time is up!\" with title \"$NAME Timer Done\" sound name \"Glass\""
  else
    MINS=$((REMAINING / 60))
    SECS=$((REMAINING % 60))

    case "$NAME" in
      Flow)  COLOR="$RED" ;;  # red
      Break) COLOR="$GREEN" ;;  # green
      *)     COLOR="$GREY" ;;  # white (default)
    esac

    sketchybar --set timer \
      label="⏱ $NAME $(printf '%02d:%02d' $MINS $SECS)" \
      label.color="$COLOR" \
      drawing=on
  fi
else
  sketchybar --set timer drawing=off
fi
