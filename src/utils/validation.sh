#!/bin/bash
# tarsync 검증 유틸리티 함수들
# 기존 util.ts에서 변환됨

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# format.sh 로드
source "$(get_script_dir)/format.sh"

# 메시지 시스템 로드
SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PROJECT_ROOT/config/messages/detect.sh"
source "$PROJECT_ROOT/config/messages/load.sh"
load_tarsync_messages

# 주어진 명령어가 시스템에 설치되어 있는지 확인
# 설치되어 있지 않으면 오류 메시지 출력 후 종료
ensure_command_exists() {
    local command="$1"
    local install_command="$2"
    
    if ! command -v "$command" >/dev/null 2>&1; then
        error_msg "MSG_ERROR_MISSING_ARGUMENT" "$command"
        printf "   다음 명령어로 설치하세요: $install_command\n"
        exit 1
    fi
}

# 주어진 경로가 존재하는지 확인
is_path_exists() {
    local path="$1"
    [[ -e "$path" ]]
}

# 주어진 경로가 디렉토리인지 확인
is_directory() {
    local path="$1"
    [[ -d "$path" ]]
}

# 주어진 경로가 파일인지 확인
is_file() {
    local path="$1"
    [[ -f "$path" ]]
}

# 주어진 경로가 읽기 가능한지 확인
is_readable() {
    local path="$1"
    [[ -r "$path" ]]
}

# 주어진 경로가 쓰기 가능한지 확인
is_writable() {
    local path="$1"
    [[ -w "$path" ]]
}

# 주어진 경로가 속한 디스크 장치 반환
get_path_device() {
    local path="$1"
    df --output=source "$path" 2>/dev/null | tail -n 1 | tr -d ' '
}

# 주어진 경로의 마운트 포인트 반환
get_path_mount() {
    local path="$1"
    df --output=target "$path" 2>/dev/null | tail -n 1 | tr -d ' '
}

# 두 경로가 같은 파일시스템에 있는지 확인
is_same_filesystem() {
    local path1="$1"
    local path2="$2"
    local device1 device2
    
    device1=$(get_path_device "$path1")
    device2=$(get_path_device "$path2")
    
    [[ "$device1" == "$device2" ]]
}

# 디스크 용량 정보 반환 (KB 단위)
get_disk_usage() {
    local path="$1"
    df --output=size,used,avail "$path" 2>/dev/null | tail -n 1
}

# 디스크 사용 가능 용량 반환 (바이트 단위)
get_available_space() {
    local path="$1"
    local avail_kb
    avail_kb=$(df --output=avail "$path" 2>/dev/null | tail -n 1 | tr -d ' ')
    echo $((avail_kb * 1024))
}

# 디스크 사용 중인 용량 반환 (바이트 단위)
get_used_space() {
    local path="$1"
    local used_kb
    used_kb=$(df --output=used "$path" 2>/dev/null | tail -n 1 | tr -d ' ')
    echo $((used_kb * 1024))
}

# 디렉토리의 실제 사용량 계산 (바이트 단위)
get_directory_usage() {
    local path="$1"
    du -sb --one-file-system "$path" 2>/dev/null | awk '{print $1}' || echo "0"
}

# 충분한 디스크 공간이 있는지 확인
check_disk_space() {
    local path="$1"
    local required_bytes="$2"
    local available_bytes
    
    available_bytes=$(get_available_space "$path")
    
    if (( available_bytes < required_bytes )); then
        error_msg "MSG_BACKUP_FAILED" "저장 공간 부족"
        printf "   필요한 공간: $(convert_size "$required_bytes")\n"
        printf "   사용 가능한 공간: $(convert_size "$available_bytes")\n"
        return 1
    fi
    
    return 0
}

# 백업 대상 디렉토리 검증
validate_backup_source() {
    local source_path="$1"
    
    if ! is_path_exists "$source_path"; then
        echo "❌ 백업 대상 경로가 존재하지 않습니다: $source_path"
        return 1
    fi
    
    if ! is_directory "$source_path"; then
        echo "❌ 백업 대상이 디렉토리가 아닙니다: $source_path"
        return 1
    fi
    
    if ! is_readable "$source_path"; then
        echo "❌ 백업 대상 디렉토리에 읽기 권한이 없습니다: $source_path"
        return 1
    fi
    
    return 0
}

# 백업 저장 디렉토리 검증
validate_backup_destination() {
    local dest_path="$1"
    
    # 상위 디렉토리 확인
    local parent_dir
    parent_dir=$(dirname "$dest_path")
    
    if ! is_path_exists "$parent_dir"; then
        echo "❌ 백업 저장 경로의 상위 디렉토리가 존재하지 않습니다: $parent_dir"
        return 1
    fi
    
    if ! is_writable "$parent_dir"; then
        echo "❌ 백업 저장 경로에 쓰기 권한이 없습니다: $parent_dir"
        return 1
    fi
    
    return 0
}

# 필수 명령어들이 설치되어 있는지 확인
validate_required_tools() {
    echo "🔍 필수 도구 확인 중..."
    
    ensure_command_exists "tar" "sudo apt install tar"
    ensure_command_exists "pv" "sudo apt install pv"
    ensure_command_exists "rsync" "sudo apt install rsync"
    ensure_command_exists "gzip" "sudo apt install gzip"
    
    echo "✅ 모든 필수 도구가 설치되어 있습니다."
} 