#!/bin/bash

# 로깅 유틸리티 함수들
# Logging utility functions

# 색상 정의 로드
# Load color definitions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/colors.sh"

# 메인 로깅 함수 (common.sh의 log 함수와 호환)
# Main logging function (compatible with log function in common.sh)
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 로그 파일 경로가 설정되어 있으면 파일에 기록
    # Write to log file if LOG_FILE is set
    if [ -n "$LOG_FILE" ] && [ -d "$(dirname "$LOG_FILE")" ]; then
        # 로그 파일이 없으면 생성
        # Create log file if it doesn't exist
        if [ ! -f "$LOG_FILE" ]; then
            touch "$LOG_FILE"
        fi
        
        # 모든 로그는 파일에 기록
        # Write all logs to file
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
    
    # 화면에 표시
    # Display on screen
    case "$level" in
        "ERROR"|"CRITICAL")
            echo -e "${RED}[$level]${NC} $message" >&2
            ;;
        "WARNING"|"WARN")
            echo -e "${YELLOW}[$level]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[$level]${NC} $message"
            ;;
        "INFO")
            # INFO 레벨은 기본 색상으로 출력
            # INFO level is displayed with default color
            echo -e "${PURPLE}[$level]${NC} $message"
            ;;
        "DEBUG")
            # DEBUG 레벨은 디버그 모드에서만 출력
            # DEBUG level is only displayed in debug mode
            if [ "${DEBUG:-false}" = "true" ]; then
                echo -e "${BLUE}[$level]${NC} $message"
            fi
            ;;
        *)
            # 그 외의 레벨은 기본 색상으로 출력
            # Other levels are displayed with default color
            echo -e "[$level] $message"
            ;;
    esac
}

# 단축 로깅 함수들
# Shorthand logging functions
log_info() {
    log "INFO" "$1"
}

log_warn() {
    log "WARNING" "$1"
}

log_error() {
    log "ERROR" "$1"
}

log_success() {
    log "SUCCESS" "$1"
}

log_debug() {
    log "DEBUG" "$1"
}

log_critical() {
    log "CRITICAL" "$1"
}

# 로그 파일 설정 함수
# Set log file function
set_log_file() {
    export LOG_FILE="$1"
    log_debug "Log file set to: $LOG_FILE"
}

# 디버그 모드 설정 함수
# Set debug mode function
set_debug_mode() {
    export DEBUG="$1"
    log_debug "Debug mode set to: $DEBUG"
} 