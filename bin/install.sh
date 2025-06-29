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
PROJECT_DIR="/usr/share/tarsync"
INSTALL_DIR="/usr/local/bin"
COMPLETION_DIR="/etc/bash_completion.d"
ZSH_COMPLETION_DIR="/usr/share/zsh/site-functions"
CONFIG_DIR="/etc/tarsync"

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
    
    # sudo 권한 체크 (전역 설치 필요)
    if [ "$EUID" -ne 0 ]; then
        log_error "전역 설치를 위해서는 sudo 권한이 필요합니다"
        log_info "다음과 같이 실행해주세요: sudo ./bin/install.sh"
        exit 1
    fi
    
    # 시스템 디렉토리 생성 가능 여부 체크
    if [ ! -w "/usr/local" ] || [ ! -w "/etc" ] || [ ! -w "/usr/share" ]; then
        log_error "시스템 디렉토리에 쓰기 권한이 없습니다"
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
    create_dir_if_not_exists "$PROJECT_DIR"
    
    cp "$PROJECT_ROOT/bin/tarsync.sh" "$INSTALL_DIR/tarsync"
    chmod +x "$INSTALL_DIR/tarsync"
    
    # VERSION 파일은 PROJECT_DIR에 복사
    cp "$PROJECT_ROOT/bin/VERSION" "$PROJECT_DIR/VERSION"
    
    update_script_paths
    
    if check_file_exists "$INSTALL_DIR/tarsync" && [ -x "$INSTALL_DIR/tarsync" ]; then
        log_info "tarsync 스크립트가 설치되었습니다: $INSTALL_DIR/tarsync"
    else
        log_error "tarsync 스크립트 설치에 실패했습니다"
        return 1
    fi
    
    if check_file_exists "$PROJECT_DIR/VERSION"; then
        log_info "VERSION 파일이 설치되었습니다: $PROJECT_DIR/VERSION"
    else
        log_error "VERSION 파일 설치에 실패했습니다"
        return 1
    fi
}

# 백업 디렉토리 설정
configure_backup_directory() {
    echo ""
    log_info "📁 백업 저장 위치를 설정합니다"
    echo ""
    echo "   백업 파일들이 저장될 디렉토리를 입력하세요:"
    echo "   • 기본값: /mnt/backup (별도 디스크/파티션 권장)"
    echo "   • 예시: ~/backup, /data/backup, /var/backup"
    echo ""
    echo -n "   백업 디렉토리 [/mnt/backup]: "
    read -r backup_dir
    backup_dir=${backup_dir:-/mnt/backup}
    
    # 경로 정규화 (~ 확장)
    if [[ "$backup_dir" == "~/"* ]]; then
        backup_dir="${HOME}/${backup_dir#~/}"
    elif [[ "$backup_dir" == "~" ]]; then
        backup_dir="${HOME}"
    fi
    
    echo ""
    log_info "선택된 백업 디렉토리: $backup_dir"
    
    # 디렉토리 생성 시도
    if [[ ! -d "$backup_dir" ]]; then
        log_info "백업 디렉토리가 존재하지 않습니다. 생성을 시도합니다..."
        
        if mkdir -p "$backup_dir" 2>/dev/null; then
            log_success "✅ 백업 디렉토리가 생성되었습니다: $backup_dir"
        else
            log_info "⚠️ 디렉토리 생성에 실패했습니다. sudo 권한이 필요할 수 있습니다."
            echo ""
            echo "다음 명령어를 실행해보세요:"
            echo "   sudo mkdir -p '$backup_dir'"
            echo "   sudo chown \$USER:\$USER '$backup_dir'"
            echo ""
            log_info "위 명령어를 실행하고 다시 설치하시겠습니까? (y/N): "
            read -r retry_response
            
            if [[ "$retry_response" =~ ^[Yy]$ ]]; then
                echo "sudo mkdir -p '$backup_dir' && sudo chown \$USER:\$USER '$backup_dir'" | bash
                if [[ -d "$backup_dir" ]] && [[ -w "$backup_dir" ]]; then
                    log_success "✅ sudo를 사용하여 백업 디렉토리가 생성되었습니다"
                else
                    log_error "❌ 백업 디렉토리 생성에 실패했습니다"
                    exit 1
                fi
            else
                log_error "❌ 백업 디렉토리를 생성할 수 없어 설치를 중단합니다"
                exit 1
            fi
        fi
    else
        # 기존 디렉토리 권한 확인
        if [[ -w "$backup_dir" ]]; then
            log_success "✅ 백업 디렉토리 권한이 확인되었습니다"
        else
            log_info "⚠️ 백업 디렉토리에 쓰기 권한이 없습니다: $backup_dir"
            echo ""
            echo "권한 수정을 시도하시겠습니까?"
            echo "   실행할 명령어: sudo chown \$USER:\$USER '$backup_dir'"
            echo ""
            log_info "권한을 수정하시겠습니까? (y/N): "
            read -r fix_permission
            
            if [[ "$fix_permission" =~ ^[Yy]$ ]]; then
                echo "sudo chown \$USER:\$USER '$backup_dir'" | bash
                
                # 권한 수정 후 재확인
                if [[ -w "$backup_dir" ]]; then
                    log_success "✅ 권한이 수정되어 백업 디렉토리를 사용할 수 있습니다"
                else
                    log_error "❌ 권한 수정에 실패했습니다"
                    echo ""
                    log_info "다른 백업 디렉토리를 사용하시겠습니까? (Y/n): "
                    read -r retry_response
                    retry_response=${retry_response:-Y}
                    
                    if [[ "$retry_response" =~ ^[Yy]$ ]]; then
                        echo ""
                        echo "다른 백업 디렉토리를 입력하세요:"
                        echo -n "   백업 디렉토리: "
                        read -r new_backup_dir
                        
                        if [[ -n "$new_backup_dir" ]]; then
                            # 재귀적으로 다시 시도 (새 경로로)
                            BACKUP_DIRECTORY=""
                            backup_dir="$new_backup_dir"
                            
                            # 경로 정규화 (~ 확장)
                            if [[ "$backup_dir" == "~/"* ]]; then
                                backup_dir="${HOME}/${backup_dir#~/}"
                            elif [[ "$backup_dir" == "~" ]]; then
                                backup_dir="${HOME}"
                            fi
                            
                            log_info "새로운 백업 디렉토리: $backup_dir"
                            
                            # 새 경로로 다시 검증 (간단한 재귀)
                            if [[ ! -d "$backup_dir" ]]; then
                                if mkdir -p "$backup_dir" 2>/dev/null; then
                                    log_success "✅ 새 백업 디렉토리가 생성되었습니다: $backup_dir"
                                else
                                    log_error "❌ 새 백업 디렉토리 생성에 실패했습니다"
                                    exit 1
                                fi
                            elif [[ ! -w "$backup_dir" ]]; then
                                log_error "❌ 새 백업 디렉토리에도 쓰기 권한이 없습니다: $backup_dir"
                                exit 1
                            else
                                log_success "✅ 새 백업 디렉토리 권한이 확인되었습니다"
                            fi
                        else
                            log_error "❌ 유효한 백업 디렉토리가 입력되지 않았습니다"
                            exit 1
                        fi
                    else
                        log_error "❌ 사용 가능한 백업 디렉토리가 없어 설치를 중단합니다"
                        exit 1
                    fi
                fi
            else
                log_error "❌ 백업 디렉토리 권한 문제로 설치를 중단합니다"
                exit 1
            fi
        fi
    fi
    
    # 전역 변수로 저장
    BACKUP_DIRECTORY="$backup_dir"
    
    echo ""
    log_info "📦 백업 디렉토리 설정이 완료되었습니다"
}

copy_project_files() {
    create_dir_if_not_exists "$PROJECT_DIR/src"
    create_dir_if_not_exists "$PROJECT_DIR/config"
    
    cp -r "$PROJECT_ROOT/src/"* "$PROJECT_DIR/src/"
    cp -r "$PROJECT_ROOT/config/"* "$PROJECT_DIR/config/"
    
    # 설정 파일 생성 (백업 디렉토리 반영)
    cat > "$PROJECT_DIR/config/settings.env" << EOF
# tarsync 기본 설정
LANGUAGE=ko
BACKUP_DIR=${BACKUP_DIRECTORY:-/mnt/backup}
LOG_LEVEL=info
EOF
    
    log_info "프로젝트 파일이 복사되었습니다"
    log_info "백업 저장 위치: ${BACKUP_DIRECTORY:-/mnt/backup}"
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
    # 전역 설치에서는 /etc/bash_completion.d/ 에 설치하면 자동으로 로드됨
    log_info "Bash 자동완성이 시스템 전역에 설치되었습니다"
}

configure_zsh_completion() {
    # 전역 설치에서는 /usr/share/zsh/site-functions/ 에 설치하면 자동으로 로드됨  
    log_info "ZSH 자동완성이 시스템 전역에 설치되었습니다"
}

update_path() {
    # 전역 설치에서는 /usr/local/bin이 이미 PATH에 포함되어 있어서 별도 설정 불필요
    log_info "실행파일이 /usr/local/bin에 설치되어 PATH 업데이트가 필요하지 않습니다"
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
    echo "   • 버전파일: $PROJECT_DIR/VERSION"
    echo "   • 라이브러리: $PROJECT_DIR"
    echo "   • Bash 자동완성: $COMPLETION_DIR/tarsync"
    echo "   • ZSH 자동완성: $ZSH_COMPLETION_DIR/_tarsync"
    echo ""
    
    # 환경 감지 및 자동완성 즉시 사용 옵션 제공
    offer_immediate_completion_setup
}

# 사용자 쉘 환경 감지
detect_user_shell() {
    if [ -n "$BASH_VERSION" ]; then
        echo "bash"
    elif [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    else
        # fallback: $SHELL 변수 사용
        case "$SHELL" in
            */bash) echo "bash" ;;
            */zsh) echo "zsh" ;;
            *) echo "unknown" ;;
        esac
    fi
}

# 쉘별 맞춤 명령어 제시
show_shell_specific_completion_commands() {
    local user_shell=$(detect_user_shell)
    
    echo ""
    case "$user_shell" in
        bash)
            echo -e "   ${CYAN}🐚 Bash 환경이 감지되었습니다${NC}"
            echo ""
            echo "   다음 중 하나를 실행하세요:"
            echo -e "   ${YELLOW}1) source ~/.bashrc${NC}              # 설정 파일 다시 로드"
            echo -e "   ${YELLOW}2) source /etc/bash_completion${NC}   # completion 직접 로드"  
            echo -e "   ${YELLOW}3) exec bash${NC}                     # 새 쉘 세션 시작 (권장)"
            ;;
        zsh)
            echo -e "   ${CYAN}🐚 ZSH 환경이 감지되었습니다${NC}"
            echo ""
            echo "   다음 중 하나를 실행하세요:"
            echo -e "   ${YELLOW}1) source ~/.zshrc${NC}               # 설정 파일 다시 로드"
            echo -e "   ${YELLOW}2) autoload -U compinit && compinit${NC}  # completion 재초기화"
            echo -e "   ${YELLOW}3) exec zsh${NC}                      # 새 쉘 세션 시작 (권장)"
            ;;
        *)
            echo -e "   ${CYAN}🐚 쉘 환경: $SHELL${NC}"
            echo ""
            echo "   다음 중 하나를 실행하세요:"
            echo -e "   ${YELLOW}1) source ~/.bashrc${NC}              # Bash 설정 로드"
            echo -e "   ${YELLOW}2) source /etc/bash_completion${NC}   # completion 직접 로드"
            echo -e "   ${YELLOW}3) exec \$SHELL${NC}                  # 새 쉘 세션 시작 (권장)"
            ;;
    esac
    echo ""
    echo -e "   ${DIM}💡 명령어를 복사해서 터미널에 붙여넣으세요${NC}"
}

# 자동완성 즉시 사용을 위한 선택권 제공
offer_immediate_completion_setup() {
    echo ""
    log_info "🚀 자동완성을 바로 사용하려면:"
    
    # Docker/컨테이너 환경 감지
    local is_container=false
    if [ -f /.dockerenv ] || [ -n "${container:-}" ] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
        is_container=true
    fi
    
    # 컨테이너 환경일 때만 추가 메시지 출력
    if [ "$is_container" = true ]; then
        echo -e "   ${YELLOW}📦 컨테이너 환경이 감지되었습니다${NC}"
    fi
    
    # 쉘별 맞춤 명령어 안내 (항상 실행)
    show_shell_specific_completion_commands
    
    echo ""
    log_info "📖 tarsync 명령어 사용법:"
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

# bash-completion 설치 및 활성화
# Install and enable bash-completion
setup_bash_completion() {
    log_info "bash-completion 시스템 설정 중..."
    
    # bash-completion 패키지 설치 여부 확인
    if ! dpkg -l | grep -q "bash-completion"; then
        log_info "bash-completion 패키지를 설치합니다..."
        
        # OS 감지해서 적절한 설치 명령어 사용
        local os_type=$(detect_os)
        case "$os_type" in
            ubuntu)
                apt update -qq && apt install -y bash-completion
                ;;
            centos)
                yum install -y bash-completion
                ;;
            fedora)
                dnf install -y bash-completion
                ;;
            *)
                log_warn "자동 설치를 지원하지 않는 시스템입니다: $os_type"
                log_info "다음 명령어로 수동 설치해주세요:"
                echo "   Ubuntu/Debian: apt install bash-completion"
                echo "   CentOS/RHEL:   yum install bash-completion"
                echo "   Fedora:        dnf install bash-completion"
                return 1
                ;;
        esac
        
        if dpkg -l | grep -q "bash-completion"; then
            log_success "✅ bash-completion 패키지가 설치되었습니다"
        else
            log_error "❌ bash-completion 패키지 설치에 실패했습니다"
            return 1
        fi
    else
        log_info "bash-completion 패키지가 이미 설치되어 있습니다"
    fi
    
    # /etc/bash.bashrc에서 bash completion 활성화
    if [ -f "/etc/bash.bashrc" ]; then
        # 이미 활성화되어 있는지 확인
        if grep -q "^if ! shopt -oq posix; then" /etc/bash.bashrc; then
            log_info "bash completion이 이미 활성화되어 있습니다"
        else
            log_info "bash completion을 활성화합니다..."
            
            # 전체 bash completion 블록 활성화 (주석 제거)
            sed -i 's/^#if ! shopt -oq posix; then/if ! shopt -oq posix; then/' /etc/bash.bashrc
            sed -i 's/^#  if \[ -f \/usr\/share\/bash-completion\/bash_completion \]/  if [ -f \/usr\/share\/bash-completion\/bash_completion ]/' /etc/bash.bashrc
            sed -i 's/^#    \. \/usr\/share\/bash-completion\/bash_completion/    . \/usr\/share\/bash-completion\/bash_completion/' /etc/bash.bashrc
            sed -i 's/^#  elif \[ -f \/etc\/bash_completion \]/  elif [ -f \/etc\/bash_completion ]/' /etc/bash.bashrc
            sed -i 's/^#    \. \/etc\/bash_completion/    . \/etc\/bash_completion/' /etc/bash.bashrc
            sed -i 's/^#  fi/  fi/' /etc/bash.bashrc
            sed -i 's/^#fi/fi/' /etc/bash.bashrc
            
            # 활성화 확인
            if grep -q "^if ! shopt -oq posix; then" /etc/bash.bashrc; then
                log_success "✅ bash completion이 활성화되었습니다"
            else
                log_error "❌ bash completion 활성화에 실패했습니다"
                return 1
            fi
        fi
    else
        log_warn "/etc/bash.bashrc 파일을 찾을 수 없습니다"
        return 1
    fi
    
    log_success "bash-completion 시스템 설정이 완료되었습니다"
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
    configure_backup_directory
    copy_project_files || exit 1
    install_tarsync_script || exit 1
    
    # 자동완성 설치
    log_info "자동완성 기능 설치 중..."
    install_completions || exit 1
    
    # bash-completion 시스템 활성화
    setup_bash_completion || exit 1
    
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