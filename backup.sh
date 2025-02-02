#!/bin/bash

# 현재 작업 디렉토리를 기준으로 백업 디렉토리 설정
BASE_PATH=$(pwd)
BACKUP_DIR=$BASE_PATH/source
mkdir -p $BACKUP_DIR  # 백업 디렉토리가 없으면 생성

# 현재 날짜와 시간을 파일명에 포함 (예: 2025_02_01_AM_01_23_30)
DATE=$(date +%Y_%m_%d_%p_%I_%M_%S)
TAR_FILE="${BACKUP_DIR}/tarsync_${DATE}.tar"

# 제외할 디렉토리 목록 설정
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


# tar 백업 파일 생성
echo "백업을 시작합니다."

echo "파일을 묶습니다."
echo "경로: ${TAR_FILE}"

cd /
sudo tar cf - \
-P \
$EXCLUDE_DIRS \
--one-file-system / \
| pv > $TAR_FILE | sudo tee $TAR_FILE > /dev/null

echo "파일 묶기 완료: ${TAR_FILE}"

# TAR 파일 용량 출력
TAR_FILE_SIZE=$(du -sb $TAR_FILE | awk '{print $1}')
TAR_FILE_SIZE_GB=$(echo "scale=2; $TAR_FILE_SIZE/1024/1024/1024" | bc)
echo "원본 TAR 파일 크기: ${TAR_FILE_SIZE_GB} GB"

# 압축 과정 시작
echo "압축을 시작합니다."
GZ_FILE="${TAR_FILE}.gz"

# tar 파일을 gzip으로 압축하며 진행률 출력
pv $TAR_FILE | gzip > $GZ_FILE

# 압축된 파일의 크기 계산
COMPRESSED_SIZE=$(du -sb $GZ_FILE | awk '{print $1}')
COMPRESSED_SIZE_GB=$(echo "scale=2; $COMPRESSED_SIZE/1024/1024/1024" | bc)

echo "원본 파일 크기: ${TAR_FILE_SIZE_GB} GB"
echo "압축된 파일 크기: ${COMPRESSED_SIZE_GB} GB"

# 압축률 계산 (백분율 출력)
COMPRESSION_RATIO=$(echo "scale=2; (1 - $COMPRESSED_SIZE / $TAR_FILE_SIZE) * 100" | bc)
echo "압축률: ${COMPRESSION_RATIO}%"

echo "백업 및 압축 완료: ${GZ_FILE}"

# 원본 tar 파일 삭제
echo "원본 tar 파일을 삭제합니다: ${TAR_FILE}"
sudo rm -f $TAR_FILE

# source 디렉토리 안 최근 5개 파일을 강조하여 출력
echo -e "\033[1;32msource 디렉토리 내 최근 5개 파일:\033[0m"
ls -alh $BACKUP_DIR | tail -n 5
