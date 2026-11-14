# Changelog

이 저장소의 변경 이력. 형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 기준. 도구별 이력은 각 도구 폴더의 CHANGELOG에 있음.

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
- [vulnerability/docs/architecture.md](vulnerability/docs/architecture.md) 신설(서브 문서, 다이어그램)
- 워크플로
  - `docs.yml`은 저장소 전체 markdownlint
  - `vulnerability.yml`은 `bash -n`, `shellcheck`, 회귀 테스트(`ubuntu-24.04`, root), libwrap 링크 확인(참고)
- 저장소 표준 파일
  - `CLAUDE.md`
  - `.gitignore`(비밀 파일 패턴)
  - `.markdownlint.jsonc`
  - `.github/dependabot.yml`(github-actions, 월 1회)

### Changed

- vulnerability 2.0.0: 이름 일반화(상세는 [vulnerability/CHANGELOG.md](vulnerability/CHANGELOG.md)). CI 테스트 경로를 `/opt/vuln` 으로 변경함.
- vulnerability README를 입구로 줄이고 사용법·항목별 조치·결과물·원복 문서를 `vulnerability/docs/`로 분리함. 루트 README 문서 목록에 링크를 추가함.
- vulnerability 조치 시 정해지지 않은 값(U-28·62·65·66)을 실행 중 선택하도록 함. 설정 파일을 선택 사항으로 바꿈(`conf/vuln_hardening.conf.example`). CI의 권한 보정 경로를 같이 고침.
- 문서 정합성 정리: [docs/structure.md](docs/structure.md)에 용도별 하위 폴더 규약, [docs/workflow.md](docs/workflow.md)에 릴리즈 규칙(태그 `<도구>-vX.Y.Z`)을 추가함. 루트 README의 중복 표를 링크로 바꾸고, CLAUDE.md 읽기 목록에 도구 `docs/`를 넣음.
- 워크플로를 도구별 파일로 분리하고 경로 필터를 추가함(도구 폴더가 바뀔 때만 해당 검사 실행).
