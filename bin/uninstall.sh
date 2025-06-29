#!/bin/bash

# ===== Tarsync 제거 도구 =====
# ===== Tarsync Uninstaller =====

# 유틸리티 모듈 로드
# Load utility modules
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/src/utils/colors.sh"
source "$PROJECT_ROOT/src/utils/log.sh"


# 설치 경로 (전역 설치)
# Installation paths (Global installation)
PROJECT_DIR="/usr/share/tarsync"
INSTALL_DIR="/usr/local/bin"
COMPLETION_DIR="/etc/bash_completion.d"
ZSH_COMPLETION_DIR="/usr/share/zsh/site-functions"
CONFIG_DIR="/etc/tarsync"

# sudo 권한 체크
check_sudo_privileges() {
    if [ "$EUID" -ne 0 ]; then
        log_error "전역 제거를 위해서는 sudo 권한이 필요합니다"
        log_info "다음과 같이 실행해주세요: sudo ./bin/uninstall.sh"
        exit 1
    fi
}

# tarsync 파일들 제거 (전역 설치)
# Remove tarsync files (Global installation)
remove_tarsync() {
    log_info "tarsync 전역 설치 파일 제거 중..."
    
    # 실행파일 제거
    if [ -f "$INSTALL_DIR/tarsync" ]; then
        rm -f "$INSTALL_DIR/tarsync"
        log_info "실행파일이 제거되었습니다: $INSTALL_DIR/tarsync"
    fi
    
    # 프로젝트 디렉토리 제거
    if [ -d "$PROJECT_DIR" ]; then
        rm -rf "$PROJECT_DIR"
        log_info "프로젝트 디렉토리가 제거되었습니다: $PROJECT_DIR"
    fi
    
    # 설정 디렉토리 제거
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        log_info "설정 디렉토리가 제거되었습니다: $CONFIG_DIR"
    fi
    
    # 자동완성 파일들 제거
    if [ -f "$COMPLETION_DIR/tarsync" ]; then
        rm -f "$COMPLETION_DIR/tarsync"
        log_info "Bash 자동완성 파일이 제거되었습니다: $COMPLETION_DIR/tarsync"
    fi
    
    if [ -f "$ZSH_COMPLETION_DIR/_tarsync" ]; then
        rm -f "$ZSH_COMPLETION_DIR/_tarsync"
        log_info "ZSH 자동완성 파일이 제거되었습니다: $ZSH_COMPLETION_DIR/_tarsync"
    fi
    
    log_success "tarsync 전역 설치 파일들이 제거되었습니다"
}

# PATH에서 tarsync 제거 (전역 설치에서는 불필요)
# Remove tarsync from PATH (Not needed for global installation)
remove_from_path() {
    log_info "전역 설치에서는 PATH 수정이 필요하지 않습니다"
}

# 자동완성 설정 제거 (전역 설치에서는 시스템 파일에서 이미 제거됨)
# Remove completion settings (Already removed from system files in global installation)
remove_completion_settings() {
    log_info "전역 자동완성 파일들은 이미 제거되었습니다"
}

# 제거 확인 (전역 설치)
# Verify uninstallation (Global installation)
verify_uninstallation() {
    local issues=()
    
    # 실행파일 확인
    if [ -f "$INSTALL_DIR/tarsync" ]; then
        issues+=("tarsync 실행파일이 여전히 존재합니다: $INSTALL_DIR/tarsync")
    fi
    
    # 프로젝트 디렉토리 확인
    if [ -d "$PROJECT_DIR" ]; then
        issues+=("tarsync 프로젝트 디렉토리가 여전히 존재합니다: $PROJECT_DIR")
    fi
    
    # 설정 디렉토리 확인
    if [ -d "$CONFIG_DIR" ]; then
        issues+=("tarsync 설정 디렉토리가 여전히 존재합니다: $CONFIG_DIR")
    fi
    
    # 자동완성 파일 확인
    if [ -f "$COMPLETION_DIR/tarsync" ]; then
        issues+=("Bash 자동완성 파일이 여전히 존재합니다: $COMPLETION_DIR/tarsync")
    fi
    
    if [ -f "$ZSH_COMPLETION_DIR/_tarsync" ]; then
        issues+=("ZSH 자동완성 파일이 여전히 존재합니다: $ZSH_COMPLETION_DIR/_tarsync")
    fi
    
    if [ ${#issues[@]} -gt 0 ]; then
        log_warn "제거 과정에서 일부 문제가 발견되었습니다:"
        for issue in "${issues[@]}"; do
            echo "  • $issue"
        done
        echo ""
        log_info "수동으로 정리가 필요할 수 있습니다"
        return 1
    else
        log_success "tarsync가 완전히 제거되었습니다"
        return 0
    fi
}

# 사용자 확인 (전역 설치)
# User confirmation (Global installation)
confirm_uninstall() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          TARSYNC 제거 도구             ║${NC}"
    echo -e "${CYAN}║     Shell Script 백업 시스템           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    log_warn "다음 전역 설치 항목들이 제거됩니다:"
    echo "  • 실행파일: $INSTALL_DIR/tarsync"
    echo "  • 프로젝트 디렉토리: $PROJECT_DIR"
    echo "  • 설정 디렉토리: $CONFIG_DIR"
    echo "  • Bash 자동완성: $COMPLETION_DIR/tarsync"
    echo "  • ZSH 자동완성: $ZSH_COMPLETION_DIR/_tarsync"
    echo ""
    
    log_info "정말로 tarsync를 제거하시겠습니까? (y/N)"
    read -r confirmation
    
    if [[ $confirmation =~ ^[Yy]$ ]]; then
        return 0
    else
        log_info "제거가 취소되었습니다"
        exit 0
    fi
}

# 메인 제거 프로세스 (전역 설치)
# Main uninstall process (Global installation)
main() {
    # sudo 권한 체크
    check_sudo_privileges
    
    # 사용자 확인
    confirm_uninstall
    
    echo ""
    log_info "tarsync 전역 설치 제거를 시작합니다..."
    echo ""
    
    # 순차적 제거
    remove_tarsync || {
        log_error "tarsync 파일 제거에 실패했습니다"
        exit 1
    }
    
    remove_from_path
    remove_completion_settings
    
    echo ""
    log_info "제거 완료 확인 중..."
    
    # 제거 확인
    if verify_uninstallation; then
        echo ""
        log_success "🎉 tarsync 전역 설치 제거가 완료되었습니다!"
        echo ""
        log_info "💡 새 터미널을 열면 변경사항이 적용됩니다"
        echo ""
    else
        echo ""
        log_warn "제거가 완료되었지만 일부 수동 정리가 필요할 수 있습니다"
        exit 1
    fi
}

# 메인 함수 실행
# Execute main function
main 