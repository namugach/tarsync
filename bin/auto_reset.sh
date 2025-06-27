#!/bin/bash

# tarsync reset script
# uninstall 후 install을 자동으로 실행하여 깨끗하게 다시 설치합니다.

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         TARSYNC AUTO RESET             ║${NC}"
echo -e "${CYAN}║     자동 제거 후 재설치 스크립트          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# 기존 설정 백업
BACKUP_DIR="/tmp/tarsync_reset_backup"
echo -e "${BLUE}[0/5] 기존 설정 백업 중...${NC}"

# 백업 디렉토리 생성
mkdir -p "$BACKUP_DIR"

# 기존 백업 데이터 확인 및 보존
if [ -d "/mnt/backup" ]; then
    BACKUP_COUNT=$(ls /mnt/backup/*.tar.gz 2>/dev/null | wc -l)
    if [ $BACKUP_COUNT -gt 0 ]; then
        echo -e "${YELLOW}📦 발견된 백업 파일: $BACKUP_COUNT 개${NC}"
        echo -e "${GREEN}✅ 백업 데이터는 보존됩니다 (/mnt/backup)${NC}"
    fi
fi

# 기존 설정 파일 백업
if [ -f "$HOME/.bashrc" ]; then
    cp "$HOME/.bashrc" "$BACKUP_DIR/bashrc.backup" 2>/dev/null
fi
if [ -f "$HOME/.zshrc" ]; then
    cp "$HOME/.zshrc" "$BACKUP_DIR/zshrc.backup" 2>/dev/null
fi

echo -e "${BLUE}[1/5] 기존 tarsync 제거 중...${NC}"
# uninstall.sh에 자동으로 'y'를 입력하여 확인 없이 진행
if [ -f "./uninstall.sh" ]; then
    echo "y" | sudo ./uninstall.sh 2>/dev/null || echo -e "${YELLOW}⚠️  제거할 기존 설치가 없습니다${NC}"
else
    echo -e "${YELLOW}⚠️  uninstall.sh를 찾을 수 없습니다${NC}"
fi

echo -e "${BLUE}[2/5] 남은 설치 파일 정리 중...${NC}"
# 시스템 설치 파일 정리
sudo rm -rf /usr/local/bin/tarsync 2>/dev/null
sudo rm -rf /usr/local/lib/tarsync 2>/dev/null
sudo rm -rf /usr/local/share/bash-completion/completions/tarsync 2>/dev/null
sudo rm -rf /usr/local/share/bash-completion/completions/completion-common.sh 2>/dev/null
sudo rm -rf /usr/local/share/zsh/site-functions/_tarsync 2>/dev/null

# 홈 디렉토리 설치 파일 정리
rm -rf ~/.tarsync 2>/dev/null

# 쉘 설정에서 tarsync 관련 라인 제거
if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# Tarsync completion/d' "$HOME/.bashrc" 2>/dev/null
    sed -i '/tarsync.*completion/d' "$HOME/.bashrc" 2>/dev/null
fi
if [ -f "$HOME/.zshrc" ]; then
    sed -i '/# Tarsync completion/d' "$HOME/.zshrc" 2>/dev/null
    sed -i '/tarsync.*completion/d' "$HOME/.zshrc" 2>/dev/null
fi

echo -e "${GREEN}✅ 정리 완료${NC}"

echo -e "${BLUE}[3/5] tarsync 다시 설치 중...${NC}"
# install.sh 자동 실행 (확인 없이)
if [ -f "./install.sh" ]; then
    echo "y" | sudo ./install.sh
    INSTALL_STATUS=$?
else
    echo -e "${RED}❌ install.sh를 찾을 수 없습니다${NC}"
    exit 1
fi

echo -e "${BLUE}[4/5] 설치 검증 중...${NC}"
# 설치 검증
if [ $INSTALL_STATUS -eq 0 ]; then
    # 실행파일 확인
    if command -v tarsync >/dev/null 2>&1; then
        echo -e "${GREEN}✅ tarsync 명령어 설치 확인${NC}"
    else
        echo -e "${YELLOW}⚠️  PATH에서 tarsync를 찾을 수 없습니다${NC}"
    fi
    
    # 자동완성 확인
    if [ -f "$HOME/.tarsync/completion/bash.sh" ] || [ -f "/usr/local/share/bash-completion/completions/tarsync" ]; then
        echo -e "${GREEN}✅ 자동완성 설치 확인${NC}"
    else
        echo -e "${YELLOW}⚠️  자동완성 파일을 찾을 수 없습니다${NC}"
    fi
else
    echo -e "${RED}❌ 설치 중 오류가 발생했습니다${NC}"
    
    # 백업 복원
    echo -e "${BLUE}백업 복원 중...${NC}"
    if [ -f "$BACKUP_DIR/bashrc.backup" ]; then
        cp "$BACKUP_DIR/bashrc.backup" "$HOME/.bashrc"
    fi
    if [ -f "$BACKUP_DIR/zshrc.backup" ]; then
        cp "$BACKUP_DIR/zshrc.backup" "$HOME/.zshrc"
    fi
    
    exit 1
fi

echo -e "${BLUE}[5/5] 리셋 완료!${NC}"
echo ""
echo -e "${GREEN}🎉 tarsync이 성공적으로 재설치되었습니다!${NC}"
echo ""
echo -e "${PURPLE}📋 설치 정보:${NC}"
if command -v tarsync >/dev/null 2>&1; then
    TARSYNC_PATH=$(which tarsync)
    echo "   • 실행파일: $TARSYNC_PATH"
else
    echo "   • 실행파일: /usr/local/bin/tarsync (PATH 새로고침 필요)"
fi

if [ -f "$HOME/.tarsync/completion/bash.sh" ]; then
    echo "   • 자동완성: ~/.tarsync/completion/ (홈 디렉토리 방식)"
elif [ -f "/usr/local/share/bash-completion/completions/tarsync" ]; then
    echo "   • 자동완성: /usr/local/share/bash-completion/completions/ (시스템 방식)"
fi

if [ $BACKUP_COUNT -gt 0 ]; then
    echo "   • 백업 데이터: /mnt/backup ($BACKUP_COUNT 개 파일 보존됨)"
fi

echo ""
echo -e "${CYAN}🚀 테스트를 위해 새 쉘을 열거나 다음 명령어를 실행하세요:${NC}"
echo -e "${YELLOW}   source ~/.bashrc${NC}    # Bash 사용자"
echo -e "${YELLOW}   source ~/.zshrc${NC}     # ZSH 사용자"
echo ""
echo -e "${CYAN}💡 빠른 테스트:${NC}"
echo -e "${YELLOW}   tarsync help${NC}        # 도움말"
echo -e "${YELLOW}   tarsync version${NC}     # 버전 확인"
echo -e "${YELLOW}   tarsync list${NC}        # 백업 목록"
echo ""

# 백업 디렉토리 정리
rm -rf "$BACKUP_DIR" 2>/dev/null

exit 0 