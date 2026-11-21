#!/usr/bin/env python3
"""회귀 테스트 출력의 `결과: PASS=N`과 문서에 적힌 개수를 비교한다(#52).

사용: check_test_count.py <run_tests.sh 출력 파일>
문서의 개수는 vulnerability/README.md의 "회귀 테스트 N개"와 CLAUDE.md의 "현재 N개"에서 읽는다.
"""
import re
import sys

DOCS = [
    ("vulnerability/README.md", r"회귀 테스트 (\d+)개"),
    ("CLAUDE.md", r"현재 (\d+)개"),
]


def main():
    if len(sys.argv) != 2:
        print("사용: check_test_count.py <출력 파일>")
        return 2
    with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
        m = re.findall(r"결과: PASS=(\d+) FAIL=(\d+)", f.read())
    if not m:
        print("오류: 출력에서 '결과: PASS=N FAIL=M'을 찾지 못함")
        return 2
    actual = int(m[-1][0])
    bad = 0
    for path, pat in DOCS:
        with open(path, encoding="utf-8") as f:
            found = re.findall(pat, f.read())
        if len(found) != 1:
            print(f"오류: {path}에서 개수 표기({pat})가 {len(found)}곳 발견됨(1곳이어야 함)")
            bad += 1
        elif int(found[0]) != actual:
            print(f"오류: {path}의 개수 {found[0]}개와 실제 PASS={actual}이 다름. 같은 커밋에서 고칠 것")
            bad += 1
        else:
            print(f"확인: {path} {actual}개 일치")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
