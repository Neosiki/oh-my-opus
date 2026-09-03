---
name: opus-prompt
description: Rewrite a rough, terse, or under-specified request into a prompt shaped for the model actually running, then carry it out. Use only when the user invokes it -- "/opus-prompt …", "프롬프트 개선해서", "가이드에 맞게 요청해", "제대로 시켜줘", "improve this prompt", "prompt it properly". Do not trigger on ordinary requests by yourself.
---
# opus-prompt - request rewrite (per-request layer)

Sources: Anthropic docs "Prompting Claude Opus 5" and "Prompting Claude Fable 5.1".
Model-specific blocks: `references/opus-5-blocks.md`. Before/after samples: `references/examples.md`.

This skill handles the **per-request layer** only. The always-on rules (brevity, narration cadence, scope,
subagent caps, targeted edits, batching) are injected by this plugin's hook for the active model, so never
repeat them here.

## Mode
- **Default: rewrite, show, then execute in the same turn.** Do not stop after showing the prompt.
- **Show only** when the user says "프롬프트만", "보여만 줘", "just the prompt", "don't run it".
- Never ask the user to write the prompt. Build it from conversation context.

## Step 0 - Know which model you are on
Read the trailer line of the oh-my-opus hook output in this session (`(oh-my-opus: profile …)`), or ask the
harness. The conditional blocks in Step 3 differ by profile. If no profile is visible, use the model-agnostic
subset: fields 1 to 4 and nothing else.

## Step 1 - Resolve referents
Fill "이거", "그거", "this", "that file", "the error" from context in this order: last path mentioned, last
error text, last artifact produced, current git diff, open thread. Write the resolved value as a concrete
path, symbol, or quote.

Ask exactly one question (with options and a recommended pick) only when different readings would lead to
**materially different work**. Routine ambiguity: pick the reading the wording and surrounding code most
directly support and state the assumption inside the prompt.

## Step 2 - Classify
| Kind | Signal | Deliverable |
|---|---|---|
| Change | build/fix/change verbs | working change, and what the user should see afterwards |
| Assessment | user describes a problem, asks why, thinks out loud | findings only, no fix until asked |
| Review | review, find bugs, audit | everything found, severity filtering left to a second pass |
| Research | look up, investigate, names of tools or models, anything time-sensitive | sourced answer |
| Writing | write, summarise, draft a doc or post | text in the requested shape and length |
| Long deliverable | full rewrite, multi-section doc, big table, whole file | as above, sized to the material |

## Step 3 - Compose
Write the task-specific parts in the user's language so they can check them. Keep any quoted guide block in
English verbatim; never translate a block.

1. **Goal** - one sentence, outcome-verifiable.
2. **Context** - resolved paths, symbols, error text, related decisions.
3. **Scope** - what is in, what is explicitly out.
4. **Done** - the observable end state: a workflow that runs, a file that exists, a number that matches.
   **Write it as an outcome, not as a verification ritual.** On the Opus 5 profile do not add "then verify",
   "double-check", "re-run to confirm", or a verifier subagent: the model already checks its own work and these
   lines compound into wasted tokens. On the Fable 5.1 profile an explicit check is worth stating.
5. **Effort** - never write an effort line into the request; it changes nothing in Claude Code. Effort is a
   setting (`effortLevel` in settings.json, or `CLAUDE_CODE_EFFORT_LEVEL`). Mention it only when it matters:
   demanding agentic work -> suggest `xhigh` for that session; a routine task at `xhigh` -> suggest dropping it.
6. **Conditional blocks** - attach at most what the request needs:
   - Assessment -> "report findings, do not fix" (both profiles).
   - Review on Opus 5 -> block **R**: report everything, filter in a second pass. Never write "only high severity".
   - Writing on Opus 5 -> block **L** (document length calibration) when the deliverable is a file.
   - Research or anything time-sensitive on Fable 5.1 at low effort -> block **H** (search the name as written).
   - Summarising sources -> block **J** (one worked quoting example).
   - Long deliverable at xhigh/max -> block **G** (do not draft twice).
   - Mannered prose -> `Please remove all mannered prose.`
   - Code review phrasing -> ask "Are there any bugs?" rather than "Does it compile?".

Attach nothing that the active profile already carries. On Opus 5 that means never re-stating brevity,
narration cadence, scope, subagent caps, self-correction, targeted edits, or batching.

## Step 4 - Show, then run
Print the prompt in one fenced block titled `개선된 요청` (or `Improved request`), the four fields plus any
conditional lines, then execute it as if the user had sent it. Lead the closing message with the outcome.
End with exactly one status: DONE, DONE_WITH_CONCERNS, BLOCKED, or NEEDS_CONTEXT.

## Do not
- Do not widen the task while improving it. The rewrite clarifies; it does not add features.
- Do not turn an Assessment into a Change.
- Do not add verification steps on the Opus 5 profile. Over-verification is the failure mode there, not under-verification.
- Do not add anti-formatting rules on the Fable 5.1 profile; it already under-formats.
