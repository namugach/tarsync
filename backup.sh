#!/bin/bash
source $(dirname "$(realpath "$0")")/config.sh
# 오류 발생 시 스크립트 종료
set -e

# 현재 작업 디렉토리를 기준으로 백업 디렉토리 설정
DATE=$(date +%Y_%m_%d_%p_%I_%M_%S)  # 날짜와 시간을 포함한 파일명 생성
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

# 디렉토리 생성 및 권한 부여
mkdir -p "$STORE_DIR"  # 백업 디렉토리가 없으면 생성
mkdir -p "$WORK_DIR"

# ---------- 요구 사항: 로그를 기록하시겠습니까? (Y/n)
echo "로그를 기록하시겠습니까? (Y/n): "
read -r LOG_CHOICE
LOG_CHOICE=${LOG_CHOICE:-Y}  # 기본값은 Y

# 시스템에서 기본 에디터 확인
EDITOR=$(update-alternatives --display editor | grep "link currently points to" | awk '{print $NF}')
EDITOR_PATH=$(which "$EDITOR")

# pv 명령어 설치 여부 확인 
if ! command -v pv &> /dev/null; then
    echo "⚠️ 'pv' 명령어가 설치되어 있지 않습니다. 다음 명령어로 설치해주세요: sudo apt install pv"
    exit 1
fi

# 디스크 용량 체크 
FREE_SPACE=$(df -BG --output=avail "$STORE_DIR" | tail -n 1 | tr -d 'G')
if [ "$FREE_SPACE" -lt 10 ]; then
    echo "⚠️ 저장 공간이 부족합니다. 최소 10GB 이상 필요합니다."
    exit 1
fi

# 로그 기록이 'Y'인 경우, 로그를 기록하기 위한 파일 열기
if [[ "$LOG_CHOICE" == "Y" || "$LOG_CHOICE" == "y" ]]; then
  LOG_FILE="${WORK_DIR}/log.md"
  touch "$LOG_FILE"  # 로그 파일 미리 생성 
  chmod 644 "$LOG_FILE"  # 적절한 권한 부여
  echo "로그 파일이 생성되었습니다: ${LOG_FILE}"
  $EDITOR_PATH "$LOG_FILE"  # 사용자에게 로그 작성 요청
fi

# 백업 시작 메시지
echo "📂 백업을 시작합니다."
echo "📌 저장 경로: ${TAR_FILE}"

# `tar` + `gzip` + `pv` 조합으로 진행률 표시 
sudo tar cf - -P --one-file-system --acls --xattrs "${EXCLUDE_DIRS[@]}" / | pv | gzip > "$TAR_FILE"

# 압축된 파일의 크기 계산
COMPRESSED_SIZE=$(du -sb "$TAR_FILE" | awk '{print $1}')
COMPRESSED_SIZE_GB=$(echo "scale=2; $COMPRESSED_SIZE/1024/1024/1024" | bc)
echo "✅ 압축 완료: ${TAR_FILE}"
echo "🗜 압축된 파일 크기: ${COMPRESSED_SIZE_GB} GB"

# source 디렉토리 안 최근 5개 파일을 강조하여 출력
./list.sh 5 -1 -1

# log.md 파일 출력
if [ -f "$LOG_FILE" ]; then
  echo -e "\n📜 백업 로그 내용:"
  echo "-----------------------------------"
  cat "$LOG_FILE"
  echo "-----------------------------------"
fi
