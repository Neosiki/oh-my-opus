#!/usr/bin/env bash
# oh-my-opus SessionStart hook: emit the ruleset matching the active model.
# Claude Code adds SessionStart stdout to the session context.
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

omo_already_delivered "$PROJ" && exit 0

MODE=auto; NOTE=""
m="$(omo_val "$GLOBAL" mode)"; case "$m" in interactive|unattended) MODE="$m";; esac
if [ "$MODE" = auto ]; then
  case "${CLAUDE_CODE_ENTRYPOINT:-}" in
    sdk-cli|sdk-ts|sdk-py) MODE=unattended ;;
    *)                     MODE=interactive ;;
  esac
  NOTE=" (auto)"
fi

PROFILE="$(omo_val "$GLOBAL" profile)"
case "$PROFILE" in
  opus-5|fable-5.1|core) ;;
  none) exit 0 ;;
  *)
    MODEL="$(omo_detect_model "$RAW")"
    PROFILE="$(omo_profile_for "$MODEL")"
    if [ -z "$PROFILE" ]; then
      FB="$(omo_val "$GLOBAL" fallback)"; [ -n "$FB" ] || FB=core
      [ "$FB" = none ] && exit 0
      PROFILE="$FB"
      NOTE="$NOTE, model not detected"
    fi
    ;;
esac

omo_emit "$HERE" "$PROFILE" "$MODE" "$NOTE"
exit 0
