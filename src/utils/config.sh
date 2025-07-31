#!/bin/bash
# tarsync 설정 관련 유틸리티 함수들
# config/defaults.sh에서 분리된 함수들

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 기본 설정 파일 로드
source "$(get_script_dir)/../../config/defaults.sh"

# 설정 파일에서 백업 디렉토리 읽기
load_backup_settings() {
    local settings_file="$HOME/.tarsync/config/settings.env"
    if [[ -f "$settings_file" ]]; then
        source "$settings_file"
        BACKUP_PATH="$BACKUP_DIR"
    fi
    # defaults.sh에서 이미 BACKUP_PATH가 설정되어 있으므로 별도 처리 불필요
}

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