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
source "$(get_script_dir)/../../config/defaults.sh"

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
        echo "❌ 명령어 실행 실패: $*" >&2
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
    create_directory "$(get_store_dir_path)"
}

# 복구 작업 디렉토리 생성
create_restore_dir() {
    create_directory "$(get_restore_dir_path)"
}

# 전체 제외 경로 목록을 tar 옵션 형태로 반환
get_backup_tar_exclude_options() {
    get_tar_exclude_options # config/defaults.sh에서 정의된 함수 사용
}

# 전체 제외 경로 목록을 rsync 옵션 형태로 반환
get_backup_rsync_exclude_options() {
    get_rsync_exclude_options # config/defaults.sh에서 정의된 함수 사용
}

# 메타데이터 파일 생성
create_metadata() {
    local work_dir="$1"
    local backup_size="$2"
    local created_date="$3"
    local exclude_paths=("${@:4}")
    
    local meta_file="$work_dir/meta.sh"
    local template_file="$PROJECT_ROOT/src/templates/meta.sh.template"
    
    # 템플릿 파일 확인
    if [[ ! -f "$template_file" ]]; then
        log_error "메타데이터 템플릿 파일을 찾을 수 없습니다: $template_file"
        return 1
    fi
    
    # exclude_paths 배열을 템플릿 형식으로 변환
    local exclude_formatted=""
    for path in "${exclude_paths[@]}"; do
        exclude_formatted+="    \"$path\"\n"
    done
    
    # 템플릿 로드하고 변수 치환
    sed -e "s/{{BACKUP_SIZE}}/$backup_size/g" \
        -e "s/{{CREATED_DATE}}/$created_date/g" \
        -e "s/{{EXCLUDE_PATHS}}/$exclude_formatted/g" \
        "$template_file" > "$meta_file"
    
    chmod +x "$meta_file"
}

# 메타데이터 파일 읽기
load_metadata() {
    local work_dir="$1"
    local meta_file="$work_dir/meta.sh"
    
    if [[ -f "$meta_file" ]]; then
        source "$meta_file"
        return 0
    else
        echo "❌ 메타데이터 파일을 찾을 수 없습니다: $meta_file" >&2
        return 1
    fi
}

# 백업 대상의 실제 크기 계산 (제외 경로 고려)
calculate_final_backup_size() {
    local source_path="$1"
    local total_size used_size final_size
    local exclude_paths
    
    echo "📊 백업 크기 계산 중..." >&2
    
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
                echo "  제외 경로 '$exclude_path': $(convert_size "$exclude_size")" >&2
            fi
        else
            echo "  제외 경로 '$exclude_path': 다른 파일시스템 또는 존재하지 않음" >&2
        fi
    done
    
    final_size=$used_size
    
    echo "  전체 크기: $(convert_size "$total_size")" >&2
    echo "  최종 백업 크기: $(convert_size "$final_size")" >&2
    
    # 크기만 stdout으로 반환
    echo "$final_size"
}

# 진행률을 표시하며 명령어 실행
run_with_progress() {
    local command="$1"
    local description="$2"
    
    echo "🚀 $description 시작..."
    echo "   명령어: $command"
    
    # 명령어 실행
    if eval "$command"; then
        echo "✅ $description 완료!"
        return 0
    else
        echo "❌ $description 실패!"
        return 1
    fi
} 