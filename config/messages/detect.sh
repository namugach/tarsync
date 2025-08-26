#!/bin/bash

# Tarsync Language Detection System
# Tarsync 언어 감지 시스템

# Detects system language for tarsync based on priority:
# 다음 우선순위에 따라 tarsync 언어를 감지합니다:
# 1. TARSYNC_LANG environment variable (explicit)
# 2. ~/.tarsync/config/settings.env file
# 3. System locale ($LANG)
# 4. Default (en)

# Function: Detect system language from locale
# 함수: 시스템 로케일에서 언어 감지
detect_locale_language() {
    # Check if running in WSL environment (Korean default)
    # WSL 환경인지 확인 (한국어 기본값)
    if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ]]; then
        echo "ko"
        return
    fi
    
    # 1. Check LC_ALL
    if [[ -n "$LC_ALL" && "$LC_ALL" == ko_* ]]; then
        echo "ko"
        return
    fi
    
    # 2. Check LC_MESSAGES
    if [[ -n "$LC_MESSAGES" && "$LC_MESSAGES" == ko_* ]]; then
        echo "ko"
        return
    fi
    
    # 3. Check LANG
    if [[ -n "$LANG" && "$LANG" == ko_* ]]; then
        echo "ko"
        return
    fi
    
    # 4. Default to English
    echo "en"
}

# Function: Check settings file for language
# 함수: 설정 파일에서 언어 확인
check_settings_language() {
    local settings_file="$HOME/.tarsync/config/settings.env"
    local system_settings="/etc/tarsync/settings.env"
    
    # Check user settings first
    # 사용자 설정 먼저 확인
    if [ -f "$settings_file" ]; then
        local lang_setting=$(grep "^TARSYNC_LANG=" "$settings_file" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'"' | tr -d '"')
        if [ -n "$lang_setting" ]; then
            echo "$lang_setting"
            return
        fi
    fi
    
    # Check system settings
    # 시스템 설정 확인
    if [ -f "$system_settings" ]; then
        local lang_setting=$(grep "^TARSYNC_LANG=" "$system_settings" 2>/dev/null | cut -d'=' -f2 | tr -d '"'"'"' | tr -d '"')
        if [ -n "$lang_setting" ]; then
            echo "$lang_setting"
            return
        fi
    fi
    
    # Return empty if no settings found
    echo ""
}

# Function: Main language detection
# 함수: 메인 언어 감지
detect_system_language() {
    # 1. Check explicit TARSYNC_LANG environment variable
    # 1. 명시적 TARSYNC_LANG 환경변수 확인
    if [ -n "$TARSYNC_LANG" ]; then
        echo "$TARSYNC_LANG"
        return
    fi
    
    # 2. Check settings file
    # 2. 설정 파일 확인
    local settings_lang=$(check_settings_language)
    if [ -n "$settings_lang" ]; then
        echo "$settings_lang"
        return
    fi
    
    # 3. Detect from system locale
    # 3. 시스템 로케일에서 감지
    local detected_lang=$(detect_locale_language)
    if [ -n "$detected_lang" ]; then
        echo "$detected_lang"
        return
    fi
    
    # 4. Default to English
    # 4. 기본값: 영어
    echo "en"
}

# Function: Validate language code
# 함수: 언어 코드 검증
validate_language_code() {
    local lang="$1"
    case "$lang" in
        "en"|"ko")
            echo "$lang"
            ;;
        *)
            echo "en"  # Default to English for unsupported languages
            ;;
    esac
}

# Function: Get language with validation
# 함수: 검증된 언어 획득
get_validated_language() {
    local detected=$(detect_system_language)
    validate_language_code "$detected"
}

# Export functions when sourced
# 소스될 때 함수들 내보내기
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f detect_system_language
    export -f detect_locale_language
    export -f check_settings_language
    export -f validate_language_code
    export -f get_validated_language
fi

# Main execution when run directly
# 직접 실행 시 메인 실행
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    get_validated_language
fi