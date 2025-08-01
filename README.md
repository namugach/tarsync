# Tarsync - 시스템 백업 및 복구 도구

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](docs/meta/CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](docs/meta/LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-blue.svg)](https://www.gnu.org/software/bash/)

Tarsync는 tar와 rsync를 기반으로 한 강력하고 사용하기 쉬운 시스템 백업 및 복구 도구입니다. 

## 빠른 시작

```bash
# 저장소 복제
git clone https://github.com/namugach/tarsync.git
cd tarsync

# Tarsync를 시스템에 설치
sudo ./bin/install.sh

# 시스템 백업 실행
sudo tarsync backup

# 백업 목록 확인
tarsync list

# 백업 복구 실행
sudo tarsync restore
```

이 명령어는 Tarsync를 시스템에 설치하고 `tarsync` 명령을 경로에 추가합니다. 설치 후에는 어떤 디렉토리에서든 Tarsync를 사용할 수 있습니다.

## 제거하기

Tarsync를 시스템에서 제거하려면:

```bash
sudo ./bin/uninstall.sh
```

## 주요 기능

- **🗜️ 압축 백업**: tar.gz 형식을 사용한 효율적인 압축 백업
- **📊 진행률 표시**: pv(pipe viewer)를 활용한 실시간 백업/복구 진행률 표시
- **🔧 유연한 설정**: 제외 경로, 백업 위치 등 다양한 설정 옵션
- **📝 메타데이터 관리**: 백업 정보, 크기, 생성일 등 상세 정보 자동 기록
- **🔄 안전한 복구**: 두 가지 복구 모드 (안전 복구 / 완전 동기화)
- **📜 로그 시스템**: 백업/복구 작업에 대한 상세한 로그 기록
- **📋 목록 관리**: 페이지네이션과 선택 기능을 지원하는 백업 목록 관리
- **🛡️ 권한 보존**: ACL과 확장 속성을 포함한 완전한 권한 보존
- **🎯 선택적 제외**: 임시 파일, 캐시 등 불필요한 파일 자동 제외

## 시스템 요구사항

- **운영체제**: Linux 기반 시스템
- **필수 도구**: 
  - `tar` - 아카이브 생성/해제
  - `gzip` - 압축/해제
  - `rsync` - 파일 동기화
  - `pv` - 진행률 표시
- **권한**: 시스템 백업을 위한 sudo 권한

## 명령어

### backup - 시스템 백업
```bash
sudo tarsync backup [백업_경로]
```
- 지정된 경로(기본값: /)를 압축하여 백업합니다
- 메타데이터와 로그 파일을 자동으로 생성합니다
- ACL 및 확장 속성을 포함하여 완전한 시스템 상태를 보존합니다

### restore - 백업 복구
```bash
sudo tarsync restore [백업_번호] [복구_경로]
```
- 백업을 선택하여 지정된 위치로 복구합니다
- **안전 복구**: 기존 파일을 보존하면서 백업 내용을 추가/업데이트
- **완전 동기화**: 백업 시점과 완전히 동일한 상태로 복구 (기존 파일 삭제)

### list - 백업 목록 관리
```bash
# 전체 백업 목록 표시
tarsync list

# 페이지별 목록 표시 (10개씩, 1페이지)
tarsync list 10 1

# 특정 백업 선택하여 로그 표시
tarsync list 10 1 3

# 백업 삭제
tarsync list delete [백업_이름]

# 백업 상세 정보
tarsync list details [백업_이름]
```

## 설정

### 기본 설정 파일: `config/defaults.sh`

```bash
# 백업 대상 디스크
BACKUP_DISK="/"

# 백업 저장 경로
BACKUP_PATH="/mnt/backup/tarsync"

# 제외할 경로들
EXCLUDE_PATHS=(
    "/tmp"
    "/var/tmp"
    "/proc"
    "/sys"
    "/dev"
    "/mnt"
    "/media"
    "*.cache"
    "node_modules"
)
```

### 설정 수정

필요에 따라 `config/defaults.sh` 파일을 편집하여 백업 설정을 변경할 수 있습니다:
- 백업 대상 경로 변경
- 백업 저장 위치 변경  
- 제외할 파일/디렉토리 패턴 추가/제거

## 백업 구조

```
/mnt/backup/tarsync/
├── store/                          # 백업 저장소
│   └── 2025_01_15_오후_02_30_45/    # 백업 디렉토리 (날짜별)
│       ├── tarsync.tar.gz          # 압축된 백업 파일
│       ├── meta.sh                 # 메타데이터 (크기, 날짜, 제외경로)
│       └── log.md                  # 백업 로그 (선택사항)
└── restore/                        # 복구 작업 로그
    └── restore_20250115_143045.log # 복구 작업 로그
```

## 사용 예시

### 기본 시스템 백업

```bash
# 전체 시스템 백업 (기본 설정 사용)
sudo tarsync backup

# 특정 디렉토리만 백업
sudo tarsync backup /home
```

### 백업 목록 및 관리

```bash
# 백업 목록 확인
tarsync list

# 페이지별 목록 (5개씩, 2페이지)
tarsync list 5 2

# 최신 백업 선택하여 로그 확인
tarsync list 10 1 1

# 오래된 백업 삭제
tarsync list delete 2025_01_10_오전_09_15_30
```

### 백업 복구

```bash
# 인터랙티브 복구 (백업 선택)
sudo tarsync restore

# 특정 백업으로 복구
sudo tarsync restore 1 /home/recovery

# 번호로 백업 선택하여 원본 위치로 복구
sudo tarsync restore 2
```

## 장점

### 📦 완전한 시스템 보존
- **권한 보존**: ACL, 확장 속성, 소유권 완벽 보존
- **메타데이터**: 백업 정보 자동 기록 및 관리
- **검증 기능**: 백업 무결성 자동 검사

### 🚀 사용 편의성
- **진행률 표시**: 실시간 백업/복구 진행률 모니터링
- **인터랙티브 인터페이스**: 직관적인 메뉴 기반 선택
- **로그 시스템**: 작업 내역 자동 기록

### 🔒 안전성
- **선택적 복구**: 안전 복구와 완전 동기화 모드 제공
- **유효성 검증**: 백업 파일 무결성 자동 확인
- **에러 처리**: 작업 실패 시 자동 정리 및 롤백

### ⚡ 성능
- **효율적 압축**: gzip을 활용한 최적화된 압축
- **병렬 처리**: tar와 압축을 파이프라인으로 병렬 실행
- **스마트 제외**: 불필요한 파일 자동 제외로 용량 절약

## 문서

- [사용자 매뉴얼](docs/MANUAL.md) - 상세한 사용 방법
- [변경 이력](docs/meta/CHANGELOG.md) - 버전별 변경 사항
- [프로젝트 소개](docs/meta/DESCRIPTION.md) - 상세한 프로젝트 설명

## 라이센스

MIT License - 자세한 내용은 [LICENSE](docs/meta/LICENSE) 파일을 참조하세요.

---

**주의사항**: 시스템 백업/복구는 중요한 작업입니다. 실제 운영 환경에서 사용하기 전에 테스트 환경에서 충분히 검증해주세요.