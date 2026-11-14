# N2SF UNIX 서버 취약점 일괄 조치 가이드 (Ubuntu 24.04 LTS)

근거 문서: 한국부동산원 N2SF 도입지원사업 UNIX 서버 보안점검 상세 결과보고서 (점검 2026.10.19~10.23)
대상: INT-SEC-PDP-01/02, INT-SEC-PEP-01/02, EXT-USR-SEC-PEP-01/02

## 1. 구성

| 파일 | 용도 |
|---|---|
| `n2sf_u2404_hardening.sh` | 조치 스크립트 (점검 / 조치 / 검증 / 롤백) |
| `n2sf_hardening.conf` | 설정 파일 (6대 공통, 하단 `case` 블록으로 호스트별 값 지정). root 소유 600 |
| `make_pwq_bundle.sh` | 폐쇄망 U-02용 .deb 9개 번들 생성 (인터넷 되는 Ubuntu 24.04에서 실행) |
| `install_apt_hook.sh` | (선택) 패키지 업데이트 후 권한 계열 항목 자동 재점검 훅 설치/제거 |
| `tests/run_tests.sh` | 회귀 테스트 (시스템 변경 없음, 100개) |

## 2. 사전 준비 (반드시 결정해야 하는 값)

| 설정 | 항목 | 내용 | 미입력 시 |
|---|---|---|---|
| `MGMT_ALLOW_NETS` | U-28 | 관리자 SSH 허용 대역 (ACL 수집 결과) | 수동확인 |
| `SNMP_MODE` (+ v3 계정, `SNMP_NMS_HOSTS`) | U-58~61 | `disable` / `v3` / `v3v2c` | 대화형 선택, 무인 실행이면 수동확인 |
| `BANNER_FILE` | U-62 | 기관 지정 경고 문구 | 기본 경고문 적용 |
| `PWQ_DEB_DIR` | U-02 | 폐쇄망용 pwquality .deb 경로 (PDP) | apt 시도 후 부분조치 |
| `NTP_SERVERS` | U-65 | 자동 선택: 업무망 10.2.13.19 / 인터넷망 123.141.115.4 | 자동 선택값 사용 |

폐쇄망에서 pwquality 패키지 준비 (인터넷이 되는 Ubuntu 24.04에서):

```bash
./make_pwq_bundle.sh ./pwq_bundle      # .deb 9개 + SHA256SUMS 생성
```

5개(libpam-pwquality, libpwquality1, libpwquality-common, libcrack2, cracklib-runtime)만으로는 부족합니다.
`cracklib-runtime`이 `file`(→ libmagic1t64, libmagic-mgc)에 **필수 의존**하고, 사전(`wamerican`)이 없으면 cracklib 검사가 실패해 비밀번호 변경이 거부될 수 있어 총 9개를 번들로 만듭니다.
폐쇄망 서버로 옮긴 뒤 설치 전에 검증하십시오 (설치하지 않음):

```bash
cd pwq_bundle && sha256sum -c SHA256SUMS && dpkg --dry-run -i ./*.deb
```

사전이 끝내 없으면 스크립트가 `dictcheck = 0` 을 적용하고 경고합니다(길이·복잡도 정책은 그대로 적용).

실행 조건 (스크립트가 가장 먼저 확인하며, 어긋나면 아무것도 하지 않고 중단)

- **root 계정에서만 실행됩니다.** `sudo ./n2sf_u2404_hardening.sh ...` 또는 root 로그인. 비root 사용자는 `--list`, `--help` 를 포함해 모두 거부됩니다.
- **bash 4 이상**으로 실행해야 합니다 (`sh script.sh` 불가). Ubuntu 24.04 기본 bash 5.2 는 충족합니다.
- **설정 파일(`n2sf_hardening.conf`)이 반드시 있어야 합니다.** 스크립트와 같은 폴더에 두거나 `--config` 로 지정하십시오. 없으면 `--check` 를 포함해 아무것도 실행하지 않고 종료합니다. (`--rollback`, `--list`, `--help` 는 설정 파일 없이 동작 — 장애 시 원복은 항상 가능해야 하기 때문)
  - 설정 파일은 root 소유·그룹/기타 쓰기 불가(권장 600)여야 하며, 문법 오류나 잘못된 값(숫자·허용값·IPv4/CIDR 형식, 존재하지 않는 `BANNER_FILE`/`PWQ_DEB_DIR` 등)이 있으면 실행 전에 중단합니다.
  - CLI 로 준 `--delay`, `--wait`, `--role` 은 설정 파일 값보다 우선합니다.

작업 전 확인 사항

- IPMI나 VM 콘솔로 root 접근 경로를 확보해 두십시오. SSH, PAM, 방화벽 변경이 포함됩니다.
- sudo 권한이 있는 일반 계정(예: pribit)으로 SSH 접속이 되는지 확인하십시오. 없으면 U-01은 자동으로 중단됩니다.
- 현재 SSH 세션은 작업이 끝날 때까지 유지하고, 확인 작업은 새 터미널에서 하십시오.

## 3. 실행 절차

```bash
# 1) 업로드 후 권한
chmod 700 n2sf_u2404_hardening.sh

# 2) 사전 점검 (변경 없음) → 결과 CSV/증적 확인
sudo ./n2sf_u2404_hardening.sh --check

# 3) 일괄 조치 (대화형: 위험 항목은 안전 게이트에서 y 입력)
sudo ./n2sf_u2404_hardening.sh --delay 5

#    무인 일괄 조치 (게이트 자동 승인 - 콘솔 확보 시에만)
sudo ./n2sf_u2404_hardening.sh --yes --delay 5

# 4) 이행 점검 (변경 없음) → 이행 진단 결과 시트 작성
sudo ./n2sf_u2404_hardening.sh --check
```

### 옵션

| 옵션 | 설명 |
|---|---|
| `--check` | 점검만 수행 (변경 없음). 점검이 끝나면 종료코드 0 |
| `--strict` | `--check` 와 함께만 사용: 취약 항목이 있으면 종료코드 3 (자동화에서 취약 여부 판별용) |
| `--yes`, `-y` | 확인 질문과 안전 게이트 자동 승인 (**콘솔 확보 시에만**) |
| `--step` | 항목마다 실행 여부 확인 |
| `--delay N` / `--wait N` | 항목 간 대기 / 조치 후 검증 전 대기 (초, 숫자) |
| `--role pdp\|pep` | 서버 역할 지정 (대소문자 무관, 그 외 값은 오류) |
| `--config FILE` | 설정 파일 지정 (기본: 스크립트와 같은 폴더. 없으면 종료) |
| `--only LIST` | 지정 항목만 수행. `U-01,U-62` / `"U-01, U-62"` / `U-01 U-62` / `--only=U-01,U-62` 모두 가능, 반복 지정 시 누적 |
| `--order` | `--only` 로 지정한 **순서대로** 실행 (기본은 항목번호 순서). `--only` 와 함께만 사용 |
| `--skip LIST` | 지정 항목 제외 (`--only` 와 같이 쓰면 `--skip` 이 우선) |
| `--rollback DIR` | 지정 백업 디렉터리 기준 전체 원복 |
| `--list` | 항목 목록 |

- 값이 필요한 옵션을 값 없이 쓰거나, 항목 코드가 형식에 맞지 않거나 존재하지 않으면 **아무것도 실행하지 않고 오류로 중단**합니다.
- SNMP 항목(U-58~61)은 하나의 설정으로 함께 조치됩니다. 일부만 지정해도 SNMP 설정 전체가 바뀌므로 경고가 표시됩니다.
- `--order` 사용 시 항목 간 의존(sshd_config, PAM, rsyslog 공유)을 직접 고려하십시오. 원복은 항상 manifest 역순입니다.

### 종료 코드

| 코드 | 의미 |
|---|---|
| 0 | 정상 (`--check` 는 취약이 있어도 점검이 끝나면 0) |
| 1 | 옵션/환경 오류 (아무 변경 없음) |
| 2 | 조치 중 실패 또는 롤백 발생 |
| 3 | `--check --strict` 에서 취약 항목 존재 |

### 항목 처리 흐름

`사전점검 → (양호면 유지) → 백업 → 조치 → 대기(--wait) → 사후검증 → 판정 → 대기(--delay)`

- **조치/원복 모드는 tty 가 없으면 `--yes` 없이 실행되지 않습니다.** (자동화·`ssh host sudo ...` 를 `-t` 없이 쓰는 경우 중단) `--yes` 로 자동 승인된 게이트는 최종 요약에 목록으로 표시되므로, 새 세션 접속 확인을 별도로 수행하십시오.
- 설정 파일은 root 소유이고 그룹/기타 쓰기 권한이 없어야 로드됩니다 (`chmod 600`). 시작 화면에 입력값 미지정으로 수동확인이 예상되는 항목이 미리 표시됩니다.
- 안전 게이트(U-01, U-03, U-28)에서는 새 세션으로 접속해 확인한 뒤 `y`를 입력합니다. `n`을 입력하거나 제한 시간 안에 응답하지 않으면 해당 항목이 자동으로 원복됩니다.
- sshd, PAM, rsyslog는 구문 검사(`sshd -t`, PAM 모듈 존재 확인, `rsyslogd -N1`)를 통과하지 못하면 즉시 원복됩니다.
- 기능 검증 내용
  - U-06: 허용 사용자와 비허용 사용자(nobody)의 su 실행 권한
  - U-59: SNMPv3 로컬 조회
  - U-65: 시각 동기화 완료까지 대기
  - U-66/67: `logger`로 남긴 테스트 로그가 실제로 기록되는지 확인. U-67에서 기록이 안 되면 자동 원복됩니다.

## 4. 항목별 조치 내용

| 코드 | 조치 | 운영 영향 / 주의 |
|---|---|---|
| U-01 | `PermitRootLogin no` (sshd_config + drop-in 중복 정리) | root SSH 불가 → 일반계정+sudo |
| U-02 | login.defs MIN 1/MAX 90/WARN 7, 기존 계정 chage (만료까지 남은 일수를 증적에 기록, 30일 이내면 경고), pwquality(8자·숫자·영문·특수, enforce_for_root), pwhistory remember=4 | **PEP 예외**(pam_pribit.so). 마지막 변경 후 90일 이상 지난 계정은 MAX 적용을 보류하고 경고만 표시 (즉시 만료 방지) |
| U-03 | pam_faillock deny=5, unlock 300s (pam-auth-update 프로파일) | PEP는 이미 양호. pam_pribit 스택은 수정하지 않음. 잠금 해제: `faillock --user <id> --reset` |
| U-06 | wheel 그룹 생성(sudo 그룹 구성원 등록), `pam_wheel.so use_uid group=wheel`, su 4750 root:wheel | 그룹 반영은 재로그인부터. sudo에는 영향 없음 |
| U-12 | `/etc/profile` TMOUT=600 | 신규 로그인부터 적용 |
| U-18 | /etc/shadow(gshadow) 400 | 비root의 unix_chkpwd 검증 불가 (서버 운영에는 영향 없음) |
| U-20 | /etc/systemd/*.conf 600. timesyncd·resolved·networkd·user.conf는 유효 설정을 `<name>.conf.d/`로 옮긴 뒤 원본 제거 | 이 파일들은 비root 데몬이 읽으므로 600으로 바꾸면 NTP·DNS 설정이 무시됩니다. dropin 방식으로 기준과 기능을 모두 유지 |
| U-21 | rsyslog.conf, rsyslog.d 640 | – |
| U-23 | newgrp 등 SUID/SGID 제거 (dpkg-statoverride) | 패키지를 업데이트해도 유지됨. 전체 SUID 목록은 증적 `U-23_suid_sgid_all.txt` |
| U-28 | hosts.allow/deny로 sshd(필요 시 snmpd)를 관리 대역만 허용. iptables 모드는 `N2SF_MGMT` 체인과 `n2sf-fw.service` | 현재 접속 IP가 허용 대역 밖이거나 IPv6로 접속 중이면 중단. **tcpwrapper 는 sshd가 libwrap을 링크한 경우에만 유효**(`ldd $(command -v sshd) \| grep wrap`). 미지원이면 `수동확인`으로 중단하고 `FW_MODE=iptables` 를 요구하며, 점검 판정도 libwrap 지원을 확인함. PEP는 자체 iptables와의 충돌을 먼저 확인 |
| U-37 | crontab/at 750, /etc/crontab·cron.d·spool 640 | 750 으로 지정하므로 **setgid 도 함께 제거**되어 일반 사용자와 crontab 그룹 구성원 모두 crontab/at 사용 불가 (root 만 가능). 의도된 동작 |
| U-58~61 | (하나의 설정으로 일괄 조치) 미사용 시 비활성화. 사용 시 v3 사용자 생성, public community 제거, NMS IP 제한 | v2c(public)로 수집하던 NMS는 수집이 끊기므로 사전에 NMS 담당자와 협의 필요. PEP의 기존 `rouser authPrivUser`는 패키지 기본값일 뿐 실제 계정이 없으므로 `SNMPV3_USER` 지정 권장 |
| U-62 | /etc/issue, issue.net, motd 경고문. 버전을 노출하는 update-motd 비활성화. SSH Banner를 /etc/issue.net으로 변경 | PEP의 `/var/connect/gateway/etc/banner`는 파일은 그대로 두고 참조만 변경 |
| U-64 | 기본은 증적 수집(OS, 커널, 대기 중인 보안 업데이트) | 인터뷰 항목. `PATCH_MODE=security`로 적용 가능 |
| U-65 | timesyncd NTP 지정(drop-in), Poll 32~2048s, 동기화 대기 | UDP/123 통신 필요 (PDP 미동기 원인 확인) |
| U-66 | `/etc/rsyslog.d/40-n2sf-policy.conf`(auth·cron·emerg·alert), 보관 26주 | logrotate 는 스탠자별 주기에 맞춰 환산 (daily 는 182개, weekly 는 26개; 기존 값이 더 크면 유지). `alert.log` 는 `/etc/logrotate.d/n2sf-alert` 로 별도 회전. 기관 로그 정책이 확정되면 보완 |
| U-67 | rsyslog를 root로 구동(PrivDrop 해제, FileOwner root), /var/log 최상위 로그 파일 root·640 (**권한 분리가 약해지는 대가**이며 점검기준 충족 목적임을 결과 상세에 표기) | **하위 디렉터리(mysql/redis 등)는 변경하지 않음** (보고서 비고: 데몬 기동 장애). 기록 실패 시 자동 원복 |

## 5. 결과물

`/root/n2sf_hardening/<호스트>_<일시>/`

| 파일 | 내용 |
|---|---|
| `result_<호스트>.csv` | 조치 전/후, 결과, **이행점검(Y/P/N/예외)** 값 → '이행 진단 결과 요약' 시트에 바로 기입 |
| `evidence/U-xx.txt` | 항목별 사전/사후 증적 (설정값, 권한, 명령 결과) |
| `run.log` | 실행 로그 |
| `manifest`, `files/` | 원복용 백업 |
| `rollback.sh` | 전체 원복 실행 파일 |

결과 판정: `조치완료`/`양호(유지)`=Y, `부분조치`=P, `수동확인`/`실패`/`롤백`=N, `예외`=예외. 항목 함수가 오류를 감지해 스스로 원복한 경우는 `실패`가 아니라 `롤백`으로 표기됩니다. 종료코드는 위 표를 참조하십시오.

## 6. 원복 (순서 보장)

- **같은 `rollback.sh` 를 다시 실행해도 안전합니다.** 전체 원복이 끝나면 manifest 에 항목별 `ROLLEDBACK` 표식이 남고, 재실행하면 "이미 원복되었거나 원복할 변경이 없습니다"만 출력하고 종료합니다(원복 이후 관리자가 바꾼 설정을 덮어쓰지 않음). 의도적으로 다시 원복해야 하면 manifest 의 `ROLLEDBACK` 줄을 삭제한 뒤 실행하십시오.
- U-02에서 스크립트가 설치한 `libpam-pwquality`는 PAM 파일 복원 **이후**에 제거됩니다 (복원 전에 제거되어 PAM 모듈이 없는 구간이 생기던 문제 수정).

```bash
sudo bash /root/n2sf_hardening/<호스트>_<일시>/rollback.sh
```

파일 내용, 권한, dpkg-statoverride, 서비스 상태, chage, 그룹, iptables 변경을 역순으로 되돌린 뒤 ssh, rsyslog, timesyncd, snmpd를 다시 적용합니다.
여러 번 실행했다면 **최근 실행 디렉터리부터** 차례로 원복하십시오.

## 7. 운영 참고

- **패치 후 자동 재점검(선택)**: `sudo ./install_apt_hook.sh install` 을 실행하면 apt/dpkg 종료 직후 U-18/20/21/37을 점검만 하고 `/var/log/n2sf_recheck.log` 와 syslog(auth.warning)에 결과를 남깁니다. 자동 조치는 하지 않으며 apt를 막지 않습니다. 제거: `remove`, 상태: `status`.
- **회귀 테스트**: 스크립트를 수정한 뒤에는 `sudo ./tests/run_tests.sh` 를 실행하십시오 (옵션 파서·root/conf 검사·로그 보관 계산 등 100개 검증, 시스템 변경 없음).
- U-62: 점검 증적에 `/etc/update-motd.d` 의 실행 가능 스크립트 목록이 남습니다. 버전·시스템 정보를 출력하는 항목이 더 있으면 conf의 `U62_MOTD` 에 추가하십시오.

- 패키지를 업데이트(특히 cron, sysstat, systemd)하면 일부 파일 권한이 초기화될 수 있습니다. 패치 후에는 `--check`를 실행하고, 필요하면 조치를 다시 실행하십시오. 스크립트는 몇 번을 실행해도 결과가 같습니다(멱등).
- PDP-02는 원격 접속이 안 되어 점검 결과를 1호기와 동일하게 작성했습니다. 이 서버는 반드시 `--check`부터 실행해 실제 상태를 확인하십시오.
