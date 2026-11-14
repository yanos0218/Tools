# Tools 저장소 규칙

전역 규칙(`~/.claude/CLAUDE.md`)에 더해 이 저장소에만 적용되는 규칙. 충돌하면 이 파일이 우선한다.

## 세션 시작 시 읽을 문서

1. [README.md](README.md)
2. [CHANGELOG.md](CHANGELOG.md)
3. 작업할 도구 폴더의 README (예: [n2sf-hardening/README.md](n2sf-hardening/README.md))

## 검증

- 문서: `npx markdownlint-cli2 "**/*.md"` (설정은 [.markdownlint.jsonc](.markdownlint.jsonc))
- 셸 문법·정적 분석: `bash -n <파일>`, `shellcheck -S warning <파일>` (n2sf-hardening 폴더에서 실행해야 [.shellcheckrc](n2sf-hardening/.shellcheckrc)가 적용된다)
- n2sf-hardening 회귀 테스트(`tests/run_tests.sh`)는 Ubuntu 24.04 root 전용이라 맥에서 실행하지 않는다. CI(`ubuntu-24.04`) 결과로만 "통과"라고 쓴다. CI 확인은 `gh run watch <실행ID> --exit-status`.
- 로컬에서 못 돌린 검사는 "미검증"으로 쓴다.

## 규칙

- 도구마다 폴더 하나. 새 도구는 새 폴더와 폴더 README를 만들고 루트 README 표에 한 줄 추가한다.
- 도구를 고치면 같은 커밋에서 그 폴더의 CHANGELOG와 README를 갱신한다. 저장소 구조·CI가 바뀌면 루트 [CHANGELOG.md](CHANGELOG.md)도 갱신한다.
- n2sf-hardening의 테스트 개수가 바뀌면 README의 개수(현재 100개)도 같은 커밋에서 고친다.
- `n2sf_hardening.conf`에 실제 SNMP 암호·community·IP 정보를 채운 채 커밋하지 않는다. 채운 사본은 서버에서만 쓴다.
- 스크립트의 대상은 Ubuntu 24.04(amd64) 서버다. 맥에서 실행해 "동작 확인"이라고 쓰지 않는다.

## 기록 (날짜 + 무슨 일 + 앞으로의 규칙)

아직 없음.
