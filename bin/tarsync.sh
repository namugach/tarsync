#!/bin/bash
# tarsync 메인 CLI 스크립트
# 모든 모듈들을 통합하는 사용자 인터페이스

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 유틸리티 로드
source "$PROJECT_ROOT/src/utils/colors.sh"

# 버전 관리 유틸리티 로드
source "$PROJECT_ROOT/src/utils/version.sh"

# 언어 감지 및 메시지 시스템 로드
source "$PROJECT_ROOT/config/messages/detect.sh"
source "$PROJECT_ROOT/config/messages/load.sh"

# 메시지 시스템 초기화
load_tarsync_messages

# 모듈 경로들
BACKUP_MODULE="$PROJECT_ROOT/src/modules/backup.sh"
RESTORE_MODULE="$PROJECT_ROOT/src/modules/restore.sh"
LIST_MODULE="$PROJECT_ROOT/src/modules/list.sh"

# 프로그램 이름
PROGRAM_NAME="tarsync"

# sudo 권한 체크 함수
check_sudo_privileges() {
    if [ "$EUID" -ne 0 ]; then
        error_msg "MSG_ERROR_SUDO_REQUIRED" >&2
        printf "${YELLOW}" >&2
        msg "MSG_ERROR_SUDO_HINT" "${WHITE}" "$PROGRAM_NAME" "$*" "${NC}" >&2
        echo "" >&2
        printf "${CYAN}" >&2
        msg "MSG_ERROR_SUDO_REASON" >&2
        printf "${NC}" >&2
        msg "MSG_ERROR_SUDO_REASON_FILES" >&2
        msg "MSG_ERROR_SUDO_REASON_BACKUP" >&2
        msg "MSG_ERROR_SUDO_REASON_RESTORE" >&2
        echo "" >&2
        exit 1
    fi
}

# 명령어별 sudo 필요 여부 확인
requires_sudo() {
    local command="$1"
    case "$command" in
        "backup"|"b"|"restore"|"r"|"delete"|"rm"|"d")
            return 0  # sudo 필요 (쓰기/수정 작업)
            ;;
        "list"|"ls"|"l"|"log"|"details"|"show"|"info"|"i"|"version"|"v"|"-v"|"--version"|"help"|"h"|"-h"|"--help")
            return 1  # sudo 불필요 (읽기 전용 작업)
            ;;
        *)
            return 0  # 알 수 없는 명령어는 안전하게 sudo 필요로 처리
            ;;
    esac
}

# 도움말 표시
show_help() {
    local version=$(get_version)
    printf "${CYAN}"
    msg "MSG_VERSION_HEADER" "$PROGRAM_NAME" "$version"
    printf "${NC}\n"
    printf "${WHITE}"
    msg "MSG_HELP_DESCRIPTION"
    printf "${NC}\n"
    echo ""
    printf "${YELLOW}"
    msg "MSG_HELP_USAGE"
    printf "${NC}\n"
    echo ""
    printf "${YELLOW}"
    msg "MSG_HELP_COMMANDS"
    printf "${NC}\n"
    printf "  ${GREEN}"
    msg "MSG_HELP_BACKUP"
    printf "${NC}\n"
    printf "  ${GREEN}"
    msg "MSG_HELP_RESTORE"
    printf "${NC}\n"
    printf "  ${GREEN}"
    msg "MSG_HELP_LIST"
    printf "${NC}\n"
    printf "  ${GREEN}"
    msg "MSG_HELP_LOG"
    printf "${NC}\n"
    printf "  ${GREEN}"
    msg "MSG_HELP_DELETE"
    printf "${NC}\n"
    printf "  ${GREEN}"
    msg "MSG_HELP_DETAILS"
    printf "${NC}\n"
    echo ""
    printf "${YELLOW}"
    msg "MSG_HELP_OTHER_COMMANDS"
    printf "${NC}\n"
    printf "  ${GREEN}"
    msg "MSG_HELP_VERSION"
    printf "${NC}\n"
    printf "  ${GREEN}"
    msg "MSG_HELP_HELP"
    printf "${NC}\n"
    echo ""
    printf "${YELLOW}"
    msg "MSG_HELP_EXAMPLES"
    printf "${NC}\n"
    msg "MSG_HELP_EXAMPLE_BACKUP" "$PROGRAM_NAME"
    msg "MSG_HELP_EXAMPLE_RESTORE" "$PROGRAM_NAME"
    msg "MSG_HELP_EXAMPLE_RESTORE_TARGET" "$PROGRAM_NAME"
    msg "MSG_HELP_EXAMPLE_LIST" "$PROGRAM_NAME"
    msg "MSG_HELP_EXAMPLE_LOG" "$PROGRAM_NAME"
    msg "MSG_HELP_EXAMPLE_DELETE" "$PROGRAM_NAME"
}

# 버전 정보 표시
show_version() {
    local version=$(get_version)
    printf "${CYAN}"
    msg "MSG_VERSION_HEADER" "$PROGRAM_NAME" "$version"
    printf "${NC}\n"
    printf "${WHITE}"
    msg "MSG_VERSION_DESCRIPTION"
    printf "${NC}\n"
    echo ""
    msg "MSG_VERSION_FEATURES"
    msg "MSG_VERSION_FEATURE_BACKUP"
    msg "MSG_VERSION_FEATURE_RESTORE"
    msg "MSG_VERSION_FEATURE_LIST"
    msg "MSG_VERSION_FEATURE_INTEGRITY"
    msg "MSG_VERSION_FEATURE_LOG"
    echo ""
    msg "MSG_VERSION_DEPENDENCIES"
    msg "MSG_VERSION_DEPS_LIST"
    echo ""
    msg "MSG_VERSION_COPYRIGHT" "$(date +%Y)"
    echo "MIT License"
}



# 모듈 존재 확인
check_module() {
    local module_path="$1"
    local module_name="$2"
    
    if [[ ! -f "$module_path" ]]; then
        error_msg "MSG_SYSTEM_FILE_NOT_FOUND" "$module_path" >&2
        return 1
    fi
    
    if [[ ! -x "$module_path" ]]; then
        chmod +x "$module_path" 2>/dev/null || {
            error_msg "MSG_SYSTEM_PERMISSION_DENIED" "$module_path" >&2
            return 1
        }
    fi
    
    return 0
}

# 백업 명령어 처리
cmd_backup() {
    local backup_path="${1:-/}"
    
    printf "${BLUE}"
    msg "MSG_BACKUP_START"
    printf "${NC}\n"
    
    if ! check_module "$BACKUP_MODULE" "backup"; then
        exit 1
    fi
    
    bash "$BACKUP_MODULE" "$backup_path"
}

# 복구 명령어 처리 (단순화 버전)
cmd_restore() {
    local backup_name="$1"
    local target_path="$2"
    
    printf "${BLUE}"
    msg "MSG_RESTORE_PREPARING"
    printf "${NC}\n"
    
    if ! check_module "$RESTORE_MODULE" "restore"; then
        exit 1
    fi
    
    bash "$RESTORE_MODULE" "$backup_name" "$target_path"
}

# 목록 명령어 처리
cmd_list() {
    local page_size="${1:-10}"
    local page_num="${2:-1}"
    local select_list="${3:-0}"
    
    if ! check_module "$LIST_MODULE" "list"; then
        exit 1
    fi
    
    bash "$LIST_MODULE" list "$page_size" "$page_num" "$select_list"
}

# 로그 명령어 처리
cmd_log() {
    local backup_identifier="$1"
    
    if [[ -z "$backup_identifier" ]]; then
        error_msg "MSG_ERROR_MISSING_ARGUMENT" "log <number|backup_name>" >&2
        printf "   "
        msg "MSG_HELP_USAGE" >&2
        printf ": $PROGRAM_NAME log <number|backup_name>\n" >&2
        exit 1
    fi
    
    if ! check_module "$LIST_MODULE" "list"; then
        exit 1
    fi
    
    bash "$LIST_MODULE" log "$backup_identifier"
}

# 삭제 명령어 처리
cmd_delete() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        error_msg "MSG_ERROR_MISSING_ARGUMENT" "delete <backup_name>" >&2
        printf "   "
        msg "MSG_HELP_USAGE" >&2
        printf ": $PROGRAM_NAME delete <backup_name>\n" >&2
        exit 1
    fi
    
    if ! check_module "$LIST_MODULE" "list"; then
        exit 1
    fi
    
    bash "$LIST_MODULE" delete "$backup_name"
}

# 상세정보 명령어 처리
cmd_details() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        error_msg "MSG_ERROR_MISSING_ARGUMENT" "details <backup_name>" >&2
        printf "   "
        msg "MSG_HELP_USAGE" >&2
        printf ": $PROGRAM_NAME details <backup_name>\n" >&2
        exit 1
    fi
    
    if ! check_module "$LIST_MODULE" "list"; then
        exit 1
    fi
    
    bash "$LIST_MODULE" details "$backup_name"
}

# 메인 함수
main() {
    local command="${1:-help}"
    
    if requires_sudo "$command"; then
        check_sudo_privileges
    fi
    
    case "$command" in
        "backup"|"b")
            cmd_backup "${@:2}"
            ;;
        "restore"|"r")
            cmd_restore "${@:2}"
            ;;
        "list"|"ls"|"l")
            cmd_list "${@:2}"
            ;;
        "log")
            cmd_log "${@:2}"
            ;;
        "delete"|"rm"|"d")
            cmd_delete "${@:2}"
            ;;
        "details"|"show"|"info"|"i")
            cmd_details "${@:2}"
            ;;
        "version"|"v"|"-v"|"--version")
            show_version
            ;;
        "help"|"h"|"-h"|"--help")
            show_help
            ;;
        *)
            error_msg "MSG_ERROR_INVALID_COMMAND" "$command" >&2
            echo ""
            printf "${YELLOW}"
            msg "MSG_HELP_COMMANDS"
            printf "${NC}\n"
            echo "  backup, restore, list, log, delete, details, version, help"
            echo ""
            printf "${CYAN}"
            printf "Help: $PROGRAM_NAME help"
            printf "${NC}\n"
            exit 1
            ;;
    esac
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 