#!/bin/bash
# tarsync 버전 관리 유틸리티
# 공통 버전 관리 함수들을 제공

# 프로젝트 루트 경로 찾기
# 이 함수는 현재 스크립트의 위치를 기준으로 프로젝트 루트를 찾음
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # src/utils에서 2단계 상위로 이동 (../../)
    cd "$script_dir/../.." && pwd
}

# 버전 파일 경로 설정
# 개발 환경과 설치 환경을 모두 고려하여 VERSION 파일 경로를 찾음
setup_version_file() {
    local project_root=$(get_project_root)
    local version_file="$project_root/bin/VERSION"
    
    # 설치된 환경에서는 다른 경로 확인
    # 1. 개발 환경: 프로젝트/bin/VERSION
    # 2. 전역 설치: /usr/share/tarsync/VERSION
    # 3. 사용자 설치: ~/.tarsync/bin/VERSION
    if [ ! -f "$version_file" ]; then
        # 스크립트가 실행되는 위치에서 VERSION 파일 찾기
        local caller_dir="$(dirname "${BASH_SOURCE[1]}")"
        local caller_version="$caller_dir/VERSION"
        
        if [ -f "$caller_version" ]; then
            version_file="$caller_version"
        elif [ -f "/usr/share/tarsync/VERSION" ]; then
            version_file="/usr/share/tarsync/VERSION"
        elif [ -f "$HOME/.tarsync/bin/VERSION" ]; then
            version_file="$HOME/.tarsync/bin/VERSION"
        fi
    fi
    
    echo "$version_file"
}

# 버전 정보 가져오기
# VERSION 파일에서 버전 정보를 읽어서 반환
get_version() {
    local version_file=$(setup_version_file)
    if [ -f "$version_file" ]; then
        cat "$version_file" | tr -d '\n'
    else
        echo "unknown"
    fi
}

# 버전 비교 함수 (나중에 migrate 기능에서 사용)
# 두 버전을 비교하여 결과를 반환 (1: v1 > v2, 0: v1 == v2, -1: v1 < v2)
compare_versions() {
    local v1="$1"
    local v2="$2"
    
    if [[ "$v1" == "$v2" ]]; then
        echo 0
        return
    fi
    
    local IFS='.'
    local i ver1=($v1) ver2=($v2)
    
    # 빈 필드는 0으로 채우기
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=${#ver2[@]}; i<${#ver1[@]}; i++)); do
        ver2[i]=0
    done
    
    # 버전 번호 비교
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ ${ver1[i]} -gt ${ver2[i]} ]]; then
            echo 1
            return
        fi
        if [[ ${ver1[i]} -lt ${ver2[i]} ]]; then
            echo -1
            return
        fi
    done
    
    echo 0
}

# 최소 버전 요구사항 확인 (나중에 기능 추가시 사용)
check_min_version() {
    local required_version="$1"
    local current_version=$(get_version)
    
    if [[ "$current_version" == "unknown" ]]; then
        return 1
    fi
    
    local comparison=$(compare_versions "$current_version" "$required_version")
    
    if [[ "$comparison" == "-1" ]]; then
        echo "Current version ($current_version) is lower than minimum required version ($required_version)." >&2
        return 1
    fi
    
    return 0
} 