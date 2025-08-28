#!/bin/bash

# tarsync reset script (Global Installation)
# Automatically run sudo uninstall then sudo install for clean reinstallation.

# sudo 권한 체크
if [ "$EUID" -ne 0 ]; then
    echo "❌ sudo permission is required for global installation reset"
    echo "Please run as: sudo ./bin/auto_reset.sh"
    exit 1
fi

# 스크립트 경로 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# 현재 백업 디렉토리 설정 백업 (있다면)
if [ -f "/etc/tarsync/settings.env" ]; then
    CURRENT_BACKUP_DIR=$(grep "BACKUP_DIR=" "/etc/tarsync/settings.env" | cut -d'=' -f2)
    echo "📍 Current backup directory setting: $CURRENT_BACKUP_DIR"
else
    CURRENT_BACKUP_DIR="/mnt/backup"  # Default value
fi

echo -e "\n🗑️  [1/3] Removing existing tarsync..."
# Automatically input 'y' to uninstall.sh for unattended operation
if [ -f "./uninstall.sh" ]; then
    echo "y" | ./uninstall.sh 2>/dev/null || echo "ℹ️  No existing installation to remove."
else
    echo "❌ Cannot find uninstall.sh."
fi

echo -e "\n📦 [2/3] Reinstalling tarsync..."
# Auto-run install.sh (preserve existing backup directory setting)
if [ -f "./install.sh" ]; then
    if [ "$CURRENT_BACKUP_DIR" != "/mnt/backup" ]; then
        # If existing backup directory is not default, auto-input that value
        echo -e "y\n$CURRENT_BACKUP_DIR" | ./install.sh
    else
        # Use default value
        echo "y" | ./install.sh
    fi
    INSTALL_STATUS=$?
else
    echo "❌ Cannot find install.sh"
    exit 1
fi

echo -e "\n✅ [3/3] Reset complete!"
if [ $INSTALL_STATUS -eq 0 ]; then
    echo "🚀 tarsync has been successfully reinstalled."
    echo -e "\n🧪 Quick test:"
    echo "   tarsync version                 # Check version"
    echo "   tarsync help                    # Help"
else
    echo "❌ An error occurred during installation."
    exit 1
fi

exit 0 