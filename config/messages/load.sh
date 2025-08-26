#!/bin/bash

# Tarsync Message Loading System
# Tarsync 메시지 로딩 시스템

# Loads message files based on TARSYNC_LANG environment variable
# TARSYNC_LANG 환경 변수에 따라 해당 언어의 메시지 파일을 로드합니다.

# Set script directory
# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function: Load tarsync messages
# 함수: tarsync 메시지 로드
load_tarsync_messages() {
    # Use language detection if TARSYNC_LANG is not set
    # TARSYNC_LANG이 설정되어 있지 않으면 언어 감지 사용
    local lang="${TARSYNC_LANG:-$(detect_system_language)}"
    local message_file="$SCRIPT_DIR/${lang}.sh"
    
    # Output loading information in debug mode
    # 디버그 모드라면 로딩 정보 출력
    if [ "$DEBUG" = "true" ]; then
        printf "Loading tarsync message file: %s\n" "$message_file" >&2
    fi
    
    # Load language-specific message file
    # 해당 언어 메시지 파일 로드
    if [ -f "$message_file" ]; then
        source "$message_file"
        export CURRENT_LANGUAGE="$lang"
        return 0
    else
        # Try to load English messages if language file not found
        # 언어 파일이 없으면 영어 메시지 로드 시도
        local en_message_file="$SCRIPT_DIR/en.sh"
        if [ -f "$en_message_file" ]; then
            source "$en_message_file"
            export CURRENT_LANGUAGE="en"
            if [ "$DEBUG" = "true" ]; then
                printf "Fallback to English: language file not found for %s\n" "$lang" >&2
            fi
            return 0
        else
            printf "Error: No language files found in %s\n" "$SCRIPT_DIR" >&2
            return 1
        fi
    fi
}

# Message output function
# 메시지 출력 함수
msg() {
    local key="$1"
    shift
    if [ -n "${!key}" ]; then
        printf "${!key}\n" "$@"
    else
        printf "Missing message: %s\n" "$key" >&2
    fi
}

# Colored message output function
# 색상 메시지 출력 함수
cmsg() {
    local color="$1"
    local key="$2"
    shift 2
    if [ -n "${!color}" ] && [ -n "${!key}" ]; then
        printf "${!color}${!key}${NC}\n" "$@"
    else
        msg "$key" "$@"
    fi
}

# Error message function
# 에러 메시지 함수
error_msg() {
    local key="$1"
    shift
    if [ -n "${RED}" ] && [ -n "${!key}" ]; then
        printf "${RED}${!key}${NC}\n" "$@" >&2
    else
        printf "${!key}\n" "$@" >&2
    fi
}

# Success message function  
# 성공 메시지 함수
success_msg() {
    local key="$1"
    shift
    if [ -n "${GREEN}" ] && [ -n "${!key}" ]; then
        printf "${GREEN}${!key}${NC}\n" "$@"
    else
        printf "${!key}\n" "$@"
    fi
}

# Load messages when executed directly
# 직접 실행 시 메시지 로드
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    load_tarsync_messages
fi