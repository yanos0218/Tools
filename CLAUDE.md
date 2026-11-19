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
- shellcheck는 CI(0.9.0)와 같은 버전으로 돌린다. 맥(0.11)은 CI가 잡는 경고를 놓친다(2026-11-19 `seen` 변수를 연관 배열로 오인하는 SC2190이 CI에서만 나옴).
  - 맥의 `shellcheck`만으로 "통과"라고 쓰지 않는다.
  - Multipass VM `vuln-test`(Ubuntu 24.04, shellcheck 0.9.0 설치됨)에 저장소를 올린 뒤 CI와 같은 명령(`cd vulnerability && shellcheck -S warning ./*.sh lib/*.sh tools/*.sh items/*.sh tests/*.sh`)을 실행한다.
- vulnerability 회귀 테스트(`tests/run_tests.sh`)는 Ubuntu 24.04 root 전용이라 맥에서 실행하지 않는다. CI(`ubuntu-24.04`) 결과로만 "통과"라고 쓴다. CI 확인은 `gh run watch <실행ID> --exit-status`.
- 로컬에서 못 돌린 검사는 "미검증"으로 쓴다.

## 규칙

- 발견한 문제는 고치기 전에 Issue부터 남기고 라벨은 `문제`(오류·판정 오류), `할 일`(개선·추가), `research`(조사 기록)를 씀. 본문과 코멘트는 음슴체. 제목·라벨·마일스톤 규칙은 [docs/workflow.md](docs/workflow.md#이슈-규칙)를 따른다.
- 도구마다 폴더 하나와 도구 이름의 워크플로 하나를 쓴다. 규약은 [docs/structure.md](docs/structure.md)를 따른다.
- 새 도구는 [docs/workflow.md](docs/workflow.md)의 "새 도구 추가 절차"대로 만든다. 루트 README 도구 목록에 한 줄을 추가하는 것을 빠뜨리지 않는다.
- 도구 내용은 그 폴더(서브)에, 둘 이상의 도구에 공통인 내용만 루트 README와 `docs/`(메인)에 둔다. 서브 내용을 메인에 복사하지 않고 링크한다.
- 도구를 고치면 같은 커밋에서 그 폴더의 CHANGELOG와 README를 갱신한다. 저장소 구조·CI가 바뀌면 루트 [CHANGELOG.md](CHANGELOG.md)도 갱신한다.
- 도구 폴더 이름이나 워크플로 이름을 바꾸면 `**/*.md`와 `.github/`에서 옛 이름을 grep해 같은 커밋에서 고친다.
- vulnerability 항목(`items/U-xx.sh`)을 새로 만들거나 판정·조치를 바꿀 때는 가이드의 해당 항목 판단 기준·조치 방법 원문과 직접 대조하고, 다른 점은 같은 커밋에서 [vulnerability/docs/items.md](vulnerability/docs/items.md) 해당 행에 "자체 기준" 또는 "가이드와 다름"으로 적는다. 서브에이전트가 요약한 가이드 내용은 근거로 쓰지 않는다. 2026-11-16 #15에서 요약만 믿고 U-02 서술이 틀렸다. 가이드 원문 파일은 저장소에 커밋하지 않는다(저작물, 개정 있음).
- vulnerability 항목은 가이드가 요구하는 점검·조치만 구현한다. 가이드의 판단 기준·조치 방법을 확인하거나 적용하는 데 꼭 필요한 것 외에는 더하지 않는다(포트 검사, 가이드에 없는 서비스·유닛 이름, 접속 보호용 사전 확인 등). 불가피한 해석은 [vulnerability/docs/items.md](vulnerability/docs/items.md)에 "자체 기준" 또는 "해석"으로 적는다. 2026-11-16 사용자 지시.
- vulnerability 테스트 개수가 바뀌면 [vulnerability/README.md](vulnerability/README.md)의 개수(현재 484개)도 같은 커밋에서 고친다.
- `vulnerability/conf/vuln_hardening.conf.example`(과 서버에서 복사한 `vuln_hardening.conf`)에 실제 SNMP 암호·community·IP 정보를 채운 채 커밋하지 않는다. 채운 사본은 서버에서만 쓴다.
- vulnerability 스크립트의 대상은 Ubuntu 24.04(amd64) 서버다. 맥에서 실행해 "동작 확인"이라고 쓰지 않는다.

## 확정된 사실 (다시 검증하지 않는다)

- 2026-11-14 CI(`ubuntu-24.04`, 실행 43536037384)가 패키지를 풀어 확인함
  - `openssh-server 1:9.6p1-3ubuntu13.20`의 `sshd`는 `libwrap.so.0`을 직접 링크한다. 그래서 U-28 기본값 `FW_MODE=tcpwrapper`는 sshd에 유효하다.
  - `snmpd 5.9.4+dfsg-1.1ubuntu3.3`는 `libwrap`을 직접 링크하지 않는다. `ldd` 기준(간접 포함)으로는 `libwrap`이 보인다(2026-11-14 CI 실행 43600452523, [ci_snmp.sh](vulnerability/tests/ci_snmp.sh)). 그래서 U-61의 hosts.allow 접근제어 판정 경로가 열린다.
  - 같은 확인이 [vulnerability.yml](.github/workflows/vulnerability.yml)의 "환경 확인" 단계로 매 실행 로그에 남는다.

## 기록 (날짜 + 무슨 일 + 앞으로의 규칙)

- 2026-11-18
  - 일
    - 커밋 메시지의 `Closes #N`으로 #30·#31이 결과 댓글 없이 자동으로 닫혔고 본문도 부실했다.
  - 규칙
    - 커밋에는 `Refs #N`만 쓴다. 이슈는 CI 통과 뒤 구현 결과 댓글(커밋·변경 파일·검증 명령과 결과·미검증·영향)을 남기고 직접 닫는다. 본문은 현상·원인·조치·확인을 채운다.

- 2026-11-17
  - 일
    - 가이드와 다른 곳을 고치는 작업을 이슈 없이 진행해 이슈 2개만 남았고, 제목 패턴·태그·마일스톤도 없었다.
  - 규칙
    - 문제를 발견하면 고치기 전에 이슈부터 남긴다. 제목은 `[툴이름] 제목`, 릴리즈마다 마일스톤을 만든다.

- 2026-11-14
  - 일
    - 로컬 markdownlint가 옛 버전이라 표 규칙(MD060)을 못 잡고 CI가 실패했다.
  - 규칙
    - 로컬 검사는 `@latest`로 한다.
