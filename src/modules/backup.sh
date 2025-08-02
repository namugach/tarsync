#!/bin/bash
# tarsync 백업 모듈
# 기존 Tarsync.backup() 메서드에서 변환됨

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 공통 유틸리티 로드
source "$(get_script_dir)/common.sh"

# 기본 JSON 로그 생성 함수
create_basic_json_log() {
    local work_dir="$1"
    local status="$2"
    local exclude_count=$(get_exclude_paths | wc -l)
    local timestamp=$(date -Iseconds)
    
    # JSON 구조 생성
    jq -n \
        --arg timestamp "$timestamp" \
        --arg date "$(date '+%Y-%m-%d')" \
        --arg time "$(date '+%H:%M:%S')" \
        --arg source "$BACKUP_DISK" \
        --arg destination "$work_dir" \
        --arg status "$status" \
        --arg created_by "tarsync shell script" \
        --argjson exclude_count "$exclude_count" \
        --argjson exclude_paths "$(get_exclude_paths | jq -R -s -c 'split("\n")[:-1]')" \
        --arg user_notes "" \
        '{
            backup: {
                timestamp: $timestamp,
                date: $date,
                time: $time,
                source: $source,
                destination: $destination,
                status: $status,
                created_by: $created_by
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
                    message: "백업 시작"
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
    
    echo "📝 사용자 메모를 편집합니다..."
    echo "   (빈 파일에 원하는 메모를 작성하세요)"
    
    # 에디터로 편집
    if command -v vim >/dev/null 2>&1; then
        echo "   (저장하고 종료: :wq, 편집 없이 종료: :q)"
        vim "$temp_notes"
    elif command -v nano >/dev/null 2>&1; then
        echo "   (저장하고 종료: Ctrl+X)"
        nano "$temp_notes"
    else
        echo "⚠️  텍스트 에디터를 찾을 수 없습니다. 기본 로그만 생성됩니다."
        rm -f "$temp_notes"
        return
    fi
    
    # 편집된 내용을 JSON에 업데이트
    local user_notes=$(cat "$temp_notes" 2>/dev/null || echo "")
    jq --arg notes "$user_notes" '.user_notes = $notes' "$work_dir/log.json" > "$work_dir/log.json.tmp"
    mv "$work_dir/log.json.tmp" "$work_dir/log.json"
    
    rm -f "$temp_notes"
    echo "📝 사용자 메모가 저장되었습니다."
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
        completion_message="백업 완료"
    else
        completion_message="백업 실패"
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

# 로그 파일 작성 여부를 사용자에게 묻기
prompt_log_creation() {
    local work_dir="$1"
    
    echo -n "📝 로그를 기록하시겠습니까? (Y/n): "
    read -r user_input
    
    # 기본값은 Y
    user_input=${user_input:-Y}
    
    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        echo "📝 JSON 로그 파일을 생성합니다..."
        
        # 기본 JSON 로그 생성
        create_basic_json_log "$work_dir" "in_progress"
        
        # 사용자 메모 편집 옵션
        echo -n "📝 추가 메모를 작성하시겠습니까? (y/N): "
        read -r edit_notes
        
        if [[ "$edit_notes" =~ ^[Yy]$ ]]; then
            edit_user_notes "$work_dir"
        fi
    else
        echo "📝 로그 생성을 건너뜁니다."
    fi
}

# 백업 실행 함수
execute_backup() {
    local source_path="$1"
    local target_file="$2"
    local exclude_options="$3"
    
    echo "📂 백업을 시작합니다."
    echo "📌 원본: $source_path"  
    echo "📌 저장 경로: $target_file"
    echo "📌 제외 경로: $(get_exclude_paths | wc -l)개"
    echo ""
    
    # tar 명령어 구성
    local tar_command="sudo tar cf - -P --one-file-system --acls --xattrs $exclude_options $source_path | pv | gzip > $target_file"
    
    echo "🚀 압축 백업 시작..."
    echo "   명령어: $tar_command"
    echo ""
    
    # 백업 실행
    if eval "$tar_command"; then
        echo ""
        echo "✅ 백업이 성공적으로 완료되었습니다!"
        
        # 생성된 파일 크기 확인
        local file_size
        file_size=$(get_file_size "$target_file")
        echo "📦 백업 파일 크기: $(convert_size "$file_size")"
        
        return 0
    else
        echo ""
        echo "❌ 백업 중 오류가 발생했습니다!"
        return 1
    fi
}

# 백업 디렉토리 구조 자동 생성 함수
ensure_backup_directory_structure() {
    local backup_path="$BACKUP_PATH"
    local store_dir="$backup_path/store"
    local restore_dir="$backup_path/restore"
    
    echo "📁 백업 디렉토리 구조 확인 중..."
    
    # 백업 루트 디렉토리 생성
    if [[ ! -d "$backup_path" ]]; then
        echo "  생성: $backup_path"
        if ! sudo mkdir -p "$backup_path"; then
            echo "❌ 백업 디렉토리 생성 실패: $backup_path"
            return 1
        fi
    else
        echo "  존재: $backup_path ✓"
    fi
    
    # store 디렉토리 생성
    if [[ ! -d "$store_dir" ]]; then
        echo "  생성: $store_dir"
        if ! sudo mkdir -p "$store_dir"; then
            echo "❌ 백업 저장소 생성 실패: $store_dir"
            return 1
        fi
    else
        echo "  존재: $store_dir ✓"
    fi
    
    # restore 디렉토리 생성
    if [[ ! -d "$restore_dir" ]]; then
        echo "  생성: $restore_dir"
        if ! sudo mkdir -p "$restore_dir"; then
            echo "❌ 복구 저장소 생성 실패: $restore_dir"
            return 1
        fi
    else
        echo "  존재: $restore_dir ✓"
    fi
    
    echo "✅ 백업 디렉토리 구조가 준비되었습니다."
    return 0
}

# 백업 결과 출력 (간단 버전)
show_backup_result() {
    local store_dir="$1"
    
    echo ""
    echo "📋 최근 백업 목록:"
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
        echo "  백업 디렉토리가 없습니다."
    fi
    
    echo "===================="
}

# 메인 백업 함수
backup() {
    local source_path="${1:-$BACKUP_DISK}"
    
    echo "🔍 tarsync 백업 시작..."
    echo ""
    
    # 0. 백업 디렉토리 확인 및 생성
    if ! ensure_backup_directory_structure; then
        echo "❌ 백업을 중단합니다."
        exit 1
    fi
    echo ""
    
    # 1. 필수 도구 검증
    validate_required_tools
    echo ""
    
    # 2. 백업 대상 검증
    echo "🔍 백업 대상 검증 중..."
    if ! validate_backup_source "$source_path"; then
        echo "❌ 백업을 중단합니다."
        exit 1
    fi
    echo "✅ 백업 대상이 유효합니다: $source_path"
    echo ""
    
    # 3. 백업 크기 계산
    local final_size
    final_size=$(calculate_final_backup_size "$source_path")
    echo ""
    
    # 4. 작업 디렉토리 설정
    local work_dir
    work_dir=$(get_store_work_dir_path)
    local tar_file="$work_dir/tarsync.tar.gz"
    
    echo "📁 작업 디렉토리: $work_dir"
    echo ""
    
    # 5. 백업 저장소 검증 및 용량 체크
    echo "🔍 저장소 용량 확인 중..."
    local store_dir
    store_dir=$(get_store_dir_path)
    
    if ! validate_backup_destination "$store_dir"; then
        echo "❌ 백업을 중단합니다."
        exit 1
    fi
    
    if ! check_disk_space "$store_dir" "$final_size"; then
        echo "❌ 백업을 중단합니다."
        exit 1
    fi
    echo "✅ 저장소 용량이 충분합니다."
    echo ""
    
    # 6. 디렉토리 생성
    echo "📁 작업 디렉토리 생성 중..."
    create_store_dir
    create_directory "$work_dir"
    echo "✅ 작업 디렉토리가 생성되었습니다."
    echo ""
    
    # 7. 메타데이터 생성
    echo "📄 메타데이터 생성 중..."
    local created_date exclude_paths
    created_date=$(get_date)
    readarray -t exclude_paths < <(get_exclude_paths)
    
    create_metadata "$work_dir" "$final_size" "$created_date" "${exclude_paths[@]}"
    echo "✅ 메타데이터가 생성되었습니다: $work_dir/meta.sh"
    echo ""
    
    # 8. 로그 파일 생성 (사용자 선택)
    prompt_log_creation "$work_dir"
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
        echo "🎉 백업이 완료되었습니다!"
        echo "📂 백업 위치: $work_dir"
        
        return 0
    else
        echo ""
        echo "💥 백업에 실패했습니다!"
        
        # 백업 실패 시간 계산 및 JSON 로그 업데이트
        local backup_end_time=$(date +%s)
        local duration=$((backup_end_time - backup_start_time))
        
        update_json_log_completion "$work_dir" "failed" "" "$duration"
        
        # 실패한 경우 작업 디렉토리 정리
        if [[ -d "$work_dir" ]]; then
            echo "🧹 실패한 백업 파일을 정리합니다..."
            rm -rf "$work_dir"
        fi
        
        return 1
    fi
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup "$@"
fi 