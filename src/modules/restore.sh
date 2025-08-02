#!/bin/bash
# tarsync 복구 모듈 (단순화 버전)

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 공통 유틸리티 로드
source "$(get_script_dir)/common.sh"

# 백업 목록 출력 (선택용) - list.sh와 동일한 형식
show_backup_list() {
    local store_dir
    store_dir=$(get_store_dir_path)
    
    echo "📋 사용 가능한 백업 목록:" >&2
    echo "====================" >&2
    
    # list.sh와 동일한 로직 사용
    local files_raw
    files_raw=$(ls -ltr "$store_dir" 2>/dev/null | tail -n +2 | awk '{if ($9 != "") print $6, $7, $8, $9}' | grep -E "^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+2[0-9]{3}_")
    
    if [[ -z "$files_raw" ]]; then
        echo "  백업 디렉토리가 없습니다." >&2
        echo "====================" >&2
        return
    fi
    
    # 배열로 변환
    local files=()
    while IFS= read -r line; do
        files+=("$line")
    done <<< "$files_raw"
    
    local files_length=${#files[@]}
    
    # 최근 5개만 표시 (마지막 5개)
    local start_index=$((files_length > 5 ? files_length - 5 : 0))
    
    for ((i = start_index; i < files_length; i++)); do
        local file="${files[$i]}"
        local file_name
        file_name=$(echo "$file" | awk '{print $4}')
        local backup_dir="$store_dir/$file_name"
        
        # 크기 정보
        local size_bytes=0
        local size="0B"
        
        # 메타데이터에서 크기 읽기 시도
        if load_metadata "$backup_dir" 2>/dev/null; then
            if [[ -n "$META_BACKUP_SIZE" && "$META_BACKUP_SIZE" -gt 0 ]]; then
                size_bytes="$META_BACKUP_SIZE"
                size=$(convert_size "$size_bytes")
            elif [[ -d "$backup_dir" ]]; then
                size_bytes=$(du -sb "$backup_dir" 2>/dev/null | awk '{print $1}')
                size_bytes=${size_bytes:-0}
                if [[ $size_bytes -gt 0 ]]; then
                    size=$(convert_size "$size_bytes")
                fi
            fi
        elif [[ -d "$backup_dir" ]]; then
            size_bytes=$(du -sb "$backup_dir" 2>/dev/null | awk '{print $1}')
            size_bytes=${size_bytes:-0}
            if [[ $size_bytes -gt 0 ]]; then
                size=$(convert_size "$size_bytes")
            fi
        fi
        
        # 아이콘 정보
        local log_icon="❌"
        if [[ -f "$backup_dir/log.json" ]]; then
            log_icon="📖"
        fi
        
        local note_icon=""
        if [[ -f "$backup_dir/note.md" ]]; then
            note_icon="📝"
        fi
        
        # 백업 상태 체크
        local integrity_status="✅"
        local tar_file="$backup_dir/tarsync.tar.gz"
        local meta_file="$backup_dir/meta.sh"
        
        if [[ -f "$tar_file" && -f "$meta_file" ]]; then
            integrity_status="✅"
        elif [[ -f "$tar_file" && ! -f "$meta_file" ]]; then
            integrity_status="⚠️"
        else
            integrity_status="❌"
        fi
        
        # list.sh와 동일한 번호 사용 (1부터 시작)
        local current_index=$((i + 1))
        echo "$current_index. ⬜️ $integrity_status $log_icon $note_icon $size $file" >&2
    done
    
    echo "====================" >&2
}

# 백업 번호를 실제 백업 이름으로 변환 - list.sh와 동일한 로직
get_backup_name_by_number() {
    local backup_number="$1"
    local store_dir
    store_dir=$(get_store_dir_path)
    
    if [[ "$backup_number" =~ ^[0-9]+$ ]]; then
        # list.sh와 동일한 로직 사용
        local files_raw
        files_raw=$(ls -ltr "$store_dir" 2>/dev/null | tail -n +2 | awk '{if ($9 != "") print $6, $7, $8, $9}' | grep -E "^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+2[0-9]{3}_")
        
        if [[ -z "$files_raw" ]]; then
            return 1
        fi
        
        # 배열로 변환
        local files=()
        while IFS= read -r line; do
            files+=("$line")
        done <<< "$files_raw"
        
        local files_length=${#files[@]}
        local array_index=$((backup_number - 1))
        
        if [[ $array_index -ge 0 && $array_index -lt $files_length ]]; then
            local file="${files[$array_index]}"
            local file_name
            file_name=$(echo "$file" | awk '{print $4}')
            echo "$file_name"
            return 0
        else
            return 1
        fi
    else
        echo "$backup_number"
        return 0
    fi
}

# 백업 선택 및 유효성 확인
select_backup() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        show_backup_list
        echo "" >&2
        echo -n "복구할 백업을 선택하세요 (번호 또는 디렉토리 이름): " >&2
        read -r backup_name
    fi
    
    local actual_backup_name
    actual_backup_name=$(get_backup_name_by_number "$backup_name")
    
    if [[ -z "$actual_backup_name" ]]; then
        echo "❌ 백업 번호 $backup_name 에 해당하는 백업을 찾을 수 없습니다." >&2
        return 1
    fi
    
    local store_dir
    store_dir=$(get_store_dir_path)
    local backup_dir="$store_dir/$actual_backup_name"
    
    if ! is_path_exists "$backup_dir" || ! is_file "$backup_dir/tarsync.tar.gz" || ! is_file "$backup_dir/meta.sh"; then
        echo "❌ 선택된 백업이 유효하지 않거나 필수 파일이 없습니다: $actual_backup_name" >&2
        return 1
    fi
    
    echo "$actual_backup_name"
}

# log.json에서 원본 소스 경로 추출
get_original_source_from_log() {
    local backup_dir="$1"
    local log_file="$backup_dir/log.json"

    if [[ -f "$log_file" ]]; then
        jq -r '.backup.source' "$log_file" 2>/dev/null || echo ""
    else
        echo ""
    fi
}

# 복구 대상 경로 확인
validate_restore_target() {
    local target_path="$1"
    local backup_dir="$2"

    local original_source
    original_source=$(get_original_source_from_log "$backup_dir")

    if [[ -z "$target_path" ]]; then
        local prompt_message="복구 대상 경로를 입력하세요"
        if [[ -n "$original_source" ]]; then
            prompt_message+=" (기본값: $original_source)"
        fi
        prompt_message+=": "
        
        echo -n "$prompt_message" >&2
        read -r target_path

        if [[ -z "$target_path" ]] && [[ -n "$original_source" ]]; then
            target_path="$original_source"
        fi
    fi
    
    local parent_dir
    parent_dir=$(dirname "$target_path")
    
    if ! is_path_exists "$parent_dir" || ! is_writable "$parent_dir"; then
        echo "❌ 복구 대상 경로가 유효하지 않거나 쓰기 권한이 없습니다: $target_path" >&2
        return 1
    fi
    
    echo "$target_path"
}

# 최종 복구 확인 (선택형 메뉴)
confirm_restore() {
    local backup_name="$1"
    local target_path="$2"

    echo ""
    echo "⚙️  복구 방식을 선택하세요"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  - 📦 백업: $backup_name"
    echo "  - 🎯 대상: $target_path"
    echo ""
    echo "1️⃣  안전 복구 (기본값)"
    echo "    기존 파일은 그대로 두고, 백업된 내용만 추가하거나 덮어씁니다."
    echo "    (일반적인 복구에 권장됩니다.)"
    echo ""
    echo "2️⃣  완전 동기화 (⚠️ 주의: 파일 삭제)"
    echo "    백업 시점과 완전히 동일한 상태로 만듭니다."
    echo "    대상 폴더에만 존재하는 파일이나 디렉토리는 **삭제**됩니다."
    echo ""
    echo "3️⃣  취소"
    echo "    복구 작업을 중단합니다."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local choice
    while true; do
        read -p "선택 (1-3, 기본값: 1): " choice
        choice=${choice:-1}
        case $choice in
            1) return 0 ;; # 안전 복구
            2) return 2 ;; # 완전 동기화
            3) return 1 ;; # 취소
            *) echo "❌ 잘못된 선택입니다. 1, 2, 3 중에서 선택하세요." ;;
        esac
    done
}

# tar 압축 해제
extract_backup() {
    local backup_dir="$1"
    local extract_dir="$2"
    local tar_file="$backup_dir/tarsync.tar.gz"
    
    echo "📦 백업 파일 압축 해제 중..."
    echo "   - 원본: $tar_file"
    echo "   - 대상: $extract_dir"
    echo "   - 파일 크기: $(get_path_size_formatted "$tar_file")"
    echo ""
    
    # pv를 사용한 진행률 표시와 함께 압축 해제
    if ! pv "$tar_file" | tar -xz -C "$extract_dir" --strip-components=0 --preserve-permissions; then
        echo "❌ 압축 해제에 실패했습니다."
        return 1
    fi
    
    echo "✅ 압축 해제 완료."
    return 0
}

# 복구 로그 생성 (원본 방식)
create_restore_log() {
    local work_dir="$1"
    local backup_name="$2"
    local target_path="$3"
    local delete_mode="$4"
    local rsync_output="$5"
    local restore_success="$6"
    local duration="$7"
    
    local log_file="$work_dir/restore.json"
    local timestamp=$(date -Iseconds)
    local status="completed"
    local mode="safe_restore"
    
    if [[ "$restore_success" == "false" ]]; then
        status="failed"
    fi
    
    if [[ "$delete_mode" == "true" ]]; then
        mode="full_sync"
    fi
    
    # 성능 데이터 추출 (rsync 출력에서)
    local files_transferred="0"
    local total_size="0"
    
    if [[ -n "$rsync_output" ]]; then
        # rsync 통계에서 파일 수와 크기 추출
        files_transferred=$(echo "$rsync_output" | grep -oP "Number of regular files transferred: \K\d+" || echo "0")
        total_size=$(echo "$rsync_output" | grep -oP "Total transferred file size: \K[\d,]+" | tr -d ',' || echo "0")
    fi
    
    # JSON 구조 생성
    jq -n \
        --arg timestamp "$timestamp" \
        --arg backup_name "$backup_name" \
        --arg target_path "$target_path" \
        --arg work_directory "$work_dir" \
        --argjson delete_mode "$delete_mode" \
        --arg status "$status" \
        --arg mode "$mode" \
        --arg rsync_output "$rsync_output" \
        --argjson duration "$duration" \
        --argjson files_transferred "$files_transferred" \
        --argjson total_size "$total_size" \
        '{
            restore: {
                timestamp: $timestamp,
                backup_name: $backup_name,
                target_path: $target_path,
                work_directory: $work_directory,
                delete_mode: $delete_mode,
                status: $status,
                mode: $mode
            },
            rsync_output: $rsync_output,
            performance: {
                duration_seconds: $duration,
                files_transferred: $files_transferred,
                total_size: $total_size
            }
        }' > "$log_file"
    
    echo "📜 복구 로그가 저장되었습니다: $log_file"
}

# restore_summary.json 업데이트 함수
update_restore_summary() {
    local backup_restore_dir="$1"
    local backup_name="$2"
    local target_path="$3"
    local delete_mode="$4"
    local restore_success="$5"
    local log_filename="$6"
    
    local summary_file="$backup_restore_dir/restore_summary.json"
    local current_time=$(date -Iseconds)
    local status="success"
    local mode="safe_restore"
    
    if [[ "$restore_success" == "false" ]]; then
        status="failed"
    fi
    
    if [[ "$delete_mode" == "true" ]]; then
        mode="full_sync"
    fi
    
    # summary 파일이 없으면 초기 구조 생성
    if [[ ! -f "$summary_file" ]]; then
        jq -n \
            --arg backup_name "$backup_name" \
            --arg first_restore "$current_time" \
            '{
                backup_info: {
                    backup_name: $backup_name,
                    first_restore_attempt: $first_restore
                },
                restore_history: [],
                statistics: {
                    total_attempts: 0,
                    successful_attempts: 0,
                    failed_attempts: 0,
                    last_successful: null
                }
            }' > "$summary_file"
    fi
    
    # 새로운 복구 기록 추가
    local error_message=""
    if [[ "$restore_success" == "false" ]]; then
        error_message="복구 실패"
    fi
    
    # 복구 기록 추가 및 통계 업데이트
    jq \
        --arg timestamp "$current_time" \
        --arg target_path "$target_path" \
        --arg mode "$mode" \
        --arg status "$status" \
        --arg log_file "$log_filename" \
        --arg error "$error_message" \
        '
        # 새 기록 추가
        .restore_history += [{
            timestamp: $timestamp,
            target_path: $target_path,
            mode: $mode,
            status: $status,
            log_file: $log_file,
            error: (if $error == "" then null else $error end)
        }] |
        
        # 통계 업데이트
        .statistics.total_attempts = (.restore_history | length) |
        .statistics.successful_attempts = (.restore_history | map(select(.status == "success")) | length) |
        .statistics.failed_attempts = (.restore_history | map(select(.status == "failed")) | length) |
        .statistics.last_successful = (
            .restore_history 
            | map(select(.status == "success")) 
            | if length > 0 then (sort_by(.timestamp) | last | .timestamp) else null end
        )
        ' "$summary_file" > "$summary_file.tmp"
    
    mv "$summary_file.tmp" "$summary_file"
    
    echo "📊 복구 이력이 업데이트되었습니다: $summary_file"
}

# rsync 동기화 실행
execute_rsync() {
    local source_dir="$1"
    local target_dir="$2"
    local -n exclude_array_ref="$3"
    local delete_mode="$4" # 삭제 모드 추가
    
    local rsync_options="-avhP --stats"
    if [[ "$delete_mode" == "true" ]]; then
        rsync_options+=" --delete"
        echo "🔥 완전 동기화 모드로 실행합니다. (백업에 없는 파일은 삭제됩니다)"
    fi
    
    echo ""
    echo "🔄 rsync로 파일 동기화 시작..."
    echo "   - 원본: $source_dir/"
    echo "   - 대상: $target_dir/"
    echo "   - 제외 경로: ${#exclude_array_ref[@]}개"
    
    # 동기화할 파일 수와 크기 미리 계산
    local file_count
    file_count=$(find "$source_dir" -type f | wc -l)
    echo "   - 처리 대상: 약 $file_count개 파일"
    echo ""
    
    # rsync 실행 및 결과 캐치
    local rsync_output
    local rsync_exit_code
    local temp_log="/tmp/tarsync_rsync_$$.log"
    
    # rsync 실행하면서 출력을 화면과 임시 파일 모두에 저장
    rsync $rsync_options "${exclude_array_ref[@]}" "$source_dir/" "$target_dir/" 2>&1 | tee "$temp_log"
    rsync_exit_code=${PIPESTATUS[0]}
    
    # 임시 파일의 내용을 변수에 저장 (로그 생성용)
    rsync_output=$(cat "$temp_log")
    rm -f "$temp_log"
    
    # rsync 출력을 전역 변수로 저장 (create_restore_log에서 사용)
    RSYNC_OUTPUT="$rsync_output"
    
    if [[ $rsync_exit_code -eq 0 ]]; then
        echo "✅ 동기화 완료."
        return 0
    else
        echo "❌ 파일 동기화에 실패했습니다. (종료 코드: $rsync_exit_code)"
        return 1
    fi
}

# 메인 복구 함수
restore() {
    local backup_name="$1"
    local target_path="$2"

    echo "🔄 tarsync 복구를 시작합니다."
    echo ""

    # 복구 작업 시작 시간 기록
    local restore_start_time
    restore_start_time=$(date +%s)

    # 1. 필수 도구 검증
    validate_required_tools
    echo ""

    # 2. 백업 선택
    echo "🔍 백업 선택 중..."
    backup_name=$(select_backup "$backup_name")
    if [[ -z "$backup_name" ]]; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 백업 선택됨: $backup_name"
    echo ""

    local store_dir
    store_dir=$(get_store_dir_path)
    local backup_dir="$store_dir/$backup_name"

    # 3. 복구 대상 경로 확인
    echo "🔍 복구 대상 확인 중..."
    target_path=$(validate_restore_target "$target_path" "$backup_dir")
    if [[ -z "$target_path" ]]; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 복구 대상: $target_path"
    echo ""

    # 4. 메타데이터 로드
    echo "📄 메타데이터 로드 중..."
    if ! load_metadata "$backup_dir"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 메타데이터 로드 완료."
    echo ""

    # 5. 최종 확인
    local confirm_status
    confirm_restore "$backup_name" "$target_path"
    confirm_status=$?

    if [[ $confirm_status -eq 1 ]]; then # 1: 취소
        echo "👋 복구를 취소했습니다."
        exit 1
    fi
    echo ""

    local delete_mode=false
    if [[ $confirm_status -eq 2 ]]; then # 2: 완전 동기화
        delete_mode=true
    fi

    # 6. 임시 작업 디렉토리 생성
    local work_dir
    work_dir=$(get_restore_work_dir_path "$backup_name")
    echo "📁 임시 작업 디렉토리 생성 중..."
    create_restore_dir
    create_directory "$work_dir"
    echo "✅ 작업 디렉토리: $work_dir"
    echo ""

    # 7. 압축 해제
    if ! extract_backup "$backup_dir" "$work_dir"; then
        rm -rf "$work_dir"
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo ""

    # 8. rsync 동기화
    local exclude_array=()
    for exclude_path in "${META_EXCLUDE[@]}"; do
        exclude_array+=("--exclude=$exclude_path")
    done

    # 9. rsync 실행 및 로그 생성 (성공/실패 관계없이)
    local restore_success=true
    if ! execute_rsync "$work_dir" "$target_path" exclude_array "$delete_mode"; then
        restore_success=false
        echo "❌ 파일 동기화에 실패했습니다."
    else
        echo "✅ 파일 동기화가 완료되었습니다."
    fi
    echo ""

    # 복구 완료 시간 계산
    local restore_end_time=$(date +%s)
    local restore_duration=$((restore_end_time - restore_start_time))
    
    # 10. 복구 로그 생성 (성공/실패 관계없이 항상 생성)
    create_restore_log "$work_dir" "$backup_name" "$target_path" "$delete_mode" "$RSYNC_OUTPUT" "$restore_success" "$restore_duration"
    
    # 로그 파일을 백업별 디렉토리로 저장 (정리되기 전에)
    local backup_restore_dir="$(get_restore_dir_path)/$backup_name"
    mkdir -p "$backup_restore_dir"
    local permanent_log_file="$backup_restore_dir/$(date +%Y-%m-%d_%H-%M-%S).json"
    cp "$work_dir/restore.json" "$permanent_log_file"
    echo "📜 복구 로그가 저장되었습니다: $permanent_log_file"
    
    # restore_summary.md 업데이트
    local log_filename=$(basename "$permanent_log_file")
    update_restore_summary "$backup_restore_dir" "$backup_name" "$target_path" "$delete_mode" "$restore_success" "$log_filename"
    echo ""
    
    # 복구 실패 시 중단 (summary는 이미 업데이트됨)
    if [[ "$restore_success" == "false" ]]; then
        rm -rf "$work_dir"
        echo "❌ 복구를 중단합니다."
        exit 1
    fi

    # 11. 정리
    echo "🧹 임시 작업 디렉토리 정리..."
    rm -rf "$work_dir"
    echo "✅ 정리 완료."
    echo ""

    echo "🎉 복구가 성공적으로 완료되었습니다!"
    echo "   - 복구된 위치: $target_path"
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    restore "$@"
fi