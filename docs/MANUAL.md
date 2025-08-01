# Tarsync 사용자 매뉴얼

이 문서는 Tarsync의 자세한 사용 방법을 설명합니다.

## 목차

1. [소개](#소개)
2. [설치 및 설정](#설치-및-설정)
3. [주요 기능](#주요-기능)
4. [명령어](#명령어)
    - [backup](#backup---시스템-백업)
    - [restore](#restore---백업-복구)
    - [list](#list---백업-목록-관리)
5. [설정 파일](#설정-파일)
6. [백업 구조](#백업-구조)
7. [고급 사용법](#고급-사용법)
8. [문제 해결](#문제-해결)

## 소개

Tarsync는 Linux 시스템을 위한 강력하고 신뢰할 수 있는 백업 및 복구 도구입니다. tar와 rsync의 장점을 결합하여 다음과 같은 목표를 달성합니다:

- **완전한 시스템 보존**: 파일 권한, ACL, 확장 속성을 포함한 모든 시스템 상태 보존
- **효율적인 압축**: gzip 압축을 통한 저장 공간 최적화
- **사용자 친화적**: 직관적인 인터페이스와 실시간 진행률 표시
- **안전한 복구**: 두 가지 복구 모드로 다양한 복구 시나리오 지원
- **완전한 추적성**: 모든 작업에 대한 상세한 로그 및 메타데이터 관리

## 설치 및 설정

### 시스템 요구사항

Tarsync를 사용하기 위해서는 다음 도구들이 시스템에 설치되어 있어야 합니다:

**필수 패키지:**
```bash
# Ubuntu/Debian
sudo apt-get install tar gzip rsync pv

# CentOS/RHEL/Fedora
sudo yum install tar gzip rsync pv
# 또는
sudo dnf install tar gzip rsync pv
```

**권한 요구사항:**
- 시스템 백업을 위한 sudo 권한
- 백업 저장 위치에 대한 쓰기 권한

### 설치 과정

1. **저장소 복제:**
   ```bash
   git clone <repository-url> tarsync
   cd tarsync
   ```

2. **시스템에 설치:**
   ```bash
   sudo ./bin/install.sh
   ```

3. **설정 확인:**
   ```bash
   # 기본 설정 확인
   cat config/defaults.sh
   ```

4. **테스트 실행:**
   ```bash
   # 도구 검증
   tarsync help
   ```

## 주요 기능

### 🗜️ 압축 백업 시스템

Tarsync는 tar와 gzip을 조합하여 효율적인 압축 백업을 제공합니다.

**주요 특징:**
- **스트리밍 압축**: tar로 아카이빙하면서 동시에 gzip으로 압축
- **파이프라인 처리**: 메모리 효율적인 스트리밍 방식
- **진행률 표시**: pv(pipe viewer)를 통한 실시간 진행률 모니터링
- **권한 보존**: ACL, 확장 속성, 하드링크 등 완전한 파일 시스템 정보 보존

**압축 명령어 예시:**
```bash
sudo tar cf - -P --one-file-system --acls --xattrs [제외옵션] [경로] | pv | gzip > backup.tar.gz
```

### 📊 실시간 진행률 모니터링

모든 백업과 복구 작업에서 실시간 진행 상황을 확인할 수 있습니다.

**표시 정보:**
- 처리된 데이터량 (MB/GB)
- 전송 속도 (MB/s)
- 예상 완료 시간 (ETA)
- 진행률 바

### 🔧 유연한 설정 시스템

프로젝트 요구사항에 맞게 백업 설정을 세밀하게 조정할 수 있습니다.

**설정 가능 항목:**
- 백업 대상 경로
- 백업 저장 위치
- 제외할 파일/디렉토리 패턴
- 압축 옵션
- 로그 설정

### 📝 완전한 메타데이터 관리

각 백업마다 상세한 메타데이터가 자동으로 생성되고 관리됩니다.

**메타데이터 포함 정보:**
- 백업 생성 날짜 및 시간
- 원본 데이터 크기
- 압축된 백업 파일 크기
- 압축률
- 제외된 경로 목록
- 백업 무결성 상태

### 🔄 안전한 복구 시스템

두 가지 복구 모드를 제공하여 다양한 복구 시나리오에 대응합니다.

**1. 안전 복구 모드 (기본값)**
- 기존 파일을 보존하면서 백업 내용을 추가/업데이트
- 충돌하는 파일은 백업 버전으로 덮어씀
- 대상 폴더에만 존재하는 파일은 그대로 유지
- 일반적인 파일 복구나 부분 복구에 적합

**2. 완전 동기화 모드**
- 백업 시점과 완전히 동일한 상태로 복구
- 백업에 없는 파일/디렉토리는 삭제됨 (rsync --delete)
- 시스템 전체 복구나 정확한 시점 복구에 적합
- ⚠️ **주의**: 데이터 손실 가능성이 있으므로 신중히 사용

## 명령어

### backup - 시스템 백업

시스템이나 지정된 경로를 압축하여 백업합니다.

```bash
sudo tarsync backup [백업_경로]
```

#### 사용법:

**전체 시스템 백업:**
```bash
# 기본 설정(/)으로 전체 시스템 백업
sudo tarsync backup

# 명시적으로 루트 경로 지정
sudo tarsync backup /
```

**특정 디렉토리 백업:**
```bash
# 홈 디렉토리만 백업
sudo tarsync backup /home

# 특정 프로젝트 디렉토리 백업
sudo tarsync backup /var/www
```

#### 백업 과정:

1. **환경 검증**
   - 필수 도구 존재 확인 (tar, gzip, rsync, pv)
   - 백업 대상 경로 유효성 검사
   - 저장소 용량 확인

2. **백업 크기 계산**
   - 제외 경로를 제외한 실제 백업 대상 크기 계산
   - 예상 압축률 적용하여 최종 백업 파일 크기 추정
   - 저장소 여유 공간과 비교하여 용량 부족 여부 확인

3. **백업 디렉토리 구조 생성**
   ```
   /workspace/backup/store/
   └── 2025_01_15_오후_02_30_45/
       ├── tarsync.tar.gz
       ├── meta.sh
       └── log.md (선택사항)
   ```

4. **메타데이터 생성**
   - 백업 정보를 담은 `meta.sh` 파일 생성
   - 백업 크기, 생성일, 제외 경로 정보 포함

5. **로그 파일 생성 (선택사항)**
   - 사용자에게 로그 작성 여부 확인
   - 기본 로그 템플릿 생성
   - 텍스트 에디터(vim/nano)로 사용자 추가 편집 가능

6. **압축 백업 실행**
   ```bash
   sudo tar cf - -P --one-file-system --acls --xattrs [제외옵션] [경로] | pv | gzip > backup.tar.gz
   ```

7. **백업 완료 처리**
   - 백업 파일 크기 확인 및 메타데이터 업데이트
   - 로그 파일 상태 업데이트 (In Progress → Success)
   - 최근 백업 목록 표시

#### 백업 옵션 설명:

**tar 옵션:**
- `-P`: 절대 경로 사용
- `--one-file-system`: 단일 파일 시스템만 백업 (마운트 포인트 건너뛰기)
- `--acls`: Access Control Lists 보존
- `--xattrs`: 확장 속성 보존

**제외 패턴:**
```bash
# 기본 제외 패턴 (config/defaults.sh에서 설정)
/tmp/*
/var/tmp/*
/proc/*
/sys/*
/dev/*
/mnt/*
/media/*
*.cache
node_modules
```

### restore - 백업 복구

저장된 백업을 사용하여 파일을 복구합니다.

```bash
sudo tarsync restore [백업_번호] [복구_경로]
```

#### 사용법:

**인터랙티브 복구:**
```bash
# 백업 목록에서 선택하여 복구
sudo tarsync restore
```

**직접 복구:**
```bash
# 1번 백업을 /home/recovery 경로로 복구
sudo tarsync restore 1 /home/recovery

# 3번 백업을 원본 위치로 복구
sudo tarsync restore 3
```

#### 복구 과정:

1. **환경 검증**
   - 필수 도구 확인
   - 백업 저장소 접근 가능 여부 확인

2. **백업 선택**
   - 사용 가능한 백업 목록 표시
   - 번호 또는 디렉토리 이름으로 백업 선택
   - 백업 파일 무결성 검증

3. **복구 대상 확인**
   - 복구할 경로 입력 또는 확인
   - 원본 소스 경로를 log.md에서 자동 추출하여 기본값으로 제공
   - 대상 경로 쓰기 권한 확인

4. **메타데이터 로드**
   - 선택된 백업의 meta.sh 파일 로드
   - 백업 정보 (크기, 날짜, 제외경로) 확인

5. **복구 방식 선택**
   ```
   ⚙️  복구 방식을 선택하세요
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
     - 📦 백업: 2025_01_15_오후_02_30_45
     - 🎯 대상: /home/recovery
   
   1️⃣  안전 복구 (기본값)
       기존 파일은 그대로 두고, 백업된 내용만 추가하거나 덮어씁니다.
       (일반적인 복구에 권장됩니다.)
   
   2️⃣  완전 동기화 (⚠️ 주의: 파일 삭제)
       백업 시점과 완전히 동일한 상태로 만듭니다.
       대상 폴더에만 존재하는 파일이나 디렉토리는 **삭제**됩니다.
   
   3️⃣  취소
       복구 작업을 중단합니다.
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

6. **임시 작업 디렉토리 생성**
   - `/workspace/backup/restore/` 하위에 작업 디렉토리 생성
   - 디렉토리명: `{날짜}__to__{백업명}` 형식

7. **압축 해제**
   ```bash
   pv backup.tar.gz | tar -xz -C work_dir --strip-components=0 --preserve-permissions
   ```

8. **rsync 동기화**
   ```bash
   # 안전 복구 모드
   rsync -avhP --stats [제외옵션] source/ target/
   
   # 완전 동기화 모드
   rsync -avhP --stats --delete [제외옵션] source/ target/
   ```

9. **복구 로그 생성**
   - 복구 작업 상세 로그 생성
   - 작업 디렉토리와 영구 저장소 양쪽에 로그 저장
   - 성공/실패 여부와 관계없이 로그 기록

10. **정리**
    - 임시 작업 디렉토리 정리
    - 복구 결과 요약 표시

#### 복구 로그 형식:

```
# tarsync 복구 로그
==========================================

복구 시작: 2025-01-15T14:30:45+09:00
백업 이름: 2025_01_15_오후_02_30_45
복구 대상: /home/recovery
작업 디렉토리: /workspace/backup/restore/2025_01_15_오후_02_33_12__to__2025_01_15_오후_02_30_45
삭제 모드: false
복구 상태: 복구 완료

==========================================

[rsync 상세 출력 내용]

==========================================

복구 완료: 2025-01-15T14:35:22+09:00
```

### list - 백업 목록 관리

백업 목록을 조회하고 관리하는 다양한 기능을 제공합니다.

```bash
tarsync list [옵션...]
```

#### 하위 명령어:

**1. list/ls - 백업 목록 표시**
```bash
# 기본 목록 (10개씩 표시)
tarsync list

# 페이지 크기와 페이지 번호 지정
tarsync list [페이지크기] [페이지번호] [선택번호]

# 예시
tarsync list 5 1        # 5개씩, 1페이지
tarsync list 10 2       # 10개씩, 2페이지  
tarsync list 0 1 3      # 전체 표시, 3번 선택하여 로그 표시
tarsync list 10 -1 -1   # 10개씩, 마지막 페이지, 마지막 항목 선택
```

**목록 표시 형식:**
```
📦 tarsync 백업 목록
====================
01. ⬜️ ✅ 📖 2.1GB Jan 15 14:30 2025_01_15_오후_02_30_45
02. ⬜️ ✅ ❌ 1.8GB Jan 14 09:15 2025_01_14_오전_09_15_30
03. ✅ ⚠️ 📖 950MB Jan 13 16:22 2025_01_13_오후_04_22_10

🔳 전체 저장소: 15.2GB
🔳 페이지 총합: 4.8GB  
🔳 페이지 1 / 3 (총 15 개 백업)
```

**아이콘 설명:**
- **선택 상태**: ⬜️ (미선택) / ✅ (선택됨)
- **백업 무결성**: ✅ (정상) / ⚠️ (메타데이터 없음) / ❌ (파일 손상)
- **로그 파일**: 📖 (로그 있음) / ❌ (로그 없음)

**2. delete/rm - 백업 삭제**
```bash
# 특정 백업 삭제
sudo tarsync delete [백업이름]

# 예시
sudo tarsync delete 2025_01_10_오전_09_15_30
```

**삭제 과정:**
```
🗑️  백업 삭제 확인
   대상: 2025_01_10_오전_09_15_30
   경로: /workspace/backup/store/2025_01_10_오전_09_15_30
   크기: 2.1GB

정말로 이 백업을 삭제하시겠습니까? [y/N]: y
```

**3. details/show - 백업 상세 정보**
```bash
# 백업 상세 정보 표시
tarsync details [백업이름]

# 예시
tarsync details 2025_01_15_오후_02_30_45
```

**상세 정보 형식:**
```
📋 백업 상세 정보
==================
📂 백업 이름: 2025_01_15_오후_02_30_45
📁 백업 경로: /workspace/backup/store/2025_01_15_오후_02_30_45
📦 백업 크기: 2.1GB
🔍 백업 상태: ✅

📄 메타데이터 정보:
   원본 크기: 8.5GB
   생성 날짜: 2025-01-15_14:30:45
   제외 경로: 12개

📁 포함된 파일:
   log.md
   meta.sh
   tarsync.tar.gz

📜 백업 로그 내용 (2025_01_15_오후_02_30_45/log.md):
-----------------------------------
[로그 파일 내용]
-----------------------------------
```

#### 페이지네이션 기능:

**고급 페이지 옵션:**
- **음수 페이지**: `-1`은 마지막 페이지, `-2`는 마지막에서 두 번째 페이지
- **음수 선택**: `-1`은 마지막 항목, `-2`는 마지막에서 두 번째 항목
- **전체 표시**: 페이지 크기를 `0`으로 설정하면 모든 백업을 한 번에 표시

**사용 예시:**
```bash
# 마지막 페이지의 마지막 백업 선택하여 로그 표시
tarsync list 10 -1 -1

# 모든 백업을 표시하면서 3번째 백업 선택
tarsync list 0 1 3

# 5개씩 표시, 2페이지, 첫 번째 항목 선택
tarsync list 5 2 1
```

## 설정 파일

### 기본 설정: `config/defaults.sh`

Tarsync의 모든 기본 설정이 포함된 파일입니다.

```bash
#!/bin/bash
# tarsync 기본 설정

# 백업 대상 디스크 (기본값: 루트 파일시스템)
BACKUP_DISK="/"

# 백업 저장 경로 (충분한 용량의 디스크를 지정하세요)
BACKUP_PATH="/workspace/backup"

# 백업에서 제외할 경로들
EXCLUDE_PATHS=(
    # 시스템 임시 디렉토리
    "/tmp"
    "/var/tmp" 
    "/var/cache"
    
    # 가상 파일 시스템
    "/proc"
    "/sys"
    "/dev"
    "/run"
    
    # 마운트 포인트
    "/mnt"
    "/media"
    
    # 네트워크 파일 시스템
    "/net"
    "/nfs"
    
    # 개발 관련 임시 파일
    "node_modules"
    ".npm"
    ".cache"
    "*.tmp"
    "*.log"
    
    # 브라우저 캐시
    "*/Cache/*"
    "*/cache/*"
    
    # 시스템 로그 (선택적)
    "/var/log"
)

# 압축 레벨 (1-9, 높을수록 더 압축되지만 느림)
COMPRESSION_LEVEL=6

# 백업 파일명 형식 (날짜 형식)
BACKUP_DATE_FORMAT="%Y_%m_%d_%p_%I_%M_%S"

# 로그 레벨 (DEBUG, INFO, WARN, ERROR)
LOG_LEVEL="INFO"
```

### 설정 수정 방법

**1. 직접 편집:**
```bash
# vim으로 설정 파일 편집
vim config/defaults.sh

# nano로 설정 파일 편집  
nano config/defaults.sh
```

**2. 백업 대상 변경:**
```bash
# 홈 디렉토리만 백업하도록 설정
BACKUP_DISK="/home"

# 특정 프로젝트 디렉토리만 백업
BACKUP_DISK="/var/www"
```

**3. 저장 위치 변경:**
```bash
# 외장 하드디스크에 백업 저장
BACKUP_PATH="/mnt/external/tarsync-backup"

# 네트워크 드라이브에 백업 저장  
BACKUP_PATH="/mnt/nas/backup"
```

**4. 제외 경로 추가:**
```bash
# 기존 제외 경로에 추가
EXCLUDE_PATHS+=(
    "/opt/large-software"
    "/home/*/Downloads"
    "*.iso"
    "*.img"
)
```

### 환경별 설정 예시

**개발 서버 설정:**
```bash
BACKUP_DISK="/var/www"
BACKUP_PATH="/backup/webserver"
EXCLUDE_PATHS=(
    "*/node_modules"
    "*/vendor"
    "*.log"
    "/tmp"
    "/var/tmp"
)
```

**데스크톱 시스템 설정:**
```bash
BACKUP_DISK="/home"
BACKUP_PATH="/mnt/backup-drive/tarsync"
EXCLUDE_PATHS=(
    "*/Downloads"
    "*/Cache"
    "*.cache"
    "*/Trash"
    "/tmp"
    "/var/tmp"
)
```

## 백업 구조

### 디렉토리 구조

```
BACKUP_PATH/
├── store/                              # 백업 저장소
│   ├── 2025_01_15_오후_02_30_45/        # 백업 디렉토리 (날짜/시간)
│   │   ├── tarsync.tar.gz              # 압축된 백업 파일
│   │   ├── meta.sh                     # 메타데이터 파일
│   │   └── log.md                      # 백업 로그 (선택사항)
│   ├── 2025_01_14_오전_09_15_30/
│   │   ├── tarsync.tar.gz
│   │   ├── meta.sh
│   │   └── log.md
│   └── 2025_01_13_오후_04_22_10/
│       ├── tarsync.tar.gz
│       └── meta.sh                     # 로그 없음
└── restore/                            # 복구 작업 로그
    ├── 2025_01_15_오후_02_35_12__to__2025_01_15_오후_02_30_45.log
    └── 2025_01_14_오전_10_20_45__to__2025_01_13_오후_04_22_10.log
```

### 메타데이터 파일 (`meta.sh`)

각 백업마다 생성되는 메타데이터 파일의 구조입니다:

```bash
#!/bin/bash
# tarsync 메타데이터 파일
# 자동 생성됨: 2025-01-15_14:30:45

# 백업 기본 정보
META_VERSION="1.0"
META_SIZE=9123456789              # 원본 데이터 크기 (바이트)
META_BACKUP_SIZE=2156789012       # 백업 파일 크기 (바이트)  
META_CREATED="2025-01-15_14:30:45"
META_SOURCE="/home"

# 제외된 경로 목록
META_EXCLUDE=(
    "/tmp"
    "/var/tmp"
    "/proc"
    "/sys"
    "/dev"
    "/run"
    "/mnt" 
    "/media"
    "node_modules"
    ".cache"
    "*.tmp"
    "*.log"
)

# 백업 통계
META_COMPRESSION_RATIO="76.3%"    # 압축률
META_DURATION="00:12:34"          # 소요 시간
META_FILES_COUNT=123456           # 백업된 파일 수
```

### 로그 파일 (`log.md`)

백업 과정에서 생성되는 선택적 로그 파일입니다:

```markdown
# Backup Log
- Date: 2025-01-15
- Time: 14:30:45
- Status: Success
- Created by: tarsync shell script

## Backup Details
- Source: /home
- Destination: /workspace/backup/store/2025_01_15_오후_02_30_45
- Exclude paths: 12 paths

## User Notes
홈 디렉토리 정기 백업
- 새로운 프로젝트 파일들 포함
- 사용자 설정 변경사항 반영

## Log
백업 시작: 2025-01-15_14:30:45
압축 진행: [████████████████████████████████] 100%
백업 완료: 2025-01-15_14:42:19

## Statistics  
- 원본 크기: 8.5GB
- 백업 크기: 2.1GB
- 압축률: 75.3%
- 소요 시간: 11분 34초
- 처리 파일: 98,742개
```

## 고급 사용법

### 스크립트를 통한 자동화

**정기 백업 스크립트 (`cron-backup.sh`):**
```bash
#!/bin/bash
# 정기 백업 자동화 스크립트

TARSYNC_PATH="/opt/tarsync"
LOG_FILE="/var/log/tarsync-cron.log"

echo "$(date): 정기 백업 시작" >> "$LOG_FILE"

# 백업 실행
if "$TARSYNC_PATH/bin/backup" >> "$LOG_FILE" 2>&1; then
    echo "$(date): 백업 성공" >> "$LOG_FILE"
else
    echo "$(date): 백업 실패" >> "$LOG_FILE"
    # 실패 시 관리자에게 알림
    mail -s "Tarsync 백업 실패" admin@example.com < "$LOG_FILE"
fi

# 30일 이상 된 백업 정리
find "$BACKUP_PATH/store" -type d -name "2*" -mtime +30 -exec rm -rf {} \;
echo "$(date): 오래된 백업 정리 완료" >> "$LOG_FILE"
```

**crontab 설정:**
```bash
# 매일 새벽 2시에 자동 백업
0 2 * * * /opt/tarsync/scripts/cron-backup.sh

# 매주 일요일 오전 3시에 전체 시스템 백업
0 3 * * 0 /opt/tarsync/bin/backup /
```

### 원격 백업

**SSH를 통한 원격 백업:**
```bash
#!/bin/bash
# 원격 서버 백업 스크립트

REMOTE_HOST="backup-server.example.com"
REMOTE_PATH="/mnt/backup-storage/server1"
LOCAL_BACKUP="/workspace/backup/store"

# 로컬 백업 실행
sudo tarsync backup

# 최신 백업을 원격 서버로 전송
LATEST_BACKUP=$(ls -t "$LOCAL_BACKUP" | head -1)
if [ -n "$LATEST_BACKUP" ]; then
    rsync -avz --progress "$LOCAL_BACKUP/$LATEST_BACKUP/" \
          "$REMOTE_HOST:$REMOTE_PATH/$LATEST_BACKUP/"
    echo "원격 백업 완료: $LATEST_BACKUP"
fi
```

### 백업 검증

**백업 무결성 검증 스크립트:**
```bash
#!/bin/bash
# 백업 파일 무결성 검증

check_backup_integrity() {
    local backup_dir="$1"
    local tar_file="$backup_dir/tarsync.tar.gz"
    
    echo "백업 검증 중: $(basename "$backup_dir")"
    
    # 파일 존재 확인
    if [[ ! -f "$tar_file" ]]; then
        echo "❌ 백업 파일 없음"
        return 1
    fi
    
    # gzip 무결성 검증
    if ! gzip -t "$tar_file" 2>/dev/null; then
        echo "❌ 압축 파일 손상"
        return 1
    fi
    
    # tar 구조 검증
    if ! tar -tzf "$tar_file" >/dev/null 2>&1; then
        echo "❌ 아카이브 구조 손상" 
        return 1
    fi
    
    echo "✅ 백업 무결성 확인"
    return 0
}

# 모든 백업 검증
STORE_DIR="/workspace/backup/store"
for backup_dir in "$STORE_DIR"/2*; do
    if [[ -d "$backup_dir" ]]; then
        check_backup_integrity "$backup_dir"
    fi
done
```

### 선택적 복구

**특정 파일만 복구하는 방법:**
```bash
#!/bin/bash
# 특정 파일/디렉토리만 복구

BACKUP_FILE="/workspace/backup/store/2025_01_15_오후_02_30_45/tarsync.tar.gz"
TARGET_FILE="/home/user/important-file.txt"
EXTRACT_DIR="/tmp/tarsync-extract"

# 임시 디렉토리 생성
mkdir -p "$EXTRACT_DIR"

# 특정 파일만 추출
tar -xzf "$BACKUP_FILE" -C "$EXTRACT_DIR" --strip-components=0 "$TARGET_FILE"

# 복구된 파일 확인
if [[ -f "$EXTRACT_DIR$TARGET_FILE" ]]; then
    echo "✅ 파일 복구 성공: $TARGET_FILE"
    ls -la "$EXTRACT_DIR$TARGET_FILE"
else
    echo "❌ 파일을 찾을 수 없습니다: $TARGET_FILE"
fi

# 정리
rm -rf "$EXTRACT_DIR"
```

## 문제 해결

### 일반적인 문제

#### 1. 백업 실행 실패

**문제**: 백업이 시작되지 않거나 중간에 실패합니다.

**원인 및 해결책:**

**권한 문제:**
```bash
# 현상: "Permission denied" 오류
# 해결: sudo 권한으로 실행
sudo tarsync backup

# root로 전환 후 실행  
sudo su -
tarsync backup
```

**디스크 용량 부족:**
```bash
# 현상: "No space left on device" 오류
# 해결: 백업 저장소 용량 확인
df -h /workspace/backup

# 불필요한 백업 정리
sudo tarsync delete [오래된_백업명]
```

**필수 도구 누락:**
```bash
# 현상: "command not found" 오류
# 해결: 필수 패키지 설치
sudo apt-get install tar gzip rsync pv  # Ubuntu/Debian
sudo yum install tar gzip rsync pv      # CentOS/RHEL
```

#### 2. 복구 실패

**문제**: 백업 복구 중 오류가 발생합니다.

**원인 및 해결책:**

**백업 파일 손상:**
```bash
# 백업 무결성 확인
gzip -t /workspace/backup/store/[백업명]/tarsync.tar.gz

# 손상된 경우 다른 백업 사용
tarsync list  # 다른 백업 확인
```

**대상 경로 권한 문제:**
```bash
# 복구 대상 디렉토리 권한 확인
ls -ld /target/path

# 권한 수정
sudo chmod 755 /target/path
sudo chown $USER:$USER /target/path
```

**rsync 동기화 실패:**
```bash
# rsync 옵션 확인 및 수동 실행
rsync -avhP --stats /source/ /target/

# 상세 로그로 문제 진단
rsync -avhP --stats --verbose /source/ /target/
```

#### 3. 성능 문제

**문제**: 백업/복구 속도가 너무 느립니다.

**개선 방법:**

**압축 레벨 조정:**
```bash
# config/defaults.sh에서 압축 레벨 낮추기
COMPRESSION_LEVEL=1  # 빠른 압축 (기본값: 6)
```

**제외 경로 최적화:**
```bash
# 불필요한 대용량 파일 제외
EXCLUDE_PATHS+=(
    "*.iso"
    "*.img" 
    "*/VirtualBox VMs"
    "*/VMware"
    "/home/*/Downloads"
)
```

**I/O 최적화:**
```bash
# SSD가 아닌 경우 동시 읽기/쓰기 제한
ionice -c3 sudo tarsync backup  # 낮은 우선순위로 실행
```

#### 4. 백업 목록 관련

**문제**: 백업 목록이 표시되지 않거나 잘못된 정보가 표시됩니다.

**해결책:**

**저장소 경로 확인:**
```bash
# 설정 파일의 BACKUP_PATH 확인
cat config/defaults.sh | grep BACKUP_PATH

# 실제 디렉토리 존재 확인
ls -la /workspace/backup/store/
```

**메타데이터 복구:**
```bash
# 메타데이터가 없는 백업의 경우 수동 생성
backup_dir="/workspace/backup/store/2025_01_15_오후_02_30_45"
tar_file="$backup_dir/tarsync.tar.gz"

# 기본 메타데이터 생성
cat > "$backup_dir/meta.sh" << EOF
#!/bin/bash
META_VERSION="1.0"
META_SIZE=$(tar -tzf "$tar_file" | wc -c)
META_BACKUP_SIZE=$(stat -c%s "$tar_file")
META_CREATED="$(basename "$backup_dir")"
META_SOURCE="/"
META_EXCLUDE=()
EOF
```

### 고급 문제 해결

#### 로그 분석

**백업 로그 확인:**
```bash
# 시스템 로그에서 tarsync 관련 오류 확인
sudo journalctl | grep tarsync

# 백업 로그 파일 확인
find /workspace/backup -name "*.log" -exec cat {} \;
```

**상세 디버그 모드:**
```bash
# 디버그 모드로 백업 실행
TARSYNC_DEBUG=1 sudo tarsync backup

# bash 디버그 모드
bash -x sudo tarsync backup
```

#### 백업 복구 테스트

**안전한 테스트 환경 구성:**
```bash
# 테스트용 임시 디렉토리 생성
TEST_DIR="/tmp/tarsync-test"
mkdir -p "$TEST_DIR"

# 작은 규모 백업으로 테스트
sudo tarsync backup "$HOME/Documents"

# 테스트 복구
sudo tarsync restore 1 "$TEST_DIR"

# 결과 확인
diff -r "$HOME/Documents" "$TEST_DIR"
```

#### 성능 프로파일링

**백업 성능 측정:**
```bash
# 시간 측정
time sudo tarsync backup

# I/O 모니터링
iostat -x 1 &
sudo tarsync backup
killall iostat
```

**병목 지점 분석:**
```bash
# 디스크 사용량 실시간 모니터링
watch -n1 'df -h'

# 프로세스 모니터링
htop  # 또는 top
```

### 지원 및 추가 도움

추가적인 문제나 질문이 있는 경우:

1. **로그 파일 수집**: 문제 발생 시 관련 로그 파일들을 수집
2. **환경 정보 확인**: OS 버전, 설치된 패키지 버전 등
3. **재현 가능한 테스트 케이스**: 문제를 재현할 수 있는 최소한의 예제 준비

**환경 정보 수집 스크립트:**
```bash
#!/bin/bash
echo "=== Tarsync 환경 정보 ==="
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME)"
echo "Kernel: $(uname -r)"
echo "Bash: $BASH_VERSION"
echo ""
echo "=== 필수 도구 버전 ==="
tar --version | head -1
gzip --version | head -1  
rsync --version | head -1
pv --version 2>&1 | head -1
echo ""
echo "=== 디스크 공간 ==="
df -h
echo ""
echo "=== Tarsync 설정 ==="
cat config/defaults.sh
```

이 매뉴얼을 통해 Tarsync의 모든 기능을 효과적으로 활용하시기 바랍니다.