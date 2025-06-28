#!/bin/bash
# tarsync 기본 설정 파일
# 기존 config.ts에서 변환됨

# 설정 파일에서 백업 디렉토리 읽기
load_backup_settings() {
    local settings_file="$HOME/.tarsync/config/settings.env"
    if [[ -f "$settings_file" ]]; then
        source "$settings_file"
        BACKUP_PATH="$BACKUP_DIR"
    else
        # 설정 파일이 없으면 기본값 사용
        BACKUP_PATH="/mnt/backup"
    fi
}

# 설정 로드
load_backup_settings

# 백업 대상 디스크 경로
BACKUP_DISK="/"

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

# 전체 제외 경로 목록을 생성하는 함수
get_exclude_paths() {
    local paths=()
    
    # 백업 경로 자체도 제외
    paths+=("$BACKUP_PATH")
    
    # 기본 제외 경로들 추가
    for path in "${EXCLUDE_DEFAULT[@]}"; do
        paths+=("$path")  
    done
    
    # 사용자 정의 제외 경로들 추가
    for path in "${EXCLUDE_CUSTOM[@]}"; do
        paths+=("$path")
    done
    
    printf '%s\n' "${paths[@]}"
}

# tar 옵션 형태로 제외 경로를 생성하는 함수
get_tar_exclude_options() {
    local exclude_paths
    exclude_paths=($(get_exclude_paths))
    
    for path in "${exclude_paths[@]}"; do
        printf -- "--exclude=%s " "$path"
    done
}

# rsync 옵션 형태로 제외 경로를 생성하는 함수
get_rsync_exclude_options() {
    local exclude_paths
    exclude_paths=($(get_exclude_paths))
    
    for path in "${exclude_paths[@]}"; do
        printf -- "--exclude=%s " "$path"
    done
} 