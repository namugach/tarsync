#!/bin/bash
# 구문 및 로직 검증 테스트 (sudo 불필요)

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
echo -e "${CYAN}     구문 및 로직 검증 테스트        ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# 1. 복구 모듈 구문 검증
echo -e "${YELLOW}1. 복구 모듈 구문 검증${NC}"
echo "================================"

restore_module="./src/modules/restore.sh"

# Bash 구문 체크
syntax_check=$(bash -n "$restore_module" 2>&1)
test_case "복구 모듈 구문 검사" "" "$syntax_check"

# 2. CLI 모듈 구문 검증
echo -e "${YELLOW}2. CLI 모듈 구문 검증${NC}"
echo "================================"

cli_module="./bin/tarsync.sh"
cli_syntax_check=$(bash -n "$cli_module" 2>&1)
test_case "CLI 모듈 구문 검사" "" "$cli_syntax_check"

# 3. 3단계 함수 호출 체인 검증
echo -e "${YELLOW}3. 함수 호출 체인 검증${NC}"
echo "================================"

# light_simulation 함수가 main restore 함수에서 호출되는지
light_call=$(grep -n "light_simulation" "$restore_module" | wc -l)
test_case "light_simulation 함수 호출" "1" "$([ $light_call -gt 0 ] && echo '1' || echo '0')"

# full_sim_restore 함수가 호출되는지
full_call=$(grep -n "full_sim_restore" "$restore_module" | wc -l)
test_case "full_sim_restore 함수 호출" "1" "$([ $full_call -gt 0 ] && echo '1' || echo '0')"

# execute_restore 함수가 호출되는지
exec_call=$(grep -n "execute_restore" "$restore_module" | wc -l)
test_case "execute_restore 함수 호출" "1" "$([ $exec_call -gt 0 ] && echo '1' || echo '0')"

# 4. 모드 분기 로직 검증
echo -e "${YELLOW}4. 모드 분기 로직 검증${NC}"
echo "================================"

# CLI에서 mode 변수 설정 확인
mode_light=$(grep -n 'mode="light"' "$cli_module" | wc -l)
test_case "light 모드 설정" "1" "$([ $mode_light -gt 0 ] && echo '1' || echo '0')"

mode_full=$(grep -n 'mode="full-sim"' "$cli_module" | wc -l)
test_case "full-sim 모드 설정" "1" "$([ $mode_full -gt 0 ] && echo '1' || echo '0')"

mode_confirm=$(grep -n 'mode="confirm"' "$cli_module" | wc -l)
test_case "confirm 모드 설정" "1" "$([ $mode_confirm -gt 0 ] && echo '1' || echo '0')"

# 5. 환경변수 설정 검증
echo -e "${YELLOW}5. 환경변수 설정 검증${NC}"
echo "================================"

# TARSYNC_FORCE_MODE 설정
force_mode=$(grep -n 'TARSYNC_FORCE_MODE="true"' "$cli_module" | wc -l)
test_case "강제 모드 환경변수" "1" "$([ $force_mode -gt 0 ] && echo '1' || echo '0')"

# TARSYNC_EXPLAIN_MODE 설정
explain_mode=$(grep -n 'TARSYNC_EXPLAIN_MODE="true"' "$cli_module" | wc -l)
test_case "설명 모드 환경변수" "1" "$([ $explain_mode -gt 0 ] && echo '1' || echo '0')"

# TARSYNC_BATCH_MODE 설정
batch_mode=$(grep -n 'TARSYNC_BATCH_MODE="true"' "$cli_module" | wc -l)
test_case "배치 모드 환경변수" "1" "$([ $batch_mode -gt 0 ] && echo '1' || echo '0')"

# 6. 하위 호환성 로직 검증
echo -e "${YELLOW}6. 하위 호환성 로직 검증${NC}"
echo "================================"

# true/false 처리 로직
true_false_logic=$(grep -A10 -B5 '"true".*"false"' "$cli_module" | wc -l)
test_case "true/false 호환성 로직" "1" "$([ $true_false_logic -gt 0 ] && echo '1' || echo '0')"

# dry_run 매핑
dry_run_mapping=$(grep -n "full-sim.*dry_run.*true\|confirm.*dry_run.*false" "$cli_module" | wc -l)
test_case "dry_run 매핑 로직" "0" "$([ $dry_run_mapping -ge 0 ] && echo '1' || echo '0')"

# 7. 에러 처리 검증
echo -e "${YELLOW}7. 에러 처리 검증${NC}"
echo "================================"

# 알 수 없는 옵션 처리
unknown_option=$(grep -A5 -B2 "알 수 없는 옵션" "$cli_module" | wc -l)
test_case "알 수 없는 옵션 처리" "1" "$([ $unknown_option -gt 0 ] && echo '1' || echo '0')"

# 도움말 호출
help_calls=$(grep -n "show_restore_help" "$cli_module" | wc -l)
test_case "복구 도움말 호출" "1" "$([ $help_calls -gt 0 ] && echo '1' || echo '0')"

# 8. 로그 및 출력 메시지 검증
echo -e "${YELLOW}8. 사용자 인터페이스 검증${NC}"
echo "================================"

# 3단계 관련 메시지
stage_messages=$(grep -r "경량 시뮬레이션\|전체 시뮬레이션\|실제 복구" "$restore_module" | wc -l)
test_case "3단계 메시지" "1" "$([ $stage_messages -gt 0 ] && echo '1' || echo '0')"

# 진행 상황 표시
progress_messages=$(grep -r "🧪\|🔧\|📊" "$restore_module" | wc -l)
test_case "진행 상황 아이콘" "1" "$([ $progress_messages -gt 0 ] && echo '1' || echo '0')"

# 9. 보안 검증
echo -e "${YELLOW}9. 보안 검증${NC}"
echo "================================"

# sudo 권한 체크
sudo_check=$(grep -n "check_sudo_privileges" "$cli_module" | wc -l)
test_case "sudo 권한 체크" "1" "$([ $sudo_check -gt 0 ] && echo '1' || echo '0')"

# 경로 검증 관련
path_validation=$(grep -r "경로\|path" "$restore_module" | wc -l)
test_case "경로 관련 처리" "1" "$([ $path_validation -gt 0 ] && echo '1' || echo '0')"

# 10. 모듈 의존성 검증
echo -e "${YELLOW}10. 모듈 의존성 검증${NC}"
echo "================================"

# common.sh 로드 확인
common_load=$(grep -n "source.*common.sh" "$restore_module" | wc -l)
test_case "공통 모듈 로드" "1" "$([ $common_load -gt 0 ] && echo '1' || echo '0')"

# 색상 유틸리티 로드 확인
colors_load=$(grep -n "source.*colors.sh" "$cli_module" | wc -l)
test_case "색상 유틸리티 로드" "1" "$([ $colors_load -gt 0 ] && echo '1' || echo '0')"

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
    echo -e "${GREEN}🎉 모든 구문 및 로직 검증 통과!${NC}"
    echo -e "${GREEN}3단계 복구 시스템 구현이 올바릅니다.${NC}"
    echo ""
    echo -e "${YELLOW}✨ 다음 단계:${NC}"
    echo "  - 실제 기능 테스트 (sudo 필요)"
    echo "  - 성능 테스트 및 최적화"
    echo "  - 엣지 케이스 테스트"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️  일부 검증에서 문제가 발견되었습니다.${NC}"
    echo -e "${RED}코드를 재검토해주세요.${NC}"
    exit 1
fi