#!/bin/bash
# 색상 정의 유틸리티
# 모든 tarsync 스크립트에서 공통으로 사용하는 색상들

# ANSI 색상 코드
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# 상황별 색상 별칭
SUCCESS="$GREEN"
WARNING="$YELLOW"
ERROR="$RED"
INFO="$BLUE"
HIGHLIGHT="$CYAN"
TITLE="$WHITE"
SUBTITLE="$PURPLE"

# 모든 색상 변수 export
export RED GREEN YELLOW BLUE PURPLE CYAN WHITE GRAY BOLD DIM NC
export SUCCESS WARNING ERROR INFO HIGHLIGHT TITLE SUBTITLE

# 색상 테스트 함수 (디버깅용)
test_colors() {
    echo -e "${RED}RED 색상 테스트${NC}"
    echo -e "${GREEN}GREEN 색상 테스트${NC}"
    echo -e "${YELLOW}YELLOW 색상 테스트${NC}"
    echo -e "${BLUE}BLUE 색상 테스트${NC}"
    echo -e "${PURPLE}PURPLE 색상 테스트${NC}"
    echo -e "${CYAN}CYAN 색상 테스트${NC}"
    echo -e "${WHITE}WHITE 색상 테스트${NC}"
    echo -e "${GRAY}GRAY 색상 테스트${NC}"
    echo -e "${BOLD}BOLD 텍스트 테스트${NC}"
    echo -e "${DIM}DIM 텍스트 테스트${NC}"
}

# 색상 비활성화 함수 (파이프 출력 등에서 사용)
disable_colors() {
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    WHITE=''
    GRAY=''
    BOLD=''
    DIM=''
    NC=''
    SUCCESS=''
    WARNING=''
    ERROR=''
    INFO=''
    HIGHLIGHT=''
    TITLE=''
    SUBTITLE=''
}

# 터미널이 색상을 지원하지 않으면 비활성화
if [[ ! -t 1 ]] || [[ "${NO_COLOR:-}" == "1" ]] || [[ "${TERM}" == "dumb" ]]; then
    disable_colors
fi 