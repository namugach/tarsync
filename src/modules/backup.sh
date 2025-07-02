#!/bin/bash
# tarsync 백업 모듈
# 기존 Tarsync.backup() 메서드에서 변환됨

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 공통 유틸리티 로드
source "$(get_script_dir)/common.sh"

# 로그 파일 작성 여부를 사용자에게 묻기
prompt_log_creation() {
    local work_dir="$1"
    
    echo -n "📝 로그를 기록하시겠습니까? (Y/n): "
    read -r user_input
    
    # 기본값은 Y
    user_input=${user_input:-Y}
    
    if [[ "$user_input" =~ ^[Yy]$ ]]; then
        echo "📝 로그 파일을 생성합니다..."
        
        # 기본 로그 내용 생성
        cat > "$work_dir/log.md" << EOF
# Backup Log
- Date: $(date '+%Y-%m-%d')
- Time: $(date '+%H:%M:%S')
- Status: In Progress
- Created by: tarsync shell script

## Backup Details
- Source: $BACKUP_DISK
- Destination: $work_dir
- Exclude paths: $(get_exclude_paths | wc -l) paths

## Log
백업 시작: $(get_timestamp)
EOF
        
        # 사용자가 추가 로그를 편집할 수 있도록 에디터 열기
        if command -v vim >/dev/null 2>&1; then
            echo "📝 로그 파일 편집을 위해 vim을 엽니다..."
            echo "   (저장하고 종료: :wq, 편집 없이 종료: :q)"
            vim "$work_dir/log.md"
        elif command -v nano >/dev/null 2>&1; then
            echo "📝 로그 파일 편집을 위해 nano를 엽니다..."
            echo "   (저장하고 종료: Ctrl+X)"
            nano "$work_dir/log.md"
        else
            echo "⚠️  텍스트 에디터를 찾을 수 없습니다. 기본 로그만 생성됩니다."
        fi
        
        # 백업 완료 후 상태 업데이트
        sed -i 's/Status: In Progress/Status: Success/' "$work_dir/log.md"
        echo "백업 완료: $(get_timestamp)" >> "$work_dir/log.md"
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
            local log_file="$backup_dir/log.md"
            
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
    
    # 9. 백업 실행
    local exclude_options
    exclude_options=$(get_backup_tar_exclude_options)
    
    if execute_backup "$source_path" "$tar_file" "$exclude_options"; then
        echo ""
        
        # 10. 백업 결과 출력
        show_backup_result "$store_dir"
        
        echo ""
        echo "🎉 백업이 완료되었습니다!"
        echo "📂 백업 위치: $work_dir"
        
        return 0
    else
        echo ""
        echo "💥 백업에 실패했습니다!"
        
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