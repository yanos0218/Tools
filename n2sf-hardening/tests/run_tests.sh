#!/usr/bin/env bash
# =============================================================================
#  n2sf 스크립트 회귀 테스트 (bash 만 필요, 시스템 변경 없음)
#    sudo ./tests/run_tests.sh        # root 필요(스크립트가 root 를 요구)
#  - 함수 단위: N2SF_SOURCE_ONLY=1 로 함수만 로드해 검증
#  - CLI 단위 : --check 모드와 '즉시 중단되어야 하는' 오류 경로만 실행 (조치 모드는 실행하지 않음)
# =============================================================================
HERE=$(dirname "$(readlink -f "$0")"); S="$HERE/../n2sf_u2404_hardening.sh"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
ok_(){ PASS=$((PASS+1)); printf '  \e[32mPASS\e[0m %s\n' "$1"; }
ng_(){ FAIL=$((FAIL+1)); printf '  \e[31mFAIL\e[0m %s\n' "$1"; }
check(){ local d=$1; shift; if "$@" >/dev/null 2>&1; then ok_ "$d"; else ng_ "$d"; fi; }
nocheck(){ local d=$1; shift; if "$@" >/dev/null 2>&1; then ng_ "$d"; else ok_ "$d"; fi; }
eq(){ [[ $2 == "$3" ]] && ok_ "$1" || ng_ "$1 (기대='$3' 실제='$2')"; }
[[ $EUID -eq 0 ]] || { echo "root 로 실행하십시오"; exit 1; }
echo "REPORT_BASE=\"$T/out\"" >"$T/c.conf"; chmod 600 "$T/c.conf"
CLI(){ "$S" --config "$T/c.conf" --delay 0 --wait 0 "$@" </dev/null; }

echo "== 함수 단위"
( export N2SF_SOURCE_ONLY=1; source "$S"
  fails=0; t(){ eval "$2" >/dev/null 2>&1 && echo "PASS $1" || { echo "FAIL $1"; fails=1; }; }
  n(){ eval "$2" >/dev/null 2>&1 && { echo "FAIL $1"; fails=1; } || echo "PASS $1"; }
  t "ip_in_cidr 포함"            'ip_in_cidr 10.2.12.135 10.2.12.0/24'
  n "ip_in_cidr 불포함"          'ip_in_cidr 10.2.13.5 10.2.12.0/24'
  t "ip_in_cidr /32"             'ip_in_cidr 10.2.12.7 10.2.12.7'
  t "cidr_tcpw /16"              '[[ $(cidr_tcpw 10.2.0.0/16) == 10.2.0.0/255.255.0.0 ]]'
  touch "$T/m"; chmod 2755 "$T/m"
  n "perm_ok 특수비트 포함 비교"  "perm_ok $T/m 750"
  chmod 640 "$T/m"; t "perm_ok 640<=640" "perm_ok $T/m 640"
  t "snmp_comm_ok 영숫자 10자"   'snmp_comm_ok Abcdefgh12'
  t "snmp_comm_ok 특수 8자"      'snmp_comm_ok "Ab1!xyz9"'
  n "snmp_comm_ok public 거부"   'snmp_comm_ok public'
  n "snmp_comm_ok 짧은 영숫자"   'snmp_comm_ok Abc12345'
  t "parse_ids 공백/소문자/중복" 'parse_ids --only " u-12, U-18 ,u-12"; [[ "${PARSED_ARR[*]}" == "U-12 U-18" ]]'
  n "parse_ids 형식 오류"        '( parse_ids --only U-1 )'
  n "parse_ids 없는 코드"        '( parse_ids --only U-99 )'
  n "parse_ids 빈 값"            '( parse_ids --only "" )'
  t "valid_id"                   'valid_id U-67'
  n "valid_id 없는 코드"         'valid_id U-04'
  BK_DIR="$T/bk"; MANIFEST="$T/mf"; CUR_ID=TEST; LOG_FILE="$T/log"; : >"$MANIFEST"; mkdir -p "$BK_DIR"
  printf 'PASS_MAX_DAYS\t99999\n#PASS_MIN_DAYS 0\n' >"$T/ld"
  set_conf "$T/ld" PASS_MAX_DAYS 90 $'\t'; set_conf "$T/ld" PASS_MAX_DAYS 90 $'\t'
  t "set_conf 값 교체·중복 없음" '[[ $(grep -c "^PASS_MAX_DAYS" "$T/ld") == 1 && $(get_kv "$T/ld" PASS_MAX_DAYS) == 90 ]]'
  t "set_conf 백업 기록"         'grep -q "^FILE|TEST|$T/ld|1" "$MANIFEST"'
  t "pam_arg"                    '[[ $(pam_arg "password requisite pam_pwquality.so retry=3 minlen=8" minlen) == 8 ]]'
  printf '/var/log/syslog\n{\n\trotate 7\n\tdaily\n}\n/var/log/auth.log\n{\n\trotate 4\n\tweekly\n}\n' >"$T/lr"
  eq_(){ [[ $1 == "$2" ]]; }
  t "u66_min_weeks 변경 전=1주"  '[[ $(u66_min_weeks "$T/lr") == 1 ]]'
  u66_rotate_apply "$T/lr" 26
  t "u66 daily→182, weekly→26"   'grep -q "rotate 182" "$T/lr" && grep -q "rotate 26" "$T/lr" && [[ $(u66_min_weeks "$T/lr") == 26 ]]'
  cp "$T/lr" "$T/lr2"; u66_rotate_apply "$T/lr" 26
  t "u66 멱등"                   'cmp -s "$T/lr" "$T/lr2"'
  u66_rotate_apply "$T/lr" 4
  t "u66 값을 낮추지 않음"       'cmp -s "$T/lr" "$T/lr2"'
  exit $fails
) | sed 's/^PASS /  \x1b[32mPASS\x1b[0m /; s/^FAIL /  \x1b[31mFAIL\x1b[0m /' | tee "$T/fn.out"
P=$(grep -c 'PASS' "$T/fn.out"); F=$(grep -c 'FAIL' "$T/fn.out"); PASS=$((PASS+P)); FAIL=$((FAIL+F))

echo "== CLI: 즉시 중단되어야 하는 오류 경로 (REPORT_BASE 에 아무것도 만들면 안 됨)"
for a in "--only" "--only=" "--skip" "--rollback" "--config" "--role" "--delay" "--wait" \
         "--check --only U-1" "--check --only U-99" "--check --only U-04" "--check --skip X" \
         "--check --role x" "--check --delay abc" "--check --order" "--bogus" "--check --config /nonexistent"; do
  nocheck "중단: $a" CLI $a
done
nocheck "비대화형 조치는 --yes 없이 실행 안 함" CLI --only U-12
nocheck "비대화형 원복은 --yes 없이 실행 안 함" CLI --rollback "$T/none"
chmod 666 "$T/c.conf"; nocheck "conf 그룹/기타 쓰기 → 거부" CLI --check --only U-12; chmod 600 "$T/c.conf"
check "오류 경로에서 결과 디렉터리 미생성" test ! -e "$T/out"

echo "== CLI: --check 정상 경로"
run(){ CLI --check "$@" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -oE '^ U-[0-9]+' | tr -d ' ' | tr '\n' ' '; }
eq "기본 순서(번호순)"                "$(run --only U-62,U-12)"              "U-12 U-62 "
eq "공백 포함 쉼표"                   "$(run --only "U-62, U-12")"           "U-12 U-62 "
eq "공백 구분"                        "$(run --only U-62 U-12)"              "U-12 U-62 "
eq "--opt=값 + 소문자"                "$(run --only=u-62,u-12)"              "U-12 U-62 "
eq "--order 지정 순서"                "$(run --only U-62,U-12 --order)"      "U-62 U-12 "
eq "반복 지정 누적 + --order"         "$(run --only U-62 --only U-12 --order)" "U-62 U-12 "
eq "--skip 이 --only 보다 우선"       "$(run --only U-12,U-18 --skip U-12)"  "U-18 "
eq "PEP 예외(U-02)"                   "$(CLI --check --role PEP --only U-02 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -c '예외')" "3"
CLI --check --only U-12 >/dev/null 2>&1; rc=$?
eq "--check 기본 종료코드는 0 (취약이 있어도)" "$rc" "0"
CLI --check --strict --only U-12 >/dev/null 2>&1; rc=$?
V=$(CLI --check --only U-12 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -c '^ U-12  취약')
[[ $V == 1 ]] && eq "--check --strict: 취약이면 3" "$rc" "3" || eq "--check --strict: 양호면 0" "$rc" "0"
CLI --check --strict --only U-02 --role pep >/dev/null 2>&1; eq "--strict: 예외 항목만 있으면 0" "$?" "0"
nocheck "--strict 는 --check 없이 사용 불가" CLI --strict --only U-12
ls "$T/out" 2>/dev/null | grep -q '_check' && ok_ "점검 결과 디렉터리 생성" || ng_ "점검 결과 디렉터리 없음"

echo "== root 전용 / bash 전용"
X="$T/x"; mkdir -p "$X"; cp "$S" "$HERE/../n2sf_hardening.conf" "$X/"; chmod 755 "$T" "$X" "$X"/*; chmod 644 "$X/n2sf_hardening.conf"
for a in "--list" "-h" "--check" "--check --only U-12" "--yes --only U-12" ""; do
  out=$(runuser -u nobody -- "$X/n2sf_u2404_hardening.sh" $a </dev/null 2>&1); rc=$?
  [[ $rc == 1 && $out == *"root 계정에서만"* ]] && ok_ "비root(nobody) 거부: '${a:-<무옵션>}'" || ng_ "비root 거부 실패: '${a:-<무옵션>}' rc=$rc"
done
out=$(sh "$X/n2sf_u2404_hardening.sh" --check </dev/null 2>&1); rc=$?
[[ $rc == 1 && $out == *"bash 로 실행"* ]] && ok_ "sh 로 실행 시 거부" || ng_ "sh 실행 거부 실패 rc=$rc"
check "root 는 --list 가능" "$S" --list

echo "== 설정 파일(conf) 존재/검증"
Y="$T/y"; mkdir -p "$Y"; cp "$S" "$Y/"; chmod 700 "$Y"           # conf 없는 폴더
before=$(ls /root/n2sf_hardening 2>/dev/null)
for a in "" "--check" "--check --only U-12" "--yes" "--config $T/none.conf --check"; do
  out=$("$Y/n2sf_u2404_hardening.sh" $a </dev/null 2>&1); rc=$?
  [[ $rc == 1 && $out == *"설정 파일이 없어 실행할 수 없습니다"* ]] && ok_ "conf 없음 → 종료: '${a:-<무옵션>}'" || ng_ "conf 없음인데 계속 진행: '${a:-<무옵션>}' rc=$rc"
done
nocheck "--no-config 옵션은 제거됨" "$Y/n2sf_u2404_hardening.sh" --no-config --check
check "conf 없어도 --list 동작" "$Y/n2sf_u2404_hardening.sh" --list
out=$("$Y/n2sf_u2404_hardening.sh" --rollback "$T/none" --yes </dev/null 2>&1); rc=$?
[[ $rc == 1 && $out == *"manifest"* && $out != *"설정 파일"* ]] && ok_ "원복은 conf 없이도 동작(manifest 검사까지 진행)" || ng_ "원복이 conf 에 의존함 rc=$rc"
for x in $(ls /root/n2sf_hardening 2>/dev/null); do grep -qxF "$x" <<<"$before" || rm -rf "/root/n2sf_hardening/$x"; done

badconf(){ printf '%s\n' "REPORT_BASE=\"$T/out\"" "$1" >"$T/b.conf"; chmod 600 "$T/b.conf"; "$S" --config "$T/b.conf" --check --only U-12 </dev/null 2>&1; }
for v in 'FW_MODE="bogus"' 'PATCH_MODE=""' 'STEP_DELAY="abc"' 'CHAGE_EXISTING="maybe"' 'SNMP_MODE="v4"' 'MGMT_ALLOW_NETS="10.2.12.0/33"' \
         'MGMT_ALLOW_NETS="10.2.300.0/24"' 'SNMP_NMS_HOSTS="nms-host"' 'BANNER_FILE="/nonexistent/banner.txt"' 'PWQ_DEB_DIR="/nonexistent"' 'REPORT_BASE="relative/path"' 'if then'; do
  out=$(badconf "$v"); rc=$?
  [[ $rc == 1 && ( $out == *"설정값 오류"* || $out == *"문법 오류"* ) ]] && ok_ "잘못된 conf 거부: $v" || ng_ "잘못된 conf 통과: $v (rc=$rc)"
done
for v in 'MGMT_ALLOW_NETS="10.2.12.0/24 10.2.13.5"' 'SNMP_MODE="v3"' 'FW_MODE="both"' 'LOG_ROTATE_COUNT=""'; do
  out=$(badconf "$v"); rc=$?; [[ $rc == 0 || $rc == 3 ]] && ok_ "올바른 conf 허용: $v" || ng_ "올바른 conf 거부: $v (rc=$rc)"
done
printf '%s\n' "REPORT_BASE=\"$T/out\"" 'STEP_DELAY=3' 'POST_WAIT=2' >"$T/d.conf"; chmod 600 "$T/d.conf"
out=$("$S" --config "$T/d.conf" --check --only U-12 --delay 0 --wait 0 </dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
[[ $out == *"항목간 0s, 검증전 0s"* ]] && ok_ "CLI --delay/--wait 가 conf 값보다 우선" || ng_ "CLI 값이 conf 에 덮임"
out=$("$S" --config "$T/d.conf" --check --only U-12 </dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g')
[[ $out == *"항목간 3s, 검증전 2s"* ]] && ok_ "CLI 미지정 시 conf 값 사용" || ng_ "conf 값 미적용"
out=$("$S" --config "$HERE/../n2sf_hardening.conf" --check --only U-12 --role pep </dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | grep -c '역할: PEP')
eq "실제 배포 conf 로딩 + --role 우선" "$out" "1"
rm -rf /root/n2sf_hardening/*_check 2>/dev/null

echo "== 전체 원복 재실행 방지 (임시 경로만 사용)"
R="$T/rb"; mkdir -p "$R/bk/files/U-98$R/t" "$R/bk/files/U-99$R/t" "$R/t"
echo ORIG98 >"$R/bk/files/U-98$R/t/a.txt"; echo ORIG99 >"$R/bk/files/U-99$R/t/b.txt"
echo CHG98 >"$R/t/a.txt"; echo CHG99 >"$R/t/b.txt"
printf '%s\n' "FILE|U-98|$R/t/a.txt|1" "FILE|U-99|$R/t/b.txt|1" "ROLLEDBACK|U-98" >"$R/bk/manifest"
RB(){ "$S" --rollback "$R/bk" --yes </dev/null 2>&1 | sed 's/\x1b\[[0-9;]*m//g'; }
RB >/dev/null
eq "항목별로 이미 원복된 U-98 은 건너뜀" "$(cat "$R/t/a.txt")" "CHG98"
eq "미원복 U-99 는 복원" "$(cat "$R/t/b.txt")" "ORIG99"
eq "완료 표식 기록(U-98, U-99)" "$(grep -c '^ROLLEDBACK|U-9[89]$' "$R/bk/manifest")" "2"
echo ADMIN_CHANGE >"$R/t/b.txt"; out=$(RB)
eq "재실행해도 이후 변경을 덮어쓰지 않음" "$(cat "$R/t/b.txt")" "ADMIN_CHANGE"
[[ $out == *"이미 원복되었거나"* ]] && ok_ "재실행 시 안내 후 종료" || ng_ "재실행 안내 없음"
nocheck_rc(){ "$@" >/dev/null 2>&1; [[ $? == 0 ]]; }
check "재실행 종료코드 0" nocheck_rc "$S" --rollback "$R/bk" --yes
sed -i '/^ROLLEDBACK|U-99$/d' "$R/bk/manifest"; RB >/dev/null
eq "표식 삭제 시 의도적 재원복 가능" "$(cat "$R/t/b.txt")" "ORIG99"
: >"$R/bk/manifest"; out=$(RB); [[ $out == *"원복할 변경이 없습니다"* ]] && ok_ "빈 manifest 는 안내 후 종료" || ng_ "빈 manifest 처리 이상"

echo; echo "결과: PASS=$PASS FAIL=$FAIL"; (( FAIL == 0 ))
