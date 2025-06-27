#!/bin/bash
# tarsync 제거 스크립트
# 시스템에서 tarsync를 완전히 제거합니다

set -e  # 에러 발생시 스크립트 종료

# ===== 기본 설정 변수 =====
# ===== Basic Configuration Variables =====

# 스크립트 경로 설정 (설치 스크립트와 동일한 위치에 있음)  
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 유틸리티 로드
source "$PROJECT_ROOT/src/utils/colors.sh"

# 상수 정의
PROGRAM_NAME="tarsync"
VERSION="1.0.0"

# 설치 경로들
INSTALL_PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="$INSTALL_PREFIX/bin"
LIB_DIR="$INSTALL_PREFIX/lib/$PROGRAM_NAME"
COMPLETION_DIR="$INSTALL_PREFIX/share/bash-completion/completions"
ZSH_COMPLETION_DIR="$INSTALL_PREFIX/share/zsh/site-functions"

# 시스템 bash completion 디렉토리들
SYSTEM_COMPLETION_DIRS=(
    "/etc/bash_completion.d"
    "/usr/share/bash-completion/completions"
    "/usr/local/share/bash-completion/completions"
)

# 시스템 zsh completion 디렉토리들
SYSTEM_ZSH_COMPLETION_DIRS=(
    "/usr/share/zsh/site-functions"
    "/usr/local/share/zsh/site-functions"
    "${HOME}/.local/share/zsh/site-functions"
)

# ===== 레벨 1: 기본 유틸리티 함수 =====
# ===== Level 1: Basic Utility Functions =====

# 로그 함수들
log_info() {
    echo -e "${INFO}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${SUCCESS}✅ $1${NC}"
}

log_warn() {
    echo -e "${WARNING}⚠️  $1${NC}"
}

log_error() {
    echo -e "${ERROR}❌ $1${NC}" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${DIM}🔍 DEBUG: $1${NC}" >&2
    fi
}

# 파일 존재 확인 함수
check_file_exists() {
    [[ -f "$1" ]]
}

# 디렉토리 존재 확인 함수  
check_dir_exists() {
    [[ -d "$1" ]]
}

# 사용자가 root인지 확인
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "root 권한이 필요합니다. sudo를 사용해주세요."
        echo "   사용법: sudo $0"
        exit 1
    fi
}

# ===== 레벨 2: 설정 및 환경 관련 함수 =====
# ===== Level 2: Configuration and Environment Functions =====

# 백업 데이터 정보 수집
collect_backup_info() {
    if [[ -d "/mnt/backup" ]]; then
        local backup_count=$(find /mnt/backup -maxdepth 1 -name "*.tar.gz" 2>/dev/null | wc -l)
        local backup_size=$(du -sh /mnt/backup 2>/dev/null | cut -f1 || echo "알 수 없음")
        
        if [[ $backup_count -gt 0 ]]; then
            log_info "📦 백업 데이터 현황:"
            echo "   • 백업 개수: $backup_count개"
            echo "   • 전체 크기: $backup_size"
            echo "   • 저장 위치: /mnt/backup"
            echo ""
            log_warn "💡 백업 데이터는 제거되지 않습니다."
            echo "   백업 데이터를 삭제하려면 수동으로 제거하세요:"
            echo "   sudo rm -rf /mnt/backup"
            echo ""
        fi
    fi
}

# 제거 대상 백업 생성
create_removal_backup() {
    local backup_dir="/tmp/tarsync_removal_backup_$(date +%Y%m%d_%H%M%S)"
    local found_any=false
    
    log_info "제거 전 백업 생성 중..."
    
    # 제거할 파일들이 있는지 확인하고 백업
    [[ -f "$BIN_DIR/tarsync" ]] && found_any=true
    [[ -d "$LIB_DIR" ]] && found_any=true
    
    if [[ "$found_any" == "true" ]]; then
        mkdir -p "$backup_dir"
        
        [[ -f "$BIN_DIR/tarsync" ]] && cp "$BIN_DIR/tarsync" "$backup_dir/" 2>/dev/null || true
        [[ -d "$LIB_DIR" ]] && cp -r "$LIB_DIR" "$backup_dir/" 2>/dev/null || true
        
        echo "$backup_dir" > /tmp/tarsync_removal_backup_path
        log_success "제거 대상을 $backup_dir 에 백업했습니다."
        return 0
    fi
    
    return 1
}

# 백업 복원 (제거 실패시 사용)
restore_removal_backup() {
    local backup_path="/tmp/tarsync_removal_backup_path"
    if [[ -f "$backup_path" ]]; then
        local backup_dir=$(cat "$backup_path")
        if [[ -d "$backup_dir" ]]; then
            log_info "제거 실패로 인한 백업 복원 중..."
            [[ -f "$backup_dir/tarsync" ]] && cp "$backup_dir/tarsync" "$BIN_DIR/" 2>/dev/null || true
            [[ -d "$backup_dir/tarsync" ]] && cp -r "$backup_dir/tarsync" "$(dirname "$LIB_DIR")/" 2>/dev/null || true
            log_success "백업이 복원되었습니다."
        fi
    fi
}

# 백업 정리
cleanup_removal_backup() {
    local backup_path="/tmp/tarsync_removal_backup_path"
    if [[ -f "$backup_path" ]]; then
        local backup_dir=$(cat "$backup_path")
        if [[ -d "$backup_dir" ]]; then
            rm -rf "$backup_dir"
            rm -f "$backup_path"
            log_debug "제거 백업 파일이 정리되었습니다."
        fi
    fi
}

# ===== 레벨 3: 의존성 및 환경 검사 함수 =====
# ===== Level 3: Dependency and Environment Check Functions =====

# 설치 상태 확인
check_installation_status() {
    local installed=false
    local found_files=()
    
    log_info "설치 상태 확인 중..."
    
    # 실행파일 확인
    if [[ -f "$BIN_DIR/tarsync" ]]; then
        found_files+=("실행파일: $BIN_DIR/tarsync")
        installed=true
    fi
    
    # 라이브러리 디렉토리 확인
    if [[ -d "$LIB_DIR" ]]; then
        found_files+=("라이브러리: $LIB_DIR")
        installed=true
    fi
    
    # Bash 자동완성 파일 확인 (모든 가능한 위치)
    for dir in "$COMPLETION_DIR" "${SYSTEM_COMPLETION_DIRS[@]}"; do
        if [[ -f "$dir/tarsync" ]]; then
            found_files+=("Bash 자동완성: $dir/tarsync")
            break
        fi
    done
    
    # ZSH 자동완성 파일 확인 (모든 가능한 위치)
    for dir in "$ZSH_COMPLETION_DIR" "${SYSTEM_ZSH_COMPLETION_DIRS[@]}"; do
        if [[ -f "$dir/_tarsync" ]]; then
            found_files+=("ZSH 자동완성: $dir/_tarsync")
            break
        fi
    done
    
    if [[ "$installed" == false ]]; then
        log_warn "$PROGRAM_NAME이 설치되어 있지 않습니다."
        echo ""
        log_info "💡 다음 위치에서 확인했습니다:"
        echo "   • $BIN_DIR/tarsync"
        echo "   • $LIB_DIR/"
        echo "   • $COMPLETION_DIR/tarsync"
        echo "   • $ZSH_COMPLETION_DIR/_tarsync"
        for dir in "${SYSTEM_COMPLETION_DIRS[@]}"; do
            echo "   • $dir/tarsync"
        done
        for dir in "${SYSTEM_ZSH_COMPLETION_DIRS[@]}"; do
            echo "   • $dir/_tarsync"
        done
        exit 0
    fi
    
    log_success "다음 설치된 파일들을 찾았습니다:"
    for file in "${found_files[@]}"; do
        echo "   • $file"
    done
    echo ""
    
    return 0
}

# 사용자 확인
confirm_removal() {
    echo ""
    log_warn "정말로 $PROGRAM_NAME을 제거하시겠습니까?"
    echo -e "${ERROR}🗑️  이 작업은 되돌릴 수 없습니다!${NC}"
    echo ""
    
    read -p "제거하려면 'yes'를 입력하세요: " -r
    if [[ ! $REPLY == "yes" ]]; then
        log_info "✋ 제거가 취소되었습니다."
        exit 0
    fi
    
    echo ""
    log_info "🚀 제거를 시작합니다..."
    echo ""
}

# ===== 레벨 4: 제거 단계별 작업 함수 =====
# ===== Level 4: Removal Step Functions =====

# 실행파일 제거
remove_executable() {
    if [[ -f "$BIN_DIR/tarsync" ]]; then
        rm -f "$BIN_DIR/tarsync"
        log_success "실행파일 삭제: $BIN_DIR/tarsync"
        return 0
    fi
    return 1
}

# 라이브러리 제거
remove_library() {
    if [[ -d "$LIB_DIR" ]]; then
        rm -rf "$LIB_DIR"
        log_success "라이브러리 삭제: $LIB_DIR"
        return 0
    fi
    return 1
}

# Bash 자동완성 제거
remove_bash_completion() {
    local removed=false
    
    for dir in "$COMPLETION_DIR" "${SYSTEM_COMPLETION_DIRS[@]}"; do
        if [[ -f "$dir/tarsync" ]]; then
            rm -f "$dir/tarsync"
            log_success "Bash 자동완성 삭제: $dir/tarsync"
            removed=true
        fi
        
        # 공통 파일도 제거
        if [[ -f "$dir/completion-common.sh" ]]; then
            rm -f "$dir/completion-common.sh"
            log_success "Bash 공통 함수 삭제: $dir/completion-common.sh"
        fi
    done
    
    [[ "$removed" == "true" ]]
}

# ZSH 자동완성 제거
remove_zsh_completion() {
    local removed=false
    
    for dir in "$ZSH_COMPLETION_DIR" "${SYSTEM_ZSH_COMPLETION_DIRS[@]}"; do
        if [[ -f "$dir/_tarsync" ]]; then
            rm -f "$dir/_tarsync"
            log_success "ZSH 자동완성 삭제: $dir/_tarsync"
            removed=true
        fi
        
        # 공통 파일도 제거
        if [[ -f "$dir/completion-common.sh" ]]; then
            rm -f "$dir/completion-common.sh"
            log_success "ZSH 공통 함수 삭제: $dir/completion-common.sh"
        fi
    done
    
    [[ "$removed" == "true" ]]
}

# hash 테이블 정리
clear_command_cache() {
    log_info "명령어 캐시 정리 중..."
    
    # bash의 명령어 해시 테이블에서 tarsync 제거
    hash -d tarsync 2>/dev/null || true
    
    log_success "명령어 캐시 정리 완료"
}

# ===== 레벨 5: 중간 레벨 통합 함수 =====
# ===== Level 5: Mid-level Integration Functions =====

# 모든 파일 제거
remove_all_files() {
    local removed_count=0
    
    log_info "파일 제거 중..."
    
    remove_executable && ((removed_count++))
    remove_library && ((removed_count++))
    remove_bash_completion && ((removed_count++))
    remove_zsh_completion && ((removed_count++))
    
    if [[ $removed_count -eq 0 ]]; then
        log_warn "제거할 파일을 찾지 못했습니다."
        return 1
    else
        log_success "총 $removed_count개 항목이 제거되었습니다."
        return 0
    fi
}

# 제거 검증
verify_removal() {
    log_info "제거 검증 중..."
    
    local remaining_files=()
    
    [[ -f "$BIN_DIR/tarsync" ]] && remaining_files+=("$BIN_DIR/tarsync")
    [[ -d "$LIB_DIR" ]] && remaining_files+=("$LIB_DIR")
    
    # 자동완성 파일 확인
    for dir in "$COMPLETION_DIR" "${SYSTEM_COMPLETION_DIRS[@]}"; do
        [[ -f "$dir/tarsync" ]] && remaining_files+=("$dir/tarsync")
    done
    
    for dir in "$ZSH_COMPLETION_DIR" "${SYSTEM_ZSH_COMPLETION_DIRS[@]}"; do
        [[ -f "$dir/_tarsync" ]] && remaining_files+=("$dir/_tarsync")
    done
    
    if [[ ${#remaining_files[@]} -gt 0 ]]; then
        log_warn "일부 파일이 제거되지 않았습니다:"
        for file in "${remaining_files[@]}"; do
            echo "   • $file"
        done
        return 1
    fi
    
    log_success "모든 파일이 성공적으로 제거되었습니다."
    return 0
}

# ===== 레벨 6: 프로젝트 제거 함수 =====
# ===== Level 6: Project Removal Functions =====

# 안전한 제거 수행
perform_safe_removal() {
    log_info "안전한 제거 진행 중..."
    
    # 백업 생성
    if create_removal_backup; then
        log_debug "제거 전 백업이 생성되었습니다."
    fi
    
    # 실제 제거 시도
    if remove_all_files && clear_command_cache; then
        # 제거 성공 - 백업 정리
        cleanup_removal_backup
        return 0
    else
        # 제거 실패 - 백업 복원
        log_error "제거 중 오류가 발생했습니다. 백업을 복원합니다..."
        restore_removal_backup
        return 1
    fi
}

# 제거 완료 메시지
show_removal_success() {
    echo ""
    log_success "$PROGRAM_NAME 제거 완료!"
    echo ""
    echo -e "${INFO}📋 후속 작업:${NC}"
    echo "   1. 현재 터미널 세션에서 tarsync 명령어가 여전히 작동할 수 있습니다."
    echo "   2. 새 터미널을 열어서 완전한 제거를 확인하세요."
    echo "   3. 자동완성이 여전히 작동한다면 다음 명령어를 실행하세요:"
    echo "      hash -r"
    echo ""
    echo -e "${INFO}💾 백업 데이터는 그대로 유지됩니다:${NC}"
    echo "   • 백업 파일들: /mnt/backup/*.tar.gz"
    echo "   • 메타데이터: /mnt/backup/*.sh"
    echo ""
    echo -e "${HIGHLIGHT}🔄 재설치하려면:${NC}"
    echo "   sudo $(dirname "$0")/install.sh"
    echo ""
}

# ===== 레벨 7: 메인 제거 프로세스 =====
# ===== Level 7: Main Removal Process =====

# 메인 제거 프로세스
main() {
    echo -e "${HIGHLIGHT}╔════════════════════════════════════════╗${NC}"
    echo -e "${HIGHLIGHT}║          TARSYNC 제거 도구             ║${NC}"
    echo -e "${HIGHLIGHT}║      Shell Script 백업 시스템          ║${NC}"
    echo -e "${HIGHLIGHT}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # 1. 기본 확인
    check_root
    
    # 2. 설치 상태 확인
    check_installation_status
    
    # 3. 백업 데이터 정보 표시
    collect_backup_info
    
    # 4. 사용자 확인
    confirm_removal
    
    # 5. 안전한 제거 수행
    if perform_safe_removal; then
        # 6. 제거 검증
        if verify_removal; then
            show_removal_success
        else
            log_warn "제거는 완료되었지만 일부 파일이 남아있을 수 있습니다."
            show_removal_success
        fi
    else
        log_error "제거에 실패했습니다."
        exit 1
    fi
}

# 스크립트 직접 실행시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 