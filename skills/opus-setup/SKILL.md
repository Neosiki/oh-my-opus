---
name: opus-setup
description: One-time setup for oh-my-opus in Claude Code. The plugin already injects the ruleset matching the active model at every session start, so the defaults need no edits. Use /opus-setup to pin or override the model profile, choose where the rules live (hook, rules file, or a CLAUDE.md section), switch interactive/unattended mode, set the effort default, and audit CLAUDE.md for rules that fight the model you actually run. Triggers -- "/opus-setup", "opus 세팅", "모델별 규칙 설정", "무인 모드로", "set up oh-my-opus", "which profile am I on", "unattended mode", "rules file".
---
# opus-setup - profile, delivery, mode, effort; audit conflicts

Profiles: `${CLAUDE_PLUGIN_ROOT}/hooks/profiles/` (`opus-5.md`, `fable-5.1.md`, `core.md`, `shared-unattended.md`).
Block reference: `${CLAUDE_PLUGIN_ROOT}/skills/opus-prompt/references/opus-5-blocks.md`.

Three layers: per request -> `/opus-prompt`; always-on rules -> delivered by the choice made here (hook by
default, profile picked per model); settings -> mode, effort, and an integration checklist.

## Arguments (skip the matching question)
`auto` (no questions, keep defaults) - `hook` | `rules-file` | `claude-md` (delivery) -
`auto` | `opus-5` | `fable-5.1` | `core` | `none` (profile) - `auto` | `interactive` | `unattended` (mode) -
`low` | `medium` | `high` | `xhigh` (effort) - `status` (report only, Step 1 + Step 5) - `remove` (undo, Step 6).

## Step 1 - Detect (one batch of reads, silent)
`./CLAUDE.md`, `./.claude/CLAUDE.md`, `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, `./.claude/settings.json`,
`~/.claude/oh-my-opus.json`, `./.claude/oh-my-opus.json`, `~/.claude/rules/`, `./.claude/rules/`,
`claude --version`, and the environment variables `CLAUDE_CODE_EFFORT_LEVEL` and `ANTHROPIC_MODEL`.

Also run `bash "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh" </dev/null` and read the trailer line to see which
profile the hook resolves to when the session payload carries no model id. Report the active model as the session
reports it, not as the hook guesses it.

## Step 2 - Questions: one AskUserQuestion call with up to three questions
Bundle questions 1 to 3 into a single call, one-line options, the recommended one marked. No preamble.

1. **Which ruleset?**
   - `Auto-detect per model (recommended)` - Opus 5 rules on Opus 5, Fable 5.1 rules on Fable/Mythos, core rules otherwise; re-applied when you switch models mid-session
   - `Pin to Opus 5` - always the Opus 5 ruleset
   - `Pin to core` - only the model-agnostic lines
   - `Off` - inject nothing, keep `/opus-prompt`
2. **Where should the rules live?**
   - `Hook (recommended)` - nothing to edit, active on install, and the only option that can follow the model
   - `Separate rules file` - `~/.claude/rules/oh-my-opus.md`, auto-loaded, also reaches subagents and teams, but static
   - `CLAUDE.md section` - inside your CLAUDE.md, needs edit approval, also static
3. **How do you mostly work?**
   - `Auto (recommended)` - unattended for headless/SDK/agent runs, interactive in the terminal or IDE
   - `Interactive` - always as if you watch and steer
   - `Unattended` - always adds the "the user is not watching" paragraph

Ask afterwards, only when relevant, one more call:
4. **Effort default?** (only when no `effortLevel` is set, or the current one came from another model's tuning)
   - `high (recommended)` - Anthropic's default for Opus 5
   - `medium` / `low` - strong quality at a fraction of the tokens where your work allows it
   - `xhigh` - demanding coding and agentic work
   - `keep current` - shown with the value found in Step 1
5. **Scope?** (only when the current directory is a git repo with its own CLAUDE.md)
   - `All projects (recommended)` - global files under `~/.claude`
   - `This project only` - files under `./.claude`
6. **Fix the conflicting rules for you?** (only when Step 4 finds conflicts; ask after showing the table)
   - `Yes, apply the suggested edits` - edits CLAUDE.md, needs approval outside auto mode
   - `No, just show me`

Ask in the user's language.

## Step 3 - Apply
**Config** (always, global `~/.claude/oh-my-opus.json`, or project `./.claude/oh-my-opus.json` for scope "this project only"):
```json
{"enabled": true, "mode": "auto", "profile": "auto", "fallback": "core"}
```
A project file may only set `"enabled": false`. `mode`, `profile` and `fallback` are read from the global file
only, so a cloned repository cannot switch someone's agent into unattended mode or swap its ruleset. If the write
is refused, print the JSON and path; the defaults apply without a file.

**Rules text** = the chosen profile file, with `shared-unattended.md` inserted after line 3 when unattended.
English regardless of the user's language.

- `hook`: nothing else to write. This is the only delivery that follows the model.
- `rules-file`: write the resolved profile text to `~/.claude/rules/oh-my-opus.md` (project: `./.claude/rules/oh-my-opus.md`).
  Claude Code loads `rules/*.md` automatically, so CLAUDE.md is not edited. Set `"delivery": "rules-file"`; the hook
  goes silent by itself once the file exists. Say in one line that a rules file is a snapshot of one profile and
  will not change when the session model changes.
- `claude-md`: insert or replace between `<!-- oh-my-opus:start v1 -->` and `<!-- oh-my-opus:end -->` with the Edit
  tool; touch nothing else. Same snapshot caveat. If refused, do not retry with another tool: say it needs a session
  outside auto mode, keep `hook`, and show the section for manual paste.

**Effort**: set `effortLevel` in `~/.claude/settings.json` (merge, keep other keys; valid values are low, medium,
high, xhigh, max). If a `modelSettings.<model>.effortLevel` or the env var `CLAUDE_CODE_EFFORT_LEVEL` overrides it,
say which one wins in one line. Effort names do not map to the same thinking across models, so an effort default
carried over from another model is worth re-checking rather than trusting.

## Step 4 - Audit (one table, then question 6)
Rule found -> verdict -> one-line suggestion. Edit CLAUDE.md only if the user chose "Yes".

Flag against the **active profile**, not in general:

| On the Opus 5 profile, flag | Why |
|---|---|
| "include a final verification step", "double-check your answer", "re-verify before responding", "use a subagent to verify" | Opus 5 verifies its own work; these compound and burn tokens with no quality gain. Suggest deleting |
| "narrate every step", "explain what you are doing before each tool call" | Opus 5 already narrates readily; this amplifies it |
| "only report high-severity issues", "be conservative" in a review prompt | Opus 5 follows this literally and reports less. Suggest reporting everything and filtering in a second pass |
| no conciseness rule anywhere | Opus 5 responses run long by default; suggest adding the brevity line |
| "always delegate to subagents", "spawn a verifier agent" | Opus 5 already delegates readily; caps belong here, not encouragement |

| On the Fable 5.1 profile, flag | Why |
|---|---|
| "hold all findings for the final response", "no closing recap" | Fable 5.1 under-narrates; this makes it silent for minutes |
| "no bullets", "no headers", any blanket anti-formatting rule | Fable 5.1 already under-formats |
| "ask before every step" | blocks autonomous completion |

Same-meaning rules -> "already covered". Never propose deleting a rule that is right for the profile in use.

## Step 5 - Verify and close
Hook: run `bash "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh" </dev/null` with `CLAUDE_PROJECT_DIR` set and confirm
the last line starts with `(oh-my-opus: profile`. Rules file / CLAUDE.md: confirm the file exists (markers exactly
once) and the hook prints nothing. Then close with exactly this, translated:

> Done. Profile: <profile>, rules: <delivery>, mode: <mode>, effort: <effort>. They apply automatically from the
> next Claude Code session. To use them in this session right now: if the plugin was installed in this session, type
> `/reload-plugins` first, then `/clear` (one per line). Ask as usual; for short or vague requests use
> `/opus-prompt <request>`. Add "just the prompt" to preview only.

One status line: DONE, DONE_WITH_CONCERNS, or NEEDS_CONTEXT.

## Step 6 - `/opus-setup remove`
Undo everything this skill may have written, then tell the user to run `claude plugin uninstall oh-my-opus@oh-my-opus`:
- delete `~/.claude/oh-my-opus.json` and `./.claude/oh-my-opus.json`
- delete `~/.claude/rules/oh-my-opus.md` and `./.claude/rules/oh-my-opus.md`
- remove the `<!-- oh-my-opus:start` ... `<!-- oh-my-opus:end -->` section (and its heading line) from any CLAUDE.md
- `effortLevel` in settings.json is left as is; say so in one line
