<div align="center">

# oh-my-opus

**지금 돌리는 모델에 맞는 규칙만 넣는다. 모델을 바꾸면 규칙도 따라 바뀐다.**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-2e7d32.svg)](https://github.com/Neosiki/oh-my-opus)

한국어 · [English](README.en.md)

</div>

---

## 왜 만들었나

Anthropic은 모델마다 **다른** 프롬프팅 가이드를 냅니다. 그리고 처방이 서로 반대인 항목이 있습니다.

| 항목 | Fable 5.1 가이드 | Opus 5 가이드 |
|---|---|---|
| 진행 서술 | 말이 적다 → **업데이트를 더 넣어라** | 말이 많다 → **중요한 걸 찾았거나 방향을 바꿀 때만** |
| 검증 | 완료 기준을 명시하라 | 알아서 검증한다 → **명시적 검증 지시를 제거하라** |
| 응답 길이 | 언급 없음 | 기본이 길다 → **간결 지시가 필요하다** |
| 서브에이전트 | 언급 없음 | 과다 위임한다 → **위임 상한이 필요하다** |
| 코드 리뷰 | 언급 없음 | "중요한 것만" 이라고 쓰면 **곧이곧대로 덜 보고한다** |

그래서 하나의 고정 규칙 뭉치를 모든 세션에 밀어 넣는 방식은, 모델이 바뀌는 순간 **최적화가 아니라 역최적화**가 됩니다.
oh-my-opus는 세션 시작 시 활성 모델을 판별해 **그 모델용 규칙만** 주입하고, 세션 도중 모델을 바꾸면 `PostModelSwitch`
훅으로 규칙을 다시 넣습니다.

## 구성

| 부분 | 언제 | 무엇 |
|---|---|---|
| **모델별 상시 규칙** | 설치 후 자동 | 세션 시작마다 활성 모델을 판별해 해당 프로파일(`opus-5` / `fable-5.1` / `core`)을 영어 원문으로 주입. 기본값은 훅이라 파일을 건드리지 않음 |
| **모델 전환 감지** | 모델을 바꿀 때 | `PostModelSwitch` 훅이 새 모델용 규칙을 다시 주입하고, 앞선 규칙을 대체한다고 명시. 프로파일이 같으면 아무것도 출력하지 않음 |
| `/opus-prompt` | 요청이 짧거나 모호할 때 | 목표·맥락·범위·완료를 채운 요청을 보여준 뒤 바로 실행. `프롬프트만` 을 붙이면 미리보기만 |
| `/opus-setup` | 설치 직후 한 번 | 프로파일·전달 위치·모드·effort를 정하고, **활성 프로파일 기준으로** CLAUDE.md의 충돌 규칙을 찾아 표로 보여줌 |

## 설치

```bash
claude plugin marketplace add Neosiki/oh-my-opus
claude plugin install oh-my-opus@oh-my-opus
```

새 세션을 열거나, 지금 세션에서 쓰려면 `/reload-plugins` 다음 `/clear` 를 한 줄씩 입력합니다.
그다음 `/opus-setup` (질문 없이 기본값으로 하려면 `/opus-setup auto`).

> **요구사항** Claude Code 2.1.258 이상. **Windows는 Git for Windows(Git Bash) 필요** — 훅이 bash로 실행됩니다.
> 설치 직후 훅 오류가 나면 대개 이것 때문입니다.

## 모델 판별은 어떻게 하나

Claude Code에는 `$CLAUDE_MODEL` 환경변수가 없고, `SessionStart` 훅의 payload에 `model` 필드가 **항상 들어오지는
않습니다**. 그래서 다음 순서로 최선을 다해 찾습니다.

1. 훅 stdin의 `to_model` (모델 전환 시) → `model` → 중첩된 `id`
2. `ANTHROPIC_MODEL` 환경변수
3. `~/.claude/settings.json` 의 `model`
4. 못 찾으면 `fallback` 프로파일 (기본 `core`) + 트레일러에 `model not detected` 표시

확실하게 고정하려면 설정에서 `"profile"` 을 직접 박으면 됩니다. 이때는 모델 전환 훅도 조용해집니다.

| 모델 id 패턴 | 프로파일 |
|---|---|
| `*opus-5*`, `*opus5*` | `opus-5` |
| `*fable*`, `*mythos*` | `fable-5.1` |
| 그 외 / 미검출 | `core` (모델 무관 규칙만) 또는 `none` |

## 프로파일별로 뭐가 들어가나

**`opus-5`** — 간결성, 서술 카덴스(중요한 것만), 범위 고정, 문서 길이 보정, 서브에이전트 위임 상한, 자기수정 서술
제한, 과잉검증 차단, 국소 편집, 툴콜 배칭.

**`fable-5.1`** — 진단만 하라는 예외, 마지막 문단이 계획이면 지금 실행, 상태 변경 명령 전 근거 확인, 범위·테스트
제한, 국소 편집, 진행 업데이트, 포매팅 규칙, 툴콜 배칭.

**`core`** — 모델 무관한 것만: 범위 고정, 미요청 버그는 후속 보고, 국소 편집, 툴콜 배칭.

전부 영어 원문입니다. `unattended` 모드에서는 "사용자가 지켜보고 있지 않다" 문단이 3행 뒤에 삽입됩니다.

> 한 줄만 Anthropic 원문이 아닙니다. `opus-5` 프로파일의 과잉검증 차단 문장은 이 플러그인이 쓴 것입니다.
> 가이드의 처방은 "검증 지시를 **추가하지 말고 제거하라**" 인데, 플러그인은 남이 쓴 CLAUDE.md를 지울 수 없어서
> 상쇄 문장을 넣었습니다. 더 깨끗한 해법은 `/opus-setup` 의 감사 기능으로 해당 줄을 실제로 지우는 것입니다.

## 설정

전역 `~/.claude/oh-my-opus.json`, 프로젝트 `./.claude/oh-my-opus.json`:

```json
{"enabled": true, "mode": "auto", "profile": "auto", "fallback": "core"}
```

- `profile` · `auto` | `opus-5` | `fable-5.1` | `core` | `none`
- `mode` · `auto` | `interactive` | `unattended`. `auto` 는 `CLAUDE_CODE_ENTRYPOINT` 가 `sdk-cli`/`sdk-ts`/`sdk-py`
  일 때(즉 `claude -p`, Agent SDK, 에이전트 하네스) unattended, 터미널·IDE면 interactive로 세션마다 판단합니다.
- `fallback` · 모델을 못 찾았을 때 쓸 프로파일. `core` 또는 `none`

**병합 규칙**: 프로젝트 파일은 **끄는 것만**(`"enabled": false`) 할 수 있습니다. `mode`, `profile`, `fallback` 은
전역 파일에서만 읽습니다. 클론한 리포지토리가 남의 에이전트를 무인 모드로 바꾸거나 규칙을 갈아치우지 못합니다.

## 규칙을 어디에 둘까

| | 훅 (기본) | 별도 rules 파일 | CLAUDE.md 섹션 |
|---|---|---|---|
| 위치 | 플러그인 안 (`hooks/profiles/`) | `~/.claude/rules/oh-my-opus.md` | `<!-- oh-my-opus:start v1 -->` 섹션 |
| 파일 수정 | 없음 | 새 파일 1개 | CLAUDE.md 편집, 승인 필요 |
| **모델 따라 바뀜** | **예** | 아니오 (스냅샷) | 아니오 (스냅샷) |
| 서브에이전트·팀에 전달 | 아니오 | 예 | 예 |
| 제거 | 언인스톨 또는 `{"enabled": false}` | 파일 삭제 | 섹션 삭제 |

파일 방식을 고르면 훅은 스스로 조용해집니다(중복 주입 없음). 모델을 자주 바꾸면 훅을, 서브에이전트를 많이 쓰면
rules 파일을 권합니다.

## effort

Opus 5의 API 기본값은 `high` 입니다. 까다로운 코딩·에이전트 작업은 `xhigh`, 품질이 유지되는 곳에서는 `low`/`medium`
을 적극적으로 쓰라는 것이 가이드 권고입니다. `xhigh`/`max` 에서는 thinking을 끌 수 없고(400), `max_tokens` 를 크게
잡아야 합니다(64k부터 시작 권장). **effort는 사고량을 조절할 뿐 보이는 응답 길이를 줄이지 않습니다** — 길이는
프롬프트로 잡아야 합니다.

다른 모델에서 쓰던 effort 기본값을 그대로 들고 오지 마세요. effort 이름은 모델 간 같은 사고량에 매핑되지 않습니다.

## 증상 → 처방

| 증상 | 처방 |
|---|---|
| 응답이 쓸데없이 길다 | `opus-5` 프로파일의 간결성 문장 (`/opus-setup`) |
| 시키지 않은 것까지 손댄다 | 범위 문장 |
| 한 일을 매번 중계방송한다 | 서술 카덴스 문장 |
| 검증을 몇 번씩 반복한다 | `/opus-setup` 감사로 CLAUDE.md의 검증 지시를 삭제 |
| 작은 일에도 서브에이전트를 띄운다 | 위임 상한 문장 + `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` |
| 리뷰에서 몇 개만 보고한다 | "중요한 것만" 지시 제거, 전부 보고 후 2차 필터 |
| 문서 파일이 군더더기로 길다 | `/opus-prompt` 가 붙이는 블록 L |
| 모델 바꿨는데 규칙이 그대로다 | 훅 전달 방식인지 확인 (rules 파일·CLAUDE.md는 스냅샷) |

## 구조

```
oh-my-opus/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── hooks/
│   ├── hooks.json            SessionStart + PostModelSwitch 등록
│   ├── lib.sh                설정 파싱·모델 판별·출력 (순수 bash, 의존성 없음)
│   ├── session-start.sh      세션 시작 시 프로파일 주입
│   ├── model-switch.sh       모델 전환 시 재주입
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

## 출처와 크레딧

- [Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- [Prompting Claude Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1)
- [Effort](https://platform.claude.com/docs/en/build-with-claude/effort) · [Hooks](https://code.claude.com/docs/en/hooks) · [Plugins](https://code.claude.com/docs/en/plugins)

훅과 설정 파일 구조는 [oh-my-fable](https://github.com/Junhan2/oh-my-fable) (MIT, Junhan2) 에서 가져왔습니다.
프로파일에 인용된 프롬프트 원문의 저작권은 Anthropic에 있습니다.

MIT © 2026 NextAI 윤영식
