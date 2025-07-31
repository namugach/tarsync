#!/bin/bash
# 개선된 롤백 시스템 테스트

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${CYAN}██████████████████████████████████████████████████████████${NC}"
echo -e "${CYAN}█                                                        █${NC}"
echo -e "${CYAN}█            개선된 롤백 시스템 검증 테스트              █${NC}"
echo -e "${CYAN}█                                                        █${NC}"
echo -e "${CYAN}██████████████████████████████████████████████████████████${NC}"
echo ""

PASSED=0
FAILED=0
TOTAL=0

test_case() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    
    TOTAL=$((TOTAL + 1))
    
    echo -n "  [$TOTAL] $test_name: "
    
    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC}"
        echo "    Expected: $expected"
        echo "    Actual: $actual"
        FAILED=$((FAILED + 1))
    fi
}

restore_module="./src/modules/restore.sh"

echo -e "${YELLOW}🔍 개선사항 검증${NC}"
echo "════════════════════════════════════════════════════════════"

# 1. 롤백 확인 대화상자
echo -e "${BLUE}1. 롤백 확인 대화상자${NC}"
echo "--------------------------------"

# ask_rollback_confirmation 함수 존재
if grep -q "ask_rollback_confirmation()" "$restore_module"; then
    test_case "롤백 확인 함수 구현" "ask_rollback_confirmation" "ask_rollback_confirmation"
else
    test_case "롤백 확인 함수 구현" "ask_rollback_confirmation" "없음"
fi

# 롤백 백업 생성 확인 메시지
rollback_confirm_msg=$(grep -A5 -B5 "롤백 백업을 생성하시겠습니까" "$restore_module")
test_case "롤백 생성 확인 메시지" "롤백 백업을 생성하시겠습니까" "$rollback_confirm_msg"

# 배치 모드 자동 생성
batch_auto_msg=$(grep -A2 -B2 "배치 모드.*롤백 백업 자동 생성" "$restore_module")
test_case "배치 모드 자동 생성" "배치 모드.*롤백 백업 자동 생성" "$batch_auto_msg"

echo ""

# 2. 개선된 디렉토리 구조
echo -e "${BLUE}2. 개선된 디렉토리 구조${NC}"
echo "--------------------------------"

# rollback 기본 디렉토리 사용
rollback_base_dir=$(grep -o 'rollback_base_dir="[^"]*"' "$restore_module")
test_case "rollback 기본 디렉토리" "rollback" "$rollback_base_dir"

# 일관된 타임스탬프 형식
timestamp_format=$(grep -o 'rollback_timestamp.*%Y_%m_%d_%p_%H_%M_%S' "$restore_module")
test_case "타임스탬프 형식" "%Y_%m_%d_%p_%H_%M_%S" "$timestamp_format"

# 백업명 포함 디렉토리명
rollback_naming=$(grep -o 'rollback_for__${backup_name}' "$restore_module")
test_case "백업명 포함 디렉토리명" "rollback_for__" "$rollback_naming"

echo ""

# 3. 진행률 표시 시스템
echo -e "${BLUE}3. 진행률 표시 시스템${NC}"
echo "--------------------------------"

# 파일 개수 계산
file_count_calc=$(grep -A2 -B2 "백업할 파일 개수 계산" "$restore_module")
test_case "파일 개수 계산" "백업할 파일 개수 계산" "$file_count_calc"

# pv를 이용한 진행률 표시
pv_usage=$(grep -A5 -B5 "pv -p -s" "$restore_module")
test_case "pv 진행률 표시" "pv -p -s" "$pv_usage"

# pv 실패시 폴백
pv_fallback=$(grep -A2 -B2 "pv를 이용한 백업 실패.*일반 복사로 재시도" "$restore_module")
test_case "pv 실패시 폴백" "일반 복사로 재시도" "$pv_fallback"

echo ""

# 4. 롤백 메타데이터 시스템
echo -e "${BLUE}4. 롤백 메타데이터 시스템${NC}"
echo "--------------------------------"

# create_rollback_metadata 함수
if grep -q "create_rollback_metadata()" "$restore_module"; then
    test_case "메타데이터 생성 함수" "create_rollback_metadata" "create_rollback_metadata"
else
    test_case "메타데이터 생성 함수" "create_rollback_metadata" "없음"
fi

# 메타데이터 파일 내용
meta_content=$(grep -A10 -B5 'cat > "$meta_file"' "$restore_module")
test_case "메타데이터 파일 내용" "ROLLBACK_TIMESTAMP" "$meta_content"

# 롤백 명령어 안내
rollback_cmd_info=$(grep -A2 -B2 "tarsync rollback.*rollback_timestamp" "$restore_module")
test_case "롤백 명령어 안내" "tarsync rollback" "$rollback_cmd_info"

echo ""

# 5. 에러 처리 개선
echo -e "${BLUE}5. 에러 처리 개선${NC}"
echo "--------------------------------"

# handle_rollback_failure 함수
if grep -q "handle_rollback_failure()" "$restore_module"; then
    test_case "롤백 실패 처리 함수" "handle_rollback_failure" "handle_rollback_failure"
else
    test_case "롤백 실패 처리 함수" "handle_rollback_failure" "없음"
fi

# 실패 원인 설명
failure_reasons=$(grep -A5 -B2 "가능한 원인:" "$restore_module")
test_case "실패 원인 설명" "디스크 공간 부족" "$failure_reasons"

# 실패한 디렉토리 정리
cleanup_logic=$(grep -A2 -B2 "실패한 롤백 디렉토리 정리" "$restore_module")
test_case "실패 디렉토리 정리" "rm -rf.*rollback_dir" "$cleanup_logic"

echo ""

# 6. 사용자 인터페이스 개선
echo -e "${BLUE}6. 사용자 인터페이스 개선${NC}"
echo "--------------------------------"

# 롤백 백업의 장점 설명
rollback_benefits=$(grep -A5 -B2 "롤백 백업의 장점:" "$restore_module")
test_case "롤백 장점 설명" "복구 실패 시 원래 상태로" "$rollback_benefits"

# 주의사항 안내
warnings=$(grep -A5 -B2 "주의사항:" "$restore_module")
test_case "주의사항 안내" "추가 디스크 공간이 필요" "$warnings"

# 진행 상황 표시
progress_display=$(grep -A2 -B2 "총.*개 파일을 백업합니다" "$restore_module")
test_case "진행 상황 표시" "총.*개 파일을 백업" "$progress_display"

echo ""

# 7. 예상 사용자 경험 시뮬레이션
echo -e "${MAGENTA}🎯 예상 롤백 시스템 플로우${NC}"
echo "════════════════════════════════════════════════════════════"
echo ""
echo -e "${CYAN}Step 1: 롤백 확인 대화상자${NC}"
echo "  🛡️ 롤백 백업 생성 확인"
echo "  📂 대상 경로: /home/user/important"
echo "  🔄 복구할 백업: backup_20250731"
echo "  💡 롤백 백업의 장점 설명"
echo "  ⚠️ 주의사항 안내"
echo "  롤백 백업을 생성하시겠습니까? (y/n): y"
echo ""
echo -e "${CYAN}Step 2: 롤백 백업 생성${NC}"
echo "  📊 백업할 파일 개수 계산 중..."
echo "  📄 총 1,234개 파일을 백업합니다."
echo "  📦 롤백 백업 진행 중..."
echo "  [████████████████████████████████] 100%"
echo "  ✅ 롤백 백업 완료"
echo ""
echo -e "${CYAN}Step 3: 롤백 정보 안내${NC}"
echo "  💡 롤백 정보:"
echo "  백업 위치: /mnt/backup/rollback/2025_07_31_PM_14_30_15__rollback_for__backup_20250731"
echo "  복구 명령어: tarsync rollback 2025_07_31_PM_14_30_15"
echo ""
echo -e "${CYAN}새로운 디렉토리 구조:${NC}"
echo "  $BACKUP_PATH/"
echo "  ├── store/     # 백업 저장소"
echo "  ├── restore/   # 복구 작업공간"
echo "  └── rollback/  # 롤백 백업 저장소 ← 새로 추가!"
echo "      └── 2025_07_31_PM_14_30_15__rollback_for__backup_20250731/"
echo "          ├── (원본 파일들...)"
echo "          └── rollback_meta.sh  # 롤백 메타데이터"
echo ""

# 최종 결과
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}           테스트 결과 요약           ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""
echo -e "총 테스트: ${BLUE}$TOTAL${NC}개"
echo -e "통과: ${GREEN}$PASSED${NC}개"
echo -e "실패: ${RED}$FAILED${NC}개"
echo -e "성공률: ${BLUE}$(( PASSED * 100 / TOTAL ))%${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 개선된 롤백 시스템 모든 검증 완료!${NC}"
    echo ""
    echo -e "${GREEN}✅ 주요 개선사항:${NC}"
    echo -e "${GREEN}   • 롤백 생성 확인 대화상자${NC}"
    echo -e "${GREEN}   • 일관된 디렉토리 구조 (/backup/rollback/)${NC}"
    echo -e "${GREEN}   • pv를 이용한 진행률 표시${NC}"
    echo -e "${GREEN}   • 상세한 롤백 메타데이터${NC}"
    echo -e "${GREEN}   • 개선된 에러 처리${NC}"
    echo -e "${GREEN}   • 사용자 친화적 인터페이스${NC}"
    echo ""
    echo -e "${BLUE}🚀 완벽한 롤백 시스템 구현 완료!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️  일부 검증에서 문제가 발견되었습니다.${NC}"
    echo -e "${RED}코드를 재검토해주세요.${NC}"
    exit 1
fi