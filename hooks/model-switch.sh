#!/usr/bin/env bash
# oh-my-opus PostModelSwitch hook: re-inject the ruleset for the new model.
# Fires whenever the session's model changes, including changes Claude Code
# makes on its own. Claude Code adds PostModelSwitch stdout to the context.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"

RAW=""; [ -t 0 ] || RAW="$(cat 2>/dev/null || true)"
PROJ="${CLAUDE_PROJECT_DIR:-.}"
GLOBAL="$HOME/.claude/oh-my-opus.json"
LOCAL="$PROJ/.claude/oh-my-opus.json"

ENABLED=true
[ "$(omo_val "$GLOBAL" enabled)" = "false" ] && ENABLED=false
[ "$(omo_val "$LOCAL"  enabled)" = "false" ] && ENABLED=false
[ "$ENABLED" = true ] || exit 0

# A pinned profile never changes with the model, so nothing to re-inject.
P="$(omo_val "$GLOBAL" profile)"
case "$P" in opus-5|fable-5.1|core|none) exit 0 ;; esac

FROM="$(omo_field "$RAW" from_model)"
TO="$(omo_detect_model "$RAW")"
NEW="$(omo_profile_for "$TO")"
OLD="$(omo_profile_for "$FROM")"
[ -n "$NEW" ] || exit 0
[ "$NEW" = "$OLD" ] && exit 0   # same ruleset, no need to repeat it

MODE=auto
m="$(omo_val "$GLOBAL" mode)"; case "$m" in interactive|unattended) MODE="$m";; esac
if [ "$MODE" = auto ]; then
  case "${CLAUDE_CODE_ENTRYPOINT:-}" in
    sdk-cli|sdk-ts|sdk-py) MODE=unattended ;;
    *)                     MODE=interactive ;;
  esac
fi

printf 'The session model changed to %s. The working rules below replace any earlier oh-my-opus rules in this conversation.\n\n' "$TO"
omo_emit "$HERE" "$NEW" "$MODE" " (after model switch)"
exit 0
