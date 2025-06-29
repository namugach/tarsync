#!/bin/bash

# tarsync reset script (전역 설치용)
# sudo uninstall 후 sudo install을 자동으로 실행하여 깨끗하게 다시 설치합니다.

# sudo 권한 체크
if [ "$EUID" -ne 0 ]; then
    echo "❌ 전역 설치 리셋을 위해서는 sudo 권한이 필요합니다"
    echo "다음과 같이 실행해주세요: sudo ./bin/auto_reset.sh"
    exit 1
fi

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# 현재 백업 디렉토리 설정 백업 (있다면)
if [ -f "/etc/tarsync/settings.env" ]; then
    CURRENT_BACKUP_DIR=$(grep "BACKUP_DIR=" "/etc/tarsync/settings.env" | cut -d'=' -f2)
    echo "현재 백업 디렉토리 설정: $CURRENT_BACKUP_DIR"
else
    CURRENT_BACKUP_DIR="/mnt/backup"  # 기본값
fi

echo -e "\n[1/3] 기존 tarsync 제거 중..."
# uninstall.sh에 자동으로 'y'를 입력하여 확인 없이 진행
if [ -f "./uninstall.sh" ]; then
    echo "y" | ./uninstall.sh 2>/dev/null || echo "제거할 기존 설치가 없습니다."
else
    echo "uninstall.sh를 찾을 수 없습니다."
fi

echo -e "\n[2/3] tarsync 다시 설치 중..."
# install.sh 자동 실행 (백업 디렉토리는 기존 설정 유지)
if [ -f "./install.sh" ]; then
    if [ "$CURRENT_BACKUP_DIR" != "/mnt/backup" ]; then
        # 기존 백업 디렉토리가 기본값이 아니면 해당 값을 자동 입력
        echo -e "y\n$CURRENT_BACKUP_DIR" | ./install.sh
    else
        # 기본값 사용
        echo "y" | ./install.sh
    fi
    INSTALL_STATUS=$?
else
    echo "❌ install.sh를 찾을 수 없습니다"
    exit 1
fi

echo -e "\n[3/3] 리셋 완료!"
if [ $INSTALL_STATUS -eq 0 ]; then
    echo "tarsync이 성공적으로 재설치되었습니다."
    echo -e "\n빠른 테스트:"
    echo "   tarsync version                 # 버전 확인"
    echo "   tarsync help                    # 도움말"
else
    echo "❌ 설치 중 오류가 발생했습니다."
    exit 1
fi

exit 0 