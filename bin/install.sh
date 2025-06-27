#!/bin/bash

# ===== Tarsync 설치 도구 =====
# ===== Tarsync Installer =====

# 유틸리티 모듈 로드
# Load utility modules
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/src/utils/colors.sh"
source "$PROJECT_ROOT/src/utils/log.sh"
source "$PROJECT_ROOT/src/utils/version.sh"

# 설치 디렉토리
# Installation directories
PROJECT_DIR="$HOME/.tarsync"
INSTALL_DIR="$HOME/.tarsync/bin"
COMPLETION_DIR="$HOME/.tarsync/completion/bash"
ZSH_COMPLETION_DIR="$HOME/.tarsync/completion/zsh"
CONFIG_DIR="$HOME/.tarsync/config"

# ===== 기본 유틸리티 함수 =====
# ===== Basic Utility Functions =====

check_file_exists() {
    [ -f "$1" ]
}

check_dir_exists() {
    [ -d "$1" ]
}

check_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

create_dir_if_not_exists() {
    [ -d "$1" ] || mkdir -p "$1"
}

# ===== 의존성 체크 =====
# ===== Dependency Check =====

# OS 감지 함수
detect_os() {
    local os_name="$(uname -s)"
    case "$os_name" in
        Linux*)
            if command -v apt >/dev/null 2>&1; then
                echo "ubuntu"
            elif command -v yum >/dev/null 2>&1; then
                echo "centos"
            elif command -v dnf >/dev/null 2>&1; then
                echo "fedora"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 패키지 설치 명령어 생성
get_install_command() {
    local os="$1"
    local missing_tools=("${@:2}")
    
    case "$os" in
        ubuntu)
            echo "sudo apt update && sudo apt install -y ${missing_tools[*]}"
            ;;
        centos)
            echo "sudo yum install -y ${missing_tools[*]}"
            ;;
        fedora)
            echo "sudo dnf install -y ${missing_tools[*]}"
            ;;
        macos)
            # macOS에서는 일부 도구가 기본 설치되어 있을 수 있음
            local brew_tools=()
            for tool in "${missing_tools[@]}"; do
                case "$tool" in
                    tar|gzip) continue ;; # macOS 기본 포함
                    *) brew_tools+=("$tool") ;;
                esac
            done
            if [ ${#brew_tools[@]} -gt 0 ]; then
                echo "brew install ${brew_tools[*]}"
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# 수동 설치 안내
show_manual_install_guide() {
    local missing_tools=("${@}")
    
    echo ""
    log_info "📋 수동 설치 안내:"
    echo "   Ubuntu/Debian: sudo apt install ${missing_tools[*]}"
    echo "   CentOS/RHEL:   sudo yum install ${missing_tools[*]}"
    echo "   Fedora:        sudo dnf install ${missing_tools[*]}"
    echo "   macOS:         brew install ${missing_tools[*]}"
    echo ""
}

# 자동 설치 실행
auto_install_dependencies() {
    local install_cmd="$1"
    
    log_info "의존성을 자동으로 설치합니다..."
    echo "   실행 명령어: $install_cmd"
    echo ""
    
    if eval "$install_cmd"; then
        log_success "✅ 의존성 설치가 완료되었습니다!"
        return 0
    else
        log_error "❌ 자동 설치에 실패했습니다"
        return 1
    fi
}

check_required_tools() {
    local required_tools=("tar" "gzip" "rsync" "pv" "bc")
    local missing_tools=()
    
    # 누락된 도구 확인
    for tool in "${required_tools[@]}"; do
        if ! check_command_exists "$tool"; then
            missing_tools+=("$tool")
        fi
    done
    
    # 모든 도구가 설치되어 있으면 종료
    if [ ${#missing_tools[@]} -eq 0 ]; then
        return 0
    fi
    
    # 누락된 도구 알림
    echo ""
    log_info "⚠️  다음 필수 도구들이 설치되지 않았습니다: ${missing_tools[*]}"
    
    # OS 감지
    local os_type=$(detect_os)
    local install_cmd=$(get_install_command "$os_type" "${missing_tools[@]}")
    
    # 자동 설치 가능한 경우
    if [ -n "$install_cmd" ]; then
        echo ""
        case "$os_type" in
            ubuntu|centos|fedora)
                log_info "🚀 Linux 시스템이 감지되었습니다 ($os_type)"
                ;;
            macos)
                log_info "🍎 macOS 시스템이 감지되었습니다"
                if ! command -v brew >/dev/null 2>&1; then
                    log_error "Homebrew가 설치되지 않았습니다"
                    log_info "Homebrew 설치: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
                    show_manual_install_guide "${missing_tools[@]}"
                    exit 1
                fi
                ;;
        esac
        
        echo ""
        log_info "자동으로 설치하시겠습니까? (Y/n): "
        read -r response
        response=${response:-Y}  # 기본값을 Y로 설정
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            if auto_install_dependencies "$install_cmd"; then
                # 설치 확인
                local still_missing=()
                for tool in "${missing_tools[@]}"; do
                    if ! check_command_exists "$tool"; then
                        still_missing+=("$tool")
                    fi
                done
                
                if [ ${#still_missing[@]} -gt 0 ]; then
                    log_error "일부 도구가 여전히 설치되지 않았습니다: ${still_missing[*]}"
                    show_manual_install_guide "${still_missing[@]}"
                    exit 1
                fi
            else
                show_manual_install_guide "${missing_tools[@]}"
                exit 1
            fi
        else
            show_manual_install_guide "${missing_tools[@]}"
            exit 1
        fi
    else
        # 자동 설치 불가능한 경우
        log_error "자동 설치를 지원하지 않는 시스템입니다 ($os_type)"
        show_manual_install_guide "${missing_tools[@]}"
        exit 1
    fi
}

check_minimal_requirements() {
    # Bash 버전 체크
    if [ -z "$BASH_VERSION" ]; then
        log_error "Bash 쉘이 필요합니다"
        exit 1
    fi
    
    # 홈 디렉토리 권한 체크
    if [ ! -w "$HOME" ]; then
        log_error "홈 디렉토리에 쓰기 권한이 없습니다: $HOME"
        exit 1
    fi
}

# ===== 설치 함수들 =====
# ===== Installation Functions =====

update_script_paths() {
    sed -i "s|PROJECT_ROOT=.*|PROJECT_ROOT=\"$PROJECT_DIR\"|" "$INSTALL_DIR/tarsync"
}

install_tarsync_script() {
    create_dir_if_not_exists "$INSTALL_DIR"
    
    cp "$PROJECT_ROOT/bin/tarsync.sh" "$INSTALL_DIR/tarsync"
    chmod +x "$INSTALL_DIR/tarsync"
    
    # VERSION 파일도 복사
    cp "$PROJECT_ROOT/bin/VERSION" "$INSTALL_DIR/VERSION"
    
    update_script_paths
    
    if check_file_exists "$INSTALL_DIR/tarsync" && [ -x "$INSTALL_DIR/tarsync" ]; then
        log_info "tarsync 스크립트가 설치되었습니다: $INSTALL_DIR/tarsync"
    else
        log_error "tarsync 스크립트 설치에 실패했습니다"
        return 1
    fi
    
    if check_file_exists "$INSTALL_DIR/VERSION"; then
        log_info "VERSION 파일이 설치되었습니다: $INSTALL_DIR/VERSION"
    else
        log_error "VERSION 파일 설치에 실패했습니다"
        return 1
    fi
}

copy_project_files() {
    create_dir_if_not_exists "$PROJECT_DIR/src"
    create_dir_if_not_exists "$PROJECT_DIR/config"
    
    cp -r "$PROJECT_ROOT/src/"* "$PROJECT_DIR/src/"
    cp -r "$PROJECT_ROOT/config/"* "$PROJECT_DIR/config/"
    
    # 기본 설정 파일 생성
    cat > "$PROJECT_DIR/config/settings.env" << 'EOF'
# tarsync 기본 설정
LANGUAGE=ko
BACKUP_DIR=/mnt/backup
LOG_LEVEL=info
EOF
    
    log_info "프로젝트 파일이 복사되었습니다"
}

install_completions() {
    # 자동완성 디렉토리 생성
    create_dir_if_not_exists "$COMPLETION_DIR"
    create_dir_if_not_exists "$ZSH_COMPLETION_DIR"
    
    # 자동완성 파일 복사
    cp "$PROJECT_ROOT/src/completion/bash.sh" "$COMPLETION_DIR/tarsync"
    chmod +x "$COMPLETION_DIR/tarsync"
    
    cp "$PROJECT_ROOT/src/completion/zsh.sh" "$ZSH_COMPLETION_DIR/_tarsync"
    chmod +x "$ZSH_COMPLETION_DIR/_tarsync"
    
    log_info "자동완성 파일이 설치되었습니다"
}

configure_bash_completion() {
    if check_file_exists "$HOME/.bashrc"; then
        if ! grep -q "source $COMPLETION_DIR/tarsync" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Tarsync completion" >> "$HOME/.bashrc"
            echo "[ -f $COMPLETION_DIR/tarsync ] && source $COMPLETION_DIR/tarsync" >> "$HOME/.bashrc"
            log_info "Bash 자동완성이 ~/.bashrc에 추가되었습니다"
        fi
    fi
}

configure_zsh_completion() {
    if check_file_exists "$HOME/.zshrc"; then
        if ! grep -q "autoload -Uz compinit" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# ZSH completion system" >> "$HOME/.zshrc"
            echo "autoload -Uz compinit" >> "$HOME/.zshrc"
            echo "compinit" >> "$HOME/.zshrc"
        fi
        
        if ! grep -q "fpath=.*$ZSH_COMPLETION_DIR" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Tarsync completion path" >> "$HOME/.zshrc"
            echo "fpath=($ZSH_COMPLETION_DIR \$fpath)" >> "$HOME/.zshrc"
        fi
        
        if ! grep -q "source $ZSH_COMPLETION_DIR/_tarsync" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Tarsync completion" >> "$HOME/.zshrc"
            echo "[ -f $ZSH_COMPLETION_DIR/_tarsync ] && source $ZSH_COMPLETION_DIR/_tarsync" >> "$HOME/.zshrc"
            log_info "ZSH 자동완성이 ~/.zshrc에 추가되었습니다"
        fi
    fi
}

update_path() {
    if check_file_exists "$HOME/.bashrc"; then
        if ! grep -q "$INSTALL_DIR" "$HOME/.bashrc"; then
            echo "" >> "$HOME/.bashrc"
            echo "# Tarsync PATH" >> "$HOME/.bashrc"
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.bashrc"
            log_info "PATH가 ~/.bashrc에 추가되었습니다"
        fi
    fi
    
    if check_file_exists "$HOME/.zshrc"; then
        if ! grep -q "$INSTALL_DIR" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Tarsync PATH" >> "$HOME/.zshrc"
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$HOME/.zshrc"
            log_info "PATH가 ~/.zshrc에 추가되었습니다"
        fi
    fi
}

# ===== 검증 함수 =====
# ===== Verification Functions =====

verify_installation() {
    if check_file_exists "$INSTALL_DIR/tarsync" && [ -x "$INSTALL_DIR/tarsync" ]; then
        show_success_message
    else
        log_error "tarsync 설치에 실패했습니다"
        log_error "tarsync 스크립트를 찾을 수 없습니다: $INSTALL_DIR/tarsync"
        exit 1
    fi
}

show_success_message() {
    # 버전 정보 가져오기 (버전 유틸리티 사용)
    local version=$(get_version)
    
    echo ""
    log_success "🎉 tarsync v$version 설치 완료!"
    echo ""
    log_info "📍 설치 위치:"
    echo "   • 실행파일: $INSTALL_DIR/tarsync"
    echo "   • 버전파일: $INSTALL_DIR/VERSION"
    echo "   • 라이브러리: $PROJECT_DIR"
    echo "   • Bash 자동완성: $COMPLETION_DIR/tarsync"
    echo "   • ZSH 자동완성: $ZSH_COMPLETION_DIR/_tarsync"
    echo ""
    log_info "🚀 사용 시작:"
    echo "   1. 새 터미널을 열거나 현재 터미널을 새로고침하세요:"
    echo "      source ~/.bashrc    # Bash 사용자"
    echo "      source ~/.zshrc     # ZSH 사용자"
    echo "   2. tarsync 명령어 사용:"
    echo "      tarsync help                    # 도움말"
    echo "      tarsync version                 # 버전 확인"
    echo "      tarsync backup /home/user       # 백업"
    echo "      tarsync list                    # 목록"
    echo ""
    log_success "💡 탭 키를 눌러서 자동완성 기능을 사용해보세요!"
}

confirm_installation() {
    echo ""
    log_info "설치를 계속하시겠습니까? (Y/n)"
    read -r confirmation
    confirmation=${confirmation:-Y}  # 기본값을 Y로 설정
    
    if [[ ! $confirmation =~ ^[Yy]$ ]]; then
        log_info "설치가 취소되었습니다"
        exit 0
    fi
}

# ===== 메인 설치 프로세스 =====
# ===== Main Installation Process =====

main() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           TARSYNC 설치 도구            ║${NC}"
    echo -e "${CYAN}║      Shell Script 백업 시스템          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    log_info "설치 초기화 중..."
    check_minimal_requirements
    
    log_info "기존 설치 확인 중..."
    if check_dir_exists "$PROJECT_DIR"; then
        log_info "기존 설치 디렉토리 발견: $PROJECT_DIR"
    fi
    
    log_info "필수 의존성 확인 중..."
    check_required_tools
    log_info "모든 의존성이 충족되었습니다"
    
    log_info "디렉토리 권한 확인 중..."
    local test_dir="$HOME/.tarsync_test"
    if mkdir -p "$test_dir" 2>/dev/null; then
        rmdir "$test_dir"
        log_info "디렉토리 권한이 충분합니다"
    else
        log_error "홈 디렉토리에 설치 권한이 없습니다"
        exit 1
    fi
    
    # 최종 확인
    confirm_installation
    
    # 실제 설치 시작
    echo ""
    log_info "tarsync 설치를 시작합니다..."
    echo ""
    
    # 기존 설치 제거
    if check_dir_exists "$PROJECT_DIR"; then
        log_info "기존 설치 제거 중..."
        rm -rf "$PROJECT_DIR"
    fi
    
    # 파일 설치
    log_info "파일 설치 중..."
    copy_project_files || exit 1
    install_tarsync_script || exit 1
    
    # 자동완성 설치
    log_info "자동완성 기능 설치 중..."
    install_completions || exit 1
    configure_bash_completion
    configure_zsh_completion
    
    # PATH 업데이트
    log_info "PATH 업데이트 중..."
    update_path
    
    # 설치 확인
    log_info "설치 확인 중..."
    verify_installation
}

# 메인 함수 실행
main 