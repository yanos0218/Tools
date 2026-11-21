#!/usr/bin/env python3
"""릴리즈된 CHANGELOG 섹션이 태그 시점과 같은지 확인한다(#51).

가장 최근 태그 시점의 `## [X.Y.Z]` 섹션이 현재 파일에서 같은 내용이어야 한다.
`## [Unreleased]`는 비교하지 않는다. 태그가 없으면 건너뛴다.
"""
import re
import subprocess
import sys

# (CHANGELOG 경로, 태그 패턴)
TARGETS = [("vulnerability/CHANGELOG.md", "vulnerability-v*")]


def git(*args):
    r = subprocess.run(["git", *args], capture_output=True, text=True)
    return r.returncode, r.stdout


def released_sections(text):
    """버전 → 섹션 본문(앞뒤 공백 제거). Unreleased는 제외."""
    parts = re.split(r"(?m)^## \[([^\]]+)\][^\n]*\n", text)
    out = {}
    for i in range(1, len(parts), 2):
        if parts[i].lower() != "unreleased":
            out[parts[i]] = parts[i + 1].strip()
    return out


def main():
    bad = 0
    for path, pattern in TARGETS:
        rc, out = git("tag", "--list", pattern, "--sort=-v:refname")
        tags = out.split()
        if rc != 0 or not tags:
            print(f"건너뜀: {path} ({pattern} 태그 없음)")
            continue
        tag = tags[0]
        rc, old = git("show", f"{tag}:{path}")
        if rc != 0:
            print(f"건너뜀: {path} ({tag} 시점에 파일 없음)")
            continue
        try:
            with open(path, encoding="utf-8") as f:
                new = f.read()
        except OSError as e:
            print(f"오류: {path} 읽기 실패: {e}")
            bad += 1
            continue
        old_s, new_s = released_sections(old), released_sections(new)
        for ver, body in old_s.items():
            if ver not in new_s:
                print(f"오류: {path} [{ver}] 섹션이 사라짐({tag} 기준)")
                bad += 1
            elif new_s[ver] != body:
                print(f"오류: {path} [{ver}] 섹션이 {tag} 시점과 다름. 새 항목은 [Unreleased]에 적을 것")
                bad += 1
        print(f"확인: {path} 릴리즈된 섹션 {len(old_s)}개를 {tag}와 비교")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
