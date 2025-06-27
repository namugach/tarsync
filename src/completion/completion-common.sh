#!/bin/bash

# tarsync 자동완성을 위한 공통 함수
# Common functions for tarsync shell completion

# 디버그 모드 설정
_TARSYNC_DEBUG=false

# 디버그 메시지 출력 함수
_tarsync_debug() {
    if [[ "$_TARSYNC_DEBUG" == "true" ]]; then
        echo "DEBUG: $1" >&2
    fi
}

# 백업 저장소 경로 확인
_tarsync_get_backup_store() {
    local backup_store="/mnt/backup"
    
    # config에서 백업 저장소 경로 가져오기 (있는 경우)
    if [[ -f "$HOME/.tarsync/config" ]]; then
        local store_path=$(grep "^BACKUP_STORE=" "$HOME/.tarsync/config" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
        if [[ -n "$store_path" ]]; then
            backup_store="$store_path"
        fi
    fi
    
    echo "$backup_store"
}

# 백업 목록 가져오기
_tarsync_get_backup_list() {
    local backup_store=$(_tarsync_get_backup_store)
    
    _tarsync_debug "Getting backup list from: $backup_store"
    
    if [[ -d "$backup_store" ]]; then
        find "$backup_store" -maxdepth 1 -name "*.tar.gz" -printf "%f\n" 2>/dev/null | \
        sed 's/\.tar\.gz$//' | sort
    fi
}

# 백업 목록을 설명과 함께 가져오기 (ZSH용)
_tarsync_get_backup_list_with_desc() {
    local backup_store=$(_tarsync_get_backup_store)
    local -a backup_list
    
    _tarsync_debug "Getting backup list with descriptions from: $backup_store"
    
    if [[ -d "$backup_store" ]]; then
        while IFS= read -r backup_file; do
            if [[ -n "$backup_file" ]]; then
                local backup_name=$(basename "$backup_file" .tar.gz)
                local backup_meta="$backup_store/${backup_name}.sh"
                local backup_size="알 수 없음"
                local backup_date="알 수 없음"
                
                # 메타데이터에서 정보 가져오기
                if [[ -f "$backup_meta" ]]; then
                    local meta_size=$(grep "^META_SIZE=" "$backup_meta" 2>/dev/null | cut -d'=' -f2)
                    local meta_created=$(grep "^META_CREATED=" "$backup_meta" 2>/dev/null | cut -d'"' -f2)
                    
                    if [[ -n "$meta_size" ]]; then
                        backup_size=$(echo "$meta_size" | numfmt --to=iec 2>/dev/null || echo "$meta_size")
                    fi
                    
                    if [[ -n "$meta_created" ]]; then
                        backup_date="$meta_created"
                    fi
                fi
                
                # 형식: "backup_name:크기 날짜"
                echo "$backup_name:$backup_size $backup_date"
            fi
        done < <(find "$backup_store" -maxdepth 1 -name "*.tar.gz" -printf "%f\n" 2>/dev/null | sort)
    fi
}

# 명령어별 설명 가져오기
_tarsync_get_command_desc() {
    local command="$1"
    
    case "$command" in
        backup|b)
            echo "디렉토리를 tar+gzip으로 압축 백업"
            ;;
        restore|r)
            echo "백업을 지정된 위치로 복구"
            ;;
        list|ls|l)
            echo "백업 목록을 페이지네이션으로 표시"
            ;;
        delete|rm|d)
            echo "지정된 백업을 완전히 삭제"
            ;;
        details|show|info|i)
            echo "백업의 상세 정보 및 메타데이터 표시"
            ;;
        version|v)
            echo "tarsync 버전 정보 표시"
            ;;
        help|h)
            echo "사용법 및 도움말 표시"
            ;;
        *)
            echo "$command"
            ;;
    esac
}

# 페이지 크기 옵션 가져오기
_tarsync_get_page_size_options() {
    echo "5 10 15 20 25 50"
}

# 시뮬레이션 모드 옵션 가져오기
_tarsync_get_simulation_options() {
    echo "true false"
}

# 삭제 모드 옵션 가져오기  
_tarsync_get_delete_mode_options() {
    echo "true false"
}

# 모든 명령어 목록 가져오기
_tarsync_get_all_commands() {
    echo "backup restore list delete details version help b r ls l rm d show info i v h"
}

# 메인 명령어만 가져오기 (단축 명령어 제외)
_tarsync_get_main_commands() {
    echo "backup restore list delete details version help"
}

# 단축 명령어만 가져오기
_tarsync_get_short_commands() {
    echo "b r ls l rm d show info i v h"
}

# Bash용 명령어와 설명 출력 (컬러 포함)
_tarsync_show_command_help_bash() {
    local commands=($(_tarsync_get_main_commands))
    
    echo "" >&2
    echo "📋 사용 가능한 명령어:" >&2
    
    for cmd in "${commands[@]}"; do
        local desc=$(_tarsync_get_command_desc "$cmd")
        printf "  \033[32m%-10s\033[0m # %s\n" "$cmd" "$desc" >&2
    done
    
    echo "" >&2
}

# 현재 셸 감지
_tarsync_detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# 백업 파일 존재 확인
_tarsync_backup_exists() {
    local backup_name="$1"
    local backup_store=$(_tarsync_get_backup_store)
    
    [[ -f "$backup_store/${backup_name}.tar.gz" ]]
}

# 자동완성 캐시 관리
_TARSYNC_BACKUP_CACHE=""
_TARSYNC_BACKUP_CACHE_TIME=0

_tarsync_get_cached_backup_list() {
    local current_time=$(date +%s)
    local cache_duration=5  # 5초 캐시
    
    if [[ -z "$_TARSYNC_BACKUP_CACHE" ]] || [[ $((current_time - _TARSYNC_BACKUP_CACHE_TIME)) -gt $cache_duration ]]; then
        _TARSYNC_BACKUP_CACHE=$(_tarsync_get_backup_list)
        _TARSYNC_BACKUP_CACHE_TIME=$current_time
        _tarsync_debug "Backup list cache refreshed"
    fi
    
    echo "$_TARSYNC_BACKUP_CACHE"
}

# 에러 처리
_tarsync_handle_error() {
    local error_msg="$1"
    _tarsync_debug "Error: $error_msg"
    # 에러가 발생해도 자동완성은 계속 동작해야 함
    return 0
}

# 자동완성 초기화
_tarsync_completion_init() {
    _tarsync_debug "Initializing tarsync completion"
    
    # 백업 저장소가 존재하는지 확인
    local backup_store=$(_tarsync_get_backup_store)
    if [[ ! -d "$backup_store" ]]; then
        _tarsync_debug "Backup store does not exist: $backup_store"
    fi
    
    return 0
}

# 초기화 실행
_tarsync_completion_init 