#!/bin/bash
# tarsync 백업 모듈
# 기존 Tarsync.backup() 메서드에서 변환됨

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 공통 유틸리티 로드
source "$(get_script_dir)/common.sh"

# 메시지 시스템 로드
SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PROJECT_ROOT/config/messages/detect.sh"
source "$PROJECT_ROOT/config/messages/load.sh"
load_tarsync_messages

# 기본 JSON 로그 생성 함수
create_basic_json_log() {
    local work_dir="$1"
    local status="$2"
    local has_notes="${3:-false}"
    local exclude_count=$(get_exclude_paths | wc -l)
    local timestamp=$(date -Iseconds)
    
    # 다국어 메시지 준비
    local backup_start_msg
    backup_start_msg=$(msg "MSG_BACKUP_START")
    local created_by_msg="tarsync shell script (${CURRENT_LANGUAGE:-ko})"
    
    # JSON 구조 생성 (다국어 지원)
    jq -n \
        --arg timestamp "$timestamp" \
        --arg date "$(date '+%Y-%m-%d')" \
        --arg time "$(date '+%H:%M:%S')" \
        --arg source "$BACKUP_DISK" \
        --arg destination "$work_dir" \
        --arg status "$status" \
        --arg created_by "$created_by_msg" \
        --arg language "${CURRENT_LANGUAGE:-ko}" \
        --arg backup_start_msg "$backup_start_msg" \
        --argjson exclude_count "$exclude_count" \
        --argjson exclude_paths "$(get_exclude_paths | jq -R -s -c 'split("\n")[:-1]')" \
        --argjson user_notes "$has_notes" \
        '{
            backup: {
                timestamp: $timestamp,
                date: $date,
                time: $time,
                source: $source,
                destination: $destination,
                status: $status,
                created_by: $created_by,
                language: $language
            },
            details: {
                exclude_paths_count: $exclude_count,
                exclude_paths: $exclude_paths,
                file_size: "",
                duration_seconds: 0
            },
            log_entries: [
                {
                    timestamp: $timestamp,
                    message: $backup_start_msg
                }
            ],
            user_notes: $user_notes
        }' > "$work_dir/log.json"
}

# 사용자 메모 편집 함수
edit_user_notes() {
    local work_dir="$1"
    local temp_notes="/tmp/tarsync_user_notes.txt"
    
    # 현재 user_notes 추출
    jq -r '.user_notes' "$work_dir/log.json" > "$temp_notes"
    
    msg "MSG_NOTES_EDIT"
    msg "MSG_NOTES_EDIT_INFO"
    
    # 에디터로 편집
    if command -v vim >/dev/null 2>&1; then
        msg "MSG_NOTES_EDITOR_VIM"
        vim "$temp_notes"
    elif command -v nano >/dev/null 2>&1; then
        msg "MSG_NOTES_EDITOR_NANO"
        nano "$temp_notes"
    else
        msg "MSG_NOTES_NO_EDITOR"
        rm -f "$temp_notes"
        return
    fi
    
    # 편집된 내용을 JSON에 업데이트
    local user_notes=$(cat "$temp_notes" 2>/dev/null || echo "")
    jq --arg notes "$user_notes" '.user_notes = $notes' "$work_dir/log.json" > "$work_dir/log.json.tmp"
    mv "$work_dir/log.json.tmp" "$work_dir/log.json"
    
    rm -f "$temp_notes"
    msg "MSG_NOTES_SAVED"
}

# note.md 파일 생성 함수
create_note_file() {
    local work_dir="$1"
    local note_file="$work_dir/note.md"
    
    # 기본 템플릿 생성
    cat > "$note_file" << EOF
# 백업 메모

**백업 날짜**: $(date '+%Y-%m-%d %H:%M:%S')
**백업 대상**: $BACKUP_DISK

## 메모
<!-- 여기에 백업과 관련된 메모를 작성하세요 -->

EOF
    
    msg "MSG_NOTES_EDIT"
    msg "MSG_NOTES_EDIT_INFO"
    
    # 에디터로 편집
    if command -v vim >/dev/null 2>&1; then
        msg "MSG_NOTES_EDITOR_VIM"
        vim "$note_file"
    elif command -v nano >/dev/null 2>&1; then
        msg "MSG_NOTES_EDITOR_NANO"
        nano "$note_file"
    else
        msg "MSG_NOTES_NO_EDITOR"
        return
    fi
    
    msg "MSG_NOTES_SAVED"
}

# JSON 로그의 user_notes 플래그 업데이트
update_json_user_notes_flag() {
    local work_dir="$1"
    local has_notes="$2"
    
    if [[ ! -f "$work_dir/log.json" ]]; then
        return
    fi
    
    jq --argjson notes "$has_notes" '.user_notes = $notes' "$work_dir/log.json" > "$work_dir/log.json.tmp"
    mv "$work_dir/log.json.tmp" "$work_dir/log.json"
}

# JSON 로그 완료 업데이트 함수
update_json_log_completion() {
    local work_dir="$1"
    local status="$2"  # "completed" 또는 "failed"
    local file_size="$3"
    local duration="$4"
    
    if [[ ! -f "$work_dir/log.json" ]]; then
        return
    fi
    
    local timestamp=$(date -Iseconds)
    local completion_message
    
    if [[ "$status" == "completed" ]]; then
        completion_message=$(msg "MSG_BACKUP_COMPLETE")
    else
        completion_message=$(msg "MSG_BACKUP_FAILED" "")
    fi
    
    # JSON 업데이트
    jq \
        --arg status "$status" \
        --arg file_size "$file_size" \
        --argjson duration "$duration" \
        --arg timestamp "$timestamp" \
        --arg message "$completion_message" \
        '.backup.status = $status |
         .details.file_size = $file_size |
         .details.duration_seconds = $duration |
         .log_entries += [{"timestamp": $timestamp, "message": $message}]' \
        "$work_dir/log.json" > "$work_dir/log.json.tmp"
    
    mv "$work_dir/log.json.tmp" "$work_dir/log.json"
}

# 로그 파일 생성 (필수)
create_backup_log() {
    local work_dir="$1"
    
    msg "MSG_BACKUP_CREATING_LOG"
    
    # 기본 JSON 로그 생성
    create_basic_json_log "$work_dir" "in_progress" false
    
    # 사용자 메모 작성 옵션
    printf "$(msg MSG_NOTES_CREATE_PROMPT)"
    read -r create_notes
    create_notes=${create_notes:-Y}
    
    local has_notes=false
    if [[ "$create_notes" =~ ^[Yy]$ ]]; then
        create_note_file "$work_dir"
        has_notes=true
        # JSON 로그의 user_notes 플래그 업데이트
        update_json_user_notes_flag "$work_dir" true
    fi
    
    msg "MSG_BACKUP_LOG_CREATED"
}

# 백업 실행 함수
execute_backup() {
    local source_path="$1"
    local target_file="$2"
    local exclude_options="$3"
    
    msg "MSG_BACKUP_START"
    printf "📌 Source: $source_path\n"
    printf "📌 Target path: $target_file\n"
    local exclude_count=$(get_exclude_paths | wc -l)
    msg "MSG_BACKUP_EXCLUDE_PATHS" "$exclude_count"
    echo ""
    
    # tar 명령어 구성
    local tar_command="sudo tar cf - -P --one-file-system --acls --xattrs $exclude_options $source_path | pv | gzip > $target_file"
    
    msg "MSG_BACKUP_CREATING_ARCHIVE"
    printf "   Command: $tar_command\n"
    echo ""
    
    # 백업 실행
    if eval "$tar_command"; then
        echo ""
        success_msg "MSG_BACKUP_COMPLETE"
        
        # 생성된 파일 크기 확인
        local file_size
        file_size=$(get_file_size "$target_file")
        printf "📦 Backup file size: $(convert_size "$file_size")\n"
        
        return 0
    else
        echo ""
        error_msg "MSG_BACKUP_FAILED" "백업 실행 오류"
        return 1
    fi
}

# 백업 디렉토리 구조 자동 생성 함수
ensure_backup_directory_structure() {
    local backup_path="$BACKUP_PATH"
    local store_dir="$backup_path/store"
    local restore_dir="$backup_path/restore"
    
    msg "MSG_BACKUP_CHECKING_STRUCTURE"
    
    # 백업 루트 디렉토리 생성
    if [[ ! -d "$backup_path" ]]; then
        msg "MSG_SYSTEM_CREATING_DIR" "$backup_path"
        if ! sudo mkdir -p "$backup_path"; then
            error_msg "MSG_BACKUP_DIR_CREATE_FAILED" "$backup_path"
            return 1
        fi
    else
        msg "MSG_SYSTEM_DIRECTORY_EXISTS" "$backup_path"
    fi
    
    # store 디렉토리 생성
    if [[ ! -d "$store_dir" ]]; then
        msg "MSG_SYSTEM_CREATING_DIR" "$store_dir"
        if ! sudo mkdir -p "$store_dir"; then
            error_msg "MSG_BACKUP_STORE_CREATE_FAILED" "$store_dir"
            return 1
        fi
    else
        msg "MSG_SYSTEM_DIRECTORY_EXISTS" "$store_dir"
    fi
    
    # restore 디렉토리 생성
    if [[ ! -d "$restore_dir" ]]; then
        msg "MSG_SYSTEM_CREATING_DIR" "$restore_dir"
        if ! sudo mkdir -p "$restore_dir"; then
            error_msg "MSG_RESTORE_STORE_CREATE_FAILED" "$restore_dir"
            return 1
        fi
    else
        msg "MSG_SYSTEM_DIRECTORY_EXISTS" "$restore_dir"
    fi
    
    success_msg "MSG_BACKUP_STRUCTURE_READY"
    return 0
}

# 백업 결과 출력 (간단 버전)
show_backup_result() {
    local store_dir="$1"
    
    echo ""
    msg "MSG_BACKUP_RECENT_LIST"
    echo "===================="
    
    # 최근 5개 백업 디렉토리 출력
    if [[ -d "$store_dir" ]]; then
        find "$store_dir" -maxdepth 1 -type d -name "2*" | sort -r | head -5 | while read -r backup_dir; do
            local dir_name
            dir_name=$(basename "$backup_dir")
            
            local tar_file="$backup_dir/tarsync.tar.gz"
            local meta_file="$backup_dir/meta.sh"
            local log_file="$backup_dir/log.json"
            
            local size_info="?"
            local log_icon="❌"
            
            if [[ -f "$tar_file" ]]; then
                size_info=$(get_path_size_formatted "$tar_file")
            fi
            
            if [[ -f "$log_file" ]]; then
                log_icon="📖"
            fi
            
            echo "  $log_icon $size_info - $dir_name"
        done
    else
        msg "MSG_BACKUP_NO_DIRECTORY"
    fi
    
    echo "===================="
}

# 메인 백업 함수
backup() {
    local source_path="${1:-$BACKUP_DISK}"
    
    msg "MSG_BACKUP_START"
    echo ""
    
    # 0. 백업 디렉토리 확인 및 생성
    if ! ensure_backup_directory_structure; then
        error_msg "MSG_BACKUP_CANCELLED"
        exit 1
    fi
    echo ""
    
    # 1. 필수 도구 검증
    validate_required_tools
    echo ""
    
    # 2. 백업 대상 검증
    msg "MSG_BACKUP_VALIDATING_TARGET"
    if ! validate_backup_source "$source_path"; then
        error_msg "MSG_BACKUP_CANCELLED"
        exit 1
    fi
    success_msg "MSG_BACKUP_TARGET_VALID" "$source_path"
    echo ""
    
    # 3. 백업 크기 계산
    local final_size
    final_size=$(calculate_final_backup_size "$source_path")
    echo ""
    
    # 4. 작업 디렉토리 설정
    local work_dir
    work_dir=$(get_store_work_dir_path)
    local tar_file="$work_dir/tarsync.tar.gz"
    
    msg "MSG_BACKUP_WORK_DIR" "$work_dir"
    echo ""
    
    # 5. 백업 저장소 검증 및 용량 체크
    msg "MSG_BACKUP_DISK_SPACE_CHECK"
    local store_dir
    store_dir=$(get_store_dir_path)
    
    if ! validate_backup_destination "$store_dir"; then
        error_msg "MSG_BACKUP_CANCELLED"
        exit 1
    fi
    
    if ! check_disk_space "$store_dir" "$final_size"; then
        error_msg "MSG_BACKUP_CANCELLED"
        exit 1
    fi
    success_msg "MSG_BACKUP_DISK_SPACE_OK"
    echo ""
    
    # 6. 디렉토리 생성
    msg "MSG_BACKUP_CREATING_WORK_DIR"
    create_store_dir
    create_directory "$work_dir"
    success_msg "MSG_BACKUP_WORK_DIR_CREATED"
    echo ""
    
    # 7. 메타데이터 생성
    msg "MSG_BACKUP_CREATING_META"
    local created_date exclude_paths
    created_date=$(get_date)
    readarray -t exclude_paths < <(get_exclude_paths)
    
    create_metadata "$work_dir" "$final_size" "$created_date" "${exclude_paths[@]}"
    success_msg "MSG_BACKUP_META_CREATED" "$work_dir/meta.sh"
    echo ""
    
    # 8. 로그 파일 생성 (필수)
    create_backup_log "$work_dir"
    echo ""
    
    # 9. 백업 실행 (시간 측정 시작)
    local backup_start_time=$(date +%s)
    local exclude_options
    exclude_options=$(get_backup_tar_exclude_options)
    
    if execute_backup "$source_path" "$tar_file" "$exclude_options"; then
        echo ""
        
        # 9.5. 메타데이터에 백업 파일 크기 추가
        update_metadata_backup_size "$work_dir" "$tar_file"
        echo ""
        
        # 백업 완료 시간 계산 및 JSON 로그 업데이트
        local backup_end_time=$(date +%s)
        local duration=$((backup_end_time - backup_start_time))
        local file_size=$(get_path_size_formatted "$tar_file")
        
        update_json_log_completion "$work_dir" "completed" "$file_size" "$duration"
        
        # 10. 백업 결과 출력
        show_backup_result "$store_dir"
        
        echo ""
        success_msg "MSG_BACKUP_COMPLETE"
        msg "MSG_BACKUP_LOCATION" "$work_dir"
        
        return 0
    else
        echo ""
        error_msg "MSG_BACKUP_FAILED"
        
        # 백업 실패 시간 계산 및 JSON 로그 업데이트
        local backup_end_time=$(date +%s)
        local duration=$((backup_end_time - backup_start_time))
        
        update_json_log_completion "$work_dir" "failed" "" "$duration"
        
        # 실패한 경우 작업 디렉토리 정리
        if [[ -d "$work_dir" ]]; then
            msg "MSG_BACKUP_CLEANUP_FAILED"
            rm -rf "$work_dir"
        fi
        
        return 1
    fi
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup "$@"
fi 