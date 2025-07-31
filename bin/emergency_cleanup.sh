#!/bin/bash
# 긴급 롤백 디렉토리 정리 스크립트
# 루트에 잘못 생성된 /rollback 디렉토리를 안전하게 정리

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${RED}██████████████████████████████████████████████████████████${NC}"
echo -e "${RED}█                                                        █${NC}"
echo -e "${RED}█                긴급 롤백 정리 스크립트                █${NC}"
echo -e "${RED}█                                                        █${NC}"
echo -e "${RED}██████████████████████████████████████████████████████████${NC}"
echo ""

# sudo 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ 이 스크립트는 sudo 권한이 필요합니다.${NC}"
    echo "사용법: sudo $0"
    exit 1
fi

echo -e "${YELLOW}🚨 긴급 상황 감지${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""

# /rollback 디렉토리 확인
if [ ! -d "/rollback" ]; then
    echo -e "${GREEN}✅ /rollback 디렉토리가 존재하지 않습니다.${NC}"
    echo "정리할 내용이 없습니다."
    exit 0
fi

echo -e "${RED}⚠️  루트에 잘못된 롤백 디렉토리 발견:${NC}"
echo ""
echo "📂 디렉토리: /rollback"
echo "📊 크기: $(du -sh /rollback 2>/dev/null | cut -f1)"
echo "📄 내용:"
ls -la /rollback/ 2>/dev/null | head -10

echo ""
echo -e "${YELLOW}🔍 문제 원인:${NC}"
echo "  • get_backup_path() 함수 누락으로 인한 경로 오류"
echo "  • 결과적으로 /rollback (루트)에 백업 생성됨"
echo "  • 현재 수정 완료되었습니다"
echo ""

# 백업 경로 확인
BACKUP_PATH="/mnt/backup"
if [ ! -d "$BACKUP_PATH" ]; then
    echo -e "${RED}❌ 백업 경로를 찾을 수 없습니다: $BACKUP_PATH${NC}"
    exit 1
fi

echo -e "${BLUE}📋 정리 계획:${NC}"
echo "  1. /rollback → $BACKUP_PATH/rollback 으로 이동"
echo "  2. 권한 및 소유자 수정"
echo "  3. 디렉토리 구조 검증"
echo ""

while true; do
    echo -n -e "${YELLOW}정리를 진행하시겠습니까? (y/n): ${NC}"
    read -r choice
    
    case "$choice" in
        y|yes|Y|YES)
            break
            ;;
        n|no|N|NO)
            echo ""
            echo -e "${CYAN}👋 정리를 취소했습니다.${NC}"
            echo ""
            echo -e "${YELLOW}수동 정리 방법:${NC}"
            echo "  sudo mv /rollback $BACKUP_PATH/"
            echo "  sudo chown -R root:root $BACKUP_PATH/rollback"
            echo "  sudo chmod -R 755 $BACKUP_PATH/rollback"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ y(yes) 또는 n(no)를 입력해주세요.${NC}"
            ;;
    esac
done

echo ""
echo -e "${CYAN}🔄 정리 시작...${NC}"
echo ""

# 1. 백업 디렉토리 롤백 폴더 생성
echo "1️⃣  백업 디렉토리 구조 준비..."
if ! mkdir -p "$BACKUP_PATH/rollback"; then
    echo -e "${RED}❌ 백업 디렉토리 생성 실패${NC}"
    exit 1
fi
echo -e "${GREEN}✅ $BACKUP_PATH/rollback 생성 완료${NC}"

# 2. 롤백 디렉토리 이동
echo ""
echo "2️⃣  롤백 디렉토리 이동 중..."
if mv /rollback/* "$BACKUP_PATH/rollback/" 2>/dev/null; then
    echo -e "${GREEN}✅ 롤백 데이터 이동 완료${NC}"
else
    echo -e "${RED}❌ 롤백 데이터 이동 실패${NC}"
    exit 1
fi

# 3. 원본 디렉토리 제거
echo ""
echo "3️⃣  원본 디렉토리 정리..."
if rmdir /rollback 2>/dev/null; then
    echo -e "${GREEN}✅ /rollback 디렉토리 제거 완료${NC}"
else
    echo -e "${YELLOW}⚠️  /rollback 디렉토리 제거 실패 (수동 제거 필요)${NC}"
fi

# 4. 권한 수정
echo ""
echo "4️⃣  권한 및 소유자 수정..."
chown -R root:root "$BACKUP_PATH/rollback"
chmod -R 755 "$BACKUP_PATH/rollback"
echo -e "${GREEN}✅ 권한 수정 완료${NC}"

# 5. 결과 확인
echo ""
echo -e "${CYAN}✅ 정리 완료!${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo -e "${GREEN}📂 새로운 디렉토리 구조:${NC}"
echo "$BACKUP_PATH/"
echo "├── store/     # 백업 저장소"
echo "├── restore/   # 복구 작업공간"
echo "└── rollback/  # 롤백 백업 저장소"
tree "$BACKUP_PATH/rollback" -L 2 2>/dev/null || ls -la "$BACKUP_PATH/rollback/"

echo ""
echo -e "${BLUE}💡 이제 정상적으로 작동합니다:${NC}"
echo "  • 롤백 백업이 올바른 위치에 저장됩니다"
echo "  • 일관된 디렉토리 구조를 유지합니다"
echo "  • 시스템 안전성이 보장됩니다"
echo ""

echo -e "${GREEN}🚀 정리 작업이 성공적으로 완료되었습니다!${NC}"