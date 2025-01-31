#!/bin/bash
mkdir -p ./source
BACKUP_DIR=$(pwd)/source
DATE=$(date +%Y_%m_%d_%p_%I_%M_%S)  # 예: 2025_02_01_AM_01_23_30
TAR_FILE="${BACKUP_DIR}/root_backup_${DATE}.tar.gz"


# 제외 디렉토리 설정
EXCLUDE_DIRS="--exclude=/proc \
--exclude=/swap.img \
--exclude=/sys \
--exclude=/dev \
--exclude=/run \
--exclude=/tmp \
--exclude=/mnt \
--exclude=/media \
--exclude=/var/run \
--exclude=/var/tmp \
--exclude=/lost+found \
--exclude=/swapfile \
--exclude=/var/lib/docker \
--exclude=/var/lib/containerd \
--exclude=/var/run/docker.sock"


echo "백업을 시작합니다: ${TAR_FILE}"

cd /
sudo tar -cvpjf $TAR_FILE \
$EXCLUDE_DIRS \
--one-file-system / 


echo "백업 완료: ${TAR_FILE}"