#!/bin/bash
# tarsync 설치 스크립트
# 시스템에 tarsync를 설치하고 자동완성 기능을 추가합니다

set -e  # 에러 발생시 스크립트 종료

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 색상 유틸리티 로드
source "$PROJECT_ROOT/src/utils/colors.sh"

# 상수 정의
PROGRAM_NAME="tarsync"
VERSION="1.0.0"

# 설치 경로들
INSTALL_PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="$INSTALL_PREFIX/bin"
LIB_DIR="$INSTALL_PREFIX/lib/$PROGRAM_NAME"
COMPLETION_DIR="$INSTALL_PREFIX/share/bash-completion/completions"

# 시스템 bash completion 디렉토리들 (fallback)
SYSTEM_COMPLETION_DIRS=(
    "/etc/bash_completion.d"
    "/usr/share/bash-completion/completions"
    "/usr/local/share/bash-completion/completions"
)

# 사용자가 root인지 확인
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}⚠️  root 권한이 필요합니다. sudo를 사용해주세요.${NC}" >&2
        echo "   사용법: sudo $0"
        exit 1
    fi
}

# 필수 명령어 확인
check_dependencies() {
    local deps=("tar" "gzip" "rsync" "pv" "bc")
    local missing=()
    
    echo -e "${BLUE}🔍 필수 의존성 확인 중...${NC}"
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}❌ 누락된 의존성: ${missing[*]}${NC}" >&2
        echo -e "${YELLOW}💡 다음 명령어로 설치하세요:${NC}"
        echo "   Ubuntu/Debian: sudo apt install ${missing[*]}"
        echo "   CentOS/RHEL: sudo yum install ${missing[*]}"
        echo "   Arch Linux: sudo pacman -S ${missing[*]}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 모든 의존성이 충족되었습니다.${NC}"
}

# 디렉토리 생성
create_directories() {
    echo -e "${BLUE}📁 설치 디렉토리 생성 중...${NC}"
    
    mkdir -p "$BIN_DIR"
    mkdir -p "$LIB_DIR"
    mkdir -p "$COMPLETION_DIR" 2>/dev/null || {
        # 기본 completion 디렉토리 생성에 실패하면 대안 찾기
        for dir in "${SYSTEM_COMPLETION_DIRS[@]}"; do
            if [[ -d "$(dirname "$dir")" ]]; then
                COMPLETION_DIR="$dir"
                mkdir -p "$COMPLETION_DIR" 2>/dev/null && break
            fi
        done
    }
    
    echo -e "${GREEN}✅ 디렉토리 생성 완료${NC}"
    echo "   • 실행파일: $BIN_DIR"
    echo "   • 라이브러리: $LIB_DIR" 
    echo "   • 자동완성: $COMPLETION_DIR"
}

# 파일 복사
copy_files() {
    echo -e "${BLUE}📋 파일 복사 중...${NC}"
    
    # 메인 실행 파일 복사
    cp "$PROJECT_ROOT/bin/tarsync.sh" "$BIN_DIR/tarsync"
    chmod +x "$BIN_DIR/tarsync"
    
    # 모든 소스 파일 복사
    cp -r "$PROJECT_ROOT/src" "$LIB_DIR/"
    cp -r "$PROJECT_ROOT/config" "$LIB_DIR/"
    
    # 소스 파일들에 실행 권한 부여
    find "$LIB_DIR" -name "*.sh" -exec chmod +x {} \;
    
    echo -e "${GREEN}✅ 파일 복사 완료${NC}"
}

# 자동완성 스크립트 생성
create_completion() {
    echo -e "${BLUE}⚡ 자동완성 스크립트 생성 중...${NC}"
    
    cat > "$COMPLETION_DIR/tarsync" << 'EOF'
#!/bin/bash
# tarsync 자동완성 스크립트

_tarsync_completion() {
    local cur prev opts backup_names
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 메인 명령어들
    local commands="backup restore list delete details version help"
    local short_commands="b r ls l rm d show info i v h"
    
    # 백업 목록 가져오기 (저장소가 존재할 때만)
    if [[ -d "/mnt/backup" ]]; then
        backup_names=$(find /mnt/backup -maxdepth 1 -name "*.tar.gz" -printf "%f\n" 2>/dev/null | sed 's/\.tar\.gz$//' | sort)
    fi
    
    case $prev in
        tarsync)
            # 첫 번째 인수: 명령어들
            COMPREPLY=($(compgen -W "$commands $short_commands" -- "$cur"))
            return 0
            ;;
        backup|b)
            # backup 명령어 다음: 디렉토리 경로
            COMPREPLY=($(compgen -d -- "$cur"))
            return 0
            ;;
        restore|r)
            # restore 명령어 다음: 백업 이름들
            if [[ -n "$backup_names" ]]; then
                COMPREPLY=($(compgen -W "$backup_names" -- "$cur"))
            fi
            return 0
            ;;
        delete|rm|d|details|show|info|i)
            # delete/details 명령어 다음: 백업 이름들
            if [[ -n "$backup_names" ]]; then
                COMPREPLY=($(compgen -W "$backup_names" -- "$cur"))
            fi
            return 0
            ;;
        list|ls|l)
            # list 명령어 다음: 숫자 (페이지 크기)
            COMPREPLY=($(compgen -W "5 10 15 20" -- "$cur"))
            return 0
            ;;
    esac
    
    # restore 명령어의 추가 인수들
    if [[ ${COMP_WORDS[1]} == "restore" || ${COMP_WORDS[1]} == "r" ]]; then
        case $COMP_CWORD in
            3)
                # 세 번째 인수: 복구 대상 경로
                COMPREPLY=($(compgen -d -- "$cur"))
                return 0
                ;;
            4)
                # 네 번째 인수: 시뮬레이션 모드
                COMPREPLY=($(compgen -W "true false" -- "$cur"))
                return 0
                ;;
            5)
                # 다섯 번째 인수: 삭제 모드
                COMPREPLY=($(compgen -W "true false" -- "$cur"))
                return 0
                ;;
        esac
    fi
    
    return 0
}

# tarsync 명령어에 대한 자동완성 등록
complete -F _tarsync_completion tarsync
EOF
    
    chmod +r "$COMPLETION_DIR/tarsync"
    echo -e "${GREEN}✅ 자동완성 스크립트 생성 완료${NC}"
}

# 심볼릭 링크 업데이트 (메인 실행파일의 경로 수정)
update_main_script() {
    echo -e "${BLUE}🔧 메인 스크립트 경로 수정 중...${NC}"
    
    # 설치된 tarsync 스크립트의 경로를 수정
    sed -i "s|PROJECT_ROOT=\"\$(dirname \"\$SCRIPT_DIR\")\"|PROJECT_ROOT=\"$LIB_DIR\"|g" "$BIN_DIR/tarsync"
    
    echo -e "${GREEN}✅ 스크립트 경로 수정 완료${NC}"
}

# 설치 완료 메시지
show_success() {
    echo ""
    echo -e "${GREEN}🎉 $PROGRAM_NAME v$VERSION 설치 완료!${NC}"
    echo ""
    echo -e "${CYAN}📍 설치 위치:${NC}"
    echo "   • 실행파일: $BIN_DIR/tarsync"
    echo "   • 라이브러리: $LIB_DIR"
    echo "   • 자동완성: $COMPLETION_DIR/tarsync"
    echo ""
    echo -e "${YELLOW}🚀 사용 시작:${NC}"
    echo "   1. 새 터미널을 열거나 다음 명령어 실행:"
    echo "      source $COMPLETION_DIR/tarsync  # 자동완성 활성화"
    echo ""
    echo "   2. tarsync 명령어 사용:"
    echo "      tarsync help                    # 도움말"
    echo "      tarsync backup /home/user       # 백업"
    echo "      tarsync list                    # 목록"
    echo ""
    echo -e "${BLUE}💡 탭 키를 눌러서 자동완성 기능을 사용해보세요!${NC}"
    echo ""
}

# 메인 설치 프로세스
main() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           TARSYNC 설치 도구            ║${NC}"
    echo -e "${CYAN}║      Shell Script 백업 시스템          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    check_dependencies
    create_directories
    copy_files
    update_main_script
    create_completion
    show_success
}

# 스크립트 직접 실행시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 