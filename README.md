# Tools

운영·점검·자동화 도구 모음 저장소. 도구마다 폴더 하나를 쓰고, 도구별 정보는 그 폴더 안(서브)에, 저장소 공통 정보는 이 문서와 [docs/](docs/structure.md)(메인)에 둠.

## 도구 목록

| 도구 | 분류 | 내용 | 대상 환경 | 버전 | 검증 |
| --- | --- | --- | --- | --- | --- |
| [vulnerability/](vulnerability/README.md) | 보안 | Linux 서버 보안 취약점 점검·조치·원복 스크립트 | Ubuntu 24.04, root | 5.0.1 | [vulnerability.yml](.github/workflows/vulnerability.yml) |

새 도구는 이 표에 한 줄을 추가함. 절차는 [작업 흐름](docs/workflow.md#새-도구-추가-절차) 참고.

메인(저장소 공통)과 서브(도구별) 구분은 [저장소 구조](docs/structure.md#메인과-서브) 참고.

## 문서

- [저장소 구조](docs/structure.md)
  - 구조도, 메인·서브 구분, 도구 폴더 규약, 이름 규칙
- [작업 흐름](docs/workflow.md)
  - 변경 흐름, CI 구조, 로컬 검사, 새 도구 추가 절차
- 도구별 문서는 각 도구 README의 문서 목록 참고
  - [vulnerability](vulnerability/README.md#문서)
- [CHANGELOG.md](CHANGELOG.md)
  - 저장소 변경 이력
- [CLAUDE.md](CLAUDE.md)
  - Claude Code 작업 규칙

## 검증

- push·PR마다 도구별 워크플로가 해당 폴더 변경 시에만 실행됨.
- vulnerability 회귀 테스트는 Ubuntu 24.04 root가 필요해 맥에서는 돌지 않고, CI의 `ubuntu-24.04` 러너가 실행함.
