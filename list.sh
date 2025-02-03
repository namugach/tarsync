#!/bin/bash

# 설정 파일 로드
source $(dirname "$(realpath "$0")")/config.sh

# 첫 번째 인자: 한 페이지당 출력할 개수 (기본값: 전체 출력)
PAGE_SIZE=${1:-0}

# 두 번째 인자: 현재 페이지 번호 (기본값: 1페이지, 음수면 뒤에서부터)
PAGE_NUM=${2:-1}

# 세 번째 인자: 선택된 인덱스 (기본값: 선택 안 함, 음수면 마지막)
SELECT_INDEX=${3:-0}

# 디렉토리 존재 여부 확인
if [ ! -d "$STORE_DIR" ]; then
  echo "⚠️  백업 디렉토리가 존재하지 않습니다: $STORE_DIR"
  exit 1
fi

# 전체 파일 목록 가져오기 (공백 포함 파일명 대응)
FILES=$(ls -lthr "$STORE_DIR" | tail -n +2 | awk '{if ($9 != "") print $6, $7, $8, $9}')
TOTAL_FILES=$(echo "$FILES" | wc -l)

# 페이지네이션 설정
if [ "$PAGE_SIZE" -gt 0 ]; then
  if [ "$PAGE_NUM" -lt 0 ]; then
    # 페이지가 음수면 끝에서부터 가져옴
    START=$(( TOTAL_FILES + PAGE_NUM * PAGE_SIZE + 1 ))
    FILES=$(echo "$FILES" | sed -n "${START},$((START + PAGE_SIZE - 1))p")
  else
    START=$(( (PAGE_NUM - 1) * PAGE_SIZE + 1 ))
    FILES=$(echo "$FILES" | sed -n "${START},$((START + PAGE_SIZE - 1))p")
  fi
else
  # PAGE_SIZE가 0이면 전체 파일 출력
  PAGE_SIZE=$TOTAL_FILES
fi

# 선택된 디렉토리의 총 용량 초기화
TOTAL_SIZE=0
i=0
res=""

while IFS= read -r FILE; do
  # 파일명 추출
  FILE_NAME=$(echo "$FILE" | awk '{print $4}')
  BACKUP_DIR="$STORE_DIR/$FILE_NAME"

  # 실제 디렉토리 용량 구하기 (디렉토리가 존재하는지 확인 후 진행)
  if [ -d "$BACKUP_DIR" ]; then
    SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
    SIZE_BYTES=$(du -sb "$BACKUP_DIR" 2>/dev/null | awk '{print $1}')
  else
    SIZE="0B"
    SIZE_BYTES=0
  fi

  # log.md 파일 존재 여부 확인
  LOG_ICON="❌"
  if [ -f "$BACKUP_DIR/log.md" ]; then
    LOG_ICON="📖"
  fi

  # 선택된 디렉토리 인덱스 처리 (음수일 경우 마지막 항목 선택)
  if [ "$SELECT_INDEX" -lt 0 ]; then
    if [ "$i" -eq $((PAGE_SIZE - 1)) ]; then
      ICON="✅"
    else
      ICON="⬜️"
    fi
  elif [ "$SELECT_INDEX" -gt 0 ] && [ "$i" -eq "$((SELECT_INDEX-1))" ]; then
    ICON="✅"
  else
    ICON="⬜️"
  fi

  # 총 용량 계산
  TOTAL_SIZE=$((TOTAL_SIZE + SIZE_BYTES))

  # 출력 형식 (넘버링 추가)
  res+="$ICON $LOG_ICON $SIZE $FILE - $((i+1))\n"
  i=$((i+1))
done <<< "$FILES"

res+="\n"

# 선택된 디렉토리의 총 용량 출력
TOTAL_SIZE_HUMAN=$(numfmt --to=iec --suffix=B --padding=7 <<< "$TOTAL_SIZE" 2>/dev/null)
[ -z "$TOTAL_SIZE_HUMAN" ] && TOTAL_SIZE_HUMAN="0B"
res+="🔳 total: $(du -sh "$STORE_DIR" 2>/dev/null | awk '{print $1}')B\n"
res+="🔳 page total: $TOTAL_SIZE_HUMAN\n"

# 페이지네이션 정보 추가
TOTAL_PAGES=$(( (TOTAL_FILES + PAGE_SIZE - 1) / PAGE_SIZE ))
[ "$TOTAL_PAGES" -eq 0 ] && TOTAL_PAGES=1  # 최소 1 페이지로 보정
res+="🔳 Page ${PAGE_NUM#-} / $TOTAL_PAGES (Total: $TOTAL_FILES files)"
res+="\n"

# echo 실행할 때 안전하게 처리
echo -e "$res"