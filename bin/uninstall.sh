#!/bin/bash
# tarsync 제거 스크립트
# 시스템에서 tarsync를 완전히 제거합니다

set -e  # 에러 발생시 스크립트 종료

# 스크립트 경로 설정 (설치 스크립트와 동일한 위치에 있음)  
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

# 시스템 bash completion 디렉토리들
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

# 설치 상태 확인
check_installation() {
    local installed=false
    local found_files=()
    
    echo -e "${BLUE}🔍 설치 상태 확인 중...${NC}"
    
    # 실행파일 확인
    if [[ -f "$BIN_DIR/tarsync" ]]; then
        found_files+=("실행파일: $BIN_DIR/tarsync")
        installed=true
    fi
    
    # 라이브러리 디렉토리 확인
    if [[ -d "$LIB_DIR" ]]; then
        found_files+=("라이브러리: $LIB_DIR")
        installed=true
    fi
    
    # 자동완성 파일 확인 (여러 위치)
    local completion_found=false
    for dir in "$COMPLETION_DIR" "${SYSTEM_COMPLETION_DIRS[@]}"; do
        if [[ -f "$dir/tarsync" ]]; then
            found_files+=("자동완성: $dir/tarsync")
            completion_found=true
            break
        fi
    done
    
    if [[ "$installed" == false ]]; then
        echo -e "${YELLOW}⚠️  $PROGRAM_NAME이 설치되어 있지 않습니다.${NC}"
        echo ""
        echo -e "${BLUE}💡 다음 위치에서 확인했습니다:${NC}"
        echo "   • $BIN_DIR/tarsync"
        echo "   • $LIB_DIR/"
        echo "   • $COMPLETION_DIR/tarsync"
        for dir in "${SYSTEM_COMPLETION_DIRS[@]}"; do
            echo "   • $dir/tarsync"
        done
        exit 0
    fi
    
    echo -e "${GREEN}✅ 다음 설치된 파일들을 찾았습니다:${NC}"
    for file in "${found_files[@]}"; do
        echo "   • $file"
    done
    echo ""
    
    return 0
}

# 사용자 확인
confirm_removal() {
    echo -e "${YELLOW}⚠️  정말로 $PROGRAM_NAME을 제거하시겠습니까?${NC}"
    echo -e "${RED}🗑️  이 작업은 되돌릴 수 없습니다!${NC}"
    echo ""
    echo -e "${BLUE}💡 참고: 백업 데이터(/mnt/backup)는 삭제되지 않습니다.${NC}"
    echo ""
    
    read -p "제거하려면 'yes'를 입력하세요: " -r
    if [[ ! $REPLY == "yes" ]]; then
        echo -e "${BLUE}✋ 제거가 취소되었습니다.${NC}"
        exit 0
    fi
    
    echo ""
    echo -e "${RED}🚀 제거를 시작합니다...${NC}"
    echo ""
}

# 파일 제거
remove_files() {
    local removed_count=0
    
    echo -e "${BLUE}🗑️  파일 제거 중...${NC}"
    
    # 실행파일 제거
    if [[ -f "$BIN_DIR/tarsync" ]]; then
        rm -f "$BIN_DIR/tarsync"
        echo -e "${GREEN}✅ 실행파일 삭제: $BIN_DIR/tarsync${NC}"
        ((removed_count++))
    fi
    
    # 라이브러리 디렉토리 제거
    if [[ -d "$LIB_DIR" ]]; then
        rm -rf "$LIB_DIR"
        echo -e "${GREEN}✅ 라이브러리 삭제: $LIB_DIR${NC}"
        ((removed_count++))
    fi
    
    # 자동완성 파일 제거 (모든 가능한 위치에서)
    local completion_removed=false
    for dir in "$COMPLETION_DIR" "${SYSTEM_COMPLETION_DIRS[@]}"; do
        if [[ -f "$dir/tarsync" ]]; then
            rm -f "$dir/tarsync"
            echo -e "${GREEN}✅ 자동완성 삭제: $dir/tarsync${NC}"
            completion_removed=true
            ((removed_count++))
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  제거할 파일을 찾지 못했습니다.${NC}"
    else
        echo -e "${GREEN}✅ 총 $removed_count개 항목이 제거되었습니다.${NC}"
    fi
}

# hash 테이블 정리
clear_command_cache() {
    echo -e "${BLUE}🧹 명령어 캐시 정리 중...${NC}"
    
    # bash의 명령어 해시 테이블에서 tarsync 제거
    hash -d tarsync 2>/dev/null || true
    
    echo -e "${GREEN}✅ 명령어 캐시 정리 완료${NC}"
}

# 제거 완료 메시지
show_success() {
    echo ""
    echo -e "${GREEN}🎉 $PROGRAM_NAME 제거 완료!${NC}"
    echo ""
    echo -e "${YELLOW}📋 후속 작업:${NC}"
    echo "   1. 현재 터미널 세션에서 tarsync 명령어가 여전히 작동할 수 있습니다."
    echo "   2. 새 터미널을 열어서 완전한 제거를 확인하세요."
    echo "   3. 자동완성이 여전히 작동한다면 다음 명령어를 실행하세요:"
    echo "      hash -r"
    echo ""
    echo -e "${BLUE}💾 백업 데이터는 그대로 유지됩니다:${NC}"
    echo "   • 백업 파일들: /mnt/backup/*.tar.gz"
    echo "   • 메타데이터: /mnt/backup/*.sh"
    echo ""
    echo -e "${CYAN}🔄 재설치하려면:${NC}"
    echo "   sudo ./install.sh"
    echo ""
}

# 백업 데이터 정보
show_backup_info() {
    if [[ -d "/mnt/backup" ]]; then
        local backup_count=$(find /mnt/backup -maxdepth 1 -name "*.tar.gz" 2>/dev/null | wc -l)
        local backup_size=$(du -sh /mnt/backup 2>/dev/null | cut -f1 || echo "알 수 없음")
        
        if [[ $backup_count -gt 0 ]]; then
            echo -e "${BLUE}📦 백업 데이터 현황:${NC}"
            echo "   • 백업 개수: $backup_count개"
            echo "   • 전체 크기: $backup_size"
            echo "   • 저장 위치: /mnt/backup"
            echo ""
            echo -e "${YELLOW}💡 백업 데이터를 삭제하려면 수동으로 제거하세요:${NC}"
            echo "      sudo rm -rf /mnt/backup"
            echo ""
        fi
    fi
}

# 메인 제거 프로세스
main() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          TARSYNC 제거 도구             ║${NC}"
    echo -e "${CYAN}║      Shell Script 백업 시스템          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    check_root
    check_installation
    show_backup_info
    confirm_removal
    remove_files
    clear_command_cache
    show_success
}

# 스크립트 직접 실행시
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 