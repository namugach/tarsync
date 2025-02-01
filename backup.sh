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

# 압축을 시작합니다.
echo "압축을 시작합니다."
GZ_FILE="${TAR_FILE}.gz"
# pv로 진행 상황을 출력하면서 압축하기
pv $TAR_FILE | gzip > $GZ_FILE

# 압축된 파일의 크기 구하기
COMPRESSED_SIZE=$(du -sb $GZ_FILE | awk '{print $1}')
COMPRESSED_SIZE_GB=$(echo "scale=2; $COMPRESSED_SIZE/1024/1024/1024" | bc)

# 원본 파일 크기와 압축된 파일 크기 출력
echo "원본 파일 크기: ${TOTAL_SIZE_GB} GB"
echo "압축된 파일 크기: ${COMPRESSED_SIZE_GB} GB"

# 압축률 계산 (백분율로 출력)
COMPRESSION_RATIO=$(echo "scale=2; (1 - $COMPRESSED_SIZE / $TOTAL_SIZE) * 100" | bc)
echo "압축률: ${COMPRESSION_RATIO}%"

# 백업이 완료되었음을 알림
echo "백업 및 압축 완료: ${GZ_FILE}"

# 원본 파일을 제거합니다.
echo "원본 tar 파일을 삭제합니다: ${TAR_FILE}"
sudo rm -f $TAR_FILE