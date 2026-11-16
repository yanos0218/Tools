# Changelog

이 저장소의 변경 이력. 형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 기준. 저장소 공통(구조·CI·표준·문서 규칙)만 이 파일에 적고, 도구별 이력은 각 도구 폴더의 CHANGELOG에 있음.

## [Unreleased]

### Added

- `docs.yml`에 상대 링크 검사 단계 추가([.github/scripts/check_links.py](.github/scripts/check_links.py))
- 이 파일 신설
- [vulnerability/](vulnerability/README.md) 이관
  - 기존 배포본 v1.1.0(2026-11-12)을 옮김. 폴더 이름은 `n2sf-hardening`에서 `vulnerability`로 정함.
  - 도구별 이력은 [vulnerability/CHANGELOG.md](vulnerability/CHANGELOG.md) 참고.
- 저장소 공통 문서(메인)
  - [docs/structure.md](docs/structure.md)에 구조도, 메인·서브 구분, 도구 폴더 규약, 이름 규칙
  - [docs/workflow.md](docs/workflow.md)에 변경 흐름, CI 구조, 새 도구 추가 절차
  - 루트 README에 도구 목록 표(분류·대상 환경·버전·검증)
- 워크플로
  - `docs.yml`은 저장소 전체 markdownlint
  - `vulnerability.yml`은 문법·정적 분석, 회귀 테스트, 실제 서버 환경 시험(항목별 독립 검증, 점검·조치·원복 왕복, 방화벽, 대화형, SNMP)
- 저장소 표준 파일
  - `CLAUDE.md`
  - `.gitignore`(비밀 파일 패턴)
  - `.markdownlint.jsonc`
  - `.github/dependabot.yml`(github-actions, 월 1회)

### Changed

- [docs/workflow.md](docs/workflow.md)의 Release 제목 규칙을 `[<도구>] vX.Y.Z - 한국어 제목`으로 정하고 제목 길이·내용 기준을 추가함(태그 규칙은 그대로).
- 문서 중복 정리
  - 루트 README의 vulnerability 문서 링크 4개를 도구 README의 문서 목록 링크 하나로 모음.
  - [docs/workflow.md](docs/workflow.md)의 CI 표를 실제 워크플로에 맞추고(링크 검사 추가), vulnerability 시험 내용은 도구 문서로 링크함.
  - 이 파일에서 도구 변경 항목(옵션·항목 수정·이름 변경 등)을 빼고 도구 CHANGELOG에만 둠.
- vulnerability 워크플로
  - 도구별 파일로 분리하고 경로 필터를 추가함(도구 폴더가 바뀔 때만 해당 검사 실행).
  - 항목별 독립 검증·방화벽·대화형·SNMP 시험을 추가하고, 왕복·SNMP 시험은 필수 검사로 올림(`continue-on-error` 제거). 왕복 job은 회귀 테스트와 동시에 실행함(`needs: test` 제거, 약 12분 → 약 6분 예상).
  - CI 테스트 경로를 `/opt/vuln`으로 바꿈. 시험 내용은 [vulnerability/CHANGELOG.md](vulnerability/CHANGELOG.md) 참고.
- 문서 정합성 정리: [docs/structure.md](docs/structure.md)에 용도별 하위 폴더 규약, [docs/workflow.md](docs/workflow.md)에 릴리즈 규칙(태그 `<도구>-vX.Y.Z`)을 추가함. 루트 README의 중복 표를 링크로 바꾸고, CLAUDE.md 읽기 목록에 도구 `docs/`를 넣음.
