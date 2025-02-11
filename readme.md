## tarsync: 시스템 백업 도구

### 개요

tarsync는 시스템의 특정 디스크를 효율적이고 안전하게 백업하기 위한 도구입니다. `rsync`, `tar`, `pv` 등의 유닉스/리눅스 유틸리티를 활용하며, 용량 확인 및 로그 기록 기능을 제공합니다.

### 주요 기능

* 압축 백업: `tar`와 `gzip`을 사용하여 백업 파일을 압축하고 저장 공간을 효율적으로 사용합니다.
* 진행 상황 표시: `pv`를 통해 백업 진행 상황을 실시간으로 모니터링할 수 있습니다.
* 용량 확인: 백업 대상 디스크와 저장 디렉토리의 용량을 확인하여 충분한 공간이 있는지 검사합니다.
* 로그 기록: 백업 과정을 기록하고, 사용자 정의 로그를 추가할 수 있습니다.
* 제외 경로 설정: 백업에서 제외할 경로를 설정 파일에서 지정할 수 있습니다.
* 백업 목록 표시: 저장된 백업 파일 목록을 확인하고, 페이지네이션을 통해 관리할 수 있습니다.

### 설치 방법

별도의 설치 과정은 필요하지 않습니다. `deno` 런타임 환경이 설치되어 있어야 합니다.

### 사용 방법

1. 설정 파일 수정: `config.ts` 파일에서 `backupDisk` (백업 대상 디스크), `backupPath` (백업 저장 디렉토리), `exclude.custom` (사용자 정의 제외 경로)를 필요에 따라 수정합니다.

2. 실행: 터미널에서 다음 명령어를 실행합니다.

```bash
./run.sh
```

### 설정

`config.ts` 파일에서 다음 설정 옵션을 구성할 수 있습니다.

* `backupDisk` (string): 백업할 디스크의 마운트 경로 (예: `/`, `/home`). 기본값은 `/`입니다.
* `backupPath` (string): 백업 파일을 저장할 디렉토리 경로 (예: `/mnt/backup`). 기본값은 `/mnt/backup`입니다.
* `exclude` (object): 백업에서 제외할 경로 목록.
* `default` (string[]): 기본적으로 제외되는 경로 목록. 시스템 파일, 임시 파일, Docker 관련 경로 등이 포함됩니다.
* `custom` (string[]): 사용자 정의 제외 경로 목록 (선택적).

### 실행 예시

```bash
my@ubuntu:/mnt/backup/tarsync$ ./run.sh 
제외 경로 '/mnt/backup'는 백업 대상 디스크에 속하지 않습니다.
제외 경로 '/swap.img'의 크기: 4.00 GB
제외 경로 '/proc'는 백업 대상 디스크에 속하지 않습니다.
제외 경로 '/sys'는 백업 대상 디스크에 속하지 않습니다.
제외 경로 '/dev'는 백업 대상 디스크에 속하지 않습니다.
제외 경로 '/run'는 백업 대상 디스크에 속하지 않습니다.
제외 경로 '/tmp'의 크기: 106.36 MB
제외 경로 '/media'의 크기: 4.00 KB
제외 경로 '/var/run'는 백업 대상 디스크에 속하지 않습니다.
제외 경로 '/var/tmp'의 크기: 60.00 KB
제외 경로 '/lost+found'의 크기: 16.00 KB
제외 경로 '/var/lib/docker'의 크기: 780.57 MB
제외 경로 '/var/lib/containerd'의 크기: 252.00 KB
제외 경로 '/var/run/docker.sock'는 백업 대상 디스크에 속하지 않습니다.
경로 '/home/user/temp'는 존재하지 않거나 접근할 수 없습니다.
경로 '/opt/logs'는 존재하지 않거나 접근할 수 없습니다.
전체 사용량 (/): 9.40 GB
최종 사용량 (제외 경로 제거 후): 4.53 GB
로그를 기록하시겠습니까? (Y/n):  
📂 백업을 시작합니다.
📌 저장 경로: /mnt/backup/tarsync/store/2025_02_11_AM_07_26_16/tarsync.tar.gz
4.66GiB 0:02:36 [30.4MiB/s] [              <=>              ]
41. ⬜️ ❌ 97M Feb 9 05:10 2025_02_09_AM_05_10_24
42. ⬜️ 📖 2.1G Feb 10 15:37 2025_02_10_PM_03_37_12
43. ⬜️ 📖 2.1G Feb 11 06:43 2025_02_11_AM_06_42_45
44. ⬜️ 📖 69M Feb 11 07:26 2025_02_11_AM_07_25_52
45. ✅ 📖 2.1G Feb 11 07:26 2025_02_11_AM_07_26_16

🔳 total: 40GB
🔳 page total: 6.32 GB
🔳 Page 9 / 9 (Total: 45 files)

📜 백업 로그 내용 (2025_02_11_AM_07_26_16/log.md):
-----------------------------------
# Backup Log
- Date: 2025-02-09
- Time: 05:08:46
- Status: Success
-----------------------------------
```

### 추가 정보

* **로그 파일:** 백업 실행 시 `store/[날짜]/log.md` 파일에 로그가 저장됩니다. `Logger` 클래스를 사용하여 사용자 정의 로그를 추가할 수 있습니다.
* **필수 명령어:** `pv`, `rsync`, `tar` 명령어가 시스템에 설치되어 있어야 합니다. 설치되어 있지 않은 경우, 프로그램 실행 시 설치 안내 메시지가 출력됩니다.
* **디스크 용량:** 백업 저장 디렉토리에 충분한 공간이 있는지 확인하십시오. 프로그램 실행 시 저장 공간 부족 시 경고 메시지가 출력됩니다.
* **백업 파일 관리:** `BackupManager` 클래스를 사용하여 백업 파일 목록을 확인하고, 페이지네이션 기능을 통해 여러 페이지의 백업 파일을 관리할 수 있습니다.

### 라이선스

MIT License
