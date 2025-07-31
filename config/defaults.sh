#!/bin/bash
# tarsync 기본 설정 파일
# 기존 config.ts에서 변환됨
# 순수 설정 데이터만 포함 (함수는 src/utils/config.sh로 이동됨)

# 백업 대상 디스크 경로
BACKUP_DISK="/"

# 기본 백업 경로 (사용자 설정이 없을 때 사용)
BACKUP_PATH="/mnt/backup/tarsync"

# 기본 제외 경로 목록
EXCLUDE_DEFAULT=(
    "/workspace"                # 개발 작업 디렉토리 (dockit 환경)
    "/swap.img"                 # 스왑 파일
    "/proc"                     # 프로세스 정보
    "/sys"                      # 시스템 정보
    "/dev"                      # 장치 파일
    "/run"                      # 실행 중인 프로세스 데이터
    "/tmp"                      # 임시 파일
    "/media"                    # 외부 저장 매체
    "/var/run"                  # 실행 중인 서비스 데이터
    "/var/tmp"                  # 임시 파일
    "/lost+found"               # 손실된 파일 복구 디렉토리
    "/var/lib/docker"           # Docker 이미지 및 컨테이너
    "/var/lib/containerd"       # Containerd 데이터
    "/var/run/docker.sock"      # Docker 소켓 파일
)

# 사용자 정의 제외 경로 목록 (선택적)
EXCLUDE_CUSTOM=(
    "/home/user/temp"           # 사용자가 추가로 제외하고 싶은 경로
    "/opt/logs"                 # 다른 사용자 정의 경로
) 