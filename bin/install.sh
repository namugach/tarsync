#!/bin/bash

# ===== Tarsync 설치 도구 =====
# ===== Tarsync Installer =====

# 유틸리티 모듈 로드
# Load utility modules
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/src/utils/colors.sh"
source "$PROJECT_ROOT/src/utils/log.sh"
source "$PROJECT_ROOT/src/utils/version.sh"

# 메시지 시스템 로드
source "$PROJECT_ROOT/config/messages/detect.sh"
source "$PROJECT_ROOT/config/messages/load.sh"
load_tarsync_messages

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
    
    msg "MSG_INSTALL_DEPS_INSTALLING"
    msg "MSG_INSTALL_DEPS_COMMAND" "$install_cmd"
    echo ""
    
    if eval "$install_cmd"; then
        success_msg "MSG_INSTALL_DEPS_SUCCESS"
        return 0
    else
        error_msg "MSG_INSTALL_DEPS_FAILED"
        return 1
    fi
}

check_required_tools() {
    local required_tools=("tar" "gzip" "rsync" "pv" "bc" "jq")
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
    msg "MSG_INSTALL_DEPS_MISSING_TOOLS" "${missing_tools[*]}"
    
    # OS 감지
    local os_type=$(detect_os)
    local install_cmd=$(get_install_command "$os_type" "${missing_tools[@]}")
    
    # 자동 설치 가능한 경우
    if [ -n "$install_cmd" ]; then
        echo ""
        case "$os_type" in
            ubuntu|centos|fedora)
                msg "MSG_INSTALL_LINUX_DETECTED" "$os_type"
                ;;
            macos)
                msg "MSG_INSTALL_MACOS_DETECTED"
                if ! command -v brew >/dev/null 2>&1; then
                    error_msg "MSG_INSTALL_HOMEBREW_MISSING"
                    msg "MSG_INSTALL_HOMEBREW_INSTALL"
                    show_manual_install_guide "${missing_tools[@]}"
                    exit 1
                fi
                ;;
        esac
        
        echo ""
        printf "$(msg MSG_INSTALL_CONFIRM_AUTO_INSTALL)"
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
                    error_msg "MSG_INSTALL_SOME_TOOLS_MISSING" "${still_missing[*]}"
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
        error_msg "MSG_INSTALL_UNSUPPORTED_SYSTEM" "$os_type"
        show_manual_install_guide "${missing_tools[@]}"
        exit 1
    fi
}

check_minimal_requirements() {
    # Bash 버전 체크
    if [ -z "$BASH_VERSION" ]; then
        error_msg "MSG_INSTALL_BASH_REQUIRED"
        exit 1
    fi
    
    # sudo 권한 체크 (전역 설치 필요)
    if [ "$EUID" -ne 0 ]; then
        error_msg "MSG_INSTALL_SUDO_REQUIRED"
        msg "MSG_INSTALL_SUDO_HINT"
        exit 1
    fi
    
    # 시스템 디렉토리 생성 가능 여부 체크
    if [ ! -w "/usr/local" ] || [ ! -w "/etc" ] || [ ! -w "/usr/share" ]; then
        error_msg "MSG_INSTALL_WRITE_PERMISSION_ERROR"
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
        log_info "$(msg MSG_INSTALL_SCRIPT_INSTALLED "$INSTALL_DIR/tarsync")"
    else
        error_msg "MSG_INSTALL_SCRIPT_INSTALL_FAILED"
        return 1
    fi
    
    if check_file_exists "$PROJECT_DIR/VERSION"; then
        log_info "$(msg MSG_INSTALL_VERSION_INSTALLED "$PROJECT_DIR/VERSION")"
    else
        error_msg "MSG_INSTALL_VERSION_INSTALL_FAILED"
        return 1
    fi
}

# 백업 디렉토리 설정
configure_backup_directory() {
    # defaults.sh에서 기본 백업 경로 로드
    local default_backup_path="/mnt/backup/tarsync"
    if [[ -f "$PROJECT_ROOT/config/defaults.sh" ]]; then
        source "$PROJECT_ROOT/config/defaults.sh"
        default_backup_path="$BACKUP_PATH"
    fi
    
    echo ""
    log_info "$(msg MSG_INSTALL_BACKUP_SETUP)"
    echo ""
    msg MSG_INSTALL_BACKUP_PROMPT
    msg MSG_INSTALL_BACKUP_DEFAULT "$default_backup_path"
    msg MSG_INSTALL_BACKUP_EXAMPLES
    echo ""
    printf "$(msg MSG_INSTALL_BACKUP_INPUT "$default_backup_path")"
    read -r backup_dir
    backup_dir=${backup_dir:-$default_backup_path}
    
    # 경로 정규화 (~ 확장)
    if [[ "$backup_dir" == "~/"* ]]; then
        backup_dir="${HOME}/${backup_dir#~/}"
    elif [[ "$backup_dir" == "~" ]]; then
        backup_dir="${HOME}"
    fi
    
    echo ""
    log_info "$(msg MSG_INSTALL_BACKUP_SELECTED "$backup_dir")"
    
    # 디렉토리 생성 시도
    if [[ ! -d "$backup_dir" ]]; then
        msg "MSG_INSTALL_BACKUP_DIR_NOT_EXIST"
        
        if mkdir -p "$backup_dir" 2>/dev/null; then
            success_msg "MSG_INSTALL_BACKUP_DIR_CREATED" "$backup_dir"
        else
            msg "MSG_INSTALL_BACKUP_DIR_CREATE_FAILED"
            echo ""
            msg "MSG_INSTALL_BACKUP_DIR_COMMAND_TIP"
            echo "   sudo mkdir -p '$backup_dir'"
            echo "   sudo chown \$USER:\$USER '$backup_dir'"
            echo ""
            printf "$(msg MSG_INSTALL_BACKUP_DIR_RETRY_PROMPT)"
            read -r retry_response
            
            if [[ "$retry_response" =~ ^[Yy]$ ]]; then
                echo "sudo mkdir -p '$backup_dir' && sudo chown \$USER:\$USER '$backup_dir'" | bash
                if [[ -d "$backup_dir" ]] && [[ -w "$backup_dir" ]]; then
                    success_msg "MSG_INSTALL_BACKUP_DIR_SUDO_SUCCESS"
                else
                    error_msg "MSG_INSTALL_BACKUP_DIR_SUDO_FAILED"
                    exit 1
                fi
            else
                error_msg "MSG_INSTALL_BACKUP_DIR_CANNOT_CREATE"
                exit 1
            fi
        fi
    else
        # 기존 디렉토리 권한 확인
        if [[ -w "$backup_dir" ]]; then
            success_msg "MSG_INSTALL_BACKUP_DIR_PERMISSIONS_OK"
        else
            msg "MSG_INSTALL_BACKUP_DIR_NO_WRITE" "$backup_dir"
            echo ""
            msg "MSG_INSTALL_BACKUP_DIR_FIX_PERMISSION"
            msg "MSG_INSTALL_BACKUP_DIR_FIX_COMMAND" "$backup_dir"
            echo ""
            printf "$(msg MSG_INSTALL_BACKUP_DIR_FIX_PROMPT)"
            read -r fix_permission
            
            if [[ "$fix_permission" =~ ^[Yy]$ ]]; then
                echo "sudo chown \$USER:\$USER '$backup_dir'" | bash
                
                # 권한 수정 후 재확인
                if [[ -w "$backup_dir" ]]; then
                    success_msg "MSG_INSTALL_BACKUP_DIR_PERMISSION_FIXED"
                else
                    error_msg "MSG_INSTALL_BACKUP_DIR_FIX_FAILED"
                    echo ""
                    printf "$(msg MSG_INSTALL_BACKUP_DIR_USE_OTHER)"
                    read -r retry_response
                    retry_response=${retry_response:-Y}
                    
                    if [[ "$retry_response" =~ ^[Yy]$ ]]; then
                        echo ""
                        msg "MSG_INSTALL_BACKUP_DIR_ENTER_NEW"
                        printf "$(msg MSG_INSTALL_BACKUP_DIR_INPUT_PROMPT)"
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
                            
                            msg "MSG_INSTALL_BACKUP_DIR_NEW_PATH" "$backup_dir"
                            
                            # 새 경로로 다시 검증 (간단한 재귀)
                            if [[ ! -d "$backup_dir" ]]; then
                                if mkdir -p "$backup_dir" 2>/dev/null; then
                                    success_msg "MSG_INSTALL_BACKUP_DIR_NEW_SUCCESS" "$backup_dir"
                                else
                                    error_msg "MSG_INSTALL_BACKUP_DIR_NEW_FAILED"
                                    exit 1
                                fi
                            elif [[ ! -w "$backup_dir" ]]; then
                                error_msg "MSG_INSTALL_BACKUP_DIR_NEW_NO_WRITE" "$backup_dir"
                                exit 1
                            else
                                success_msg "MSG_INSTALL_BACKUP_DIR_NEW_PERMISSION_OK"
                            fi
                        else
                            error_msg "MSG_INSTALL_BACKUP_DIR_INVALID"
                            exit 1
                        fi
                    else
                        error_msg "MSG_INSTALL_BACKUP_DIR_NO_AVAILABLE"
                        exit 1
                    fi
                fi
            else
                error_msg "MSG_INSTALL_BACKUP_DIR_PERMISSION_ERROR"
                exit 1
            fi
        fi
    fi
    
    # 전역 변수로 저장
    BACKUP_DIRECTORY="$backup_dir"
    
    echo ""
    log_info "$(msg MSG_INSTALL_BACKUP_SETUP_COMPLETE)"
}

copy_project_files() {
    create_dir_if_not_exists "$PROJECT_DIR/src"
    create_dir_if_not_exists "$PROJECT_DIR/config"
    
    cp -r "$PROJECT_ROOT/src/"* "$PROJECT_DIR/src/"
    cp -r "$PROJECT_ROOT/config/"* "$PROJECT_DIR/config/"
    
    # 시스템 설정 디렉토리 생성
    create_dir_if_not_exists "$CONFIG_DIR"

    # 설정 파일 생성 (언어 선택 및 백업 디렉토리 반영)
    cat > "$CONFIG_DIR/settings.env" << EOF
# tarsync 기본 설정
TARSYNC_LANG=${selected_lang:-en}
LANGUAGE=${selected_lang:-en}
BACKUP_DIR=${BACKUP_DIRECTORY:-/mnt/backup/tarsync}
LOG_LEVEL=info
EOF
    
    log_info "$(msg MSG_INSTALL_FILES_COPIED)"
    log_info "$(msg MSG_INSTALL_BACKUP_LOCATION "${BACKUP_DIRECTORY:-/mnt/backup}")"
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
    
    log_info "$(msg MSG_INSTALL_COMPLETION_INSTALLED)"
}

configure_bash_completion() {
    # 전역 설치에서는 /etc/bash_completion.d/ 에 설치하면 자동으로 로드됨
    log_info "$(msg MSG_INSTALL_COMPLETION_BASH_GLOBAL)"
}

configure_zsh_completion() {
    # 전역 설치에서는 /usr/share/zsh/site-functions/ 에 설치하면 자동으로 로드됨  
    log_info "$(msg MSG_INSTALL_COMPLETION_ZSH_GLOBAL)"
}

update_path() {
    # 전역 설치에서는 /usr/local/bin이 이미 PATH에 포함되어 있어서 별도 설정 불필요
    log_info "$(msg MSG_INSTALL_PATH_NOT_NEEDED)"
}

# ===== 언어 선택 함수 =====
# ===== Language Selection Functions =====

# 언어 파일에서 코드와 이름 추출
process_language_file() {
    local lang_file="$1"
    local code=""
    local name=""
    
    if [ -f "$lang_file" ]; then
        # 언어 코드 추출 (LANG_CODE 변수에서)
        code=$(grep "^LANG_CODE=" "$lang_file" 2>/dev/null | cut -d'=' -f2 | tr -d "\"'")
        # 언어 이름 추출 (LANG_NAME 변수에서)
        name=$(grep "^LANG_NAME=" "$lang_file" 2>/dev/null | cut -d'=' -f2 | tr -d "\"'")
        
        if [ -n "$code" ] && [ -n "$name" ]; then
            langs+=("$code")
            lang_names+=("$name")
            
            if [ "$code" = "en" ]; then  # tarsync default is English (globalization)
                default_idx=$i
            fi
            
            i=$((i+1))
        fi
    fi
}

# 사용 가능한 언어 찾기
find_available_languages() {
    langs=()
    lang_names=()
    default_idx=0
    i=0
    
    log_info "Finding available languages..."
    
    # 언어 메시지 파일들 검사
    for lang_file in "$PROJECT_ROOT/config/messages"/*.sh; do
        if [[ "$(basename "$lang_file")" != "detect.sh" && "$(basename "$lang_file")" != "load.sh" ]]; then
            process_language_file "$lang_file"
        fi
    done
    
    # 언어가 없으면 기본값 추가
    if [ ${#langs[@]} -eq 0 ]; then
        langs=("en" "ko")
        lang_names=("English" "한국어")
        default_idx=0  # English is default (globalization)
    fi
}

# 언어 옵션 표시
display_language_options() {
    echo ""
    log_info "$(msg MSG_INSTALL_SELECT_LANGUAGE)"
    echo "   0. $(msg MSG_INSTALL_CANCEL)"
    
    for i in "${!langs[@]}"; do
        local default_mark=""
        if [ $i -eq $default_idx ]; then
            default_mark=$(msg "MSG_INSTALL_DEFAULT_MARK")
        fi
        echo "   $((i+1)). ${lang_names[$i]}${default_mark}"
    done
}

# 언어 선택 입력 처리
handle_language_selection() {
    echo ""
    printf "$(msg MSG_INSTALL_LANGUAGE_INPUT "$(( ${#langs[@]} - 1 ))")"
    read -r lang_choice
    
    if [ "$lang_choice" = "0" ]; then
        log_info "$(msg MSG_INSTALL_CANCELLED)"
        exit 0
    fi
    
    process_language_choice
}

# 선택된 언어 처리
process_language_choice() {
    if [[ "$lang_choice" =~ ^[0-9]+$ ]] && [ "$lang_choice" -ge 1 ] && [ "$lang_choice" -le "${#langs[@]}" ]; then
        set_selected_language
    else
        set_default_language
    fi
    
    prepare_language_settings
}

# 선택된 언어 설정
set_selected_language() {
    local idx=$((lang_choice-1))
    selected_lang="${langs[$idx]}"
    selected_name="${lang_names[$idx]}"
    
    TARSYNC_LANG="$selected_lang"
    export TARSYNC_LANG
    
    log_info "$(msg MSG_INSTALL_LANGUAGE_SELECTED "$selected_name" "$selected_lang")"
}

# 기본 언어 설정
set_default_language() {
    local default_lang="${langs[$default_idx]}"
    local default_name="${lang_names[$default_idx]}"
    
    selected_lang="$default_lang"
    selected_name="$default_name"
    
    TARSYNC_LANG="$default_lang"
    export TARSYNC_LANG
    
    log_info "$(msg MSG_INSTALL_LANGUAGE_INVALID "$default_name" "$default_lang")"
}

# 언어 설정 준비
prepare_language_settings() {
    # 선택된 언어로 메시지 시스템 다시 로드
    load_tarsync_messages
    
    log_info "$(msg MSG_INSTALL_LANGUAGE_CONFIGURED)"
}

# 메인 언어 선택 함수
setup_language() {
    find_available_languages
    display_language_options  
    handle_language_selection
}

# ===== 검증 함수 =====
# ===== Verification Functions =====

verify_installation() {
    if check_file_exists "$INSTALL_DIR/tarsync" && [ -x "$INSTALL_DIR/tarsync" ]; then
        show_success_message
    else
        error_msg "MSG_INSTALL_VERIFY_FAILED"
        error_msg "MSG_INSTALL_SCRIPT_NOT_FOUND" "$INSTALL_DIR/tarsync"
        exit 1
    fi
}

show_success_message() {
    # 버전 정보 가져오기 (버전 유틸리티 사용)
    local version=$(get_version)
    
    echo ""
    success_msg "MSG_INSTALL_SUCCESS_HEADER" "$version"
    echo ""
    msg "MSG_INSTALL_LOCATIONS_HEADER"
    msg "MSG_INSTALL_LOCATION_EXECUTABLE" "$INSTALL_DIR/tarsync"
    msg "MSG_INSTALL_LOCATION_VERSION" "$PROJECT_DIR/VERSION"
    msg "MSG_INSTALL_LOCATION_LIBRARY" "$PROJECT_DIR"
    msg "MSG_INSTALL_LOCATION_BASH_COMPLETION" "$COMPLETION_DIR/tarsync"
    msg "MSG_INSTALL_LOCATION_ZSH_COMPLETION" "$ZSH_COMPLETION_DIR/_tarsync"
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
            echo -e "   ${CYAN}🐚 Bash environment detected${NC}"
            echo ""
            echo "   Run one of the following:"
            echo -e "   ${YELLOW}1) source ~/.bashrc${NC}              # Reload configuration file"
            echo -e "   ${YELLOW}2) source /etc/bash_completion${NC}   # Load completion directly"  
            echo -e "   ${YELLOW}3) exec bash${NC}                     # Start new shell session (recommended)"
            ;;
        zsh)
            echo -e "   ${CYAN}🐚 ZSH environment detected${NC}"
            echo ""
            echo "   Run one of the following:"
            echo -e "   ${YELLOW}1) source ~/.zshrc${NC}               # Reload configuration file"
            echo -e "   ${YELLOW}2) autoload -U compinit && compinit${NC}  # Reinitialize completion"
            echo -e "   ${YELLOW}3) exec zsh${NC}                      # Start new shell session (recommended)"
            ;;
        *)
            echo -e "   ${CYAN}🐚 Shell environment: $SHELL${NC}"
            echo ""
            echo "   Run one of the following:"
            echo -e "   ${YELLOW}1) source ~/.bashrc${NC}              # Load Bash configuration"
            echo -e "   ${YELLOW}2) source /etc/bash_completion${NC}   # Load completion directly"
            echo -e "   ${YELLOW}3) exec \$SHELL${NC}                  # Start new shell session (recommended)"
            ;;
    esac
    echo ""
    printf "   ${DIM}$(msg MSG_INSTALL_COMPLETION_COPY_TIP)${NC}\n"
}

# 자동완성 즉시 사용을 위한 선택권 제공
offer_immediate_completion_setup() {
    echo ""
    log_info "$(msg MSG_INSTALL_COMPLETION_IMMEDIATE)"
    
    # Docker/컨테이너 환경 감지
    local is_container=false
    if [ -f /.dockerenv ] || [ -n "${container:-}" ] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
        is_container=true
    fi
    
    # 컨테이너 환경일 때만 추가 메시지 출력
    if [ "$is_container" = true ]; then
        printf "   ${YELLOW}$(msg MSG_INSTALL_CONTAINER_ENV_DETECTED)${NC}\n"
    fi
    
    # 쉘별 맞춤 명령어 안내 (항상 실행)
    show_shell_specific_completion_commands
    
    echo ""
    msg "MSG_INSTALL_USAGE_EXAMPLES"
    msg "MSG_INSTALL_USAGE_HELP"
    msg "MSG_INSTALL_USAGE_VERSION"
    msg "MSG_INSTALL_USAGE_BACKUP"
    msg "MSG_INSTALL_USAGE_LIST"
    echo ""
    success_msg "MSG_INSTALL_COMPLETION_TIP"
}

confirm_installation() {
    echo ""
    log_info "$(msg MSG_INSTALL_CONFIRM_PROCEED)"
    read -r confirmation
    confirmation=${confirmation:-Y}  # 기본값을 Y로 설정
    
    if [[ ! $confirmation =~ ^[Yy]$ ]]; then
        log_info "$(msg MSG_INSTALL_CANCELLED)"
        exit 0
    fi
}

# bash-completion 설치 및 활성화
# Install and enable bash-completion
setup_bash_completion() {
    msg "MSG_INSTALL_BASH_COMPLETION_SETUP"
    
    # bash-completion 패키지 설치 여부 확인
    if ! dpkg -l | grep -q "bash-completion"; then
        msg "MSG_INSTALL_BASH_COMPLETION_INSTALLING"
        
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
            success_msg "MSG_INSTALL_BASH_COMPLETION_SUCCESS"
        else
            error_msg "MSG_INSTALL_BASH_COMPLETION_FAILED"
            return 1
        fi
    else
        msg "MSG_INSTALL_BASH_COMPLETION_INSTALLED"
    fi
    
    # /etc/bash.bashrc에서 bash completion 활성화
    if [ -f "/etc/bash.bashrc" ]; then
        # 이미 활성화되어 있는지 확인
        if grep -q "^if ! shopt -oq posix; then" /etc/bash.bashrc; then
            msg "MSG_INSTALL_BASH_COMPLETION_ACTIVE"
        else
            msg "MSG_INSTALL_BASH_COMPLETION_ACTIVATING"
            
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
                success_msg "MSG_INSTALL_BASH_COMPLETION_ACTIVATED"
            else
                error_msg "MSG_INSTALL_BASH_COMPLETION_ACTIVATE_FAILED"
                return 1
            fi
        fi
    else
        log_warn "$(msg MSG_INSTALL_BASH_COMPLETION_BASHRC_NOT_FOUND)"
        return 1
    fi
    
    log_success "$(msg MSG_INSTALL_BASH_COMPLETION_COMPLETE)"
}

# ===== 메인 설치 프로세스 =====
# ===== Main Installation Process =====

main() {
    log_info "Initializing installation..."
    check_minimal_requirements
    
    log_info "Checking for existing installation..."
    if check_dir_exists "$PROJECT_DIR"; then
        log_info "Existing installation directory found: $PROJECT_DIR"
    fi
    
    log_info "Checking required dependencies..."
    check_required_tools
    log_info "All dependencies satisfied"
    
    # 언어 선택
    setup_language
    
    # 언어 선택 후 헤더 출력
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           $(msg MSG_INSTALL_HEADER_TITLE)            ║${NC}"
    echo -e "${CYAN}║      $(msg MSG_INSTALL_HEADER_SUBTITLE)          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # 최종 확인
    confirm_installation
    
    # 실제 설치 시작
    echo ""
    log_info "$(msg MSG_INSTALL_STARTING)"
    echo ""
    
    # 기존 설치 제거
    if check_dir_exists "$PROJECT_DIR"; then
        log_info "$(msg MSG_INSTALL_REMOVING_EXISTING)"
        rm -rf "$PROJECT_DIR"
    fi
    
    # 파일 설치
    log_info "$(msg MSG_INSTALL_FILES)"
    configure_backup_directory
    copy_project_files || exit 1
    install_tarsync_script || exit 1
    
    # 자동완성 설치
    msg "MSG_INSTALL_COMPLETION_INSTALLING"
    install_completions || exit 1
    
    # bash-completion 시스템 활성화
    setup_bash_completion || exit 1
    
    configure_bash_completion
    configure_zsh_completion
    
    # PATH 업데이트
    msg "MSG_INSTALL_PATH_UPDATING"
    update_path
    
    # 설치 확인
    log_info "$(msg MSG_INSTALL_VERIFYING)"
    verify_installation
}

# 메인 함수 실행
main 