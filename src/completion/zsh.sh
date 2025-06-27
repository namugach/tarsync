#!/bin/zsh

# ===== Tarsync ZSH 자동완성 =====
# ===== Tarsync ZSH Completion =====

# ZSH 자동완성 함수
# ZSH completion function
_tarsync() {
    local context state line
    typeset -A opt_args
    
    # 첫 번째 인자: 주 명령어
    # First argument: main commands
    _arguments \
        '1:commands:(backup restore list help version)' \
        '*::arguments:->args'
    
    case $state in
        args)
            case $words[1] in
                backup)
                    # backup 명령어: 디렉토리 자동완성
                    # backup command: directory completion
                    _arguments \
                        '(-v --verbose)'{-v,--verbose}'[상세 출력]' \
                        '(-q --quiet)'{-q,--quiet}'[조용한 모드]' \
                        '(-f --force)'{-f,--force}'[강제 실행]' \
                        '*:directory:_directories'
                    ;;
                restore)
                    # restore 명령어: 백업 파일 자동완성
                    # restore command: backup file completion
                    local backup_dir="/mnt/backup"
                    if [ -f "$HOME/.tarsync/config/settings.env" ]; then
                        local custom_dir=$(grep "^BACKUP_DIR=" "$HOME/.tarsync/config/settings.env" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
                        [ -n "$custom_dir" ] && backup_dir="$custom_dir"
                    fi
                    
                    local backup_files=()
                    if [ -d "$backup_dir" ]; then
                        backup_files=($(find "$backup_dir" -name "*.tar.gz" -type f -printf "%f\n" 2>/dev/null))
                    fi
                    
                    _arguments \
                        '(-s --simulate)'{-s,--simulate}'[시뮬레이션 모드]' \
                        '(-v --verbose)'{-v,--verbose}'[상세 출력]' \
                        '(-q --quiet)'{-q,--quiet}'[조용한 모드]' \
                        '(-f --force)'{-f,--force}'[강제 실행]' \
                        "*:backup files:(${backup_files[*]})"
                    ;;
                list)
                    # list 명령어: 옵션 자동완성
                    # list command: option completion
                    _arguments \
                        '(-p --page)'{-p,--page}'[페이지 번호]:page number:(1 2 3 4 5)' \
                        '--select[백업 선택]:backup id:(1 2 3 4 5 6 7 8 9 10)' \
                        '(-v --verbose)'{-v,--verbose}'[상세 출력]'
                    ;;
                help|version)
                    # help, version: 추가 인자 없음
                    # help, version: no additional arguments
                    ;;
            esac
            ;;
    esac
}

# ZSH 자동완성 등록
# Register ZSH completion
compdef _tarsync tarsync 