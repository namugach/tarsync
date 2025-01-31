#!/bin/bash
BASE_PATH=$(pwd)
BACKUP_DIR=$BASE_PATH/source
mkdir -p $BACKUP_DIR
DATE=$(date +%Y_%m_%d_%p_%I_%M_%S)  # 예: 2025_02_01_AM_01_23_30
TAR_FILE="${BACKUP_DIR}/root_backup_${DATE}.tar"



# 제외 디렉토리 설정
EXCLUDE_DIRS="--exclude=/proc \
--exclude=/swap.img \
--exclude=/sys \
--exclude=/cdrom \
--exclude=/dev \
--exclude=/run \
--exclude=/tmp \
--exclude=/mnt \
--exclude=/media \
--exclude=/var/run \
--exclude=/var/tmp \
--exclude=/lost+found \
--exclude=/var/lib/docker \
--exclude=/var/lib/containerd \
--exclude=/var/run/docker.sock \
--exclude=/swapfile"



echo "백업할 데이터의 크기를 재고 있습니다."
TOTAL_SIZE=$(sudo du -sb $EXCLUDE_DIRS / | awk '{print $1}')
TOTAL_SIZE_GB=$(echo "scale=2; $TOTAL_SIZE/1024/1024/1024" | bc)
echo "백업할 데이터 크기: ${TOTAL_SIZE_GB} GB"

echo "백업을 시작합니다: ${TAR_FILE}"
cd /
sudo tar -cf - \
-P \
$EXCLUDE_DIRS \
--one-file-system / | pv -s $TOTAL_SIZE | sudo tee $TAR_FILE > /dev/null


echo "백업 완료: ${TAR_FILE}"
