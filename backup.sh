#!/bin/bash

# 현재 작업 디렉토리를 기준으로 백업 디렉토리 설정
BASE_PATH=$(pwd)
BACKUP_DIR=$BASE_PATH/source

# 현재 날짜와 시간을 파일명에 포함 (예: 2025_02_01_AM_01_23_30)
DATE=$(date +%Y_%m_%d_%p_%I_%M_%S)
WORK_DIR=$BACKUP_DIR/$DATE
TAR_FILE="${WORK_DIR}/tarsync.tar.gz"

# 제외할 디렉토리 목록 설정 (배열로 변경)
EXCLUDE_DIRS=(
  "--exclude=/proc"
  "--exclude=/swap.img"
  "--exclude=/sys"
  "--exclude=/cdrom"
  "--exclude=/dev"
  "--exclude=/run"
  "--exclude=/tmp"
  "--exclude=/mnt"
  "--exclude=/media"
  "--exclude=/var/run"
  "--exclude=/var/tmp"
  "--exclude=/lost+found"
  "--exclude=/var/lib/docker"
  "--exclude=/var/lib/containerd"
  "--exclude=/var/run/docker.sock"
  "--exclude=/swapfile"
)

# 백업 시작 메시지
echo "📂 백업을 시작합니다."
echo "📌 저장 경로: ${TAR_FILE}"

mkdir -p $BACKUP_DIR  # 백업 디렉토리가 없으면 생성
mkdir -p $WORK_DIR

# `tar` + `gzip` + `pv` 조합으로 진행률 표시
sudo tar cf - -P --one-file-system "${EXCLUDE_DIRS[@]}" / | pv | gzip > "$TAR_FILE"

# 압축된 파일의 크기 계산
COMPRESSED_SIZE=$(du -sb "$TAR_FILE" | awk '{print $1}')
COMPRESSED_SIZE_GB=$(echo "scale=2; $COMPRESSED_SIZE/1024/1024/1024" | bc)

echo "✅ 압축 완료: ${TAR_FILE}"
echo "🗜 압축된 파일 크기: ${COMPRESSED_SIZE_GB} GB"

# source 디렉토리 안 최근 5개 파일을 강조하여 출력
FILES=$(ls -ltr --time-style=long-iso $BACKUP_DIR | awk 'NR>1 {print $6, $7, $8}')
COUNT=0
LINES=()

while read -r LINE; do
  COUNT=$((COUNT + 1))
  LINES+=("$LINE")
done <<< "$FILES"

if [ "$COUNT" -eq 0 ]; then
  echo "📂 source 디렉토리에 파일이 없습니다."
else
  for ((i=0; i<COUNT; i++)); do
    if [ "$i" -eq $((COUNT-1)) ] && [ "$COUNT" -lt 5 ]; then
      # 파일이 5개 미만일 때, 마지막 파일 강조
      echo -e "\033[1;32m${LINES[i]} (✔ 작업 완료)\033[0m"
    else
      echo "${LINES[i]}"
    fi
  done
fi
