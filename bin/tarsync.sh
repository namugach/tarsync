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

# 모듈 경로들
BACKUP_MODULE="$PROJECT_ROOT/src/modules/backup.sh"
RESTORE_MODULE="$PROJECT_ROOT/src/modules/restore.sh"
LIST_MODULE="$PROJECT_ROOT/src/modules/list.sh"

# 프로그램 이름
PROGRAM_NAME="tarsync"

# sudo 권한 체크 함수
check_sudo_privileges() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ 시스템 백업/복구를 위해서는 sudo 권한이 필요합니다${NC}" >&2
        echo -e "${YELLOW}💡 다음과 같이 실행해주세요: ${WHITE}sudo $PROGRAM_NAME $*${NC}" >&2
        echo ""
        echo -e "${CYAN}📖 권한이 필요한 이유:${NC}"
        echo "  • 시스템 파일 읽기 권한 (/etc, /var, /root 등)"
        echo "  • 백업 파일 생성 권한"
        echo "  • 복구 시 원본 권한 복원"
        echo ""
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
        "list"|"ls"|"l"|"details"|"show"|"info"|"i"|"version"|"v"|"-v"|"--version"|"help"|"h"|"-h"|"--help")
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
    echo -e "${CYAN}$PROGRAM_NAME v$version${NC}"
    echo -e "${WHITE}Shell Script로 재작성된 안정적인 백업 및 복구 도구${NC}"
    echo ""
    echo -e "${YELLOW}사용법:${NC}"
    echo "  $PROGRAM_NAME <명령어> [인수]"
    echo ""
    echo -e "${YELLOW}주요 명령어:${NC}"
    echo -e "  ${GREEN}backup [경로]${NC}      # 특정 경로 또는 전체 시스템을 백업합니다. (기본값: /)"
    echo -e "  ${GREEN}restore [백업명] [대상]${NC} # 선택한 백업을 지정한 경로로 복구합니다."
    echo -e "  ${GREEN}list${NC}              # 생성된 백업 목록을 최신순으로 표시합니다."
    echo -e "  ${GREEN}delete <백업명>${NC}    # 지정한 백업을 영구적으로 삭제합니다."
    echo -e "  ${GREEN}details <백업명>${NC}   # 백업의 상세 정보를 표시합니다."
    echo ""
    echo -e "${YELLOW}기타 명령어:${NC}"
    echo -e "  ${GREEN}version${NC}           # 프로그램 버전 정보를 표시합니다."
    echo -e "  ${GREEN}help${NC}              # 이 도움말을 표시합니다."
    echo ""
    echo -e "${YELLOW}사용 예시:${NC}"
    echo "  sudo $PROGRAM_NAME backup /home/user    # /home/user 디렉토리 백업"
    echo "  sudo $PROGRAM_NAME restore              # 대화형 모드로 복구 시작"
    echo "  sudo $PROGRAM_NAME restore 1 /tmp/res   # 1번 백업을 /tmp/res에 복구"
    echo "  $PROGRAM_NAME list                      # 백업 목록 보기"
    echo "  sudo $PROGRAM_NAME delete backup_name   # 특정 백업 삭제"
}

# 버전 정보 표시
show_version() {
    local version=$(get_version)
    echo -e "${CYAN}$PROGRAM_NAME v$version${NC}"
    echo -e "${WHITE}Shell Script 기반 백업 도구${NC}"
    echo ""
    echo "📦 기능:"
    echo "  • tar+gzip 압축 백업"
    echo "  • rsync 기반 복구"
    echo "  • 페이지네이션 목록 관리"
    echo "  • 백업 무결성 검사"
    echo "  • 로그 관리"
    echo ""
    echo "🛠️  의존성:"
    echo "  • tar, gzip, rsync, pv, bc, jq"
    echo ""
    echo "Copyright (c) $(date +%Y)"
    echo "MIT License"
}



# 모듈 존재 확인
check_module() {
    local module_path="$1"
    local module_name="$2"
    
    if [[ ! -f "$module_path" ]]; then
        echo -e "${RED}❌ $module_name 모듈을 찾을 수 없습니다: $module_path${NC}" >&2
        return 1
    fi
    
    if [[ ! -x "$module_path" ]]; then
        chmod +x "$module_path" 2>/dev/null || {
            echo -e "${RED}❌ $module_name 모듈에 실행 권한을 설정할 수 없습니다: $module_path${NC}" >&2
            return 1
        }
    fi
    
    return 0
}

# 백업 명령어 처리
cmd_backup() {
    local backup_path="${1:-/}"
    
    echo -e "${BLUE}🔄 백업 시작: $backup_path${NC}"
    
    if ! check_module "$BACKUP_MODULE" "백업"; then
        exit 1
    fi
    
    bash "$BACKUP_MODULE" "$backup_path"
}

# 복구 명령어 처리 (단순화 버전)
cmd_restore() {
    local backup_name="$1"
    local target_path="$2"
    
    echo -e "${BLUE}🔄 복구 절차를 시작합니다.${NC}"
    
    if ! check_module "$RESTORE_MODULE" "복구"; then
        exit 1
    fi
    
    bash "$RESTORE_MODULE" "$backup_name" "$target_path"
}

# 목록 명령어 처리
cmd_list() {
    local page_size="${1:-10}"
    local page_num="${2:-1}"
    local select_list="${3:-0}"
    
    if ! check_module "$LIST_MODULE" "목록"; then
        exit 1
    fi
    
    bash "$LIST_MODULE" list "$page_size" "$page_num" "$select_list"
}

# 삭제 명령어 처리
cmd_delete() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        echo -e "${RED}❌ 삭제할 백업 이름을 지정해주세요.${NC}" >&2
        echo "   사용법: $PROGRAM_NAME delete <백업이름>"
        exit 1
    fi
    
    if ! check_module "$LIST_MODULE" "목록"; then
        exit 1
    fi
    
    bash "$LIST_MODULE" delete "$backup_name"
}

# 상세정보 명령어 처리
cmd_details() {
    local backup_name="$1"
    
    if [[ -z "$backup_name" ]]; then
        echo -e "${RED}❌ 조회할 백업 이름을 지정해주세요.${NC}" >&2
        echo "   사용법: $PROGRAM_NAME details <백업이름>"
        exit 1
    fi
    
    if ! check_module "$LIST_MODULE" "목록"; then
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
            echo -e "${RED}❌ 알 수 없는 명령어: $command${NC}" >&2
            echo ""
            echo -e "${YELLOW}사용 가능한 명령어:${NC}"
            echo "  backup, restore, list, delete, details, version, help"
            echo ""
            echo -e "${CYAN}도움말 보기: $PROGRAM_NAME help${NC}"
            exit 1
            ;;
    esac
}

# 스크립트가 직접 실행된 경우
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 