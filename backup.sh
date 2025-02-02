#!/bin/bash

# 현재 작업 디렉토리를 기준으로 백업 디렉토리 설정
BASE_PATH=$(pwd)
STORE_DIR=$BASE_PATH/store

# 현재 날짜와 시간을 파일명에 포함 (예: 2025_02_01_AM_01_23_30)
DATE=$(date +%Y_%m_%d_%p_%I_%M_%S)
WORK_DIR=$STORE_DIR/$DATE
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

mkdir -p $STORE_DIR  # 백업 디렉토리가 없으면 생성
mkdir -p $WORK_DIR

# ---------- 요구 사항
# 로그를 기록 하시겠습니까? (Y/n)
# Y 기본값
echo "로그를 기록하시겠습니까? (Y/n): "
read -r LOG_CHOICE

# 기본값은 Y
LOG_CHOICE=${LOG_CHOICE:-Y}

# 시스템에서 기본 에디터 확인
EDITOR=$(update-alternatives --display editor | grep "link currently points to" | awk '{print $NF}')
EDITOR_PATH=$(which $EDITOR)


# 로그 기록이 'Y'인 경우, 로그를 기록하기 위한 파일 열기
if [ "$LOG_CHOICE" == "Y" ] || [ "$LOG_CHOICE" == "y" ]; then
  LOG_FILE="${WORK_DIR}/log.md"
  echo "로그 파일이 생성되었습니다: ${LOG_FILE}"
  $EDITOR_PATH "$LOG_FILE"
fi

# 백업 시작 메시지
echo "📂 백업을 시작합니다."
echo "📌 저장 경로: ${TAR_FILE}"


# `tar` + `gzip` + `pv` 조합으로 진행률 표시
sudo tar cf - -P --one-file-system "${EXCLUDE_DIRS[@]}" / | pv | gzip > "$TAR_FILE"

# 압축된 파일의 크기 계산
COMPRESSED_SIZE=$(du -sb "$TAR_FILE" | awk '{print $1}')
COMPRESSED_SIZE_GB=$(echo "scale=2; $COMPRESSED_SIZE/1024/1024/1024" | bc)

echo "✅ 압축 완료: ${TAR_FILE}"
echo "🗜 압축된 파일 크기: ${COMPRESSED_SIZE_GB} GB"

# source 디렉토리 안 최근 5개 파일을 강조하여 출력

FILES=$(ls -lthr $STORE_DIR | tail -n 5 | awk '{print $6, $7, $8, $9}')
COUNT=$(echo "$FILES" | wc -l)
i=0

while read -r FILE; do
  # 파일명 추출
  BACKUP_DIR="$STORE_DIR/$(echo "$FILE" | awk '{print $4}')"
  
  # 실제 디렉토리 용량 구하기
  SIZE=$(du -sh "$BACKUP_DIR" | awk '{print $1}')
  
  # log.md 파일 존재 여부 확인
  if [ -f "$BACKUP_DIR/log.md" ]; then
    LOG_ICON="📋"
  else
    LOG_ICON=""
  fi
  
  if [ "$i" -eq $((COUNT-1)) ]; then
    # 마지막 디렉토리일 경우 색상 변경하고 '(✔ 작업 완료)' 추가
    if [ -n "$LOG_ICON" ]; then
      echo -e "🟢 $SIZE $FILE $LOG_ICON ✔️  done‼️"
    else
      echo -e "🟢 $SIZE $FILE ✔️  done‼️"
    fi
  else
    # 나머지 디렉토리는 그냥 출력
    echo "⚪ $SIZE $FILE $LOG_ICON"
  fi
  i=$((i+1))
done <<< "$FILES"