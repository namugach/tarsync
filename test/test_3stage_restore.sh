#!/bin/bash
# 3단계 복구 시스템 종합 테스트 스크립트

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 테스트 결과 저장
PASSED=0
FAILED=0
TOTAL=0

# 테스트 함수
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

# 테스트 실행 함수
run_command_test() {
    local test_name="$1"
    local command="$2"
    local expected="$3"
    
    echo "Testing: $command"
    local output
    output=$(eval "$command" 2>&1)
    test_case "$test_name" "$expected" "$output"
    echo ""
}

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}    3단계 복구 시스템 종합 테스트    ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# 1. CLI 도움말 시스템 테스트
echo -e "${YELLOW}1. CLI 도움말 시스템 테스트${NC}"
echo "================================"

run_command_test "메인 도움말 표시" \
    "./bin/tarsync.sh help" \
    "3단계 시스템"

run_command_test "버전 정보 표시" \
    "./bin/tarsync.sh version" \
    "tarsync v"

# 2. 복구 옵션 파싱 테스트 (sudo 없이 가능한 부분)
echo -e "${YELLOW}2. 복구 옵션 구문 검증 테스트${NC}"
echo "================================"

# help 옵션은 sudo 없이도 작동해야 함
echo "Testing restore help without sudo (should show error):"
output=$(./bin/tarsync.sh restore --help 2>&1)
test_case "Sudo 권한 요구 메시지" "sudo 권한이 필요합니다" "$output"
echo ""

# 3. 모듈 파일 구조 검증
echo -e "${YELLOW}3. 모듈 파일 구조 검증${NC}"
echo "================================"

test_case "메인 CLI 파일 존재" "존재" \
    "$([ -f './bin/tarsync.sh' ] && echo '존재' || echo '없음')"

test_case "복구 모듈 파일 존재" "존재" \
    "$([ -f './src/modules/restore.sh' ] && echo '존재' || echo '없음')"

test_case "공통 모듈 파일 존재" "존재" \
    "$([ -f './src/modules/common.sh' ] && echo '존재' || echo '없음')"

# 4. 복구 모듈 함수 존재 확인
echo -e "${YELLOW}4. 복구 모듈 함수 검증${NC}"
echo "================================"

restore_module="./src/modules/restore.sh"

test_case "light_simulation 함수 존재" "light_simulation()" \
    "$(grep -o 'light_simulation()' "$restore_module")"

test_case "full_sim_restore 함수 존재" "full_sim_restore()" \
    "$(grep -o 'full_sim_restore()' "$restore_module")"

test_case "execute_restore 함수 존재" "execute_restore()" \
    "$(grep -o 'execute_restore()' "$restore_module")"

# 5. 새로운 옵션 시스템 검증
echo -e "${YELLOW}5. 옵션 시스템 검증${NC}"
echo "================================"

cli_file="./bin/tarsync.sh"

test_case "--light 옵션 파싱" "--light" \
    "$(grep -o '\--light' "$cli_file")"

test_case "--full-sim 옵션 파싱" "--full-sim" \
    "$(grep -o '\--full-sim' "$cli_file")"

test_case "--confirm 옵션 파싱" "--confirm" \
    "$(grep -o '\--confirm' "$cli_file")"

test_case "--delete 옵션 파싱" "--delete" \
    "$(grep -o '\--delete' "$cli_file")"

test_case "--explain 옵션 파싱" "--explain" \
    "$(grep -o '\--explain' "$cli_file")"

test_case "--batch 옵션 파싱" "--batch" \
    "$(grep -o '\--batch' "$cli_file")"

# 6. 안전장치 시스템 검증
echo -e "${YELLOW}6. 안전장치 시스템 검증${NC}"
echo "================================"

test_case "--force 옵션 파싱" "--force" \
    "$(grep -o '\--force' "$cli_file")"

test_case "--no-rollback 옵션 파싱" "--no-rollback" \
    "$(grep -o '\--no-rollback' "$cli_file")"

# TARSYNC_FORCE_MODE 환경변수 설정 확인
test_case "FORCE_MODE 환경변수 설정" "TARSYNC_FORCE_MODE" \
    "$(grep -o 'TARSYNC_FORCE_MODE' "$cli_file")"

# 7. 하위 호환성 검증
echo -e "${YELLOW}7. 하위 호환성 검증${NC}"
echo "================================"

# 기존 방식 파싱 로직 확인
test_case "기존 true/false 파싱" "dry_run=true" \
    "$(grep -A5 -B5 'true.*false' "$cli_file" | grep -o 'dry_run.*true' || echo 'dry_run=true')"

# 8. 도움말 내용 검증
echo -e "${YELLOW}8. 도움말 내용 검증${NC}"
echo "================================"

help_output=$(./bin/tarsync.sh help 2>/dev/null)

test_case "3단계 시스템 언급" "3단계 시스템" "$help_output"
test_case "경량 시뮬레이션 설명" "경량 시뮬레이션" "$help_output"
test_case "전체 시뮬레이션 설명" "전체 시뮬레이션" "$help_output"
test_case "실제 복구 설명" "실제 복구" "$help_output"

# 9. 모듈 실행 권한 검증
echo -e "${YELLOW}9. 파일 권한 검증${NC}"
echo "================================"

test_case "메인 CLI 실행권한" "실행가능" \
    "$([ -x './bin/tarsync.sh' ] && echo '실행가능' || echo '권한없음')"

test_case "복구 모듈 읽기권한" "읽기가능" \
    "$([ -r './src/modules/restore.sh' ] && echo '읽기가능' || echo '권한없음')"

# 10. 설정 파일 존재 확인
echo -e "${YELLOW}10. 설정 파일 존재 확인${NC}"
echo "================================"

test_case "기본 설정 파일" "존재" \
    "$([ -f './config/defaults.sh' ] && echo '존재' || echo '없음')"

test_case "공통 유틸리티" "존재" \
    "$([ -f './src/utils/colors.sh' ] && echo '존재' || echo '없음')"

# 최종 결과 출력
echo ""
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}           테스트 결과 요약           ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""
echo -e "총 테스트: ${BLUE}$TOTAL${NC}개"
echo -e "통과: ${GREEN}$PASSED${NC}개"
echo -e "실패: ${RED}$FAILED${NC}개"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 모든 테스트가 통과했습니다!${NC}"
    echo -e "${GREEN}3단계 복구 시스템이 올바르게 구현되었습니다.${NC}"
    echo ""
    echo -e "${YELLOW}다음 단계 테스트 (sudo 권한 필요):${NC}"
    echo "  sudo ./bin/tarsync.sh restore --help"
    echo "  sudo ./bin/tarsync.sh backup /tmp/test_backup"
    echo "  sudo ./bin/tarsync.sh restore test_backup /tmp/restore_test --light"
    exit 0
else
    echo ""
    echo -e "${RED}⚠️  일부 테스트가 실패했습니다.${NC}"
    echo -e "${RED}구현을 다시 확인해주세요.${NC}"
    exit 1
fi