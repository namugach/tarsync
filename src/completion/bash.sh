#!/bin/bash
# tarsync Bash 자동완성 스크립트
# Advanced Bash completion for tarsync command

# 공통 스크립트 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 설치된 위치와 현재 위치 모두 시도
if [[ -f "$SCRIPT_DIR/completion-common.sh" ]]; then
    source "$SCRIPT_DIR/completion-common.sh"
elif [[ -f "/usr/local/lib/tarsync/src/completion/completion-common.sh" ]]; then
    source "/usr/local/lib/tarsync/src/completion/completion-common.sh"
elif [[ -f "/usr/local/share/bash-completion/completions/completion-common.sh" ]]; then
    source "/usr/local/share/bash-completion/completions/completion-common.sh"
elif [[ -f "/etc/bash_completion.d/completion-common.sh" ]]; then
    source "/etc/bash_completion.d/completion-common.sh"
else
    echo "Warning: Could not find tarsync completion-common.sh" >&2
    return 1
fi

# Bash용 명령어 설명 표시 (선택적)
_tarsync_show_help_if_multiple() {
    local current_completions=("$@")
    
    # 여러 옵션이 있고 설명 모드가 활성화된 경우만
    if [[ ${#current_completions[@]} -gt 1 ]] && [[ "${TARSYNC_SHOW_HELP:-false}" == "true" ]]; then
        _tarsync_show_command_help_bash
    fi
}

# Bash 자동완성 메인 함수
_tarsync_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 현재 명령어 위치 확인
    local cmd_pos=1
    local main_cmd=""
    
    if [[ $COMP_CWORD -ge $cmd_pos ]]; then
        main_cmd="${COMP_WORDS[$cmd_pos]}"
    fi
    
    _tarsync_debug "Bash completion: cur='$cur', prev='$prev', main_cmd='$main_cmd', COMP_CWORD=$COMP_CWORD"
    
    # 첫 번째 인수: 메인 명령어들
    if [[ $COMP_CWORD -eq 1 ]]; then
        local all_commands=$(_tarsync_get_all_commands)
        COMPREPLY=($(compgen -W "$all_commands" -- "$cur"))
        
        # 도움말 표시 (환경변수로 제어)
        _tarsync_show_help_if_multiple "${COMPREPLY[@]}"
        
        return 0
    fi
    
    # 명령어별 세부 자동완성
    case "$main_cmd" in
        backup|b)
            _tarsync_complete_backup_command
            ;;
        restore|r)
            _tarsync_complete_restore_command
            ;;
        list|ls|l)
            _tarsync_complete_list_command
            ;;
        delete|rm|d)
            _tarsync_complete_delete_command
            ;;
        details|show|info|i)
            _tarsync_complete_details_command
            ;;
        version|v|help|h)
            # 이 명령어들은 추가 인수가 없음
            COMPREPLY=()
            ;;
        *)
            # 알 수 없는 명령어
            COMPREPLY=()
            ;;
    esac
    
    return 0
}

# backup 명령어 자동완성
_tarsync_complete_backup_command() {
    case $COMP_CWORD in
        2)
            # backup 경로: 디렉토리만
            COMPREPLY=($(compgen -d -- "$cur"))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# restore 명령어 자동완성
_tarsync_complete_restore_command() {
    case $COMP_CWORD in
        2)
            # backup 이름들
            local backup_names=$(_tarsync_get_cached_backup_list)
            if [[ -n "$backup_names" ]]; then
                COMPREPLY=($(compgen -W "$backup_names" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
        3)
            # 복구 대상 경로: 디렉토리만
            COMPREPLY=($(compgen -d -- "$cur"))
            ;;
        4)
            # 시뮬레이션 모드
            local sim_options=$(_tarsync_get_simulation_options)
            COMPREPLY=($(compgen -W "$sim_options" -- "$cur"))
            ;;
        5)
            # 삭제 모드
            local del_options=$(_tarsync_get_delete_mode_options)
            COMPREPLY=($(compgen -W "$del_options" -- "$cur"))
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# list 명령어 자동완성
_tarsync_complete_list_command() {
    case $COMP_CWORD in
        2)
            # 페이지 크기
            local page_options=$(_tarsync_get_page_size_options)
            COMPREPLY=($(compgen -W "$page_options" -- "$cur"))
            ;;
        3)
            # 페이지 번호 (동적으로 생성하기 어려우므로 일반적인 값들)
            COMPREPLY=($(compgen -W "1 2 3 4 5 -1 -2" -- "$cur"))
            ;;
        4)
            # 선택 인덱스 (1부터 페이지 크기까지)
            local page_size="${COMP_WORDS[2]:-10}"
            if [[ "$page_size" =~ ^[0-9]+$ ]]; then
                local select_options=$(seq 1 "$page_size" | tr '\n' ' ')
                COMPREPLY=($(compgen -W "$select_options" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# delete 명령어 자동완성
_tarsync_complete_delete_command() {
    case $COMP_CWORD in
        2)
            # backup 이름들
            local backup_names=$(_tarsync_get_cached_backup_list)
            if [[ -n "$backup_names" ]]; then
                COMPREPLY=($(compgen -W "$backup_names" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# details 명령어 자동완성
_tarsync_complete_details_command() {
    case $COMP_CWORD in
        2)
            # backup 이름들
            local backup_names=$(_tarsync_get_cached_backup_list)
            if [[ -n "$backup_names" ]]; then
                COMPREPLY=($(compgen -W "$backup_names" -- "$cur"))
            else
                COMPREPLY=()
            fi
            ;;
        *)
            COMPREPLY=()
            ;;
    esac
}

# 자동완성 등록
complete -F _tarsync_completion tarsync

# 환경변수로 도움말 표시 제어
# export TARSYNC_SHOW_HELP=true 를 설정하면 명령어 설명이 표시됨 