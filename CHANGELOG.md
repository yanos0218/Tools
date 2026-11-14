# Changelog

이 저장소의 변경 이력. 형식은 [Keep a Changelog](https://keepachangelog.com/ko/1.1.0/) 기준. 도구별 이력은 각 폴더의 CHANGELOG에 있음.

## [Unreleased]

### Added

- 이 파일 신설
- [n2sf-hardening/](n2sf-hardening/README.md) 이관
  - 기존 배포본 v1.1.0(2026-11-12)을 그대로 옮김. 스크립트 내용은 바꾸지 않음.
  - 도구별 이력은 [n2sf-hardening/CHANGELOG.md](n2sf-hardening/CHANGELOG.md) 참고.
- CI 신설(`.github/workflows/ci.yml`)
  - markdownlint
  - `bash -n`, `shellcheck`
  - n2sf-hardening 회귀 테스트(`ubuntu-24.04`, root)
- 저장소 표준 파일
  - `CLAUDE.md`
  - `.gitignore`(비밀 파일 패턴)
  - `.markdownlint.jsonc`
  - `.github/dependabot.yml`(github-actions, 월 1회)
