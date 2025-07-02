#!/bin/bash
# tarsync 백업 목록 관리 모듈
# 기존 StoreManager.ts에서 변환됨

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 공통 유틸리티 로드
source "$(get_script_dir)/common.sh"

# 백업 디렉토리 존재 확인
check_store_dir() {
    local store_dir
    store_dir=$(get_store_dir_path)
    
    if ! is_path_exists "$store_dir"; then
        echo "⚠️  백업 디렉토리가 존재하지 않습니다: $store_dir" >&2
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
    
    # ls -lthr로 시간순 정렬하여 파일 목록 가져오기
    # awk로 날짜, 시간, 파일명 추출
    ls -lthr "$store_dir" 2>/dev/null | tail -n +2 | awk '{if ($9 != "") print $6, $7, $8, $9}' | grep -E "^[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+[^[:space:]]+[[:space:]]+2[0-9]{3}_"
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

# 선택된 백업의 로그 파일 내용 출력
print_backup_log() {
    local backup_dir="$1"
    local file_name="$2"
    
    local log_file="$backup_dir/log.md"
    
    if [[ -f "$log_file" ]]; then
        echo ""
        echo "📜 백업 로그 내용 ($file_name/log.md):"
        echo "-----------------------------------"
        cat "$log_file"
        echo "-----------------------------------"
    else
        echo ""
        echo "⚠️  선택된 디렉토리에 log.md 파일이 없습니다: $file_name"
    fi
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
    
    echo "📋 백업 목록 조회 중..."
    echo ""
    
    # 백업 파일 목록 가져오기
    local files_raw
    files_raw=$(get_backup_files)
    if [[ $? -ne 0 ]] || [[ -z "$files_raw" ]]; then
        echo "⚠️  백업 파일이 없습니다."
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
    local selected_backup_dir=""
    local selected_file_name=""
    local store_dir
    store_dir=$(get_store_dir_path)
    
    # 현재 페이지의 시작 인덱스 계산 (표시용)
    local display_start_index=$((start_index + 1))
    
    result+="📦 tarsync 백업 목록"$'\n'
    result+="===================="$'\n'
    
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
        
        # 로그 파일 존재 여부 확인
        local log_icon="❌"
        if [[ -f "$backup_dir/log.md" ]]; then
            log_icon="📖"
        fi
        
        # 백업 상태 체크
        local integrity_status
        integrity_status=$(check_backup_integrity "$backup_dir")
        
        # 선택된 디렉토리 표시
        local selection_icon="⬜️"
        local is_selected=false
        
        if [[ $select_list -lt 0 ]] && [[ $i -eq $((items_count + select_list)) ]]; then
            selection_icon="✅"
            is_selected=true
        elif [[ $select_list -gt 0 ]] && [[ $i -eq $((select_list - 1)) ]]; then
            selection_icon="✅"
            is_selected=true
        fi
        
        # 선택된 항목 정보 저장
        if [[ $is_selected == true ]]; then
            selected_backup_dir="$backup_dir"
            selected_file_name="$file_name"
        fi
        
        # 총 용량 계산
        total_size=$((total_size + size_bytes))
        
        # 결과 문자열에 추가
        local current_index=$((display_start_index + i))
        local padded_index
        padded_index=$(pad_index_to_reference_length "$files_length" "$current_index")
        
        result+="$padded_index. $selection_icon $integrity_status $log_icon $size $file"$'\n'
    done
    
    result+=""$'\n'
    
    # 총 용량 정보
    local store_total_size
    store_total_size=$(du -sh "$store_dir" 2>/dev/null | awk '{print $1}')
    local page_total_size_human
    page_total_size_human=$(convert_size "$total_size")
    
    result+="🔳 전체 저장소: ${store_total_size}B"$'\n'
    result+="🔳 페이지 총합: $page_total_size_human"$'\n'
    result+="🔳 페이지 $current_page / $total_pages (총 $files_length 개 백업)"$'\n'
    
    # 결과 출력
    echo "$result"
    
    # 선택된 백업의 로그 출력
    if [[ -n "$selected_backup_dir" ]] && [[ -n "$selected_file_name" ]]; then
        print_backup_log "$selected_backup_dir" "$selected_file_name"
    fi
}

# 백업 삭제 함수
delete_backup() {
    local backup_name="$1"
    local store_dir
    store_dir=$(get_store_dir_path)
    local backup_dir="$store_dir/$backup_name"
    
    if [[ -z "$backup_name" ]]; then
        echo "❌ 삭제할 백업 이름을 지정해주세요." >&2
        return 1
    fi
    
    if ! is_path_exists "$backup_dir"; then
        echo "❌ 백업이 존재하지 않습니다: $backup_name" >&2
        return 1
    fi
    
    echo "🗑️  백업 삭제 확인"
    echo "   대상: $backup_name"
    echo "   경로: $backup_dir"
    
    # 백업 크기 표시
    local backup_size
    backup_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
    echo "   크기: $backup_size"
    
    echo ""
    echo -n "정말로 이 백업을 삭제하시겠습니까? [y/N]: "
    read -r confirmation
    
    if [[ "$confirmation" =~ ^[Yy]$ ]]; then
        echo "🗑️  백업 삭제 중..."
        if rm -rf "$backup_dir"; then
            echo "✅ 백업이 성공적으로 삭제되었습니다: $backup_name"
            return 0
        else
            echo "❌ 백업 삭제 중 오류가 발생했습니다." >&2
            return 1
        fi
    else
        echo "❌ 백업 삭제가 취소되었습니다."
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
        echo "❌ 조회할 백업 이름을 지정해주세요." >&2
        return 1
    fi
    
    if ! is_path_exists "$backup_dir"; then
        echo "❌ 백업이 존재하지 않습니다: $backup_name" >&2
        return 1
    fi
    
    echo "📋 백업 상세 정보"
    echo "=================="
    echo "📂 백업 이름: $backup_name"
    echo "📁 백업 경로: $backup_dir"
    
    # 백업 크기
    local backup_size
    backup_size=$(du -sh "$backup_dir" 2>/dev/null | awk '{print $1}')
    echo "📦 백업 크기: $backup_size"
    
    # 파일 상태 체크
    local integrity_status
    integrity_status=$(check_backup_integrity "$backup_dir")
    echo "🔍 백업 상태: $integrity_status"
    
    # 메타데이터 정보
    local meta_file="$backup_dir/meta.sh"
    if [[ -f "$meta_file" ]]; then
        echo ""
        echo "📄 메타데이터 정보:"
        if load_metadata "$backup_dir"; then
            echo "   원본 크기: $(convert_size "$META_SIZE")"
            echo "   생성 날짜: $META_CREATED"
            echo "   제외 경로: ${#META_EXCLUDE[@]}개"
        fi
    fi
    
    # 파일 목록
    echo ""
    echo "📁 포함된 파일:"
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
        "help"|"-h"|"--help")
            echo "tarsync 백업 목록 관리"
            echo ""
            echo "사용법:"
            echo "  $0 list [페이지크기] [페이지번호] [선택번호]    # 백업 목록 표시"
            echo "  $0 delete <백업이름>                        # 백업 삭제"
            echo "  $0 details <백업이름>                       # 백업 상세 정보"
            echo "  $0 help                                    # 도움말 표시"
            echo ""
            echo "예시:"
            echo "  $0 list 5 1                               # 5개씩, 1페이지"
            echo "  $0 list 10 -1 2                          # 10개씩, 마지막 페이지, 2번째 선택"
            echo "  $0 delete 2025_06_27_오후_02_28_59         # 특정 백업 삭제"
            echo "  $0 details 2025_06_27_오후_02_28_59        # 백업 상세 정보"
            ;;
        *)
            echo "❌ 알 수 없는 명령어: $command" >&2
            echo "도움말을 보려면: $0 help" >&2
            return 1
            ;;
    esac
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 