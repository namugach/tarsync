#!/bin/bash
# tarsync 복구 모듈
# 기존 Tarsync.restore() 메서드에서 변환됨

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 공통 유틸리티 로드
source "$(get_script_dir)/common.sh"

# 백업 목록 출력 (선택용)
show_backup_list() {
    local store_dir
    store_dir=$(get_store_dir_path)
    
    echo "📋 사용 가능한 백업 목록:" >&2
    echo "====================" >&2
    
    local count=0
    if [[ -d "$store_dir" ]]; then
        find "$store_dir" -maxdepth 1 -type d -name "2*" | sort -r | while read -r backup_dir; do
            local dir_name
            dir_name=$(basename "$backup_dir")
            
            local tar_file="$backup_dir/tarsync.tar.gz"
            local meta_file="$backup_dir/meta.sh"
            local log_file="$backup_dir/log.md"
            
            local size_info="?"
            local log_icon="❌"
            local meta_icon="❌"
            
            if [[ -f "$tar_file" ]]; then
                size_info=$(get_path_size_formatted "$tar_file")
            fi
            
            if [[ -f "$log_file" ]]; then
                log_icon="📖"
            fi
            
            if [[ -f "$meta_file" ]]; then
                meta_icon="📄"
            fi
            
            count=$((count + 1))
            echo "  $count. $meta_icon $log_icon $size_info - $dir_name" >&2
        done
    else
        echo "  백업 디렉토리가 없습니다." >&2
    fi
    
    echo "====================" >&2
}

# 백업 번호를 실제 백업 이름으로 변환
get_backup_name_by_number() {
    local backup_number="$1"
    local store_dir
    store_dir=$(get_store_dir_path)
    
    # 숫자인지 확인
    if [[ "$backup_number" =~ ^[0-9]+$ ]]; then
        # list 명령과 동일한 정렬 방식 사용 (ls -lthr)
        local backup_list
        readarray -t backup_list < <(ls -lthr "$store_dir" 2>/dev/null | tail -n +2 | awk '{if ($9 != "") print $9}' | grep -E "^2[0-9]{3}_")
        
        # 배열 인덱스는 0부터 시작하므로 1을 빼야 함
        local array_index=$((backup_number - 1))
        
        if [[ $array_index -ge 0 && $array_index -lt ${#backup_list[@]} ]]; then
            echo "${backup_list[$array_index]}"
            return 0
        else
            return 1
        fi
    else
        # 숫자가 아니면 그대로 반환
        echo "$backup_number"
        return 0
    fi
}

# 백업 선택 및 유효성 확인
select_backup() {
    local backup_name="$1"
    local store_dir
    store_dir=$(get_store_dir_path)
    
    if [[ -z "$backup_name" ]]; then
        show_backup_list
        echo "" >&2
        echo -n "복구할 백업을 선택하세요 (번호 또는 디렉토리 이름): " >&2
        read -r backup_name
    fi
    
    # 백업 번호를 실제 이름으로 변환
    local actual_backup_name
    actual_backup_name=$(get_backup_name_by_number "$backup_name")
    
    if [[ -z "$actual_backup_name" ]]; then
        echo "❌ 백업 번호 $backup_name에 해당하는 백업을 찾을 수 없습니다." >&2
        return 1
    fi
    
    backup_name="$actual_backup_name"
    
    local backup_dir="$store_dir/$backup_name"
    
    if ! is_path_exists "$backup_dir"; then
        echo "❌ 백업 디렉토리가 존재하지 않습니다: $backup_dir" >&2
        return 1
    fi
    
    local tar_file="$backup_dir/tarsync.tar.gz"
    if ! is_file "$tar_file"; then
        echo "❌ 백업 파일이 존재하지 않습니다: $tar_file" >&2
        return 1
    fi
    
    local meta_file="$backup_dir/meta.sh"
    if ! is_file "$meta_file"; then
        echo "❌ 메타데이터 파일이 존재하지 않습니다: $meta_file" >&2
        return 1
    fi
    
    echo "$backup_name"
}

# 복구 대상 경로 확인
validate_restore_target() {
    local target_path="$1"
    
    if [[ -z "$target_path" ]]; then
        echo -n "복구 대상 경로를 입력하세요 (예: /tmp/restore_test): " >&2
        read -r target_path
    fi
    
    # 상위 디렉토리가 존재하고 쓰기 가능한지 확인
    local parent_dir
    parent_dir=$(dirname "$target_path")
    
    if ! is_path_exists "$parent_dir"; then
        echo "❌ 복구 대상의 상위 디렉토리가 존재하지 않습니다: $parent_dir" >&2
        return 1
    fi
    
    if ! is_writable "$parent_dir"; then
        echo "❌ 복구 대상에 쓰기 권한이 없습니다: $parent_dir" >&2
        return 1
    fi
    
    echo "$target_path"
}

# tar 압축 해제
extract_backup() {
    local backup_dir="$1"
    local extract_dir="$2"
    local tar_file="$backup_dir/tarsync.tar.gz"
    
    echo "📦 백업 파일 압축 해제 중..."
    echo "   원본: $tar_file"
    echo "   대상: $extract_dir"
    
    # tar 압축 해제 명령어
    local extract_command="tar -xzf '$tar_file' -C '$extract_dir' --strip-components=0 --preserve-permissions"
    
    if eval "$extract_command"; then
        echo "✅ 압축 해제 완료!"
        return 0
    else
        echo "❌ 압축 해제 실패!"
        return 1
    fi
}

# rsync 동기화 실행
execute_rsync() {
    local source_dir="$1"
    local target_dir="$2"
    local dry_run="$3"
    local delete_mode="$4"
    local exclude_options="$5"
    
    # rsync 옵션 구성
    local rsync_options="-avhP --stats"
    
    if [[ "$delete_mode" == "true" ]]; then
        rsync_options="$rsync_options --delete"
        echo "🗑️  삭제 모드: 대상에서 원본에 없는 파일들을 삭제합니다"
    fi
    
    if [[ "$dry_run" == "true" ]]; then
        rsync_options="$rsync_options --dry-run"
        echo "🧪 시뮬레이션 모드: 실제 복구는 수행되지 않습니다"
    fi
    
    echo ""
    echo "🔄 rsync 동기화 시작..."
    echo "   원본: $source_dir/"
    echo "   대상: $target_dir/"
    echo "   옵션: $rsync_options"
    
    # rsync 명령어 실행
    local rsync_command="rsync $rsync_options $exclude_options '$source_dir/' '$target_dir/'"
    
    echo "   명령어: $rsync_command"
    echo ""
    
    if eval "$rsync_command"; then
        echo ""
        if [[ "$dry_run" == "true" ]]; then
            echo "✅ 시뮬레이션 완료! (실제 파일은 변경되지 않았습니다)"
        else
            echo "✅ 복구 동기화 완료!"
        fi
        return 0
    else
        echo ""
        echo "❌ 복구 동기화 실패!"
        return 1
    fi
}

# 경량 시뮬레이션 실행
light_simulation() {
    local backup_dir="$1"
    local target_path="$2"
    local tar_file="$backup_dir/tarsync.tar.gz"
    
    echo "🧪 경량 시뮬레이션 (기본모드)"
    echo "================================"
    
    # 백업 파일 기본 정보
    local backup_size
    backup_size=$(get_file_size "$tar_file")
    echo "📦 백업: $(basename "$backup_dir") ($(convert_size "$backup_size"))"
    echo "📂 복구 대상: $target_path"
    
    # tar 파일 내용 분석
    echo ""
    echo "📊 백업 내용 분석 중..."
    
    local file_count dir_count total_size
    file_count=$(tar -tzf "$tar_file" 2>/dev/null | grep -v '/$' | wc -l)
    dir_count=$(tar -tzf "$tar_file" 2>/dev/null | grep '/$' | wc -l)
    
    echo "📄 파일 개수: $(printf "%'d" "$file_count")개"
    echo "📁 디렉토리 개수: $(printf "%'d" "$dir_count")개"
    
    # 주요 디렉토리 구조 표시 (상위 레벨만)
    echo ""
    echo "📋 주요 디렉토리 구조:"
    # 루트부터 주요 디렉토리들 표시
    tar -tzf "$tar_file" 2>/dev/null | head -20 | grep '/$' | while read -r dir; do
        # 경로 정리 (앞의 / 제거)
        clean_dir="${dir#/}"
        if [[ "$dir" == "/" ]]; then
            echo "  📁 / (루트 디렉토리)"
        elif [[ -n "$clean_dir" ]]; then
            echo "  📁 /$clean_dir"
        fi
    done | head -8
    
    # 예상 복구 시간 계산 (대략적)
    local estimated_time_seconds
    estimated_time_seconds=$((backup_size / 50000000))  # 50MB/s 가정
    if [[ $estimated_time_seconds -lt 60 ]]; then
        echo "⏱️  예상 복구 시간: ~${estimated_time_seconds}초"
    else
        local estimated_minutes=$((estimated_time_seconds / 60))
        echo "⏱️  예상 복구 시간: ~${estimated_minutes}분"
    fi
    
    # 대상 경로 공간 확인
    echo ""
    echo "💾 저장 공간 확인:"
    local available_space
    available_space=$(get_available_space "$target_path")
    if (( available_space > backup_size )); then
        echo "✅ 충분한 저장 공간 ($(convert_size "$available_space") 사용 가능)"
    else
        echo "⚠️  저장 공간 부족 ($(convert_size "$available_space") 사용 가능, $(convert_size "$backup_size") 필요)"
        return 1
    fi
    
    echo ""
    echo "✅ 문제없이 복구 가능합니다!"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 다음 단계 선택"  
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1️⃣  완전한 검증 (전체 시뮬레이션)"
    echo "   tarsync restore $(basename "$backup_dir") $target_path full-sim"
    echo "   💡 압축 해제 + rsync 시뮬레이션으로 정확한 검증"
    echo ""
    echo "2️⃣  바로 실제 복구 실행"
    echo "   tarsync restore $(basename "$backup_dir") $target_path confirm"
    echo "   ⚠️  실제로 파일이 복구됩니다 (신중하게 선택)"
    echo ""
    echo "3️⃣  다른 백업 선택"
    echo "   tarsync list                    # 다른 백업 목록 보기"
    echo "   tarsync restore [번호] $target_path   # 다른 백업으로 복구"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    return 0
}

# 복구 로그 생성
create_restore_log() {
    local work_dir="$1"
    local backup_name="$2"
    local target_path="$3"
    local dry_run="$4"
    local delete_mode="$5"
    
    local log_file="$work_dir/restore.log"
    
    cat > "$log_file" << EOF
# tarsync 복구 로그
==========================================

복구 시작: $(get_timestamp)
백업 이름: $backup_name
복구 대상: $target_path
시뮬레이션 모드: $dry_run
삭제 모드: $delete_mode

복구 완료: $(get_timestamp)
EOF
    
    echo "📜 복구 로그가 저장되었습니다: $log_file"
}

# 복구 초기화 및 모드 안내
initialize_restore() {
    local mode="$1"
    
    echo "🔄 tarsync 복구 시작..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 모드별 안내 메시지
    case "$mode" in
        "light"|"")
            echo "📱 모드: 경량 시뮬레이션 (기본값)"
            echo "💡 빠른 미리보기로 복구 가능성을 확인합니다"
            ;;
        "full-sim"|"verify")
            echo "🔍 모드: 전체 시뮬레이션"
            echo "💡 실제 복구 과정을 시뮬레이션하여 정확하게 검증합니다"
            ;;
        "confirm"|"execute")
            echo "⚠️  모드: 실제 복구 실행"
            echo "🚨 주의: 실제로 파일이 복구됩니다!"
            ;;
    esac
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 경량 복구 실행 (경량 시뮬레이션만)
light_restore() {
    local backup_name="$1"
    local target_path="$2"
    
    initialize_restore "light"
    
    # 1. 필수 도구 검증
    validate_required_tools
    echo ""
    
    # 2. 백업 선택 및 검증
    echo "🔍 백업 선택 중..."
    backup_name=$(select_backup "$backup_name")
    if [[ $? -ne 0 ]]; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 백업 선택됨: $backup_name"
    echo ""
    
    # 3. 복구 대상 경로 확인
    echo "🔍 복구 대상 확인 중..."
    target_path=$(validate_restore_target "$target_path")
    if [[ $? -ne 0 ]]; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 복구 대상: $target_path"
    echo ""
    
    # 4. 메타데이터 로드  
    local store_dir backup_dir
    store_dir=$(get_store_dir_path)
    backup_dir="$store_dir/$backup_name"
    
    echo "📄 메타데이터 로드 중..."
    if ! load_metadata "$backup_dir"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 백업 크기: $(convert_size "$META_SIZE")"
    echo "✅ 백업 날짜: $META_CREATED"
    echo "✅ 제외 경로: ${#META_EXCLUDE[@]}개"
    echo ""
    
    # 5. 경량 시뮬레이션 실행
    if ! light_simulation "$backup_dir" "$target_path"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    
    return 0
}

# 전체 시뮬레이션 복구 실행
full_sim_restore() {
    local backup_name="$1"
    local target_path="$2"
    local delete_mode="$3"
    
    initialize_restore "full-sim"
    
    # 공통 준비 작업 실행
    if ! prepare_restore_common "$backup_name" "$target_path"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    
    # 전체 시뮬레이션 로직 실행
    execute_restore_process "$backup_name" "$target_path" "true" "$delete_mode"
}

# 실제 복구 실행
execute_restore() {
    local backup_name="$1"
    local target_path="$2"
    local delete_mode="$3"
    
    initialize_restore "confirm"
    
    # 공통 준비 작업 실행
    if ! prepare_restore_common "$backup_name" "$target_path"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    
    # 실제 복구 로직 실행
    execute_restore_process "$backup_name" "$target_path" "false" "$delete_mode"
}

# 복구 공통 준비 작업
prepare_restore_common() {
    local backup_name="$1"
    local target_path="$2"
    
    # 1. 필수 도구 검증
    validate_required_tools
    echo ""
    
    # 2. 백업 선택 및 검증
    echo "🔍 백업 선택 중..."
    backup_name=$(select_backup "$backup_name")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    echo "✅ 백업 선택됨: $backup_name"
    echo ""
    
    # 3. 복구 대상 경로 확인
    echo "🔍 복구 대상 확인 중..."
    target_path=$(validate_restore_target "$target_path")
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    echo "✅ 복구 대상: $target_path"
    echo ""
    
    # 4. 메타데이터 로드  
    local store_dir backup_dir
    store_dir=$(get_store_dir_path)
    backup_dir="$store_dir/$backup_name"
    
    echo "📄 메타데이터 로드 중..."
    if ! load_metadata "$backup_dir"; then
        return 1
    fi
    echo "✅ 백업 크기: $(convert_size "$META_SIZE")"
    echo "✅ 백업 날짜: $META_CREATED"
    echo "✅ 제외 경로: ${#META_EXCLUDE[@]}개"
    echo ""
    
    # 전역 변수로 결과 반환 (서브셸 문제 해결)
    RESTORE_BACKUP_NAME="$backup_name"
    RESTORE_TARGET_PATH="$target_path"
    RESTORE_BACKUP_DIR="$backup_dir"
    
    return 0
}

# 복구 프로세스 실행 (전체 시뮬레이션 또는 실제 복구)
execute_restore_process() {
    local backup_name="$1"
    local target_path="$2"
    local dry_run="$3"
    local delete_mode="$4"
    
    # prepare_restore_common에서 설정한 전역 변수 사용
    backup_name="$RESTORE_BACKUP_NAME"
    target_path="$RESTORE_TARGET_PATH"
    local backup_dir="$RESTORE_BACKUP_DIR"
    
    # 5. 복구 대상 용량 체크
    echo "🔍 복구 대상 용량 확인 중..."
    if ! check_disk_space "$target_path" "$META_SIZE"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 복구 대상 용량이 충분합니다."
    echo ""
    
    # 6. 작업 디렉토리 생성
    local work_dir
    work_dir=$(get_restore_work_dir_path "$backup_name")
    
    echo "📁 작업 디렉토리 생성 중..."
    create_restore_dir
    create_directory "$work_dir"
    echo "✅ 작업 디렉토리: $work_dir"
    echo ""
    
    # 7. tar 압축 해제
    if ! extract_backup "$backup_dir" "$work_dir"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo ""
    
    # 8. rsync 동기화 준비
    local extract_source_dir="$work_dir"
    
    # 압축 해제된 디렉토리 구조 확인
    local subdirs_count
    subdirs_count=$(find "$work_dir" -maxdepth 1 -type d ! -path "$work_dir" | wc -l)
    
    if [[ $subdirs_count -eq 1 ]]; then
        # 하나의 하위 디렉토리만 있는 경우 (특정 디렉토리 백업)
        local single_subdir
        single_subdir=$(find "$work_dir" -maxdepth 1 -type d ! -path "$work_dir" | head -1)
        extract_source_dir="$single_subdir"
        echo "📂 압축 해제된 디렉토리: $extract_source_dir" >&2
    else
        # 여러 하위 디렉토리가 있는 경우 (루트 백업)
        echo "📂 루트 백업 감지: 작업 디렉토리 전체를 복구 원본으로 사용" >&2
        echo "📂 압축 해제된 내용: $subdirs_count개 디렉토리/파일" >&2
    fi
    
    # 9. 제외 경로 옵션 생성
    local exclude_options=""
    for exclude_path in "${META_EXCLUDE[@]}"; do
        exclude_options="$exclude_options --exclude='$exclude_path'"
    done
    
    # 10. rsync 실행
    if ! execute_rsync "$extract_source_dir" "$target_path" "$dry_run" "$delete_mode" "$exclude_options"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo ""
    
    # 11. 복구 로그 생성
    create_restore_log "$work_dir" "$backup_name" "$target_path" "$dry_run" "$delete_mode"
    echo ""
    
    # 12. 복구 완료
    echo "🎉 복구가 완료되었습니다!"
    echo "📂 작업 디렉토리: $work_dir"
    echo "📂 복구 대상: $target_path"
    
    if [[ "$dry_run" == "true" ]]; then
        echo "⚠️  시뮬레이션 모드였으므로 실제 파일은 변경되지 않았습니다."
        echo "   실제 복구를 원한다면 'confirm' 모드로 다시 실행하세요."
    fi
    
    return 0
}

# 메인 복구 함수 (라우터 역할)
restore() {
    local backup_name="$1"
    local target_path="$2"
    local mode="${3:-light}"         # 기본값: 경량 시뮬레이션 모드
    local delete_mode="${4:-false}"  # 기본값: 삭제 안함
    
    # 모드별 적절한 함수 호출
    case "$mode" in
        "light"|"")
            light_restore "$backup_name" "$target_path"
            ;;
        "full-sim"|"verify")
            full_sim_restore "$backup_name" "$target_path" "$delete_mode"
            ;;
        "confirm"|"execute")
            execute_restore "$backup_name" "$target_path" "$delete_mode"
            ;;
        *)
            # 알 수 없는 모드는 경량 시뮬레이션으로 처리
            echo "⚠️  알 수 없는 모드: $mode. 경량 시뮬레이션으로 진행합니다."
            light_restore "$backup_name" "$target_path"
            ;;
    esac
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    restore "$@"
fi 