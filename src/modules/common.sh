#!/bin/bash
# tarsync 공통 유틸리티 함수들
# 기존 util.ts에서 변환됨

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 필요한 유틸리티들 로드
source "$(get_script_dir)/../utils/format.sh"
source "$(get_script_dir)/../utils/validation.sh"
source "$(get_script_dir)/../utils/config.sh"
source "$(get_script_dir)/../utils/log.sh"

# 메시지 시스템 로드
SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PROJECT_ROOT/config/messages/detect.sh"
source "$PROJECT_ROOT/config/messages/load.sh"
load_tarsync_messages

# 설정 로드 (config.sh에서 처리)  
load_backup_settings

# shell 명령어 실행 (stdout/stderr 직접 출력) - 기존 $ 함수
run_command() {
    "$@"
}

# shell 명령어 실행 후 결과 반환 - 기존 $$ 함수  
run_command_capture() {
    local output
    local exit_code
    
    # 명령어 실행 및 출력 캡처
    output=$("$@" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo "$output"
    else
        msg "MSG_COMMON_COMMAND_FAILED" "$*" >&2
        echo "$output" >&2
        return $exit_code
    fi
}

# 프로젝트 기본 경로 반환 (workspace 기준)
get_base_path() {
    echo "/workspace"
}

# 백업 저장소 디렉토리 경로 반환
get_store_dir_path() {
    echo "$BACKUP_PATH/store"
}

# 복구 작업 디렉토리 경로 반환  
get_restore_dir_path() {
    echo "$BACKUP_PATH/restore"
}

# 백업 작업 디렉토리 경로 생성 (날짜 포함)
get_store_work_dir_path() {
    local date_str
    date_str=$(get_date)
    echo "$(get_store_dir_path)/$date_str"
}

# 복구 작업 디렉토리 경로 생성 (날짜 + 원본 백업명 포함)
get_restore_work_dir_path() {
    local backup_name="$1"
    local date_str
    date_str=$(get_date)
    echo "$(get_restore_dir_path)/${date_str}__to__${backup_name}"
}

# tar 파일 경로 반환
get_tar_file_path() {
    local work_dir="$1"
    echo "$(get_store_dir_path)/$work_dir/tarsync.tar.gz"
}

# 디렉토리 생성 (mkdir -p와 동일)
create_directory() {
    local dir_path="$1"
    mkdir -p "$dir_path"
}

# 백업 저장소 디렉토리 생성
create_store_dir() {
    local store_dir
    store_dir=$(get_store_dir_path)
    
    # 디렉토리가 이미 존재하면 그대로 사용
    if [[ -d "$store_dir" ]]; then
        return 0
    fi
    
    echo "📁 Creating backup storage: $store_dir"
    
    # 디렉토리 생성
    create_directory "$store_dir"
}

# 복구 작업 디렉토리 생성
create_restore_dir() {
    create_directory "$(get_restore_dir_path)"
}

# 전체 제외 경로 목록을 tar 옵션 형태로 반환
get_backup_tar_exclude_options() {
    get_tar_exclude_options # src/utils/config.sh에서 정의된 함수 사용
}

# 전체 제외 경로 목록을 rsync 옵션 형태로 반환
get_backup_rsync_exclude_options() {
    get_rsync_exclude_options # src/utils/config.sh에서 정의된 함수 사용
}

# 메타데이터 파일 생성
create_metadata() {
    local work_dir="$1"
    local backup_size="$2"
    local created_date="$3"
    local exclude_paths=("${@:4}")
    
    local meta_file="$work_dir/meta.sh"
    
    # 메타데이터 파일 생성 (단순한 변수 방식)
    cat > "$meta_file" << EOF
#!/bin/bash
# tarsync 백업 메타데이터

META_SIZE=$backup_size
META_CREATED="$created_date"
META_EXCLUDE=(
EOF
    
    # exclude_paths 배열을 파일에 추가
    for path in "${exclude_paths[@]}"; do
        echo "    \"$path\"" >> "$meta_file"
    done
    
    # 파일 종료
    echo ')' >> "$meta_file"
    
    chmod +x "$meta_file"
}

# 백업 완료 후 메타데이터에 실제 백업 파일 크기 추가
update_metadata_backup_size() {
    local work_dir="$1"
    local backup_file="$2"
    
    local meta_file="$work_dir/meta.sh"
    local backup_file_size
    
    # 백업 파일 크기 계산
    backup_file_size=$(get_file_size "$backup_file")
    
    # META_CREATED 줄 다음에 META_BACKUP_SIZE 추가
    sed -i "/^META_CREATED=/a\\
META_BACKUP_SIZE=$backup_file_size" "$meta_file"
    
    echo "📦 Backup file size recorded in metadata: $(convert_size "$backup_file_size")"
}

# 메타데이터 파일 읽기
load_metadata() {
    local work_dir="$1"
    local meta_file="$work_dir/meta.sh"
    
    if [[ -f "$meta_file" ]]; then
        source "$meta_file"
        return 0
    else
        echo "❌ Cannot find metadata file: $meta_file" >&2
        return 1
    fi
}

# 백업 대상의 실제 크기 계산 (제외 경로 고려)
calculate_final_backup_size() {
    local source_path="$1"
    local total_size used_size final_size
    local exclude_paths
    
    echo "📊 Calculating backup size..." >&2
    
    # 전체 사용량 계산
    total_size=$(get_directory_usage "$source_path")
    used_size=$total_size
    
    # 제외 경로 목록 가져오기
    readarray -t exclude_paths < <(get_exclude_paths)
    
    # 각 제외 경로의 크기를 차감
    for exclude_path in "${exclude_paths[@]}"; do
        if [[ -e "$exclude_path" ]] && is_same_filesystem "$source_path" "$exclude_path"; then
            local exclude_size
            exclude_size=$(get_directory_usage "$exclude_path")
            
            if (( exclude_size > 0 )); then
                used_size=$((used_size - exclude_size))
                echo "  Excluded path '$exclude_path': $(convert_size "$exclude_size")" >&2
            fi
        else
            echo "  Excluded path '$exclude_path': different filesystem or does not exist" >&2
        fi
    done
    
    final_size=$used_size
    
    echo "  Total size: $(convert_size "$total_size")" >&2
    echo "  Final backup size: $(convert_size "$final_size")" >&2
    
    # 크기만 stdout으로 반환
    echo "$final_size"
}

# 진행률을 표시하며 명령어 실행
run_with_progress() {
    local command="$1"
    local description="$2"
    
    echo "🚀 Starting $description..."
    echo "   Command: $command"
    
    # 명령어 실행
    if eval "$command"; then
        echo "✅ $description completed!"
        return 0
    else
        echo "❌ $description failed!"
        return 1
    fi
} 