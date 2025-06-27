#!/bin/bash

# ===== Tarsync 제거 도구 =====
# ===== Tarsync Uninstaller =====

# 유틸리티 모듈 로드
# Load utility modules
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/src/utils/colors.sh"
source "$PROJECT_ROOT/src/utils/log.sh"


# 설치 경로
# Installation paths
PROJECT_DIR="$HOME/.tarsync"
INSTALL_DIR="$HOME/.tarsync/bin"

# tarsync 디렉토리 제거
# Remove tarsync directory
remove_tarsync() {
    if [ -d "$PROJECT_DIR" ]; then
        log_info "tarsync 디렉토리 제거 중: $PROJECT_DIR"
        rm -rf "$PROJECT_DIR"
        
        if [ ! -d "$PROJECT_DIR" ]; then
            log_success "tarsync 디렉토리가 제거되었습니다"
        else
            log_error "tarsync 디렉토리 제거에 실패했습니다"
            return 1
        fi
    else
        log_info "tarsync 디렉토리가 없습니다: $PROJECT_DIR"
    fi
}

# PATH에서 tarsync 제거
# Remove tarsync from PATH
remove_from_path() {
    log_info "PATH에서 tarsync 경로 제거 중..."
    
    # .bashrc에서 제거
    if [ -f "$HOME/.bashrc" ]; then
        if grep -q "\.tarsync/bin" "$HOME/.bashrc"; then
            sed -i '/export PATH=".*\.tarsync\/bin/d' "$HOME/.bashrc"
            log_info "~/.bashrc에서 PATH 항목이 제거되었습니다"
        fi
    fi
    
    # .zshrc에서 제거
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "\.tarsync/bin" "$HOME/.zshrc"; then
            sed -i '/export PATH=".*\.tarsync\/bin/d' "$HOME/.zshrc"
            log_info "~/.zshrc에서 PATH 항목이 제거되었습니다"
        fi
    fi
}

# 자동완성 설정 제거
# Remove completion settings
remove_completion_settings() {
    log_info "자동완성 설정 제거 중..."
    
    # Bash 자동완성 제거
    if [ -f "$HOME/.bashrc" ]; then
        if grep -q "tarsync" "$HOME/.bashrc"; then
            sed -i '/# Tarsync completion/d' "$HOME/.bashrc"
            sed -i '/\.tarsync.*tarsync/d' "$HOME/.bashrc"
            log_info "~/.bashrc에서 Bash 자동완성이 제거되었습니다"
        fi
    fi
    
    # ZSH 자동완성 제거
    if [ -f "$HOME/.zshrc" ]; then
        if grep -q "tarsync" "$HOME/.zshrc"; then
            sed -i '/# Tarsync completion/d' "$HOME/.zshrc"
            sed -i '/# ZSH completion system/d' "$HOME/.zshrc"
            sed -i '/autoload -Uz compinit/d' "$HOME/.zshrc"
            sed -i '/compinit/d' "$HOME/.zshrc"
            sed -i '/# Tarsync completion path/d' "$HOME/.zshrc"
            sed -i '/fpath=.*\.tarsync/d' "$HOME/.zshrc"
            sed -i '/\.tarsync.*_tarsync/d' "$HOME/.zshrc"
            log_info "~/.zshrc에서 ZSH 자동완성이 제거되었습니다"
        fi
    fi
}

# 제거 확인
# Verify uninstallation
verify_uninstallation() {
    local issues=()
    
    # 디렉토리 확인
    if [ -d "$PROJECT_DIR" ]; then
        issues+=("tarsync 디렉토리가 여전히 존재합니다: $PROJECT_DIR")
    fi
    
    # PATH 확인
    if grep -q "\.tarsync/bin" "$HOME/.bashrc" 2>/dev/null; then
        issues+=("~/.bashrc에 tarsync PATH가 여전히 있습니다")
    fi
    
    if grep -q "\.tarsync/bin" "$HOME/.zshrc" 2>/dev/null; then
        issues+=("~/.zshrc에 tarsync PATH가 여전히 있습니다")
    fi
    
    # 자동완성 확인
    if grep -q "tarsync" "$HOME/.bashrc" 2>/dev/null; then
        issues+=("~/.bashrc에 tarsync 자동완성이 여전히 있습니다")
    fi
    
    if grep -q "tarsync" "$HOME/.zshrc" 2>/dev/null; then
        issues+=("~/.zshrc에 tarsync 자동완성이 여전히 있습니다")
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

# 사용자 확인
# User confirmation
confirm_uninstall() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          TARSYNC 제거 도구             ║${NC}"
    echo -e "${CYAN}║     Shell Script 백업 시스템           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    log_warn "다음 항목들이 제거됩니다:"
    echo "  • tarsync 설치 디렉토리: $PROJECT_DIR"
    echo "  • PATH 설정 (~/.bashrc, ~/.zshrc)"
    echo "  • 자동완성 설정 (~/.bashrc, ~/.zshrc)"
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

# 메인 제거 프로세스
# Main uninstall process
main() {
    # 사용자 확인
    confirm_uninstall
    
    echo ""
    log_info "tarsync 제거를 시작합니다..."
    echo ""
    
    # 순차적 제거
    remove_tarsync || {
        log_error "tarsync 디렉토리 제거에 실패했습니다"
        exit 1
    }
    
    remove_from_path
    remove_completion_settings
    
    echo ""
    log_info "제거 완료 확인 중..."
    
    # 제거 확인
    if verify_uninstallation; then
        echo ""
        log_success "🎉 tarsync 제거가 완료되었습니다!"
        echo ""
        log_info "💡 변경사항을 적용하려면 새 터미널을 열거나 다음 명령을 실행하세요:"
        echo "   source ~/.bashrc    # Bash 사용자"
        echo "   source ~/.zshrc     # ZSH 사용자"
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