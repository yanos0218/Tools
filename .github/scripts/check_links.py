#!/usr/bin/env python3
"""저장소 .md 의 상대 경로 링크가 실제 파일·폴더를 가리키는지 검사한다. 외부 URL·앵커는 대상 아님."""
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote

root = Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip())
files = subprocess.check_output(["git", "ls-files", "*.md"], cwd=root, text=True).split()
link = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
bad = []
checked = 0

for rel in files:
    in_code = False
    for no, line in enumerate((root / rel).read_text(encoding="utf-8").splitlines(), 1):
        if line.lstrip().startswith("```"):
            in_code = not in_code
            continue
        if in_code:
            continue
        for target in link.findall(re.sub(r"`[^`]*`", "", line)):
            if re.match(r"^[a-z]+:", target) or target.startswith("#"):
                continue
            path = unquote(target.split("#")[0])
            checked += 1
            if not (root / rel).parent.joinpath(path).resolve().exists():
                bad.append(f"{rel}:{no}: {target}")

print(f"검사한 링크 {checked}건, 끊긴 링크 {len(bad)}건")
for b in bad:
    print("  " + b)
sys.exit(1 if bad or checked == 0 else 0)
