# opus-prompt - before/after samples

Four fields plus conditional lines only. Never repeat what the active profile already carries.

## 1. Change on Opus 5 - "로그인 버튼 눌러도 아무 반응 없어 고쳐줘"

```
개선된 요청
목표: 로그인 버튼을 누르면 /api/login 이 호출되고, 성공하면 /dashboard 로 이동한다.
맥락: src/components/LoginButton.tsx, 콘솔 오류 원문 "TypeError: onSubmit is not a function". 인증 방식을 바꾼 커밋 a1b2c3 이후 발생.
범위: 이 버튼과 그 핸들러만. 옆의 회원가입 폼과 다른 오류는 손대지 말고 후속 과제로 보고.
완료: 로그인 클릭 시 /dashboard 로 이동하고 콘솔 오류가 없는 상태.
```
Note the "완료" line names the end state, not a verification ritual. On Opus 5, adding "고친 뒤 다시 확인하고
재검증할 것" would produce extra passes with no quality gain.

## 2. Assessment - "왜 이거 자꾸 느려져?"

```
개선된 요청
목표: next dev 가 시간이 갈수록 느려지는 원인을 증거와 함께 밝힌다. 수정은 하지 않는다.
맥락: ~/Desktop/app, Next 16, pnpm 모노레포.
범위: 원인 후보 3개 이상, 각각 지지·반박 증거, 가장 유력한 것 하나와 확인 방법. 코드 변경 금지.
완료: 증거(명령 출력, 파일:줄)가 붙은 진단 보고 1개.
```

## 3. Review on Opus 5 - "이 PR 좀 봐줘" (block R attached)

```
개선된 요청
목표: PR #482 의 변경분에서 실제 버그를 찾는다.
맥락: git diff main...HEAD, 6개 파일, 결제 상태 전이 로직 위주.
범위: 이 diff 안에서만. 스타일 지적과 리팩터링 제안은 제외.
완료: 발견한 이슈 목록. 각 항목에 파일:줄, 재현 조건, 심각도.
+ Report every issue you find, with severity labelled. Do not pre-filter to high-severity items; filtering is a separate pass.
```
"중요한 것만 골라줘" 같은 문장은 Opus 5 에서 문자 그대로 지켜져 보고량이 줄어든다. 필터링은 두 번째 패스로 분리한다.

## 4. Writing on Opus 5 - "이거 정리해서 리포트로 뽑아줘" (block L attached)

```
개선된 요청
목표: 2026년 8월 판매 데이터를 임원 회의용 요약 문서로 만든다. 결론이 맨 위.
맥락: 2026-08-sales.xlsx, 시트 "raw".
범위: 표와 요약만. 원본 시트는 수정하지 않는다. 이상치는 표시만 하고 고치지 않는다.
완료: docs/2026-08-summary.md 1개. 합계가 "summary" 시트와 일치.
+ Match the length of written documents to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate.
```

## 5. Research on Fable 5.1 at low effort - "grok 4.6 요즘 가격 어때?" (block H attached)

```
개선된 요청
목표: xAI Grok 4.6 의 현재 API 가격과 구독 요금을 출처 링크와 함께 정리한다.
맥락: 없음.
범위: 사용자가 쓴 표기 "grok 4.6" 을 그대로 넣은 검색 1회 이상 포함. 기억으로 답하지 않는다.
완료: 가격 표 1개, 각 행에 출처 URL과 확인 날짜.
+ block H
```
On Opus 5 this block is usually unnecessary; raise effort instead if searches are being skipped.
