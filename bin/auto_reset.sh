#!/bin/bash

# tarsync reset script
# uninstall 후 install을 자동으로 실행하여 깨끗하게 다시 설치합니다.

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# 현재 백업 디렉토리 설정 백업 (있다면)
if [ -f "$HOME/.tarsync/config/settings.env" ]; then
    CURRENT_BACKUP_DIR=$(grep "BACKUP_DIR=" "$HOME/.tarsync/config/settings.env" | cut -d'=' -f2)
    echo "현재 백업 디렉토리 설정: $CURRENT_BACKUP_DIR"
else
    CURRENT_BACKUP_DIR="/mnt/backup"  # 기본값
fi

echo -e "\n[1/4] 기존 tarsync 제거 중..."
# uninstall.sh에 자동으로 'y'를 입력하여 확인 없이 진행
if [ -f "./uninstall.sh" ]; then
    echo "y" | ./uninstall.sh 2>/dev/null || echo "제거할 기존 설치가 없습니다."
else
    echo "uninstall.sh를 찾을 수 없습니다."
fi

echo -e "\n[2/4] 남은 설치 파일 정리 중..."
# 홈 디렉토리 설치 파일 정리
rm -rf ~/.tarsync 2>/dev/null

# 쉘 설정에서 tarsync 관련 라인 제거
if [ -f "$HOME/.bashrc" ]; then
    sed -i '/# Tarsync/d' "$HOME/.bashrc" 2>/dev/null
    sed -i '/tarsync/d' "$HOME/.bashrc" 2>/dev/null
fi
if [ -f "$HOME/.zshrc" ]; then
    sed -i '/# Tarsync/d' "$HOME/.zshrc" 2>/dev/null
    sed -i '/tarsync/d' "$HOME/.zshrc" 2>/dev/null
fi

echo -e "\n[3/4] tarsync 다시 설치 중..."
# install.sh 자동 실행
if [ -f "./install.sh" ]; then
    echo "y" | ./install.sh
    INSTALL_STATUS=$?
else
    echo "❌ install.sh를 찾을 수 없습니다"
    exit 1
fi

# 백업 디렉토리 설정 복원
if [ $INSTALL_STATUS -eq 0 ] && [ "$CURRENT_BACKUP_DIR" != "/mnt/backup" ]; then
    sed -i "s|BACKUP_DIR=.*|BACKUP_DIR=$CURRENT_BACKUP_DIR|" "$HOME/.tarsync/config/settings.env" 2>/dev/null
fi

echo -e "\n[4/4] 리셋 완료!"
echo "tarsync이 성공적으로 재설치되었습니다."
echo -e "\n테스트를 위해 새 쉘을 열거나 다음 명령어를 실행하세요:"
echo "source ~/.bashrc"
echo -e "\n빠른 테스트:"
echo "   tarsync version                 # 버전 확인"
echo "   tarsync help                    # 도움말"

exit 0 