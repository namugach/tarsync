#!/bin/bash
# 3단계 복구 기능 실제 테스트 스크립트

# 색상 설정
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}    3단계 복구 기능 실제 테스트       ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

# 테스트 환경 설정
TEST_SOURCE="/tmp/tarsync_test_source"
TEST_RESTORE="/tmp/tarsync_test_restore"
TEST_BACKUP_NAME=""

# 정리 함수
cleanup() {
    echo "🧹 테스트 환경 정리 중..."
    rm -rf "$TEST_SOURCE" "$TEST_RESTORE"
    if [[ -n "$TEST_BACKUP_NAME" ]]; then
        echo "🗑️  테스트 백업 삭제: $TEST_BACKUP_NAME"
        sudo ./bin/tarsync.sh delete "$TEST_BACKUP_NAME" 2>/dev/null || true
    fi
}

# 시그널 핸들러 설정
trap cleanup EXIT

# 1. 테스트 데이터 생성
echo -e "${YELLOW}1. 테스트 환경 준비${NC}"
echo "================================"

mkdir -p "$TEST_SOURCE/subdir"
echo "Test file 1" > "$TEST_SOURCE/file1.txt"
echo "Test file 2" > "$TEST_SOURCE/subdir/file2.txt"
echo "Configuration data" > "$TEST_SOURCE/config.ini"

echo "✅ 테스트 데이터 생성 완료"
echo "   📂 $TEST_SOURCE/"
echo "   ├── file1.txt"
echo "   ├── config.ini"
echo "   └── subdir/"
echo "       └── file2.txt"
echo ""

# 2. 테스트 백업 생성
echo -e "${YELLOW}2. 테스트 백업 생성${NC}"
echo "================================"

echo "🔄 백업 생성 중: $TEST_SOURCE"
backup_output=$(sudo ./bin/tarsync.sh backup "$TEST_SOURCE" 2>&1)
backup_status=$?

if [ $backup_status -eq 0 ]; then
    echo "✅ 백업 생성 성공"
    # 백업 이름 추출 (로그에서)
    TEST_BACKUP_NAME=$(echo "$backup_output" | grep -oE "2[0-9]{3}_[0-9]{2}_[0-9]{2}_[AP]M_[0-9]{2}_[0-9]{2}_[0-9]{2}" | head -1)
    echo "📦 백업 이름: $TEST_BACKUP_NAME"
else
    echo "❌ 백업 생성 실패"
    echo "$backup_output"
    exit 1
fi
echo ""

# 3. 복구 모드 테스트 준비
mkdir -p "$TEST_RESTORE"

echo -e "${YELLOW}3. 1단계: 경량 시뮬레이션 테스트${NC}"
echo "================================"

echo "🧪 경량 시뮬레이션 실행 중..."
light_output=$(sudo ./bin/tarsync.sh restore "$TEST_BACKUP_NAME" "$TEST_RESTORE" --light 2>&1)
light_status=$?

if [ $light_status -eq 0 ]; then
    echo "✅ 경량 시뮬레이션 성공"
    echo "📊 출력 내용 확인:"
    if [[ "$light_output" == *"경량 시뮬레이션"* ]]; then
        echo "  ✓ 경량 시뮬레이션 모드 실행됨"
    fi
    if [[ "$light_output" == *"파일 개수"* ]]; then
        echo "  ✓ 파일 개수 정보 표시됨"
    fi
    if [[ "$light_output" == *"디렉토리 개수"* ]]; then
        echo "  ✓ 디렉토리 개수 정보 표시됨"
    fi
    
    # 실제 파일이 복구되지 않았는지 확인
    if [ ! -f "$TEST_RESTORE/file1.txt" ]; then
        echo "  ✓ 경량 시뮬레이션: 실제 파일 복구 안됨 (정상)"
    else
        echo "  ⚠️  경량 시뮬레이션인데 파일이 복구됨 (문제)"
    fi
else
    echo "❌ 경량 시뮬레이션 실패"
    echo "$light_output"
fi
echo ""

echo -e "${YELLOW}4. 2단계: 전체 시뮬레이션 테스트${NC}"
echo "================================"

echo "🧪 전체 시뮬레이션 실행 중..."
full_output=$(sudo ./bin/tarsync.sh restore "$TEST_BACKUP_NAME" "$TEST_RESTORE" --full-sim 2>&1)
full_status=$?

if [ $full_status -eq 0 ]; then
    echo "✅ 전체 시뮬레이션 성공"
    echo "📊 출력 내용 확인:"
    if [[ "$full_output" == *"전체 시뮬레이션"* || "$full_output" == *"시뮬레이션"* ]]; then
        echo "  ✓ 전체 시뮬레이션 모드 실행됨"
    fi
    if [[ "$full_output" == *"rsync"* || "$full_output" == *"복구"* ]]; then
        echo "  ✓ rsync 시뮬레이션 실행됨"
    fi
    
    # 실제 파일이 복구되지 않았는지 확인
    if [ ! -f "$TEST_RESTORE/file1.txt" ]; then
        echo "  ✓ 전체 시뮬레이션: 실제 파일 복구 안됨 (정상)"
    else
        echo "  ⚠️  전체 시뮬레이션인데 파일이 복구됨 (문제)"
    fi
else
    echo "❌ 전체 시뮬레이션 실패"
    echo "$full_output"
fi
echo ""

echo -e "${YELLOW}5. 3단계: 실제 복구 테스트${NC}"
echo "================================"

echo "🔧 실제 복구 실행 중..."
restore_output=$(sudo ./bin/tarsync.sh restore "$TEST_BACKUP_NAME" "$TEST_RESTORE" --confirm 2>&1)
restore_status=$?

if [ $restore_status -eq 0 ]; then
    echo "✅ 실제 복구 성공"
    
    # 파일 복구 확인
    echo "📂 복구된 파일 확인:"
    if [ -f "$TEST_RESTORE/file1.txt" ]; then
        echo "  ✓ file1.txt 복구됨"
        content1=$(cat "$TEST_RESTORE/file1.txt")
        if [[ "$content1" == "Test file 1" ]]; then
            echo "    ✓ 내용 일치: $content1"
        else
            echo "    ❌ 내용 불일치: $content1"
        fi
    else
        echo "  ❌ file1.txt 복구 안됨"
    fi
    
    if [ -f "$TEST_RESTORE/subdir/file2.txt" ]; then
        echo "  ✓ subdir/file2.txt 복구됨"
        content2=$(cat "$TEST_RESTORE/subdir/file2.txt")
        if [[ "$content2" == "Test file 2" ]]; then
            echo "    ✓ 내용 일치: $content2"
        else
            echo "    ❌ 내용 불일치: $content2"
        fi
    else
        echo "  ❌ subdir/file2.txt 복구 안됨"
    fi
    
    if [ -f "$TEST_RESTORE/config.ini" ]; then
        echo "  ✓ config.ini 복구됨"
    else
        echo "  ❌ config.ini 복구 안됨"
    fi
    
else
    echo "❌ 실제 복구 실패"
    echo "$restore_output"
fi
echo ""

# 6. 추가 옵션 테스트
echo -e "${YELLOW}6. 추가 옵션 테스트${NC}"
echo "================================"

echo "🔍 --explain 옵션 테스트:"
explain_output=$(sudo ./bin/tarsync.sh restore "$TEST_BACKUP_NAME" "$TEST_RESTORE" --light --explain 2>&1)
if [[ "$explain_output" == *"설명"* || "$explain_output" == *"학습"* ]]; then
    echo "  ✅ --explain 옵션 작동"
else
    echo "  ⚠️  --explain 옵션 효과 불분명"
fi

echo ""

# 7. 하위 호환성 테스트
echo -e "${YELLOW}7. 하위 호환성 테스트${NC}"
echo "================================"

echo "🔄 기존 방식 테스트 (true = 전체 시뮬레이션):"
compat_output=$(sudo ./bin/tarsync.sh restore "$TEST_BACKUP_NAME" "$TEST_RESTORE" true 2>&1)
if [ $? -eq 0 ]; then
    echo "  ✅ 기존 방식 호환성 유지"
else
    echo "  ❌ 기존 방식 호환성 문제"
fi

echo ""

# 최종 결과
echo -e "${CYAN}======================================${NC}"
echo -e "${CYAN}           테스트 결과 요약           ${NC}"
echo -e "${CYAN}======================================${NC}"
echo ""

if [ $light_status -eq 0 ] && [ $full_status -eq 0 ] && [ $restore_status -eq 0 ]; then
    echo -e "${GREEN}🎉 3단계 복구 시스템 모든 테스트 통과!${NC}"
    echo ""
    echo -e "${GREEN}✅ 1단계: 경량 시뮬레이션 - 작동 확인${NC}"
    echo -e "${GREEN}✅ 2단계: 전체 시뮬레이션 - 작동 확인${NC}"
    echo -e "${GREEN}✅ 3단계: 실제 복구 - 작동 확인${NC}"
    echo ""
    echo -e "${BLUE}🚀 시스템이 성공적으로 구현되었습니다!${NC}"
else
    echo -e "${RED}⚠️  일부 테스트에서 문제가 발견되었습니다.${NC}"
    echo "   - 경량 시뮬레이션: $([ $light_status -eq 0 ] && echo '✅ 성공' || echo '❌ 실패')"
    echo "   - 전체 시뮬레이션: $([ $full_status -eq 0 ] && echo '✅ 성공' || echo '❌ 실패')"
    echo "   - 실제 복구: $([ $restore_status -eq 0 ] && echo '✅ 성공' || echo '❌ 실패')"
fi

echo ""
echo "🧹 테스트 정리는 자동으로 수행됩니다..."