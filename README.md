# Tools

운영 도구 모음 저장소. 도구마다 폴더 하나이고, 상세 설명은 각 폴더의 README에 있음.

## 도구

| 폴더 | 내용 |
| --- | --- |
| [n2sf-hardening/](n2sf-hardening/README.md) | Ubuntu 24.04 UNIX 서버 N2SF 보안 취약점 점검·조치·원복 스크립트 (v1.1.0) |

## 검증

- CI(`.github/workflows/ci.yml`)가 push·PR마다 문서(markdownlint)와 스크립트(`bash -n`, `shellcheck`, 회귀 테스트)를 검사함.
- n2sf-hardening 회귀 테스트는 Ubuntu 24.04 root 환경이 필요해 맥에서는 돌지 않음. CI의 `ubuntu-24.04` 러너가 대신 실행함.

## 문서

- [CHANGELOG.md](CHANGELOG.md)
  - 저장소 변경 이력
- [CLAUDE.md](CLAUDE.md)
  - Claude Code 작업 규칙
