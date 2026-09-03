#!/usr/bin/env bash
# oh-my-opus shared helpers. Pure bash: no jq, python, or other runtime.
# Sourced by session-start.sh and model-switch.sh.
set -u

# --- config -----------------------------------------------------------------
# Global: $HOME/.claude/oh-my-opus.json   Project: $CLAUDE_PROJECT_DIR/.claude/oh-my-opus.json
#   {"enabled": true, "mode": "auto"|"interactive"|"unattended",
#    "profile": "auto"|"opus-5"|"fable-5.1"|"core"|"none",
#    "fallback": "core"|"none"}
# Merge rule: a project file may only turn the plugin OFF. "mode", "profile" and
# "fallback" are read from the global file only, so a cloned repository cannot
# switch someone's agent into unattended mode or swap its ruleset.

omo_val() { # $1=file $2=key -> scalar value, empty when absent
  [ -f "$1" ] || return 0
  tr -d '[:space:]' < "$1" | grep -o "\"$2\":\"\{0,1\}[A-Za-z0-9_.:-]*" | head -1 | sed 's/^[^:]*://; s/"//g'
}

omo_field() { # $1=json text $2=key -> string value, empty when absent
  printf '%s' "$1" | tr -d '\n' \
    | grep -o "\"$2\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
    | sed 's/^.*:[[:space:]]*"//; s/"$//'
}

# --- model detection --------------------------------------------------------
# Claude Code does not export a $CLAUDE_MODEL variable and only sometimes puts a
# "model" field in the SessionStart payload, so this is best effort with an
# explicit override ("profile" in the config) as the reliable path.
omo_detect_model() { # $1=raw hook stdin
  local raw="${1:-}" m=""
  m="$(omo_field "$raw" to_model)"                       # PostModelSwitch
  [ -n "$m" ] || m="$(omo_field "$raw" model)"           # SessionStart, when present
  [ -n "$m" ] || m="$(omo_field "$raw" id)"              # {"model":{"id":...}}
  [ -n "$m" ] || m="${ANTHROPIC_MODEL:-}"
  [ -n "$m" ] || m="$(omo_val "$HOME/.claude/settings.json" model)"
  printf '%s' "$m"
}

omo_profile_for() { # $1=model id -> profile name, empty when unrecognised
  local m
  m="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$m" in
    *opus-5*|*opus5*)                 printf 'opus-5' ;;
    *fable*|*mythos*)                 printf 'fable-5.1' ;;
    *)                                printf '' ;;
  esac
}

# --- delivery guard ---------------------------------------------------------
# If the rules already live in a file the session loads anyway, print nothing.
omo_already_delivered() { # $1=project dir
  local proj="${1:-.}" f
  for f in "$HOME/.claude/CLAUDE.md" "$proj/CLAUDE.md" "$proj/.claude/CLAUDE.md"; do
    [ -f "$f" ] && grep -q 'oh-my-opus:start' "$f" && return 0
  done
  for f in "$HOME/.claude/rules/oh-my-opus.md" "$proj/.claude/rules/oh-my-opus.md"; do
    [ -f "$f" ] && return 0
  done
  return 1
}

# --- emit -------------------------------------------------------------------
omo_emit() { # $1=hooks dir  $2=profile  $3=mode  $4=trailer note
  local here="$1" profile="$2" mode="$3" note="${4:-}" body head rest
  [ -f "$here/profiles/$profile.md" ] || return 1
  body="$(cat "$here/profiles/$profile.md")"
  if [ "$mode" = unattended ] && [ -f "$here/profiles/shared-unattended.md" ]; then
    head="$(printf '%s\n' "$body" | sed -n '1,3p')"
    rest="$(printf '%s\n' "$body" | sed '1,3d')"
    body="$head"$'\n'"$(cat "$here/profiles/shared-unattended.md")"$'\n'"$rest"
  fi
  printf '%s\n\n(oh-my-opus: profile %s, mode %s%s. Change with /opus-setup. Per-request layer: /opus-prompt.)\n' \
    "$body" "$profile" "$mode" "$note"
}
