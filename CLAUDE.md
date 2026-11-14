# Tools 저장소 규칙

전역 규칙(`~/.claude/CLAUDE.md`)에 더해 이 저장소에만 적용되는 규칙. 충돌하면 이 파일이 우선한다.

## 세션 시작 시 읽을 문서

1. [README.md](README.md) (도구 목록)
2. [docs/structure.md](docs/structure.md), [docs/workflow.md](docs/workflow.md)
3. [CHANGELOG.md](CHANGELOG.md)
4. 작업할 도구 폴더의 README와 `docs/` (예: [vulnerability/README.md](vulnerability/README.md), [vulnerability/docs/](vulnerability/docs/usage.md))

## 검증

- 문서
  - `npx markdownlint-cli2@latest "**/*.md"` 실행. 설정은 [.markdownlint.jsonc](.markdownlint.jsonc)에 있다.
  - 버전을 `latest`로 쓰는 이유는 CI 액션이 최신 규칙을 쓰기 때문이다. 2026-11-14 옛 버전 로컬 검사는 통과했는데 CI에서 표 규칙 MD060으로 실패했다.
- 셸 문법·정적 분석은 `bash -n <파일>`, 도구 폴더에서 `shellcheck -S warning <파일>`로 한다. 도구 폴더의 `.shellcheckrc`가 적용된다.
- vulnerability 회귀 테스트(`tests/run_tests.sh`)는 Ubuntu 24.04 root 전용이라 맥에서 실행하지 않는다. CI(`ubuntu-24.04`) 결과로만 "통과"라고 쓴다. CI 확인은 `gh run watch <실행ID> --exit-status`.
- 로컬에서 못 돌린 검사는 "미검증"으로 쓴다.

## 규칙

- 발견한 문제는 Issue로 남기고 라벨은 `문제`(오류·판정 오류), `할 일`(개선·추가), `research`(조사 기록)를 씀. 본문과 코멘트는 음슴체.
- 도구마다 폴더 하나와 도구 이름의 워크플로 하나를 쓴다. 규약은 [docs/structure.md](docs/structure.md)를 따른다.
- 새 도구는 [docs/workflow.md](docs/workflow.md)의 "새 도구 추가 절차"대로 만든다. 루트 README 도구 목록에 한 줄을 추가하는 것을 빠뜨리지 않는다.
- 도구 내용은 그 폴더(서브)에, 둘 이상의 도구에 공통인 내용만 루트 README와 `docs/`(메인)에 둔다. 서브 내용을 메인에 복사하지 않고 링크한다.
- 도구를 고치면 같은 커밋에서 그 폴더의 CHANGELOG와 README를 갱신한다. 저장소 구조·CI가 바뀌면 루트 [CHANGELOG.md](CHANGELOG.md)도 갱신한다.
- 도구 폴더 이름이나 워크플로 이름을 바꾸면 `**/*.md`와 `.github/`에서 옛 이름을 grep해 같은 커밋에서 고친다.
- vulnerability 테스트 개수가 바뀌면 [vulnerability/README.md](vulnerability/README.md)의 개수(현재 136개)도 같은 커밋에서 고친다.
- `vulnerability/conf/vuln_hardening.conf.example`(과 서버에서 복사한 `vuln_hardening.conf`)에 실제 SNMP 암호·community·IP 정보를 채운 채 커밋하지 않는다. 채운 사본은 서버에서만 쓴다.
- vulnerability 스크립트의 대상은 Ubuntu 24.04(amd64) 서버다. 맥에서 실행해 "동작 확인"이라고 쓰지 않는다.

## 확정된 사실 (다시 검증하지 않는다)

- 2026-11-14 CI(`ubuntu-24.04`, 실행 43536037384)가 패키지를 풀어 확인함
  - `openssh-server 1:9.6p1-3ubuntu13.20`의 `sshd`는 `libwrap.so.0`을 직접 링크한다. 그래서 U-28 기본값 `FW_MODE=tcpwrapper`는 sshd에 유효하다.
  - `snmpd 5.9.4+dfsg-1.1ubuntu3.3`는 `libwrap`을 직접 링크하지 않는다. 간접 링크(`ldd` 기준)는 미확인이다.
  - 같은 확인이 [vulnerability.yml](.github/workflows/vulnerability.yml)의 "환경 확인" 단계로 매 실행 로그에 남는다.

## 기록 (날짜 + 무슨 일 + 앞으로의 규칙)

- 2026-11-14
  - 일
    - 로컬 markdownlint가 옛 버전이라 표 규칙(MD060)을 못 잡고 CI가 실패했다.
  - 규칙
    - 로컬 검사는 `@latest`로 한다.
