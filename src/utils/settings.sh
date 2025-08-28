#!/bin/bash
# tarsync 사용자 설정 관리 유틸리티
# User settings management utility for tarsync

# 현재 스크립트의 디렉토리 경로 가져오기
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# 메시지 시스템 로드
SCRIPT_DIR="$(get_script_dir)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PROJECT_ROOT/config/messages/detect.sh"
source "$PROJECT_ROOT/config/messages/load.sh"
load_tarsync_messages

# 설정 경로 상수
USER_CONFIG_DIR="$HOME/.tarsync/config"
USER_SETTINGS_FILE="$USER_CONFIG_DIR/settings.env"
SYSTEM_CONFIG_DIR="/etc/tarsync"
SYSTEM_SETTINGS_FILE="$SYSTEM_CONFIG_DIR/settings.env"

# 사용자 설정 디렉토리 생성
create_user_config_dir() {
    if [[ ! -d "$USER_CONFIG_DIR" ]]; then
        mkdir -p "$USER_CONFIG_DIR" 2>/dev/null || {
            error_msg "MSG_SYSTEM_PERMISSION_DENIED" "$USER_CONFIG_DIR" >&2
            return 1
        }
        msg "MSG_SYSTEM_CREATING_DIR" "$USER_CONFIG_DIR"
    fi
    return 0
}

# 사용자 언어 설정 읽기
get_user_language_setting() {
    local setting_value=""
    
    # 사용자 설정 파일에서 읽기
    if [[ -f "$USER_SETTINGS_FILE" ]]; then
        setting_value=$(grep "^TARSYNC_LANG=" "$USER_SETTINGS_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d "\"'")
    fi
    
    # 시스템 설정 파일에서 읽기 (사용자 설정이 없는 경우)
    if [[ -z "$setting_value" && -f "$SYSTEM_SETTINGS_FILE" ]]; then
        setting_value=$(grep "^TARSYNC_LANG=" "$SYSTEM_SETTINGS_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d "\"'")
    fi
    
    echo "$setting_value"
}

# 사용자 언어 설정 저장
set_user_language_setting() {
    local language="$1"
    
    if [[ -z "$language" ]]; then
        error_msg "MSG_ERROR_MISSING_ARGUMENT" "language" >&2
        return 1
    fi
    
    # 언어 코드 검증
    case "$language" in
        "en"|"ko")
            ;;
        *)
            error_msg "MSG_ERROR_INVALID_COMMAND" "$language - supported: en, ko" >&2
            return 1
            ;;
    esac
    
    # 사용자 설정 디렉토리 생성
    if ! create_user_config_dir; then
        return 1
    fi
    
    # 기존 설정 파일 백업 (있는 경우)
    if [[ -f "$USER_SETTINGS_FILE" ]]; then
        cp "$USER_SETTINGS_FILE" "$USER_SETTINGS_FILE.bak" 2>/dev/null || true
    fi
    
    # 새 설정 작성
    {
        echo "# tarsync user configuration"
        echo "# Generated on $(date)"
        echo ""
        echo "# Language setting - en, ko"
        echo "TARSYNC_LANG=\"$language\""
        echo ""
        echo "# Other user settings can be added here"
    } > "$USER_SETTINGS_FILE" || {
        error_msg "MSG_SYSTEM_PERMISSION_DENIED" "$USER_SETTINGS_FILE" >&2
        return 1
    }
    
    success_msg "MSG_INSTALL_LANGUAGE_CONFIG" "$language"
    printf "  Settings saved to: %s\n" "$USER_SETTINGS_FILE"
    return 0
}

# 현재 활성 언어 표시
show_current_language() {
    local current_lang="${CURRENT_LANGUAGE:-$(detect_system_language)}"
    local setting_source=""
    
    # 설정 소스 확인
    if [[ -n "$TARSYNC_LANG" ]]; then
        setting_source="environment variable"
    elif [[ -f "$USER_SETTINGS_FILE" ]] && grep -q "^TARSYNC_LANG=" "$USER_SETTINGS_FILE" 2>/dev/null; then
        setting_source="user config file"
    elif [[ -f "$SYSTEM_SETTINGS_FILE" ]] && grep -q "^TARSYNC_LANG=" "$SYSTEM_SETTINGS_FILE" 2>/dev/null; then
        setting_source="system config file"
    else
        setting_source="system locale"
    fi
    
    printf "Current language: %s - %s\n" "$current_lang" "$setting_source"
    printf "User config: %s\n" "$USER_SETTINGS_FILE"
    
    if [[ -f "$USER_SETTINGS_FILE" ]]; then
        printf "✅ User settings exist\n"
    else
        printf "⚪ No user settings - using system defaults\n"
    fi
}

# 설정 파일 초기화
reset_user_settings() {
    if [[ -f "$USER_SETTINGS_FILE" ]]; then
        if [[ -f "$USER_SETTINGS_FILE.bak" ]]; then
            rm -f "$USER_SETTINGS_FILE.bak" 2>/dev/null || true
        fi
        mv "$USER_SETTINGS_FILE" "$USER_SETTINGS_FILE.bak" 2>/dev/null || true
        msg "MSG_SYSTEM_REMOVING_FILE" "$USER_SETTINGS_FILE"
        printf "  Backup saved as: %s.bak\n" "$USER_SETTINGS_FILE"
    else
        printf "No user settings to reset.\n"
    fi
}

# 도움말 표시
show_settings_help() {
    printf "tarsync settings management\n\n"
    printf "Usage:\n"
    printf "  tarsync config lang [en|ko]    Set language preference\n"
    printf "  tarsync config lang show       Show current language settings\n"
    printf "  tarsync config reset          Reset user settings\n"
    printf "\n"
    printf "Supported languages:\n"
    printf "  en    English\n"
    printf "  ko    Korean\n"
    printf "\n"
    printf "Configuration files:\n"
    printf "  User:   %s\n" "$USER_SETTINGS_FILE"
    printf "  System: %s\n" "$SYSTEM_SETTINGS_FILE"
}

# Export functions when sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f create_user_config_dir
    export -f get_user_language_setting
    export -f set_user_language_setting
    export -f show_current_language
    export -f reset_user_settings
    export -f show_settings_help
fi