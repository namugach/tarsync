#!/bin/bash
# tarsync 포맷팅 유틸리티 함수들
# 기존 util.ts에서 변환됨

# 쉼표가 포함된 숫자 문자열을 정수로 변환
# 예: "1,024,000" -> 1024000
convert_string_number() {
    local input="$1"
    echo "$input" | tr -d ','
}

# 바이트 크기를 사람이 읽기 쉬운 형태로 변환
# 예: 1073741824 -> "1.00 GB"
convert_size() {
    local size="$1"
    
    # 문자열인 경우 쉼표 제거 후 숫자로 변환
    if [[ "$size" =~ [^0-9] ]]; then
        size=$(convert_string_number "$size")
    fi
    
    # 숫자 검증
    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        echo "0 Bytes"
        return
    fi
    
    local gb_threshold=$((1024 * 1024 * 1024))
    local mb_threshold=$((1024 * 1024))
    local kb_threshold=1024
    
    if (( size >= gb_threshold )); then
        # GB 단위
        local gb_size=$(echo "scale=2; $size / $gb_threshold" | bc)
        echo "${gb_size} GB"
    elif (( size >= mb_threshold )); then
        # MB 단위
        local mb_size=$(echo "scale=2; $size / $mb_threshold" | bc)
        echo "${mb_size} MB"
    elif (( size >= kb_threshold )); then
        # KB 단위
        local kb_size=$(echo "scale=2; $size / $kb_threshold" | bc)
        echo "${kb_size} KB"
    else
        # Bytes 단위
        echo "${size} Bytes"
    fi
}

# 현재 날짜를 tarsync 형식으로 반환
# 예: "2025_06_27_AM_11_59_00"
get_date() {
    local hour=$(date '+%H')
    local ampm="AM"
    if [[ $hour -ge 12 ]]; then
        ampm="PM"
    fi
    date '+%Y_%m_%d_'${ampm}'_%I_%M_%S'
}

# 현재 타임스탬프를 반환 (로그용)
# 예: "2025-06-27 11:59:00"
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 파일 크기를 바이트 단위로 반환
get_file_size() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        stat -c%s "$file_path" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# 디렉토리 크기를 바이트 단위로 반환 (재귀적)
get_directory_size() {
    local dir_path="$1"
    if [[ -d "$dir_path" ]]; then
        du -sb "$dir_path" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

# 경로의 크기를 사람이 읽기 쉬운 형태로 반환
get_path_size_formatted() {
    local path="$1"
    local size_bytes
    
    if [[ -f "$path" ]]; then
        size_bytes=$(get_file_size "$path")
    elif [[ -d "$path" ]]; then
        size_bytes=$(get_directory_size "$path")
    else
        echo "경로가 존재하지 않음"
        return 1
    fi
    
    convert_size "$size_bytes"
} 