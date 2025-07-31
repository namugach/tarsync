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
        # 배치 모드에서는 가장 최근 백업 자동 선택
        if [[ "$TARSYNC_BATCH_MODE" == "true" ]]; then
            local latest_backup
            latest_backup=$(ls -t "$store_dir" 2>/dev/null | grep -E "^2[0-9]{3}_" | head -1)
            if [[ -n "$latest_backup" ]]; then
                echo "🤖 배치 모드: 최신 백업 자동 선택 - $latest_backup" >&2
                backup_name="$latest_backup"
            else
                echo "❌ 배치 모드: 사용 가능한 백업이 없습니다." >&2
                return 1
            fi
        else
            show_backup_list
            echo "" >&2
            echo -n "복구할 백업을 선택하세요 (번호 또는 디렉토리 이름): " >&2
            read -r backup_name
        fi
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
        if [[ "$TARSYNC_BATCH_MODE" == "true" ]]; then
            # 배치 모드에서는 기본 경로 사용
            target_path="/tmp/tarsync_restore_$(date +%Y%m%d_%H%M%S)"
            echo "🤖 배치 모드: 기본 복구 경로 사용 - $target_path" >&2
        else
            echo -n "복구 대상 경로를 입력하세요 (예: /tmp/restore_test): " >&2
            read -r target_path
        fi
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

# tar 압축 해제 (성능 최적화)
extract_backup() {
    local backup_dir="$1"
    local extract_dir="$2"
    local tar_file="$backup_dir/tarsync.tar.gz"
    
    echo "📦 백업 파일 압축 해제 중..."
    echo "   원본: $tar_file"
    echo "   대상: $extract_dir"
    
    # 파일 크기 확인
    local file_size
    file_size=$(get_file_size "$tar_file")
    local size_gb=$((file_size / 1073741824))
    
    # 대용량 파일 처리 최적화
    local extract_command
    if [[ $size_gb -gt 5 ]]; then
        echo "💾 대용량 백업 감지 (${size_gb}GB) - 성능 최적화 모드"
        # 대용량 파일용 최적화: 병렬 압축 해제, 진행률 표시
        if command -v pv >/dev/null 2>&1; then
            extract_command="pv '$tar_file' | tar -xzf - -C '$extract_dir' --strip-components=0 --preserve-permissions"
        else
            extract_command="tar -xzf '$tar_file' -C '$extract_dir' --strip-components=0 --preserve-permissions --checkpoint=1000 --checkpoint-action=echo='Extracted %u files'"
        fi
    else
        # 일반 크기 파일
        extract_command="tar -xzf '$tar_file' -C '$extract_dir' --strip-components=0 --preserve-permissions"
    fi
    
    # 메모리 사용량 최적화 (배치 모드)
    if [[ "$TARSYNC_BATCH_MODE" == "true" ]]; then
        # 배치 모드에서는 메모리 효율적인 옵션 사용
        extract_command="$extract_command --no-same-owner"
    fi
    
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

# 위험도 평가 시스템
assess_restore_risk() {
    local target_path="$1"
    local backup_size="$2"
    local risk_score=0
    local risk_reasons=()
    
    # 1. 경로 위험도 평가
    case "$target_path" in
        "/"|"/root"|"/etc"|"/usr"|"/var"|"/bin"|"/sbin")
            risk_score=$((risk_score + 40))
            risk_reasons+=("시스템 중요 디렉토리 ($target_path)")
            ;;
        "/home"|"/opt"|"/srv")
            risk_score=$((risk_score + 20))
            risk_reasons+=("중요 사용자 디렉토리 ($target_path)")
            ;;
        "/tmp"|"/var/tmp")
            risk_score=$((risk_score + 5))
            risk_reasons+=("임시 디렉토리 ($target_path)")
            ;;
        *)
            if [[ "$target_path" =~ ^/home/[^/]+$ ]]; then
                risk_score=$((risk_score + 15))
                risk_reasons+=("사용자 홈 디렉토리 ($target_path)")
            elif [[ "$target_path" =~ ^/home ]]; then
                risk_score=$((risk_score + 10))
                risk_reasons+=("홈 디렉토리 하위 ($target_path)")
            else
                risk_score=$((risk_score + 5))
                risk_reasons+=("일반 디렉토리 ($target_path)")
            fi
            ;;
    esac
    
    # 2. 백업 크기 위험도 평가
    local size_gb=$((backup_size / 1073741824))  # GB 단위
    if [[ $size_gb -gt 50 ]]; then
        risk_score=$((risk_score + 30))
        risk_reasons+=("대용량 백업 (${size_gb}GB)")
    elif [[ $size_gb -gt 10 ]]; then
        risk_score=$((risk_score + 15))
        risk_reasons+=("중용량 백업 (${size_gb}GB)")
    fi
    
    # 3. 기존 파일 존재 여부 확인
    if [[ -d "$target_path" ]] && [[ -n "$(ls -A "$target_path" 2>/dev/null)" ]]; then
        risk_score=$((risk_score + 25))
        risk_reasons+=("기존 파일 덮어쓰기 위험")
    fi
    
    # 4. 권한 확인
    if [[ ! -w "$(dirname "$target_path")" ]]; then
        risk_score=$((risk_score + 10))
        risk_reasons+=("권한 부족 가능성")
    fi
    
    # 위험도 등급 결정
    local risk_level
    if [[ $risk_score -ge 80 ]]; then
        risk_level="CRITICAL"
    elif [[ $risk_score -ge 60 ]]; then
        risk_level="HIGH"
    elif [[ $risk_score -ge 40 ]]; then
        risk_level="MEDIUM"
    elif [[ $risk_score -ge 20 ]]; then
        risk_level="LOW"
    else
        risk_level="MINIMAL"
    fi
    
    # 결과 출력
    echo "🔍 복구 위험도 평가"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "위험도 점수: $risk_score/100"
    echo "위험도 등급: $risk_level"
    echo ""
    echo "위험 요소:"
    for reason in "${risk_reasons[@]}"; do
        echo "  ⚠️  $reason"
    done
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # 전역 변수로 결과 저장
    RISK_SCORE="$risk_score"
    RISK_LEVEL="$risk_level"
    
    return 0
}

# 위험도별 확인 절차
confirm_restore_operation() {
    local mode="$1"
    local target_path="$2"
    local risk_level="$3"
    local risk_score="$4"
    
    # 시뮬레이션 모드는 위험하지 않음
    if [[ "$mode" == "light" || "$mode" == "full-sim" ]]; then
        return 0
    fi
    
    # 강제 모드인 경우 확인 절차 생략
    if [[ "$TARSYNC_FORCE_MODE" == "true" ]]; then
        echo "⚠️  강제 모드: 안전장치 확인 절차를 생략합니다."
        echo "   대상: $target_path"
        echo "   위험도: $risk_score/100 ($risk_level)"
        echo ""
        return 0
    fi
    
    # 배치 모드인 경우 위험도에 따라 자동 결정
    if [[ "$TARSYNC_BATCH_MODE" == "true" ]]; then
        echo "🤖 배치 모드: 자동 확인 절차"
        echo "   대상: $target_path"
        echo "   위험도: $risk_score/100 ($risk_level)"
        
        case "$risk_level" in
            "CRITICAL"|"HIGH")
                echo "❌ 배치 모드에서는 위험도가 높은 작업을 수행할 수 없습니다."
                echo "   수동 모드로 실행하거나 --force 옵션을 사용하세요."
                return 1
                ;;
            *)
                echo "✅ 위험도가 낮아 자동으로 진행합니다."
                echo ""
                return 0
                ;;
        esac
    fi
    
    echo "⚠️  실제 복구 확인 절차"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    case "$risk_level" in
        "CRITICAL")
            echo "🚨 매우 위험한 복구 작업입니다!"
            echo "   대상: $target_path"
            echo "   위험도: $risk_score/100 ($risk_level)"
            echo ""
            echo "이 작업은 시스템에 심각한 영향을 줄 수 있습니다."
            echo "계속 진행하려면 'YES'를 정확히 입력하세요."
            echo -n "확인 입력: "
            read -r confirmation
            if [[ "$confirmation" != "YES" ]]; then
                echo "복구가 취소되었습니다."
                return 1
            fi
            ;;
        "HIGH")
            echo "⚠️  위험한 복구 작업입니다."
            echo "   대상: $target_path"
            echo "   위험도: $risk_score/100 ($risk_level)"
            echo ""
            echo "이 작업은 중요한 파일을 덮어쓸 수 있습니다."
            echo "계속 진행하시겠습니까? (yes/no)"
            echo -n "확인 입력: "
            read -r confirmation
            if [[ "$confirmation" != "yes" ]]; then
                echo "복구가 취소되었습니다."
                return 1
            fi
            ;;
        "MEDIUM"|"LOW")
            echo "ℹ️  복구 작업 확인"
            echo "   대상: $target_path"
            echo "   위험도: $risk_score/100 ($risk_level)"
            echo ""
            echo "계속 진행하시겠습니까? (y/n)"
            echo -n "확인 입력: "
            read -r confirmation
            if [[ "$confirmation" != "y" && "$confirmation" != "yes" ]]; then
                echo "복구가 취소되었습니다."
                return 1
            fi
            ;;
        "MINIMAL")
            echo "✅ 안전한 복구 작업입니다."
            echo "   대상: $target_path"
            echo "   위험도: $risk_score/100 ($risk_level)"
            echo ""
            echo "자동으로 진행합니다..."
            sleep 1
            ;;
    esac
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    return 0
}

# 복구 전 백업 생성 (롤백 준비)
create_rollback_backup() {
    local target_path="$1"
    local backup_name="$2"
    
    # 롤백 백업 생성 안함 옵션 체크
    if [[ "$TARSYNC_NO_ROLLBACK" == "true" ]]; then
        echo "💡 롤백 백업 생성을 건너뜁니다 (--no-rollback 옵션)."
        return 0
    fi
    
    # 대상 경로가 존재하고 비어있지 않은 경우에만 백업
    if [[ ! -d "$target_path" ]] || [[ -z "$(ls -A "$target_path" 2>/dev/null)" ]]; then
        echo "💡 대상 경로가 비어있어 롤백 백업을 건너뜁니다."
        return 0
    fi
    
    local rollback_dir="/tmp/tarsync_rollback_$(date +%Y%m%d_%H%M%S)"
    
    echo "🔄 롤백을 위한 기존 파일 백업 중..."
    echo "   원본: $target_path"
    echo "   백업: $rollback_dir"
    
    if mkdir -p "$rollback_dir" && cp -r "$target_path"/* "$rollback_dir/" 2>/dev/null; then
        echo "✅ 롤백 백업 완료: $rollback_dir"
        echo "💡 복구 실패 시 다음 명령어로 롤백 가능:"
        echo "   rm -rf $target_path/* && cp -r $rollback_dir/* $target_path/"
        
        # 전역 변수로 롤백 경로 저장
        ROLLBACK_DIR="$rollback_dir"
        return 0
    else
        echo "⚠️  롤백 백업 생성에 실패했습니다. 계속 진행하시겠습니까? (y/n)"
        echo -n "확인 입력: "
        read -r confirmation
        if [[ "$confirmation" != "y" && "$confirmation" != "yes" ]]; then
            echo "복구가 취소되었습니다."
            return 1
        fi
        return 0
    fi
}

# 복구 중단 감지 및 정리
setup_interrupt_handler() {
    local work_dir="$1"
    local rollback_dir="$2"
    
    # 중단 시그널 핸들러 설정
    trap 'handle_restore_interrupt "$work_dir" "$rollback_dir"' INT TERM
}

# 복구 중단 처리
handle_restore_interrupt() {
    local work_dir="$1"
    local rollback_dir="$2"
    
    echo ""
    echo "🚫 복구 작업이 중단되었습니다."
    
    if [[ -n "$rollback_dir" && -d "$rollback_dir" ]]; then
        echo "💡 롤백 백업이 준비되어 있습니다: $rollback_dir"
        echo "필요시 수동으로 롤백하세요."
    fi
    
    if [[ -n "$work_dir" && -d "$work_dir" ]]; then
        echo "🧹 작업 디렉토리 정리 중: $work_dir"
        rm -rf "$work_dir" 2>/dev/null || true
    fi
    
    echo "복구가 안전하게 중단되었습니다."
    exit 130
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

# 학습 모드 설명 출력
explain_step() {
    local step="$1"
    local description="$2"
    
    if [[ "$TARSYNC_EXPLAIN_MODE" == "true" ]]; then
        echo "🎓 학습 모드: $step"
        echo "   $description"
        echo ""
        if [[ "$TARSYNC_EXPLAIN_INTERACTIVE" == "true" ]]; then
            echo -n "   계속하려면 Enter를 누르세요..."
            read -r
        else
            sleep 2
        fi
        echo ""
    fi
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
            explain_step "경량 시뮬레이션이란?" "tar 파일 목록만 조회하여 백업 내용을 빠르게 확인하는 방식입니다. 실제 파일을 추출하지 않아 매우 빠르지만, rsync 동작은 시뮬레이션하지 않습니다."
            ;;
        "full-sim"|"verify")
            echo "🔍 모드: 전체 시뮬레이션"
            echo "💡 실제 복구 과정을 시뮬레이션하여 정확하게 검증합니다"
            explain_step "전체 시뮬레이션이란?" "실제 복구와 동일한 과정(압축 해제 + rsync --dry-run)을 수행하되, 파일을 실제로 덮어쓰지는 않습니다. 정확한 검증이 가능하지만 시간이 오래 걸립니다."
            ;;
        "confirm"|"execute")
            echo "⚠️  모드: 실제 복구 실행"
            echo "🚨 주의: 실제로 파일이 복구됩니다!"
            explain_step "실제 복구란?" "백업 파일을 압축 해제한 후 rsync로 대상 경로에 실제로 복사합니다. 기존 파일이 덮어써질 수 있으므로 주의가 필요합니다."
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
    explain_step "필수 도구 검증" "tarsync가 동작하기 위해 필요한 도구들(tar, gzip, rsync, pv, bc)이 설치되어 있는지 확인합니다."
    validate_required_tools
    echo ""
    
    # 2. 백업 선택 및 검증
    explain_step "백업 선택" "사용 가능한 백업 목록에서 복구할 백업을 선택합니다. 번호나 이름으로 지정할 수 있습니다."
    echo "🔍 백업 선택 중..."
    backup_name=$(select_backup "$backup_name")
    if [[ $? -ne 0 ]]; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 백업 선택됨: $backup_name"
    echo ""
    
    # 3. 복구 대상 경로 확인
    explain_step "복구 대상 경로 확인" "파일을 복구할 대상 경로를 확인하고, 해당 경로에 쓰기 권한이 있는지 검증합니다."
    echo "🔍 복구 대상 확인 중..."
    target_path=$(validate_restore_target "$target_path")
    if [[ $? -ne 0 ]]; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    echo "✅ 복구 대상: $target_path"
    echo ""
    
    # 4. 메타데이터 로드  
    explain_step "메타데이터 로드" "백업 파일의 메타데이터(크기, 생성일, 제외 경로 등)를 로드하여 복구 준비를 합니다."
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
    explain_step "경량 시뮬레이션 실행" "tar 파일의 목록을 조회하여 백업 내용, 파일 개수, 예상 복구 시간을 빠르게 분석합니다."
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
    
    # 안전장치 시스템 적용
    backup_name="$RESTORE_BACKUP_NAME"
    target_path="$RESTORE_TARGET_PATH"
    
    # 위험도 평가
    assess_restore_risk "$target_path" "$META_SIZE"
    
    # 확인 절차
    if ! confirm_restore_operation "confirm" "$target_path" "$RISK_LEVEL" "$RISK_SCORE"; then
        echo "❌ 복구를 중단합니다."
        exit 1
    fi
    
    # 롤백 백업 생성
    if ! create_rollback_backup "$target_path" "$backup_name"; then
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
    
    # 중단 핸들러 설정 (실제 복구인 경우에만)
    if [[ "$dry_run" == "false" ]]; then
        setup_interrupt_handler "" "$ROLLBACK_DIR"
    fi
    
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
    
    # 중단 핸들러 업데이트 (work_dir 포함)
    if [[ "$dry_run" == "false" ]]; then
        setup_interrupt_handler "$work_dir" "$ROLLBACK_DIR"
    fi
    
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