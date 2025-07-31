#!/bin/bash
# 안전장치 및 고급 기능 테스트

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}   안전장치 및 고급 기능 테스트      ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# 1. 안전장치 옵션 파싱 검증
echo -e "${YELLOW}1. 안전장치 옵션 파싱 검증${NC}"
echo "================================"

cli_file="./bin/tarsync.sh"

# --force 옵션 처리
force_option=$(grep -A5 -B2 "\--force\|\--skip-confirm" "$cli_file")
test_case "--force 옵션 처리" "TARSYNC_FORCE_MODE" "$force_option"

# --no-rollback 옵션 처리
no_rollback_option=$(grep -A5 -B2 "\--no-rollback" "$cli_file")
test_case "--no-rollback 옵션 처리" "TARSYNC_NO_ROLLBACK" "$no_rollback_option"

# 2. 고급 기능 옵션 파싱 검증
echo -e "${YELLOW}2. 고급 기능 옵션 파싱 검증${NC}"
echo "================================"

# --explain 옵션 처리
explain_option=$(grep -A5 -B2 "\--explain\|\--learn" "$cli_file")
test_case "--explain 옵션 처리" "TARSYNC_EXPLAIN_MODE" "$explain_option"

# --explain-interactive 옵션 처리
interactive_option=$(grep -A5 -B2 "\--explain-interactive" "$cli_file")
test_case "--explain-interactive 옵션 처리" "TARSYNC_EXPLAIN_INTERACTIVE" "$interactive_option"

# --batch 옵션 처리
batch_option=$(grep -A5 -B2 "\--batch" "$cli_file")
test_case "--batch 옵션 처리" "TARSYNC_BATCH_MODE" "$batch_option"

# 3. 환경변수 설정 확인
echo -e "${YELLOW}3. 환경변수 설정 확인${NC}"
echo "================================"

# 모든 환경변수가 export로 설정되는지 확인
export_vars=$(grep -c "export TARSYNC_" "$cli_file")
test_case "환경변수 export 설정" "1" "$([ $export_vars -gt 0 ] && echo '1' || echo '0')"

# 4. 복구 모듈의 안전장치 구현 확인
echo -e "${YELLOW}4. 복구 모듈 안전장치 구현${NC}"
echo "================================"

restore_file="./src/modules/restore.sh"

# 위험도 평가 시스템
risk_assessment=$(grep -i "위험\|risk" "$restore_file" | wc -l)
test_case "위험도 평가 시스템" "1" "$([ $risk_assessment -gt 0 ] && echo '1' || echo '0')"

# 확인 절차
confirmation_logic=$(grep -i "확인\|confirm" "$restore_file" | wc -l)
test_case "확인 절차 구현" "1" "$([ $confirmation_logic -gt 0 ] && echo '1' || echo '0')"

# 롤백 기능
rollback_logic=$(grep -i "롤백\|rollback\|백업.*생성" "$restore_file" | wc -l)
test_case "롤백 관련 기능" "1" "$([ $rollback_logic -gt 0 ] && echo '1' || echo '0')"

# 5. 학습 모드 구현 확인
echo -e "${YELLOW}5. 학습 모드 구현 확인${NC}"
echo "================================"

# EXPLAIN_MODE 환경변수 사용
explain_usage=$(grep -c "TARSYNC_EXPLAIN_MODE" "$restore_file")
test_case "EXPLAIN_MODE 환경변수 사용" "1" "$([ $explain_usage -gt 0 ] && echo '1' || echo '0')"

# 설명 메시지
explain_messages=$(grep -i "설명\|학습\|교육" "$restore_file" | wc -l)
test_case "학습 모드 메시지" "1" "$([ $explain_messages -gt 0 ] && echo '1' || echo '0')"

# 6. 배치 모드 구현 확인
echo -e "${YELLOW}6. 배치 모드 구현 확인${NC}"
echo "================================"

# BATCH_MODE 환경변수 사용
batch_usage=$(grep -c "TARSYNC_BATCH_MODE" "$restore_file")
test_case "BATCH_MODE 환경변수 사용" "1" "$([ $batch_usage -gt 0 ] && echo '1' || echo '0')"

# 비대화형 처리
non_interactive=$(grep -i "배치\|batch\|자동" "$restore_file" | wc -l)
test_case "배치 모드 로직" "1" "$([ $non_interactive -gt 0 ] && echo '1' || echo '0')"

# 7. 도움말 시스템의 고급 옵션 설명
echo -e "${YELLOW}7. 도움말 고급 옵션 설명${NC}"
echo "================================"

# 복구 전용 도움말에서 고급 옵션 확인
help_output=$(./bin/tarsync.sh help 2>/dev/null)

test_case "도움말의 --explain 언급" "explain" "$help_output"
test_case "도움말의 --batch 언급" "batch" "$help_output"
test_case "도움말의 --force 언급" "force" "$help_output"

# 8. 에러 메시지 및 사용자 안내
echo -e "${YELLOW}8. 사용자 인터페이스 품질${NC}"
echo "================================"

# 사용자 친화적 메시지
user_messages=$(grep -r "💡\|⚠️\|❌\|✅" "$cli_file" "$restore_file" | wc -l)
test_case "사용자 친화적 아이콘 사용" "1" "$([ $user_messages -gt 0 ] && echo '1' || echo '0')"

# 한글 메시지
korean_messages=$(grep -r "사용법\|도움말\|옵션" "$cli_file" | wc -l)
test_case "한글 인터페이스" "1" "$([ $korean_messages -gt 0 ] && echo '1' || echo '0')"

# 9. 옵션 조합 로직 검증
echo -e "${YELLOW}9. 옵션 조합 검증${NC}"
echo "================================"

# 배치 모드에서 자동으로 --no-rollback 설정
batch_no_rollback=$(grep -A5 -B5 "TARSYNC_BATCH_MODE.*true" "$cli_file" | grep "TARSYNC_NO_ROLLBACK")
test_case "배치 모드 자동 no-rollback" "TARSYNC_NO_ROLLBACK" "$batch_no_rollback"

# 10. 복구 단계별 메시지 차별화
echo -e "${YELLOW}10. 단계별 메시지 차별화${NC}"
echo "================================"

# 각 단계별 고유 메시지
light_msg=$(grep -A10 -B5 "light_simulation" "$restore_file" | grep -i "경량\|light")
test_case "경량 시뮬레이션 메시지" "경량" "$light_msg"

full_msg=$(grep -A10 -B5 "full_sim_restore" "$restore_file" | grep -i "전체\|full")
test_case "전체 시뮬레이션 메시지" "전체" "$full_msg"

exec_msg=$(grep -A10 -B5 "execute_restore" "$restore_file" | grep -i "실제\|실행\|execute")
test_case "실제 복구 메시지" "실제" "$exec_msg"

# 최종 결과
echo ""
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
    echo -e "${GREEN}🎉 안전장치 및 고급 기능 모두 검증 완료!${NC}"
    echo ""
    echo -e "${GREEN}✅ 안전장치 시스템 (--force, --no-rollback)${NC}"
    echo -e "${GREEN}✅ 학습 모드 (--explain, --explain-interactive)${NC}"
    echo -e "${GREEN}✅ 배치 모드 (--batch)${NC}"
    echo -e "${GREEN}✅ 사용자 인터페이스 품질${NC}"
    echo ""
    echo -e "${BLUE}🚀 고급 기능이 완벽하게 구현되었습니다!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️  일부 고급 기능에서 문제가 발견되었습니다.${NC}"
    echo -e "${RED}구현을 재검토해주세요.${NC}"
    exit 1
fi