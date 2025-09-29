#!/bin/bash
# tarsync 복구 모듈 (단순화 버전)

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

# 백업 목록 출력 (선택용) - list.sh와 동일한 형식
show_backup_list() {
    local store_dir
    store_dir=$(get_store_dir_path)
    
    msg "MSG_RESTORE_SELECT" >&2
    echo "====================" >&2
    
    # list.sh와 동일한 로직 사용
    local files_raw
    files_raw=$(ls -ltr "$store_dir" 2>/dev/null | tail -n +2 | awk '{if ($9 != "") print $6, $7, $8, $9}' | grep -E "^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+2[0-9]{3}_")
    
    if [[ -z "$files_raw" ]]; then
        msg "MSG_LIST_NO_BACKUPS" >&2
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
        printf "$(msg "MSG_RESTORE_SELECT_BACKUP")" >&2
        read -r backup_name
    fi
    
    local actual_backup_name
    actual_backup_name=$(get_backup_name_by_number "$backup_name")
    
    if [[ -z "$actual_backup_name" ]]; then
        msg "MSG_RESTORE_BACKUP_NOT_FOUND" "$backup_name" >&2
        return 1
    fi
    
    local store_dir
    store_dir=$(get_store_dir_path)
    local backup_dir="$store_dir/$actual_backup_name"
    
    if ! is_path_exists "$backup_dir" || ! is_file "$backup_dir/tarsync.tar.gz" || ! is_file "$backup_dir/meta.sh"; then
        msg "MSG_RESTORE_INVALID_BACKUP" "$actual_backup_name" >&2
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

# log.json에서 exclude_paths 추출
get_exclude_paths_from_log() {
    local backup_dir="$1"
    local log_file="$backup_dir/log.json"
    local -n exclude_paths_ref="$2"

    exclude_paths_ref=()

    if [[ -f "$log_file" ]]; then
        # jq로 exclude_paths 배열을 읽어서 bash 배열로 변환
        while IFS= read -r path; do
            if [[ -n "$path" && "$path" != "null" ]]; then
                exclude_paths_ref+=("$path")
            fi
        done < <(jq -r '.details.exclude_paths[]?' "$log_file" 2>/dev/null)
        
        echo "📋 Loaded ${#exclude_paths_ref[@]} exclude paths from log.json."
        return 0
    else
        echo "⚠️ Could not find log.json. Using metadata exclude paths."
        return 1
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
        msg "MSG_RESTORE_INVALID_TARGET" "$target_path" >&2
        return 1
    fi
    
    echo "$target_path"
}

# 최종 복구 확인 (선택형 메뉴)
confirm_restore() {
    local backup_name="$1"
    local target_path="$2"

    echo ""
    msg "MSG_RESTORE_MODE_SELECT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    msg "MSG_RESTORE_BACKUP_INFO" "$backup_name"
    echo "  - 🎯 Target: $target_path"
    echo ""
    msg "MSG_RESTORE_MODE_SAFE"
    msg "MSG_RESTORE_MODE_SAFE_DESC"
    msg "MSG_RESTORE_MODE_SAFE_RECOMMEND"
    echo ""
    msg "MSG_RESTORE_MODE_FULL"
    msg "MSG_RESTORE_MODE_FULL_DESC"
    echo "    Files or directories that only exist in target folder will be **deleted**."
    echo ""
    msg "MSG_RESTORE_MODE_CANCEL"
    msg "MSG_RESTORE_MODE_CANCEL_DESC"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local choice
    while true; do
        read -p "선택 (1-3, 기본값: 1): " choice
        choice=${choice:-1}
        case $choice in
            1) return 0 ;; # 안전 복구
            2) return 2 ;; # 완전 동기화
            3) return 1 ;; # 취소
            *) msg "MSG_RESTORE_INVALID_CHOICE" ;;
        esac
    done
}

# tar 압축 해제
extract_backup() {
    local backup_dir="$1"
    local extract_dir="$2"
    local tar_file="$backup_dir/tarsync.tar.gz"
    
    msg "MSG_RESTORE_EXTRACTING"
    echo "   - Source: $tar_file"
    echo "   - Target: $extract_dir"
    echo "   - File size: $(get_path_size_formatted "$tar_file")"
    echo ""
    
    # pv를 사용한 진행률 표시와 함께 압축 해제
    if ! pv "$tar_file" | tar -xz -C "$extract_dir" --strip-components=0 --preserve-permissions; then
        msg "MSG_RESTORE_EXTRACT_FAILED"
        return 1
    fi
    
    msg "MSG_RESTORE_EXTRACT_COMPLETE"
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
    
    msg "MSG_RESTORE_LOG_SAVED" "$log_file"
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
    
    msg "MSG_RESTORE_HISTORY_UPDATED" "$summary_file"
}

# rsync 동기화 실행
execute_rsync() {
    local source_dir="$1"
    local target_dir="$2"
    local -n exclude_array_ref="$3"
    local delete_mode="$4"
    local -n protect_paths_ref="$5" # 보호할 경로 배열 추가
    
    local rsync_options="-av --stats"  # -P 제거로 상세 출력 방지, -h 제거
    local protect_filters=()
    
    if [[ "$delete_mode" == "true" ]]; then
        rsync_options+=" --delete"
        
        # 제외된 경로들을 삭제로부터 보호
        if [[ ${#protect_paths_ref[@]} -gt 0 ]]; then
            for exclude_path in "${protect_paths_ref[@]}"; do
                protect_filters+=("--filter=protect $exclude_path")
            done
            # 완전 동기화 모드 보호 메시지 (번역 상수 추가 필요)
        fi
        
        msg "MSG_RESTORE_FULL_SYNC_WARNING"
    fi
    
    echo ""
    msg "MSG_RESTORE_SYNC_START"
    echo "   📂 Source: $source_dir/"
    echo "   🎯 Target: $target_dir/"
    echo "   🚫 Exclude: ${#exclude_array_ref[@]} paths"
    
    # 동기화할 파일 수 계산 (시간 제한으로 빠른 응답)
    local file_count
    file_count=$(timeout 5s find "$source_dir" -type f 2>/dev/null | wc -l || echo "many files")
    echo "   📊 Target: approximately $file_count files"
    echo ""
    
    # rsync 실행 및 결과 캐치
    local rsync_output
    local rsync_exit_code
    local temp_log="/tmp/tarsync_rsync_$$.log"
    
    echo "⏳ Synchronization in progress..."
    
    # pv를 사용한 진행률 표시가 가능한지 확인
    if command -v pv >/dev/null 2>&1 && [[ "$file_count" =~ ^[0-9]+$ ]] && [[ "$file_count" -gt 100 ]]; then
        # 파일이 많은 경우 pv를 통한 진행률 시뮬레이션
        echo "📊 Processing $file_count files..."
        
        # rsync를 백그라운드에서 실행하고 진행률 표시
        rsync $rsync_options "${exclude_array_ref[@]}" "${protect_filters[@]}" "$source_dir/" "$target_dir/" >"$temp_log" 2>&1 &
        local rsync_pid=$!
        
        # 간단한 진행률 표시
        local progress=0
        while kill -0 "$rsync_pid" 2>/dev/null; do
            printf "\r🔄 Progress: %d%%" "$progress"
            progress=$(( (progress + 10) % 100 ))
            sleep 2
        done
        printf "\r✅ Synchronization complete!      \n"
        
        # rsync 종료 코드 확인
        wait "$rsync_pid"
        rsync_exit_code=$?
    else
        # 일반적인 방식으로 rsync 실행
        rsync $rsync_options "${exclude_array_ref[@]}" "${protect_filters[@]}" "$source_dir/" "$target_dir/" >"$temp_log" 2>&1
        rsync_exit_code=$?
    fi
    
    # 임시 파일의 내용을 변수에 저장 (로그 생성용)
    rsync_output=$(cat "$temp_log" 2>/dev/null || echo "")
    rm -f "$temp_log"
    
    # rsync 출력을 전역 변수로 저장 (create_restore_log에서 사용)
    RSYNC_OUTPUT="$rsync_output"
    
    # rsync 통계 정보 추출 및 사용자 친화적 표시
    if [[ -n "$rsync_output" ]]; then
        local transferred_files=$(echo "$rsync_output" | grep -oP "Number of regular files transferred: \K\d+" 2>/dev/null || echo "0")
        local total_size=$(echo "$rsync_output" | grep -oP "Total transferred file size: \K[^\s]+" 2>/dev/null || echo "0")
        local speedup=$(echo "$rsync_output" | grep -oP "speedup is \K[^\s]+" 2>/dev/null || echo "1.0")
        
        if [[ "$transferred_files" != "0" ]]; then
            msg "MSG_RESTORE_SYNC_COMPLETE" "${transferred_files}" "${total_size}" "${speedup}"
        else
            # 파일이 이미 최신 상태일 때 메시지 (번역 상수 추가 필요)
            :
        fi
    fi
    
    # 결과 처리 및 에러 분석
    if [[ $rsync_exit_code -eq 0 ]]; then
        # 동기화 완료 메시지 (번역 상수 추가 필요)
        return 0
    elif [[ $rsync_exit_code -eq 23 ]]; then
        echo "⚠️  Some file processing limitations occurred, but main synchronization was successful."
        
        # 보호된 파일 개수 계산
        local protected_count=$(echo "$rsync_output" | grep -c "Read-only file system\|Operation not permitted\|failed:" 2>/dev/null || echo "0")
        if [[ "$protected_count" -gt "0" ]]; then
            echo "   💡 ${protected_count} files were not modified due to system protection. (normal)"
        fi
        echo "   🛡️  Important files like SSH keys and system files were protected."
        return 0
    else
        # 동기화 실패 메시지 (번역 상수 추가 필요)
        
        # 주요 에러만 요약해서 표시
        if [[ -n "$rsync_output" ]]; then
            local error_lines=$(echo "$rsync_output" | grep -E "(failed|error|Error|Permission denied)" | head -3)
            if [[ -n "$error_lines" ]]; then
                echo "📋 Main errors:"
                echo "$error_lines" | sed 's/^/   /'
            fi
        fi
        return 1
    fi
}

# 메인 복구 함수
restore() {
    local backup_name="$1"
    local target_path="$2"

    echo "🔄 Starting tarsync restore."
    echo ""

    # 복구 작업 시작 시간 기록
    local restore_start_time
    restore_start_time=$(date +%s)

    # 1. 필수 도구 검증
    validate_required_tools
    echo ""

    # 2. 백업 선택
    echo "🔍 Selecting backup..."
    backup_name=$(select_backup "$backup_name")
    if [[ -z "$backup_name" ]]; then
        echo "❌ Restoration cancelled."
        exit 1
    fi
    echo "✅ Backup selected: $backup_name"
    echo ""

    local store_dir
    store_dir=$(get_store_dir_path)
    local backup_dir="$store_dir/$backup_name"

    # 3. 복구 대상 경로 확인
    echo "🔍 Checking restore target..."
    target_path=$(validate_restore_target "$target_path" "$backup_dir")
    if [[ -z "$target_path" ]]; then
        echo "❌ Restoration cancelled."
        exit 1
    fi
    echo "✅ Restore target: $target_path"
    echo ""

    # 4. 메타데이터 로드
    echo "📄 Loading metadata..."
    if ! load_metadata "$backup_dir"; then
        echo "❌ Restoration cancelled."
        exit 1
    fi
    echo "✅ Metadata loading completed."
    echo ""

    # 5. 최종 확인
    local confirm_status
    confirm_restore "$backup_name" "$target_path"
    confirm_status=$?

    if [[ $confirm_status -eq 1 ]]; then # 1: 취소
        echo "👋 Restore cancelled."
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
    echo "📁 Creating temporary working directory..."
    create_restore_dir
    create_directory "$work_dir"
    echo "✅ Working directory: $work_dir"
    echo ""

    # 7. 압축 해제
    if ! extract_backup "$backup_dir" "$work_dir"; then
        rm -rf "$work_dir"
        echo "❌ Restoration cancelled."
        exit 1
    fi
    echo ""

    # 8. rsync 동기화 - log.json에서 제외 경로 로드
    local exclude_array=()
    local log_exclude_paths=()
    
    # log.json에서 exclude_paths 로드 시도
    if get_exclude_paths_from_log "$backup_dir" log_exclude_paths; then
        echo "✅ Successfully loaded exclude paths from log.json."
        for exclude_path in "${log_exclude_paths[@]}"; do
            exclude_array+=("--exclude=$exclude_path")
        done
    else
        echo "⚠️ Cannot load exclude paths from log.json. Using metadata."
        for exclude_path in "${META_EXCLUDE[@]}"; do
            exclude_array+=("--exclude=$exclude_path")
        done
    fi
    
    # 시스템 중요 경로 추가 보호
    local critical_paths=("/boot" "/etc/fstab" "/etc/grub*")
    echo "🛡️ Adding protection for critical system paths..."
    for critical_path in "${critical_paths[@]}"; do
        exclude_array+=("--exclude=$critical_path")
    done

    # 9. rsync 실행 및 로그 생성 (성공/실패 관계없이)
    local restore_success=true
    
    # 보호할 경로 배열 준비
    local protect_paths=()
    if [[ ${#log_exclude_paths[@]} -gt 0 ]]; then
        protect_paths=("${log_exclude_paths[@]}")
    else
        protect_paths=("${META_EXCLUDE[@]}")
    fi
    
    if ! execute_rsync "$work_dir" "$target_path" exclude_array "$delete_mode" protect_paths; then
        restore_success=false
        echo "❌ File synchronization failed."
    else
        echo "✅ File synchronization completed."
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
    echo "📜 Restore log saved: $permanent_log_file"
    
    # restore_summary.md 업데이트
    local log_filename=$(basename "$permanent_log_file")
    update_restore_summary "$backup_restore_dir" "$backup_name" "$target_path" "$delete_mode" "$restore_success" "$log_filename"
    echo ""
    
    # 복구 실패 시 중단 (summary는 이미 업데이트됨)
    if [[ "$restore_success" == "false" ]]; then
        rm -rf "$work_dir"
        echo "❌ Restoration cancelled."
        exit 1
    fi

    # 11. 정리
    echo "🧹 Cleaning up temporary working directory..."
    rm -rf "$work_dir"
    echo "✅ Cleanup completed."
    echo ""

    success_msg "MSG_RESTORE_COMPLETE"
    echo "   - Restored location: $target_path"
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    restore "$@"
fi