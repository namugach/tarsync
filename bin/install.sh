#!/bin/bash
# tarsync 설치 스크립트
# 시스템에 tarsync를 설치하고 자동완성 기능을 추가합니다

set -e  # 에러 발생시 스크립트 종료

# ===== 기본 설정 변수 =====
# ===== Basic Configuration Variables =====

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 유틸리티 로드
source "$PROJECT_ROOT/src/utils/colors.sh"

# 설치 디렉토리
PROGRAM_NAME="tarsync"
VERSION="1.0.0"
INSTALL_PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="$INSTALL_PREFIX/bin"
LIB_DIR="$INSTALL_PREFIX/lib/$PROGRAM_NAME"
COMPLETION_DIR="$INSTALL_PREFIX/share/bash-completion/completions"
ZSH_COMPLETION_DIR="$INSTALL_PREFIX/share/zsh/site-functions"

# 시스템 bash completion 디렉토리들 (fallback)
SYSTEM_COMPLETION_DIRS=(
    "/etc/bash_completion.d"
    "/usr/share/bash-completion/completions" 
    "/usr/local/share/bash-completion/completions"
)

# 시스템 zsh completion 디렉토리들 (fallback)
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

# 명령어 존재 확인 함수
check_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 디렉토리 생성 함수
create_dir_if_not_exists() {
    [[ -d "$1" ]] || mkdir -p "$1"
}

# 권한 확인 함수
check_write_permission() {
    [[ -w "$1" ]]
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

# 기존 설정 백업
backup_existing_settings() {
    local backup_dir="/tmp/tarsync_backup_$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$BIN_DIR/tarsync" ]] || [[ -d "$LIB_DIR" ]]; then
        log_info "기존 설치 백업 중..."
        create_dir_if_not_exists "$backup_dir"
        
        [[ -f "$BIN_DIR/tarsync" ]] && cp "$BIN_DIR/tarsync" "$backup_dir/"
        [[ -d "$LIB_DIR" ]] && cp -r "$LIB_DIR" "$backup_dir/"
        
        echo "$backup_dir" > /tmp/tarsync_backup_path
        log_success "기존 설치를 $backup_dir 에 백업했습니다."
    fi
}

# 백업 복원
restore_backup() {
    local backup_path="/tmp/tarsync_backup_path"
    if [[ -f "$backup_path" ]]; then
        local backup_dir=$(cat "$backup_path")
        if [[ -d "$backup_dir" ]]; then
            log_info "백업 복원 중..."
            [[ -f "$backup_dir/tarsync" ]] && cp "$backup_dir/tarsync" "$BIN_DIR/"
            [[ -d "$backup_dir/tarsync" ]] && cp -r "$backup_dir/tarsync" "$LIB_DIR"
            log_success "백업이 복원되었습니다."
        fi
    fi
}

# 백업 정리
cleanup_backup() {
    local backup_path="/tmp/tarsync_backup_path"
    if [[ -f "$backup_path" ]]; then
        local backup_dir=$(cat "$backup_path")
        if [[ -d "$backup_dir" ]]; then
            rm -rf "$backup_dir"
            rm -f "$backup_path"
            log_debug "백업 파일이 정리되었습니다."
        fi
    fi
}

# ===== 레벨 3: 의존성 및 환경 검사 함수 =====
# ===== Level 3: Dependency and Environment Check Functions =====

# 필수 명령어 확인
check_dependencies() {
    local deps=("tar" "gzip" "rsync" "pv" "bc")
    local missing=()
    
    log_info "필수 의존성 확인 중..."
    
    for dep in "${deps[@]}"; do
        if ! check_command_exists "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "누락된 의존성: ${missing[*]}"
        log_info "다음 명령어로 설치하세요:"
        echo "   Ubuntu/Debian: sudo apt install ${missing[*]}"
        echo "   CentOS/RHEL: sudo yum install ${missing[*]}"
        echo "   Arch Linux: sudo pacman -S ${missing[*]}"
        exit 1
    fi
    
    log_success "모든 의존성이 충족되었습니다."
}

# 기존 설치 확인
check_existing_installation() {
    local found_files=()
    
    log_info "기존 설치 확인 중..."
    
    [[ -f "$BIN_DIR/tarsync" ]] && found_files+=("실행파일: $BIN_DIR/tarsync")
    [[ -d "$LIB_DIR" ]] && found_files+=("라이브러리: $LIB_DIR")
    
    # 자동완성 파일들 확인
    for dir in "$COMPLETION_DIR" "${SYSTEM_COMPLETION_DIRS[@]}"; do
        if [[ -f "$dir/tarsync" ]]; then
            found_files+=("Bash 자동완성: $dir/tarsync")
            break
        fi
    done
    
    for dir in "$ZSH_COMPLETION_DIR" "${SYSTEM_ZSH_COMPLETION_DIRS[@]}"; do
        if [[ -f "$dir/_tarsync" ]]; then
            found_files+=("ZSH 자동완성: $dir/_tarsync")
            break
        fi
    done
    
    if [[ ${#found_files[@]} -gt 0 ]]; then
        log_warn "$PROGRAM_NAME이 이미 설치되어 있습니다:"
        for file in "${found_files[@]}"; do
            echo "   • $file"
        done
        echo ""
        
        read -p "기존 설치를 덮어쓰시겠습니까? [Y/n]: " -r
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_info "설치가 취소되었습니다."
            exit 0
        fi
        
        return 0
    fi
    
    log_success "새로운 설치를 진행합니다."
}

# 디렉토리 권한 체크
check_directory_permissions() {
    log_info "디렉토리 권한 확인 중..."
    
    # 상위 디렉토리들 확인
    local dirs_to_check=("$(dirname "$BIN_DIR")" "$(dirname "$LIB_DIR")")
    
    for dir in "${dirs_to_check[@]}"; do
        if [[ -d "$dir" ]] && ! check_write_permission "$dir"; then
            log_error "$dir 디렉토리에 쓰기 권한이 없습니다."
            log_info "sudo를 사용해서 다시 실행해주세요."
            exit 1
        fi
    done
    
    log_success "디렉토리 권한이 충분합니다."
}

# ===== 레벨 4: 설치 단계별 작업 함수 =====
# ===== Level 4: Installation Step Functions =====

# 설치 디렉토리 생성
create_installation_directories() {
    log_info "설치 디렉토리 생성 중..."
    
    create_dir_if_not_exists "$BIN_DIR"
    create_dir_if_not_exists "$LIB_DIR"
    
    # 자동완성 디렉토리 생성 (가능한 곳에)
    if ! create_dir_if_not_exists "$COMPLETION_DIR" 2>/dev/null; then
        for dir in "${SYSTEM_COMPLETION_DIRS[@]}"; do
            if [[ -d "$(dirname "$dir")" ]]; then
                COMPLETION_DIR="$dir"
                create_dir_if_not_exists "$COMPLETION_DIR" 2>/dev/null && break
            fi
        done
    fi
    
    if ! create_dir_if_not_exists "$ZSH_COMPLETION_DIR" 2>/dev/null; then
        for dir in "${SYSTEM_ZSH_COMPLETION_DIRS[@]}"; do
            if [[ -d "$(dirname "$dir")" ]]; then
                ZSH_COMPLETION_DIR="$dir"
                create_dir_if_not_exists "$ZSH_COMPLETION_DIR" 2>/dev/null && break
            fi
        done
    fi
    
    log_success "디렉토리 생성 완료"
    log_debug "실행파일: $BIN_DIR"
    log_debug "라이브러리: $LIB_DIR"
    log_debug "Bash 자동완성: $COMPLETION_DIR"
    log_debug "ZSH 자동완성: $ZSH_COMPLETION_DIR"
}

# 프로젝트 파일 복사
copy_project_files() {
    log_info "파일 복사 중..."
    
    # 메인 실행 파일 복사 및 경로 수정
    cp "$PROJECT_ROOT/bin/tarsync.sh" "$BIN_DIR/tarsync"
    chmod +x "$BIN_DIR/tarsync"
    
    # 설치된 tarsync 스크립트의 경로를 수정
    sed -i "s|PROJECT_ROOT=\"\$(dirname \"\$SCRIPT_DIR\")\"|PROJECT_ROOT=\"$LIB_DIR\"|g" "$BIN_DIR/tarsync"
    
    # 모든 소스 파일 복사
    cp -r "$PROJECT_ROOT/src" "$LIB_DIR/"
    cp -r "$PROJECT_ROOT/config" "$LIB_DIR/"
    
    # 소스 파일들에 실행 권한 부여
    find "$LIB_DIR" -name "*.sh" -exec chmod +x {} \;
    
    log_success "파일 복사 완료"
}

# Bash 자동완성 스크립트 생성
create_bash_completion() {
    log_info "Bash 자동완성 스크립트 생성 중..."
    
    # 공통 함수 복사
    cp "$PROJECT_ROOT/src/completion/completion-common.sh" "$COMPLETION_DIR/"
    chmod +r "$COMPLETION_DIR/completion-common.sh"
    
    # Bash 자동완성 복사 및 설정
    cp "$PROJECT_ROOT/src/completion/bash.sh" "$COMPLETION_DIR/tarsync"
    chmod +r "$COMPLETION_DIR/tarsync"
    
    log_success "고급 Bash 자동완성 스크립트 생성 완료"
    log_info "💡 설명 모드를 활성화하려면: export TARSYNC_SHOW_HELP=true"
}

# ZSH 자동완성 스크립트 생성
create_zsh_completion() {
    log_info "ZSH 자동완성 스크립트 생성 중..."
    
    # 공통 함수 복사 (ZSH 디렉토리에도)
    cp "$PROJECT_ROOT/src/completion/completion-common.sh" "$ZSH_COMPLETION_DIR/"
    chmod +r "$ZSH_COMPLETION_DIR/completion-common.sh"
    
    # ZSH 자동완성 복사 및 설정
    cp "$PROJECT_ROOT/src/completion/zsh.sh" "$ZSH_COMPLETION_DIR/_tarsync"
    chmod +r "$ZSH_COMPLETION_DIR/_tarsync"
    
    log_success "고급 ZSH 자동완성 스크립트 생성 완료"
}

# ===== 레벨 5: 중간 레벨 통합 함수 =====
# ===== Level 5: Mid-level Integration Functions =====

# 자동완성 설치
install_completion() {
    log_info "자동완성 기능 설치 중..."
    
    create_bash_completion
    create_zsh_completion
    
    log_success "자동완성 기능 설치 완료"
}

# 설치 검증
verify_installation() {
    log_info "설치 검증 중..."
    
    local errors=0
    
    # 실행파일 확인
    if [[ ! -f "$BIN_DIR/tarsync" ]] || [[ ! -x "$BIN_DIR/tarsync" ]]; then
        log_error "실행파일이 올바르게 설치되지 않았습니다: $BIN_DIR/tarsync"
        ((errors++))
    fi
    
    # 라이브러리 확인
    if [[ ! -d "$LIB_DIR/src" ]] || [[ ! -d "$LIB_DIR/config" ]]; then
        log_error "라이브러리 파일들이 올바르게 설치되지 않았습니다: $LIB_DIR"
        ((errors++))
    fi
    
    # 자동완성 확인
    if [[ ! -f "$COMPLETION_DIR/tarsync" ]]; then
        log_warn "Bash 자동완성이 설치되지 않았습니다: $COMPLETION_DIR/tarsync"
    fi
    
    if [[ ! -f "$ZSH_COMPLETION_DIR/_tarsync" ]]; then
        log_warn "ZSH 자동완성이 설치되지 않았습니다: $ZSH_COMPLETION_DIR/_tarsync"
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "설치 검증에 실패했습니다. ($errors개 오류)"
        return 1
    fi
    
    log_success "설치 검증 완료"
    return 0
}

# ===== 레벨 6: 프로젝트 설치 함수 =====
# ===== Level 6: Project Installation Functions =====

# 안전한 설치 수행
perform_safe_installation() {
    log_info "안전한 설치 진행 중..."
    
    # 백업 생성
    backup_existing_settings
    
    # 실제 설치 시도
    if create_installation_directories && \
       copy_project_files && \
       install_completion && \
       verify_installation; then
        
        # 설치 성공 - 백업 정리
        cleanup_backup
        return 0
    else
        # 설치 실패 - 백업 복원
        log_error "설치 중 오류가 발생했습니다. 백업을 복원합니다..."
        restore_backup
        return 1
    fi
}

# 설치 완료 메시지
show_success_message() {
    echo ""
    log_success "$PROGRAM_NAME v$VERSION 설치 완료!"
    echo ""
    echo -e "${HIGHLIGHT}📍 설치 위치:${NC}"
    echo "   • 실행파일: $BIN_DIR/tarsync"
    echo "   • 라이브러리: $LIB_DIR"
    echo "   • Bash 자동완성: $COMPLETION_DIR/tarsync"
    echo "   • ZSH 자동완성: $ZSH_COMPLETION_DIR/_tarsync"
    echo ""
    echo -e "${INFO}🚀 사용 시작:${NC}"
    echo "   1. 새 터미널을 열거나 현재 터미널을 새로고침하세요"
    echo "   2. tarsync 명령어 사용:"
    echo "      tarsync help                    # 도움말"
    echo "      tarsync backup /home/user       # 백업"
    echo "      tarsync list                    # 목록"
    echo ""
    echo -e "${SUCCESS}💡 탭 키를 눌러서 자동완성 기능을 사용해보세요!${NC}"
    echo ""
    echo -e "${HIGHLIGHT}🎯 고급 자동완성 기능:${NC}"
    echo "   • 명령어별 컨텍스트 인식 자동완성"
    echo "   • 백업 파일 실시간 목록 및 메타데이터 표시"
    echo "   • ZSH: 각 옵션에 대한 설명 표시"
    echo "   • Bash: TARSYNC_SHOW_HELP=true로 설명 모드 활성화"
    echo "   • 캐시 기능으로 빠른 응답 속도"
    echo ""
    echo -e "${WARNING}📝 참고사항:${NC}"
    echo "   • 백업 저장소: /mnt/backup (자동 생성)"
    echo "   • 제거: sudo $(dirname "$0")/uninstall.sh"
    echo ""
}

# ===== 레벨 7: 메인 설치 프로세스 =====
# ===== Level 7: Main Installation Process =====

# 메인 설치 프로세스
main() {
    echo -e "${HIGHLIGHT}╔════════════════════════════════════════╗${NC}"
    echo -e "${HIGHLIGHT}║           TARSYNC 설치 도구            ║${NC}"
    echo -e "${HIGHLIGHT}║      Shell Script 백업 시스템          ║${NC}"
    echo -e "${HIGHLIGHT}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # 1. 기본 확인
    check_root
    check_dependencies
    check_directory_permissions
    
    # 2. 기존 설치 확인
    check_existing_installation
    
    # 3. 최종 확인
    echo ""
    log_info "다음 위치에 설치됩니다:"
    echo "   • 실행파일: $BIN_DIR/tarsync"
    echo "   • 라이브러리: $LIB_DIR"
    echo "   • 자동완성: $COMPLETION_DIR/tarsync, $ZSH_COMPLETION_DIR/_tarsync"
    echo ""
    read -p "설치를 계속하시겠습니까? [Y/n]: " -r
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        log_info "설치가 취소되었습니다."
        exit 0
    fi
    
    # 4. 안전한 설치 수행
    if perform_safe_installation; then
        show_success_message
    else
        log_error "설치에 실패했습니다."
        exit 1
    fi
}

# 스크립트 직접 실행시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 