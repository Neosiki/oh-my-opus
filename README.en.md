<div align="center">

# oh-my-opus

**Inject the rules that match the model you are actually running. Switch models, and the rules follow.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-2e7d32.svg)](https://github.com/Neosiki/oh-my-opus)

[한국어](README.md) · English

</div>

---

## Why

Anthropic publishes a **different** prompting guide per model, and some of the prescriptions point in opposite
directions.

| Topic | Fable 5.1 guide | Opus 5 guide |
|---|---|---|
| Progress narration | under-narrates → **add updates** | over-narrates → **only when something important or a change of direction** |
| Verification | state done criteria | verifies on its own → **remove explicit verification instructions** |
| Response length | not addressed | runs long → **needs an explicit brevity instruction** |
| Subagents | not addressed | delegates readily → **needs a delegation cap** |
| Code review | not addressed | "only high severity" is **followed literally and reports less** |

So a single fixed block of rules pushed into every session stops being an optimization the moment the model
changes. oh-my-opus resolves the active model at session start, injects only that model's ruleset, and
re-injects through a `PostModelSwitch` hook when you switch models mid-session.

## What it does

| Part | When | What |
|---|---|---|
| **Per-model always-on rules** | automatically once installed | At each session start, resolves the active model and injects the matching profile (`opus-5` / `fable-5.1` / `core`) verbatim in English. The default is a hook, so no file is touched |
| **Model-switch detection** | when the model changes | A `PostModelSwitch` hook re-injects the new model's rules and says they replace the earlier ones. Prints nothing when the profile is unchanged |
| `/opus-prompt` | when a request is short or vague | shows a request with goal, context, scope and done filled in, then runs it. Add `just the prompt` to preview only |
| `/opus-setup` | once right after install | sets profile, delivery, mode and effort, and audits CLAUDE.md for conflicts **against the active profile** |

## Install

```bash
claude plugin marketplace add Neosiki/oh-my-opus
claude plugin install oh-my-opus@oh-my-opus
```

Open a new session, or type `/reload-plugins` then `/clear` (one per line) to use it in the current one.
Then `/opus-setup` (`/opus-setup auto` for defaults without questions).

> **Requirements** Claude Code 2.1.258 or newer. **Windows needs Git for Windows (Git Bash)**: the hook runs
> through bash. A hook error right after install usually means this.

## How the model is detected

Claude Code has no `$CLAUDE_MODEL` environment variable, and the `SessionStart` payload does **not always**
include a `model` field. Detection is therefore best effort, in this order:

1. hook stdin `to_model` (on a switch) → `model` → a nested `id`
2. the `ANTHROPIC_MODEL` environment variable
3. `model` in `~/.claude/settings.json`
4. otherwise the `fallback` profile (default `core`), with `model not detected` in the trailer

To make it deterministic, pin `"profile"` in the config; the model-switch hook then stays silent.

| Model id pattern | Profile |
|---|---|
| `*opus-5*`, `*opus5*` | `opus-5` |
| `*fable*`, `*mythos*` | `fable-5.1` |
| anything else / not detected | `core`, or `none` |

## What each profile carries

**`opus-5`** — brevity, narration cadence, scope lock, document length calibration, subagent delegation cap,
self-correction narration limit, an anti-over-verification line, targeted edits, batched tool calls.

**`fable-5.1`** — the assess-only exception, the finish-the-task self-check, the caution before state-changing
commands, scope and test limits, targeted edits, progress updates, the formatting rule, batched tool calls.

**`core`** — model-agnostic only: scope lock, unrequested bugs as follow-ups, targeted edits, batching.

All in English. In `unattended` mode the "the user is not watching" paragraph is inserted after line 3.

> One line is not Anthropic's text. The anti-over-verification sentence in the `opus-5` profile is the plugin's
> own wording. The guide prescribes **removing** verification instructions rather than adding a counter-instruction,
> but a plugin cannot delete text it did not write. The cleaner fix is `/opus-setup`'s audit, which finds and
> removes the offending CLAUDE.md line for real.

## Config

Global `~/.claude/oh-my-opus.json`, project `./.claude/oh-my-opus.json`:

```json
{"enabled": true, "mode": "auto", "profile": "auto", "fallback": "core"}
```

- `profile` · `auto` | `opus-5` | `fable-5.1` | `core` | `none`
- `mode` · `auto` | `interactive` | `unattended`. `auto` decides per session: unattended when
  `CLAUDE_CODE_ENTRYPOINT` is `sdk-cli`/`sdk-ts`/`sdk-py` (`claude -p`, the Agent SDK, agent harnesses),
  interactive in a terminal or IDE.
- `fallback` · the profile to use when no model is detected: `core` or `none`

**Merge rule**: a project file may only turn the plugin **off** (`"enabled": false`). `mode`, `profile` and
`fallback` are read from the global file only, so a cloned repository cannot switch someone's agent into
unattended mode or swap its ruleset.

## Where the rules live

| | Hook (default) | Separate rules file | CLAUDE.md section |
|---|---|---|---|
| Where | inside the plugin (`hooks/profiles/`) | `~/.claude/rules/oh-my-opus.md` | `<!-- oh-my-opus:start v1 -->` section |
| File edits | none | one new file | edits CLAUDE.md, needs approval |
| **Follows the model** | **yes** | no (snapshot) | no (snapshot) |
| Reaches subagents and teams | no | yes | yes |
| Removal | uninstall or `{"enabled": false}` | delete the file | delete the section |

Pick a file option and the hook goes silent by itself, so there is no double injection. Switch models often →
hook. Use subagents heavily → rules file.

## Effort

The API default for Opus 5 is `high`. Step up to `xhigh` for demanding coding and agentic work, and use `low`
and `medium` liberally wherever quality holds. Thinking cannot be disabled at `xhigh` or `max` (400 error), and
those levels need a large `max_tokens` (64k is a reasonable start). **Effort controls thinking volume, not
visible response length** — prompt for length instead.

Do not carry an effort default over from another model unchanged; effort names do not map to the same amount of
thinking across models.

## Symptom → fix

| Symptom | Fix |
|---|---|
| Responses run long | the brevity line in the `opus-5` profile (`/opus-setup`) |
| Touches things you did not ask for | the scope line |
| Narrates every step | the narration cadence line |
| Verifies the same thing repeatedly | `/opus-setup` audit; delete the verification instruction in CLAUDE.md |
| Spawns subagents for small tasks | the delegation cap line + `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` |
| Reports only a few issues in review | remove "only high severity"; report everything, filter in a second pass |
| Written documents are padded | block L, attached by `/opus-prompt` |
| Changed model but the rules did not change | check you are on hook delivery; a rules file or CLAUDE.md section is a snapshot |

## Layout

```
oh-my-opus/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── hooks/
│   ├── hooks.json            registers SessionStart + PostModelSwitch
│   ├── lib.sh                config parsing, model detection, emit (pure bash, no deps)
│   ├── session-start.sh      injects the profile at session start
│   ├── model-switch.sh       re-injects on a model change
│   └── profiles/
│       ├── opus-5.md
│       ├── fable-5.1.md
│       ├── core.md
│       └── shared-unattended.md
├── skills/
│   ├── opus-setup/SKILL.md
│   └── opus-prompt/
│       ├── SKILL.md
│       └── references/
│           ├── opus-5-blocks.md
│           └── examples.md
├── README.md · README.en.md
└── LICENSE
```

## Sources and credit

- [Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- [Prompting Claude Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1)
- [Effort](https://platform.claude.com/docs/en/build-with-claude/effort) · [Hooks](https://code.claude.com/docs/en/hooks) · [Plugins](https://code.claude.com/docs/en/plugins)

The hook and config architecture is adapted from [oh-my-fable](https://github.com/Junhan2/oh-my-fable)
(MIT, Junhan2). The prompt texts quoted in the profiles are copyright Anthropic.

MIT © 2026 Youngsik Yun (NextAI)
