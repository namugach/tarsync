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

# 백업 선택 및 유효성 확인
select_backup() {
    local backup_name="$1"
    local store_dir
    store_dir=$(get_store_dir_path)
    
    if [[ -z "$backup_name" ]]; then
        show_backup_list
        echo "" >&2
        echo -n "복구할 백업을 선택하세요 (디렉토리 이름): " >&2
        read -r backup_name
    fi
    
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

# 메인 복구 함수
restore() {
    local backup_name="$1"
    local target_path="$2"
    local dry_run="${3:-true}"      # 기본값: 시뮬레이션 모드
    local delete_mode="${4:-false}" # 기본값: 삭제 안함
    
    echo "🔄 tarsync 복구 시작..."
    echo ""
    
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
    # 백업 원본이 루트(/) 전체인 경우 vs 특정 디렉토리인 경우를 구분
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
        echo "   실제 복구를 원한다면 세 번째 매개변수를 'false'로 설정하세요."
    fi
    
    return 0
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    restore "$@"
fi 