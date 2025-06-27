#compdef tarsync

# tarsync ZSH 자동완성 스크립트
# Advanced ZSH completion for tarsync command

# 공통 스크립트 로드
SCRIPT_DIR="${0:A:h}"

# 설치된 위치와 현재 위치 모두 시도
if [[ -f "$SCRIPT_DIR/completion-common.sh" ]]; then
    source "$SCRIPT_DIR/completion-common.sh"
elif [[ -f "/usr/local/lib/tarsync/src/completion/completion-common.sh" ]]; then
    source "/usr/local/lib/tarsync/src/completion/completion-common.sh"
elif [[ -f "${HOME}/.local/share/zsh/site-functions/completion-common.sh" ]]; then
    source "${HOME}/.local/share/zsh/site-functions/completion-common.sh"
else
    echo "Warning: Could not find tarsync completion-common.sh" >&2
    return 1
fi

# ZSH 자동완성 메인 함수
_tarsync() {
    local context state line
    local -a commands backup_names
    
    _tarsync_debug "ZSH completion: words=$words, CURRENT=$CURRENT"
    
    # 백업 목록을 설명과 함께 가져오기
    local backup_list_with_desc=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && backup_list_with_desc+=("$line")
    done < <(_tarsync_get_backup_list_with_desc)
    
    # 서브 명령어별 자동완성
    if (( CURRENT == 3 )); then
        case ${words[2]} in
            backup|b)
                _tarsync_complete_backup_zsh
                return 0
                ;;
            restore|r)
                _tarsync_complete_restore_zsh
                return 0
                ;;
            list|ls|l)
                _tarsync_complete_list_zsh
                return 0
                ;;
            delete|rm|d)
                _tarsync_complete_delete_zsh
                return 0
                ;;
            details|show|info|i)
                _tarsync_complete_details_zsh
                return 0
                ;;
            version|v|help|h)
                # 이 명령어들은 추가 인수가 없음
                return 0
                ;;
        esac
    fi
    
    # restore 명령어의 추가 인수들
    if [[ ${words[2]} == "restore" || ${words[2]} == "r" ]]; then
        case $CURRENT in
            4)
                _directories
                return 0
                ;;
            5)
                _tarsync_complete_simulation_options_zsh
                return 0
                ;;
            6)
                _tarsync_complete_delete_mode_options_zsh
                return 0
                ;;
        esac
    fi
    
    # list 명령어의 추가 인수들
    if [[ ${words[2]} == "list" || ${words[2]} == "ls" || ${words[2]} == "l" ]]; then
        case $CURRENT in
            4)
                _tarsync_complete_page_numbers_zsh
                return 0
                ;;
            5)
                _tarsync_complete_select_options_zsh
                return 0
                ;;
        esac
    fi
    
    # 첫 번째 인자: 메인 명령어들 (설명과 함께)
    if (( CURRENT > 2 )); then
        return 0
    fi
    
    # 명령어와 설명 정의
    commands=(
        "backup:$(_tarsync_get_command_desc backup)"
        "b:backup의 단축 명령어"
        "restore:$(_tarsync_get_command_desc restore)"
        "r:restore의 단축 명령어"
        "list:$(_tarsync_get_command_desc list)"
        "ls:list의 단축 명령어"
        "l:list의 단축 명령어"
        "delete:$(_tarsync_get_command_desc delete)"
        "rm:delete의 단축 명령어"
        "d:delete의 단축 명령어"
        "details:$(_tarsync_get_command_desc details)"
        "show:details의 단축 명령어"
        "info:details의 단축 명령어"
        "i:details의 단축 명령어"
        "version:$(_tarsync_get_command_desc version)"
        "v:version의 단축 명령어"
        "help:$(_tarsync_get_command_desc help)"
        "h:help의 단축 명령어"
    )
    
    _describe 'tarsync 명령어' commands
}

# backup 명령어 ZSH 자동완성
_tarsync_complete_backup_zsh() {
    _directories && return 0
    _message "백업할 디렉토리 경로를 입력하세요"
}

# restore 명령어 ZSH 자동완성
_tarsync_complete_restore_zsh() {
    local backup_list_with_desc=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && backup_list_with_desc+=("$line")
    done < <(_tarsync_get_backup_list_with_desc)
    
    if [[ ${#backup_list_with_desc[@]} -gt 0 ]]; then
        _describe '사용 가능한 백업' backup_list_with_desc
    else
        _message "사용 가능한 백업이 없습니다"
    fi
}

# list 명령어 ZSH 자동완성  
_tarsync_complete_list_zsh() {
    local -a page_sizes
    local page_options=$(_tarsync_get_page_size_options)
    
    for size in ${=page_options}; do
        page_sizes+=("$size:${size}개씩 표시")
    done
    
    _describe '페이지 크기' page_sizes
}

# delete 명령어 ZSH 자동완성
_tarsync_complete_delete_zsh() {
    local backup_list_with_desc=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && backup_list_with_desc+=("$line")
    done < <(_tarsync_get_backup_list_with_desc)
    
    if [[ ${#backup_list_with_desc[@]} -gt 0 ]]; then
        _describe '삭제할 백업' backup_list_with_desc
    else
        _message "삭제할 수 있는 백업이 없습니다"
    fi
}

# details 명령어 ZSH 자동완성
_tarsync_complete_details_zsh() {
    local backup_list_with_desc=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && backup_list_with_desc+=("$line")
    done < <(_tarsync_get_backup_list_with_desc)
    
    if [[ ${#backup_list_with_desc[@]} -gt 0 ]]; then
        _describe '정보를 볼 백업' backup_list_with_desc
    else
        _message "조회할 수 있는 백업이 없습니다"
    fi
}

# 시뮬레이션 옵션 ZSH 자동완성
_tarsync_complete_simulation_options_zsh() {
    local -a sim_options
    sim_options=(
        "true:시뮬레이션 모드 (실제 복구하지 않음)"
        "false:실제 복구 모드"
    )
    _describe '시뮬레이션 모드' sim_options
}

# 삭제 모드 옵션 ZSH 자동완성
_tarsync_complete_delete_mode_options_zsh() {
    local -a del_options
    del_options=(
        "true:삭제 모드 (대상에 없는 파일 삭제)"
        "false:보존 모드 (기존 파일 유지)"
    )
    _describe '삭제 모드' del_options
}

# 페이지 번호 ZSH 자동완성
_tarsync_complete_page_numbers_zsh() {
    local -a page_options
    page_options=(
        "1:첫 번째 페이지"
        "2:두 번째 페이지"
        "3:세 번째 페이지"
        "-1:마지막 페이지"
        "-2:마지막에서 두 번째 페이지"
    )
    _describe '페이지 번호' page_options
}

# 선택 옵션 ZSH 자동완성
_tarsync_complete_select_options_zsh() {
    local page_size="${words[3]:-10}"
    local -a select_options
    
    if [[ "$page_size" =~ ^[0-9]+$ ]]; then
        for ((i=1; i<=page_size; i++)); do
            select_options+=("$i:${i}번째 백업 선택")
        done
        _describe '선택할 백업 번호' select_options
    else
        _message "유효한 페이지 크기를 먼저 입력하세요"
    fi
}

# 자동완성 시스템 초기화 확인
(( $+functions[compdef] )) || autoload -Uz compinit && compinit

# 자동완성 함수 등록
compdef _tarsync tarsync 