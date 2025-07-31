#!/bin/bash
# tarsync 복구 모듈 (단순화 버전)

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
    
    if [[ "$backup_number" =~ ^[0-9]+$ ]]; then
        local backup_list
        readarray -t backup_list < <(find "$store_dir" -maxdepth 1 -type d -name "2*" | sort -r | xargs -n 1 basename)
        
        local array_index=$((backup_number - 1))
        
        if [[ $array_index -ge 0 && $array_index -lt ${#backup_list[@]} ]]; then
            echo "${backup_list[$array_index]}"
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

# log.md에서 원본 소스 경로 추출
get_original_source_from_log() {
    local backup_dir="$1"
    local log_file="$backup_dir/log.md"

    if [[ -f "$log_file" ]]; then
        grep '^- Source:' "$log_file" | awk -F': ' '{print $2}' | tr -d '[:space:]'
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

# 최종 복구 확인
confirm_restore() {
    local backup_name="$1"
    local target_path="$2"

    echo ""
    echo "⚠️  최종 확인"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "선택된 백업의 내용을 다음 경로에 복구합니다."
    echo ""
    echo "  - 📦 백업: $backup_name"
    echo "  - 🎯 대상: $target_path"
    echo ""
    echo "이 작업은 대상 경로의 파일을 덮어쓸 수 있습니다."
    echo -n "정말로 복구를 진행하시겠습니까? (y/n): "
    read -r choice

    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo "👋 복구를 취소했습니다."
        return 1
    fi
    
    return 0
}

# tar 압축 해제
extract_backup() {
    local backup_dir="$1"
    local extract_dir="$2"
    local tar_file="$backup_dir/tarsync.tar.gz"
    
    echo "📦 백업 파일 압축 해제 중..."
    echo "   - 원본: $tar_file"
    echo "   - 대상: $extract_dir"
    
    if ! tar -xzf "$tar_file" -C "$extract_dir" --strip-components=0 --preserve-permissions; then
        echo "❌ 압축 해제에 실패했습니다."
        return 1
    fi
    
    echo "✅ 압축 해제 완료."
    return 0
}

# rsync 동기화 실행
execute_rsync() {
    local source_dir="$1"
    local target_dir="$2"
    local exclude_options="$3"
    
    local rsync_options="-avhP --stats"
    
    echo ""
    echo "🔄 rsync로 파일 동기화 시작..."
    echo "   - 원본: $source_dir/"
    echo "   - 대상: $target_dir/"
    
    if ! rsync $rsync_options $exclude_options "$source_dir/" "$target_dir/"; then
        echo "❌ 파일 동기화에 실패했습니다."
        return 1
    fi
    
    echo "✅ 동기화 완료."
    return 0
}

# 메인 복구 함수
restore() {
    local backup_name="$1"
    local target_path="$2"

    echo "🔄 tarsync 복구를 시작합니다."
    echo ""

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
    if ! confirm_restore "$backup_name" "$target_path"; then
        exit 1
    fi
    echo ""

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
    local exclude_options=""
    for exclude_path in "${META_EXCLUDE[@]}"; do
        exclude_options="$exclude_options --exclude='$exclude_path'"
    done

    if ! execute_rsync "$work_dir" "$target_path" "$exclude_options"; then
        rm -rf "$work_dir"
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo ""

    # 9. 정리
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