#!/bin/bash

# ===== Tarsync Bash 자동완성 =====
# ===== Tarsync Bash Completion =====

# Bash 자동완성 함수
# Bash completion function
_tarsync_completion() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # 사용 가능한 명령어 목록
    # List of available commands
    local commands="backup restore list help version"
    
    # 첫 번째 인자: 주 명령어 자동완성
    # First argument: main command completion
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=($(compgen -W "${commands}" -- ${cur}))
        return 0
    
    # 두 번째 인자: 명령어별 자동완성
    # Second argument: command-specific completion
    elif [ "$COMP_CWORD" -eq 2 ]; then
        case "$prev" in
            "backup")
                # 디렉토리 자동완성
                # Directory completion
                COMPREPLY=($(compgen -d -- ${cur}))
                return 0
                ;;
            "restore")
                # 백업 파일 자동완성
                # Backup file completion
                local backup_dir="/mnt/backup"
                if [ -f "$HOME/.tarsync/config/settings.env" ]; then
                    local custom_dir=$(grep "^BACKUP_DIR=" "$HOME/.tarsync/config/settings.env" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
                    [ -n "$custom_dir" ] && backup_dir="$custom_dir"
                fi
                
                if [ -d "$backup_dir" ]; then
                    local backup_files=$(find "$backup_dir" -name "*.tar.gz" -type f -printf "%f\n" 2>/dev/null)
                    COMPREPLY=($(compgen -W "${backup_files}" -- ${cur}))
                fi
                return 0
                ;;
            "list")
                # list 명령어 옵션
                # list command options
                COMPREPLY=($(compgen -W "--page --select --verbose" -- ${cur}))
                return 0
                ;;
        esac
    
    # 세 번째 인자: 옵션별 자동완성
    # Third argument: option-specific completion
    elif [ "$COMP_CWORD" -eq 3 ]; then
        local cmd="${COMP_WORDS[1]}"
        case "$cmd" in
            "backup")
                case "$prev" in
                    "--verbose"|"-v"|"--quiet"|"-q"|"--force"|"-f")
                        # 옵션 뒤에는 디렉토리
                        COMPREPLY=($(compgen -d -- ${cur}))
                        return 0
                        ;;
                esac
                ;;
            "restore")
                case "$prev" in
                    "--simulate"|"-s"|"--verbose"|"-v"|"--quiet"|"-q"|"--force"|"-f")
                        # 옵션 뒤에는 백업 파일
                        local backup_dir="/mnt/backup"
                        if [ -f "$HOME/.tarsync/config/settings.env" ]; then
                            local custom_dir=$(grep "^BACKUP_DIR=" "$HOME/.tarsync/config/settings.env" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
                            [ -n "$custom_dir" ] && backup_dir="$custom_dir"
                        fi
                        
                        if [ -d "$backup_dir" ]; then
                            local backup_files=$(find "$backup_dir" -name "*.tar.gz" -type f -printf "%f\n" 2>/dev/null)
                            COMPREPLY=($(compgen -W "${backup_files}" -- ${cur}))
                        fi
                        return 0
                        ;;
                esac
                ;;
            "list")
                case "$prev" in
                    "--page"|"-p")
                        # 페이지 번호
                        COMPREPLY=($(compgen -W "1 2 3 4 5" -- ${cur}))
                        return 0
                        ;;
                    "--select")
                        # 백업 ID (간단하게 1-10)
                        COMPREPLY=($(compgen -W "1 2 3 4 5 6 7 8 9 10" -- ${cur}))
                        return 0
                        ;;
                esac
                ;;
        esac
    fi
    
    # 기본적으로 옵션 제공
    # Provide options by default
    case "${COMP_WORDS[1]}" in
        "backup")
            COMPREPLY=($(compgen -W "--verbose -v --quiet -q --force -f" -- ${cur}))
            ;;
        "restore")
            COMPREPLY=($(compgen -W "--simulate -s --verbose -v --quiet -q --force -f" -- ${cur}))
            ;;
        "list")
            COMPREPLY=($(compgen -W "--page -p --select --verbose -v" -- ${cur}))
            ;;
    esac
}

# 자동완성 등록
# Register completion
complete -F _tarsync_completion tarsync 