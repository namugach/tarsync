#!/bin/bash
# tarsync 백업 목록 관리 모듈
# 기존 StoreManager.ts에서 변환됨

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

# 백업 디렉토리 존재 확인
check_store_dir() {
    local store_dir
    store_dir=$(get_store_dir_path)
    
    if ! is_path_exists "$store_dir"; then
        error_msg "MSG_SYSTEM_FILE_NOT_FOUND" "$store_dir" >&2
        return 1
    fi
    return 0
}

# 숫자를 기준 숫자의 자릿수에 맞춰 0으로 패딩
pad_index_to_reference_length() {
    local reference_number="$1"
    local target_index="$2"
    
    local reference_length=${#reference_number}
    printf "%0${reference_length}d" "$target_index"
}

# 백업 디렉토리의 파일 목록 가져오기
get_backup_files() {
    local store_dir
    store_dir=$(get_store_dir_path)
    
    if ! check_store_dir; then
        return 1
    fi
    
    # ls -ltr로 시간순 정렬하여 파일 목록 가져오기 (추가순)
    # awk로 날짜, 시간, 파일명 추출
    ls -ltr "$store_dir" 2>/dev/null | tail -n +2 | awk '{if ($9 != "") print $6, $7, $8, $9}' | grep -E "^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+2[0-9]{3}_"
}

# 파일 배열을 페이지 단위로 나누기
paginate_files() {
    local -n files_array=$1
    local page_size=$2
    local page_num=$3
    
    local total_items=${#files_array[@]}
    local total_pages=$(( (total_items + page_size - 1) / page_size ))
    
    # 파일이 없는 경우
    if [[ $total_pages -eq 0 ]]; then
        echo "0 1 0"  # items_count current_page total_pages
        return
    fi
    
    # 페이지 번호 보정 (음수 처리 및 범위 제한)
    local corrected_page_num
    if [[ $page_num -lt 0 ]]; then
        corrected_page_num=$((total_pages + page_num + 1))
    else
        corrected_page_num=$page_num
    fi
    
    # 범위 제한
    corrected_page_num=$(( corrected_page_num < 1 ? 1 : corrected_page_num ))
    corrected_page_num=$(( corrected_page_num > total_pages ? total_pages : corrected_page_num ))
    
    # 시작 인덱스와 끝 인덱스 계산
    local start=$(( (corrected_page_num - 1) * page_size ))
    
    # 마지막 페이지 조정
    if [[ $((start + page_size)) -gt $total_items ]]; then
        start=$(( total_items - page_size > 0 ? total_items - page_size : 0 ))
    fi
    
    local end=$(( start + page_size ))
    end=$(( end > total_items ? total_items : end ))
    
    local items_count=$((end - start))
    
    # 결과: items_count current_page total_pages start_index
    echo "$items_count $corrected_page_num $total_pages $start"
}

# 백업 번호를 실제 백업 이름으로 변환 (log 명령어용)
get_backup_name_by_number_for_log() {
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

# 백업 로그와 메모 표시 (log 명령어용)
show_backup_log() {
    local backup_identifier="$1"
    
    if [[ -z "$backup_identifier" ]]; then
        msg "MSG_LIST_LOG_BACKUP_NAME_REQUIRED" >&2
        msg "MSG_LIST_LOG_USAGE" >&2
        return 1
    fi
    
    # 번호 또는 이름을 실제 백업 이름으로 변환
    local backup_name
    backup_name=$(get_backup_name_by_number_for_log "$backup_identifier")
    
    if [[ -z "$backup_name" ]]; then
        msg "MSG_LIST_BACKUP_NOT_FOUND_IDENTIFIER" "$backup_identifier" >&2
        return 1
    fi
    
    local store_dir
    store_dir=$(get_store_dir_path)
    local backup_dir="$store_dir/$backup_name"
    
    if [[ ! -d "$backup_dir" ]]; then
        msg "MSG_LIST_LOG_NOT_EXISTS" "$backup_name" >&2
        return 1
    fi
    
    printf "📋 "
    msg "MSG_LOG_HEADER" "$backup_name"
    echo ""
    
    local note_file="$backup_dir/note.md"
    local log_file="$backup_dir/log.json"
    
    # 메모 파일 표시
    if [[ -f "$note_file" ]]; then
        echo "=== meno ==="
        cat "$note_file"
        echo ""
    fi
    
    # 로그 파일 표시 (사용자 친화적 포맷)
    printf "=== "
    msg "MSG_LOG_DETAILS_HEADER"
    printf " ===\n"
    if [[ -f "$log_file" ]]; then
        display_formatted_log "$log_file"
    else
        msg "MSG_LOG_NO_LOG_FILE"
    fi
}

# JSON 로그를 사용자 친화적으로 포맷팅해서 표시
display_formatted_log() {
    local log_file="$1"
    
    if [[ ! -f "$log_file" ]] || ! command -v jq >/dev/null 2>&1; then
        # jq가 없거나 파일이 없으면 원본 출력
        cat "$log_file" 2>/dev/null || msg "MSG_LOG_NO_LOG_FILE"
        return
    fi
    
    # JSON에서 주요 정보 추출
    local backup_date=$(jq -r '.backup.date // "N/A"' "$log_file" 2>/dev/null)
    local backup_time=$(jq -r '.backup.time // "N/A"' "$log_file" 2>/dev/null)
    local backup_status=$(jq -r '.backup.status // "N/A"' "$log_file" 2>/dev/null)
    local backup_source=$(jq -r '.backup.source // "N/A"' "$log_file" 2>/dev/null)
    local file_size=$(jq -r '.details.file_size // "N/A"' "$log_file" 2>/dev/null)
    local duration=$(jq -r '.details.duration_seconds // 0' "$log_file" 2>/dev/null)
    local language=$(jq -r '.backup.language // "ko"' "$log_file" 2>/dev/null)
    
    # 다국어 메시지로 포맷팅해서 표시
    msg "MSG_DETAILS_DATE" "$backup_date $backup_time"
    msg "MSG_DETAILS_SOURCE" "$backup_source"
    msg "MSG_DETAILS_STATUS" "$backup_status"
    
    if [[ "$file_size" != "N/A" && "$file_size" != "" ]]; then
        msg "MSG_DETAILS_SIZE" "$file_size"
    fi
    
    if [[ "$duration" != "0" && "$duration" != "N/A" ]]; then
        local duration_formatted=$(printf "%d seconds" "$duration")
        msg "MSG_DETAILS_DURATION" "$duration_formatted"
    fi
    
    # 로그 엔트리들 표시
    echo ""
    msg "MSG_LOG_DETAILS_HEADER"
    jq -r '.log_entries[]? | "  " + .timestamp + ": " + .message' "$log_file" 2>/dev/null || echo ""
}

# 백업 상태 체크 (파일 완전성) - 최적화 버전
check_backup_integrity() {
    local backup_dir="$1"
    local tar_file="$backup_dir/tarsync.tar.gz"
    local meta_file="$backup_dir/meta.sh"
    
    # 빠른 파일 존재 확인만 수행 (gzip -t 제거로 성능 향상)
    if [[ -f "$tar_file" && -f "$meta_file" ]]; then
        echo "✅"
    elif [[ -f "$tar_file" && ! -f "$meta_file" ]]; then
        echo "⚠️"
    else
        echo "❌"
    fi
}

# 백업 목록 출력 메인 함수
print_backups() {
    local page_size=${1:-0}     # 0이면 전체 표시
    local page_num=${2:-1}      # 기본 1페이지
    local select_list=${3:-0}   # 선택된 항목 (1부터 시작, 음수면 뒤에서부터)
    
    msg "MSG_LIST_LOADING"
    echo ""
    
    # 백업 파일 목록 가져오기
    local files_raw
    files_raw=$(get_backup_files)
    if [[ $? -ne 0 ]] || [[ -z "$files_raw" ]]; then
        msg "MSG_LIST_NO_BACKUPS"
        return 1
    fi
    
    # 배열로 변환
    local files=()
    while IFS= read -r line; do
        files+=("$line")
    done <<< "$files_raw"
    
    local files_length=${#files[@]}
    
    # 페이지 크기가 0이면 전체 표시
    if [[ $page_size -eq 0 ]]; then
        page_size=$files_length
    fi
    
    # 페이지네이션 계산
    local pagination_result
    pagination_result=$(paginate_files files "$page_size" "$page_num")
    read -r items_count current_page total_pages start_index <<< "$pagination_result"
    
    local result=""
    local total_size=0
    local store_dir
    store_dir=$(get_store_dir_path)
    
    # 현재 페이지의 시작 인덱스 계산 (표시용)
    local display_start_index=$((start_index + 1))
    
    result+="$(msg "MSG_LIST_HEADER")"$'\n'
    result+="$(msg "MSG_LIST_DIVIDER")"$'\n'
    
    # 현재 페이지의 파일 목록 순회
    for ((i = 0; i < items_count; i++)); do
        local file_index=$((start_index + i))
        local file="${files[$file_index]}"
        local file_name
        file_name=$(echo "$file" | awk '{print $4}')
        local backup_dir="$store_dir/$file_name"
        
        # 디렉토리 크기 계산 - 메타데이터 기반 최적화 버전
        local size="0B"
        local size_bytes=0
        
        # 메타데이터에서 크기 읽기 시도
        if load_metadata "$backup_dir" 2>/dev/null; then
            if [[ -n "$META_BACKUP_SIZE" && "$META_BACKUP_SIZE" -gt 0 ]]; then
                # 새로운 방식: 메타데이터에서 백업 파일 크기 사용
                size_bytes="$META_BACKUP_SIZE"
                size=$(convert_size "$size_bytes")
            elif [[ -d "$backup_dir" ]]; then
                # 호환성 fallback: META_BACKUP_SIZE가 없으면 기존 du 방식
                size_bytes=$(du -sb "$backup_dir" 2>/dev/null | awk '{print $1}')
                size_bytes=${size_bytes:-0}
                if [[ $size_bytes -gt 0 ]]; then
                    size=$(convert_size "$size_bytes")
                fi
            fi
        elif [[ -d "$backup_dir" ]]; then
            # 메타데이터 로드 실패 시 기존 방식 사용
            size_bytes=$(du -sb "$backup_dir" 2>/dev/null | awk '{print $1}')
            size_bytes=${size_bytes:-0}
            if [[ $size_bytes -gt 0 ]]; then
                size=$(convert_size "$size_bytes")
            fi
        fi
        
        # 사용자 메모 파일 존재 여부만 확인
        local note_icon="❌"
        if [[ -f "$backup_dir/note.md" ]]; then
            note_icon="📝"
        fi
        
        # 총 용량 계산
        total_size=$((total_size + size_bytes))
        
        # 결과 문자열에 추가
        local current_index=$((display_start_index + i))
        local padded_index
        padded_index=$(pad_index_to_reference_length "$files_length" "$current_index")
        
        result+="$padded_index. $note_icon $size $file"$'\n'
    done
    
    result+=""$'\n'
    
    # 총 용량 정보
    local store_total_size
    store_total_size=$(du -sh "$store_dir" 2>/dev/null | awk '{print $1}')
    local page_total_size_human
    page_total_size_human=$(convert_size "$total_size")
    
    result+="$(msg "MSG_LIST_STORAGE_TOTAL" "${store_total_size}")"$'\n'
    result+="$(msg "MSG_LIST_PAGE_TOTAL" "$page_total_size_human")"$'\n'
    result+="$(msg "MSG_LIST_PAGE_INFO" "$current_page" "$total_pages" "$files_length")"$'\n'
    
    # 결과 출력
    echo "$result"
}

# 백업 삭제 함수
delete_backup() {
    local backup_name="$1"
    local store_dir
    store_dir=$(get_store_dir_path)
    local backup_dir="$store_dir/$backup_name"
    
    if [[ -z "$backup_name" ]]; then
        msg "MSG_LIST_DELETE_NAME_REQUIRED" >&2
        return 1
    fi
    
    if ! is_path_exists "$backup_dir"; then
        msg "MSG_LIST_DELETE_NOT_EXISTS" "$backup_name" >&2
        return 1
    fi
    
    msg "MSG_LIST_DELETE_CONFIRM"
    msg "MSG_LIST_DELETE_TARGET" "$backup_name"
    msg "MSG_LIST_DELETE_PATH" "$backup_dir"
    
    # 백업 크기 표시
    local backup_size
    backup_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
    msg "MSG_LIST_DELETE_SIZE" "$backup_size"
    
    echo ""
    printf "$(msg "MSG_LIST_DELETE_PROMPT")"
    read -r confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        msg "MSG_LIST_DELETE_PROCESSING"
        if rm -rf "$backup_dir"; then
            msg "MSG_LIST_DELETE_SUCCESS" "$backup_name"
            return 0
        else
            msg "MSG_LIST_DELETE_ERROR" >&2
            return 1
        fi
    else
        msg "MSG_LIST_DELETE_CANCELLED"
        return 1
    fi
}

# 백업 상세 정보 표시
show_backup_details() {
    local backup_name="$1"
    local store_dir
    store_dir=$(get_store_dir_path)
    local backup_dir="$store_dir/$backup_name"
    
    if [[ -z "$backup_name" ]]; then
        msg "MSG_LIST_DETAILS_NAME_REQUIRED" >&2
        return 1
    fi
    
    if ! is_path_exists "$backup_dir"; then
        msg "MSG_LIST_DETAILS_NOT_EXISTS" "$backup_name" >&2
        return 1
    fi
    
    msg "MSG_LIST_DETAILS_HEADER"
    msg "MSG_LIST_DETAILS_DIVIDER"
    msg "MSG_LIST_DETAILS_NAME" "$backup_name"
    msg "MSG_LIST_DETAILS_PATH" "$backup_dir"
    
    # 백업 크기
    local backup_size
    backup_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
    msg "MSG_LIST_DETAILS_SIZE" "$backup_size"
    
    # 파일 상태 체크
    local integrity_status
    integrity_status=$(check_backup_integrity "$backup_dir")
    msg "MSG_LIST_DETAILS_STATUS" "$integrity_status"
    
    # 메타데이터 정보
    local meta_file="$backup_dir/meta.sh"
    if [[ -f "$meta_file" ]]; then
        echo ""
        msg "MSG_LIST_DETAILS_META_HEADER"
        if load_metadata "$backup_dir"; then
            msg "MSG_LIST_DETAILS_META_SOURCE_SIZE" "$(convert_size "$META_SIZE")"
            msg "MSG_LIST_DETAILS_META_CREATED" "$META_CREATED"
            msg "MSG_LIST_DETAILS_META_EXCLUDES" "${#META_EXCLUDE[@]}"
        fi
    fi
    
    # 파일 목록
    echo ""
    msg "MSG_LIST_DETAILS_FILES_HEADER"
    find "$backup_dir" -type f -exec basename {} \; | sort
    
    # 로그 파일 내용
    print_backup_log "$backup_dir" "$backup_name"
}

# 메인 함수 - 명령행 인터페이스
main() {
    local command="${1:-list}"
    
    case "$command" in
        "list"|"ls")
            local page_size="${2:-10}"
            local page_num="${3:-1}"  
            local select_list="${4:-0}"
            print_backups "$page_size" "$page_num" "$select_list"
            ;;
        "delete"|"rm")
            local backup_name="$2"
            delete_backup "$backup_name"
            ;;
        "details"|"show")
            local backup_name="$2"
            show_backup_details "$backup_name"
            ;;
        "log")
            local backup_identifier="$2"
            show_backup_log "$backup_identifier"
            ;;
        "help"|"-h"|"--help")
            msg "MSG_LIST_HELP_TITLE"
            echo ""
            msg "MSG_LIST_HELP_USAGE"
            msg "MSG_LIST_HELP_LIST_CMD" "$0"
            msg "MSG_LIST_HELP_LOG_CMD" "$0"
            msg "MSG_LIST_HELP_DELETE_CMD" "$0"
            msg "MSG_LIST_HELP_DETAILS_CMD" "$0"
            msg "MSG_LIST_HELP_HELP_CMD" "$0"
            echo ""
            msg "MSG_LIST_HELP_EXAMPLES"
            msg "MSG_LIST_HELP_EXAMPLE_LIST" "$0"
            msg "MSG_LIST_HELP_EXAMPLE_LIST_SIZE" "$0"
            msg "MSG_LIST_HELP_EXAMPLE_LOG_NUM" "$0"
            msg "MSG_LIST_HELP_EXAMPLE_LOG_NAME" "$0"
            msg "MSG_LIST_HELP_EXAMPLE_DELETE" "$0"
            msg "MSG_LIST_HELP_EXAMPLE_DETAILS" "$0"
            ;;
        *)
            msg "MSG_LIST_UNKNOWN_COMMAND" "$command" >&2
            msg "MSG_LIST_HELP_HINT" "$0" >&2
            return 1
            ;;
    esac
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 