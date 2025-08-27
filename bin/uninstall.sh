#!/bin/bash

# ===== Tarsync 제거 도구 =====
# ===== Tarsync Uninstaller =====

# 유틸리티 모듈 로드
# Load utility modules
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/src/utils/colors.sh"
source "$PROJECT_ROOT/src/utils/log.sh"

# 언어 감지 및 메시지 시스템 로드
source "$PROJECT_ROOT/config/messages/detect.sh"
source "$PROJECT_ROOT/config/messages/load.sh"

# 메시지 시스템 초기화
load_tarsync_messages


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
        error_msg "MSG_INSTALL_SUDO_REQUIRED"
        msg "MSG_INSTALL_SUDO_HINT"
        exit 1
    fi
}

# tarsync 파일들 제거 (전역 설치)
# Remove tarsync files (Global installation)
remove_tarsync() {
    msg "MSG_UNINSTALL_START"
    
    # 실행파일 제거
    if [ -f "$INSTALL_DIR/tarsync" ]; then
        rm -f "$INSTALL_DIR/tarsync"
        msg "MSG_SYSTEM_REMOVING_FILE" "$INSTALL_DIR/tarsync"
    fi
    
    # 프로젝트 디렉토리 제거
    if [ -d "$PROJECT_DIR" ]; then
        rm -rf "$PROJECT_DIR"
        msg "MSG_SYSTEM_REMOVING_FILE" "$PROJECT_DIR"
    fi
    
    # 설정 디렉토리 제거
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        msg "MSG_SYSTEM_REMOVING_FILE" "$CONFIG_DIR"
    fi
    
    # 자동완성 파일들 제거
    if [ -f "$COMPLETION_DIR/tarsync" ]; then
        rm -f "$COMPLETION_DIR/tarsync"
        msg "MSG_SYSTEM_REMOVING_FILE" "$COMPLETION_DIR/tarsync"
    fi
    
    if [ -f "$ZSH_COMPLETION_DIR/_tarsync" ]; then
        rm -f "$ZSH_COMPLETION_DIR/_tarsync"
        msg "MSG_SYSTEM_REMOVING_FILE" "$ZSH_COMPLETION_DIR/_tarsync"
    fi
    
    success_msg "MSG_UNINSTALL_COMPLETE"
}

# PATH에서 tarsync 제거 (전역 설치에서는 불필요)
# Remove tarsync from PATH (Not needed for global installation)
remove_from_path() {
    msg "MSG_INSTALL_PATH_NOT_NEEDED"
}

# 자동완성 설정 제거 (전역 설치에서는 시스템 파일에서 이미 제거됨)
# Remove completion settings (Already removed from system files in global installation)
remove_completion_settings() {
    msg "MSG_INSTALL_COMPLETION_BASH_COMPLETE"
}

# 제거 확인 (전역 설치)
# Verify uninstallation (Global installation)
verify_uninstallation() {
    local issues=()
    
    # 실행파일 확인
    if [ -f "$INSTALL_DIR/tarsync" ]; then
        issues+=("$(msg MSG_INSTALL_SCRIPT_NOT_FOUND "$INSTALL_DIR/tarsync")")
    fi
    
    # 프로젝트 디렉토리 확인
    if [ -d "$PROJECT_DIR" ]; then
        issues+=("$(msg MSG_SYSTEM_DIRECTORY_EXISTS "$PROJECT_DIR")")
    fi
    
    # 설정 디렉토리 확인
    if [ -d "$CONFIG_DIR" ]; then
        issues+=("$(msg MSG_SYSTEM_DIRECTORY_EXISTS "$CONFIG_DIR")")
    fi
    
    # 자동완성 파일 확인
    if [ -f "$COMPLETION_DIR/tarsync" ]; then
        issues+=("$(msg MSG_SYSTEM_FILE_EXISTS "$COMPLETION_DIR/tarsync")")
    fi
    
    if [ -f "$ZSH_COMPLETION_DIR/_tarsync" ]; then
        issues+=("$(msg MSG_SYSTEM_FILE_EXISTS "$ZSH_COMPLETION_DIR/_tarsync")")
    fi
    
    if [ ${#issues[@]} -gt 0 ]; then
        warn_msg "MSG_UNINSTALL_ISSUES_FOUND"
        for issue in "${issues[@]}"; do
            echo "  • $issue"
        done
        echo ""
        msg "MSG_UNINSTALL_MANUAL_CLEANUP_NEEDED"
        return 1
    else
        success_msg "MSG_UNINSTALL_COMPLETE"
        return 0
    fi
}

# 사용자 확인 (전역 설치)
# User confirmation (Global installation)
confirm_uninstall() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          $(msg MSG_UNINSTALL_HEADER_TITLE)             ║${NC}"
    echo -e "${CYAN}║     $(msg MSG_INSTALL_HEADER_SUBTITLE)           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    warn_msg "MSG_UNINSTALL_ITEMS_TO_REMOVE"
    msg "MSG_INSTALL_LOCATION_EXECUTABLE" "$INSTALL_DIR/tarsync"
    msg "MSG_INSTALL_LOCATION_LIBRARY" "$PROJECT_DIR"
    msg "MSG_UNINSTALL_CONFIG_DIR" "$CONFIG_DIR"
    msg "MSG_INSTALL_LOCATION_BASH_COMPLETION" "$COMPLETION_DIR/tarsync"
    msg "MSG_INSTALL_LOCATION_ZSH_COMPLETION" "$ZSH_COMPLETION_DIR/_tarsync"
    echo ""
    
    printf "$(msg MSG_UNINSTALL_CONFIRM)"
    read -r confirmation
    
    if [[ $confirmation =~ ^[Yy]$ ]]; then
        return 0
    else
        msg "MSG_UNINSTALL_CANCELLED"
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
    msg "MSG_UNINSTALL_START"
    echo ""
    
    # 순차적 제거
    remove_tarsync || {
        error_msg "MSG_UNINSTALL_FAILED"
        exit 1
    }
    
    remove_from_path
    remove_completion_settings
    
    echo ""
    msg "MSG_INSTALL_VERIFYING"
    
    # 제거 확인
    if verify_uninstallation; then
        echo ""
        success_msg "MSG_UNINSTALL_COMPLETE"
        echo ""
        msg "MSG_UNINSTALL_RESTART_TERMINAL"
        echo ""
    else
        echo ""
        warn_msg "MSG_UNINSTALL_MANUAL_CLEANUP_NEEDED"
        exit 1
    fi
}

# 메인 함수 실행
# Execute main function
main 