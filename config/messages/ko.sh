#!/bin/bash

# 한국어 메시지 파일 - Tarsync
# Korean messages for Tarsync

# 언어 메타데이터
LANG_CODE="ko"
LANG_NAME="한국어"
LANG_LOCALE="ko_KR.UTF-8"
LANG_TIMEZONE="Asia/Seoul"
LANG_DIRECTION="ltr"
LANG_VERSION="1.0"

# ======================
# CLI 인터페이스 메시지
# ======================

# 도움말 시스템
MSG_HELP_USAGE="사용법: tarsync <명령어> [인수]"
MSG_HELP_DESCRIPTION="Shell Script로 재작성된 안정적인 백업 및 복구 도구"
MSG_HELP_COMMANDS="주요 명령어:"
MSG_HELP_BACKUP="backup [경로]           # 특정 경로 또는 전체 시스템을 백업합니다. (기본값: /)"
MSG_HELP_RESTORE="restore [백업명] [대상]   # 선택한 백업을 지정한 경로로 복구합니다."
MSG_HELP_LIST="list                    # 생성된 백업 목록을 최신순으로 표시합니다."
MSG_HELP_LOG="log <번호|백업명>         # 백업의 메모와 로그를 표시합니다."
MSG_HELP_DELETE="delete <백업명>          # 지정한 백업을 영구적으로 삭제합니다."
MSG_HELP_DETAILS="details <백업명>         # 백업의 상세 정보를 표시합니다."
MSG_HELP_OTHER_COMMANDS="기타 명령어:"
MSG_HELP_VERSION="version                 # 프로그램 버전 정보를 표시합니다."
MSG_HELP_HELP="help                    # 이 도움말을 표시합니다."
MSG_HELP_EXAMPLES="사용 예시:"
MSG_HELP_EXAMPLE_BACKUP="sudo %s backup /home/user    # /home/user 디렉토리 백업"
MSG_HELP_EXAMPLE_RESTORE="sudo %s restore              # 대화형 모드로 복구 시작"
MSG_HELP_EXAMPLE_RESTORE_TARGET="sudo %s restore 1 /tmp/res   # 1번 백업을 /tmp/res에 복구"
MSG_HELP_EXAMPLE_LIST="%s list                      # 백업 목록 보기"
MSG_HELP_EXAMPLE_LOG="%s log 7                     # 7번 백업의 메모와 로그 보기"
MSG_HELP_EXAMPLE_DELETE="sudo %s delete backup_name   # 특정 백업 삭제"

# 에러 메시지
MSG_ERROR_SUDO_REQUIRED="❌ 시스템 백업/복구를 위해서는 sudo 권한이 필요합니다"
MSG_ERROR_SUDO_HINT="💡 다음과 같이 실행해주세요: %ssudo %s %s%s"
MSG_ERROR_SUDO_REASON="📖 권한이 필요한 이유:"
MSG_ERROR_SUDO_REASON_FILES="  • 시스템 파일 읽기 권한 (/etc, /var, /root 등)"
MSG_ERROR_SUDO_REASON_BACKUP="  • 백업 파일 생성 권한"
MSG_ERROR_SUDO_REASON_RESTORE="  • 복구 시 원본 권한 복원"
MSG_ERROR_INVALID_COMMAND="잘못된 명령어: %s"
MSG_ERROR_MISSING_ARGUMENT="필수 인수가 누락되었습니다: %s"
MSG_ERROR_INVALID_PATH="잘못된 경로: %s"
MSG_ERROR_PERMISSION_DENIED="권한이 거부되었습니다: %s"

# 버전 메시지
MSG_VERSION_HEADER="%s v%s"
MSG_VERSION_DESCRIPTION="Shell Script 기반 백업 도구"
MSG_VERSION_FEATURES="📦 기능:"
MSG_VERSION_FEATURE_BACKUP="  • tar+gzip 압축 백업"
MSG_VERSION_FEATURE_RESTORE="  • rsync 기반 복구"
MSG_VERSION_FEATURE_LIST="  • 페이지네이션 목록 관리"
MSG_VERSION_FEATURE_INTEGRITY="  • 백업 무결성 검사"
MSG_VERSION_FEATURE_LOG="  • 로그 관리"
MSG_VERSION_DEPENDENCIES="🛠️  의존성:"
MSG_VERSION_DEPS_LIST="  • tar, gzip, rsync, pv, bc, jq"
MSG_VERSION_COPYRIGHT="Copyright (c) %s"

# ======================
# 백업 모듈 메시지
# ======================

# 백업 상태
MSG_BACKUP_START="백업 프로세스를 시작합니다..."
MSG_BACKUP_PROGRESS="진행률: %s%% - %s"
MSG_BACKUP_COMPLETE="✅ 백업이 성공적으로 완료되었습니다"
MSG_BACKUP_FAILED="❌ 백업에 실패했습니다: %s"
MSG_BACKUP_CREATING_ARCHIVE="압축 아카이브를 생성하고 있습니다..."
MSG_BACKUP_CALCULATING_SIZE="백업 크기를 계산하고 있습니다..."
MSG_BACKUP_PREPARING="백업을 준비하고 있습니다..."
MSG_BACKUP_FINALIZING="백업을 마무리하고 있습니다..."

# 사용자 메모 편집
MSG_NOTES_EDIT="📝 사용자 메모를 편집합니다..."
MSG_NOTES_EDIT_INFO="   (빈 파일에 원하는 메모를 작성하세요)"
MSG_NOTES_EDITOR_VIM="   (저장하고 종료: :wq, 편집 없이 종료: :q)"
MSG_NOTES_EDITOR_NANO="   (저장하고 종료: Ctrl+X)"
MSG_NOTES_NO_EDITOR="⚠️  텍스트 에디터를 찾을 수 없습니다. 기본 로그만 생성됩니다."
MSG_NOTES_SAVED="📝 사용자 메모가 저장되었습니다."

# 백업 생성
MSG_BACKUP_CREATING_DIR="백업 디렉토리를 생성합니다: %s"
MSG_BACKUP_CREATING_META="백업 메타데이터를 생성하고 있습니다..."
MSG_BACKUP_CREATING_LOG="백업 로그를 생성하고 있습니다..."
MSG_BACKUP_DISK_SPACE_CHECK="사용 가능한 디스크 공간을 확인하고 있습니다..."
MSG_BACKUP_EXCLUDE_PATHS="백업에서 %d개 경로를 제외합니다"

# ======================
# 복구 모듈 메시지
# ======================

# 복구 선택
MSG_RESTORE_SELECT="복구할 백업을 선택하세요:"
MSG_RESTORE_CONFIRM="%s을(를) %s로 복구하시겠습니까? (y/N)"
MSG_RESTORE_COMPLETE="✅ 복구가 성공적으로 완료되었습니다"
MSG_RESTORE_FAILED="❌ 복구에 실패했습니다: %s"
MSG_RESTORE_CANCELLED="복구가 취소되었습니다"

# 복구 모드
MSG_RESTORE_MODE_SELECT="복구 모드를 선택하세요:"
MSG_RESTORE_MODE_SAFE="안전 모드 (기존 파일 보존)"
MSG_RESTORE_MODE_FULL="완전 모드 (기존 파일 덮어쓰기)"
MSG_RESTORE_PREPARING="복구 작업을 준비하고 있습니다..."
MSG_RESTORE_EXTRACTING="백업 아카이브를 추출하고 있습니다..."
MSG_RESTORE_COPYING="파일을 목적지로 복사하고 있습니다..."
MSG_RESTORE_SETTING_PERMISSIONS="파일 권한을 설정하고 있습니다..."

# ======================
# 목록 관리 메시지
# ======================

# 백업 목록
MSG_LIST_HEADER="사용 가능한 백업 목록 (총 %d개 중 %d개 표시):"
MSG_LIST_NO_BACKUPS="백업을 찾을 수 없습니다"
MSG_LIST_PAGE_INFO="페이지 %d / %d (다음 페이지: Enter, 종료: 'q')"
MSG_LIST_LOADING="백업 목록을 로딩하고 있습니다..."
MSG_LIST_COLUMN_NO="번호"
MSG_LIST_COLUMN_NAME="이름"
MSG_LIST_COLUMN_SIZE="크기"
MSG_LIST_COLUMN_DATE="날짜"
MSG_LIST_COLUMN_SOURCE="소스"

# 백업 상세정보
MSG_DETAILS_SIZE="크기: %s"
MSG_DETAILS_DATE="생성일: %s"
MSG_DETAILS_SOURCE="소스: %s"
MSG_DETAILS_DESTINATION="대상: %s"
MSG_DETAILS_DURATION="소요시간: %s"
MSG_DETAILS_STATUS="상태: %s"
MSG_DETAILS_EXCLUDE_COUNT="제외된 경로: %d개"
MSG_DETAILS_NOTES="메모: %s"

# 로그 표시
MSG_LOG_HEADER="=== 백업 로그: %s ==="
MSG_LOG_NOTES_HEADER="📝 사용자 메모:"
MSG_LOG_DETAILS_HEADER="📊 백업 상세정보:"
MSG_LOG_NO_NOTES="사용자 메모가 없습니다"
MSG_LOG_NO_LOG_FILE="로그 파일을 찾을 수 없습니다"

# ======================
# 시스템 메시지
# ======================

# 권한 관리
MSG_SYSTEM_SUDO_REQUIRED="관리자 권한이 필요합니다"
MSG_SYSTEM_PERMISSION_DENIED="권한이 거부되었습니다: %s"
MSG_SYSTEM_CHECKING_PERMISSIONS="권한을 확인하고 있습니다..."

# 파일 시스템
MSG_SYSTEM_CREATING_DIR="디렉토리를 생성합니다: %s"
MSG_SYSTEM_FILE_NOT_FOUND="파일을 찾을 수 없습니다: %s"
MSG_SYSTEM_DISK_SPACE="사용 가능한 공간: %s"
MSG_SYSTEM_DIRECTORY_EXISTS="디렉토리가 이미 존재합니다: %s"
MSG_SYSTEM_COPYING_FILE="파일을 복사하고 있습니다: %s"
MSG_SYSTEM_REMOVING_FILE="파일을 제거하고 있습니다: %s"

# 프로세스 관리
MSG_SYSTEM_STARTING_PROCESS="프로세스를 시작합니다: %s"
MSG_SYSTEM_PROCESS_COMPLETE="프로세스가 완료되었습니다: %s"
MSG_SYSTEM_PROCESS_FAILED="프로세스가 실패했습니다: %s"

# ======================
# 설치 메시지
# ======================

# 설치 프로세스
MSG_INSTALL_START="tarsync 설치를 시작합니다..."
MSG_INSTALL_COMPLETE="✅ 설치가 성공적으로 완료되었습니다"
MSG_INSTALL_FAILED="❌ 설치에 실패했습니다: %s"
MSG_INSTALL_ALREADY_INSTALLED="Tarsync가 이미 설치되어 있습니다"

# 의존성 체크
MSG_INSTALL_CHECKING_DEPS="필수 의존성을 확인하고 있습니다..."
MSG_INSTALL_DEPS_OK="✅ 모든 의존성이 충족되었습니다"
MSG_INSTALL_DEPS_MISSING="⚠️  다음 필수 도구들이 설치되지 않았습니다: %s"
MSG_INSTALL_DEPS_INSTALL_CMD="설치 명령어: %s"

# 자동 설치
MSG_INSTALL_AUTO_DEPS="의존성을 자동으로 설치하고 있습니다..."
MSG_INSTALL_AUTO_SUCCESS="✅ 의존성이 성공적으로 설치되었습니다"
MSG_INSTALL_AUTO_FAILED="❌ 자동 설치에 실패했습니다"
MSG_INSTALL_MANUAL_GUIDE="📋 수동 설치 안내:"

# 파일 작업
MSG_INSTALL_COPYING_FILES="프로그램 파일을 복사하고 있습니다..."
MSG_INSTALL_SETTING_PERMISSIONS="파일 권한을 설정하고 있습니다..."
MSG_INSTALL_CREATING_SYMLINK="심볼릭 링크를 생성하고 있습니다..."
MSG_INSTALL_CONFIGURING_SYSTEM="시스템 설정을 구성하고 있습니다..."

# 언어 설정
MSG_INSTALL_LANGUAGE_SETUP="언어 설정을 구성하고 있습니다..."
MSG_INSTALL_LANGUAGE_DETECTION="시스템 언어를 감지했습니다: %s"
MSG_INSTALL_LANGUAGE_CONFIG="언어를 설정하고 있습니다: %s"
MSG_INSTALL_LANGUAGE_FILES_COPIED="언어 파일이 성공적으로 복사되었습니다"
MSG_INSTALL_FINDING_LANGUAGES="사용 가능한 언어를 찾는 중..."
MSG_INSTALL_SELECT_LANGUAGE="📍 설치 언어를 선택하세요"
MSG_INSTALL_CANCEL="설치 취소"
MSG_INSTALL_LANGUAGE_SELECTED="✓ 선택된 언어: %s (%s)"
MSG_INSTALL_LANGUAGE_INVALID="⚠️  잘못된 입력입니다. 기본 언어로 설정됩니다: %s (%s)"
MSG_INSTALL_LANGUAGE_CONFIGURED="📝 언어 설정이 완료되었습니다"

# 설치 단계
MSG_INSTALL_INITIALIZING="설치 초기화 중..."
MSG_INSTALL_CHECKING_EXISTING="기존 설치 확인 중..."
MSG_INSTALL_ALL_DEPS_OK="모든 의존성이 충족되었습니다"
MSG_INSTALL_CONFIRM_PROCEED="설치를 계속하시겠습니까? (Y/n)"
MSG_INSTALL_CANCELLED="설치가 취소되었습니다"
MSG_INSTALL_STARTING="tarsync 설치를 시작합니다..."
MSG_INSTALL_FILES="파일 설치 중..."

# 백업 디렉토리 설정
MSG_INSTALL_BACKUP_SETUP="📁 백업 저장 위치를 설정합니다"
MSG_INSTALL_BACKUP_PROMPT="백업 파일들이 저장될 디렉토리를 입력하세요:"
MSG_INSTALL_BACKUP_DEFAULT="• 기본값: %s"
MSG_INSTALL_BACKUP_EXAMPLES="• 예시: ~/backup/tarsync, /data/backup/tarsync, /var/backup/tarsync"
MSG_INSTALL_BACKUP_INPUT="백업 디렉토리 [%s]: "
MSG_INSTALL_BACKUP_SELECTED="선택된 백업 디렉토리: %s"
MSG_INSTALL_BACKUP_CREATED="✅ 백업 디렉토리가 생성되었습니다: %s"
MSG_INSTALL_BACKUP_PERMISSIONS_OK="✅ 백업 디렉토리 권한이 확인되었습니다"
MSG_INSTALL_BACKUP_SETUP_COMPLETE="📦 백업 디렉토리 설정이 완료되었습니다"

# 파일 작업  
MSG_INSTALL_FILES_COPIED="프로젝트 파일이 복사되었습니다"
MSG_INSTALL_BACKUP_LOCATION="백업 저장 위치: %s"
MSG_INSTALL_SCRIPT_INSTALLED="tarsync 스크립트가 설치되었습니다: %s"
MSG_INSTALL_VERSION_INSTALLED="VERSION 파일이 설치되었습니다: %s"

# 자동완성 시스템
MSG_INSTALL_COMPLETION_INSTALLING="자동완성 기능 설치 중..."
MSG_INSTALL_COMPLETION_INSTALLED="자동완성 파일이 설치되었습니다"
MSG_INSTALL_COMPLETION_BASH_SETUP="bash-completion 시스템 설정 중..."
MSG_INSTALL_COMPLETION_BASH_INSTALLED="bash-completion 패키지가 이미 설치되어 있습니다"
MSG_INSTALL_COMPLETION_BASH_ACTIVE="bash completion이 이미 활성화되어 있습니다"
MSG_INSTALL_COMPLETION_BASH_COMPLETE="bash-completion 시스템 설정이 완료되었습니다"
MSG_INSTALL_COMPLETION_BASH_GLOBAL="Bash 자동완성이 시스템 전역에 설치되었습니다"
MSG_INSTALL_COMPLETION_ZSH_GLOBAL="ZSH 자동완성이 시스템 전역에 설치되었습니다"

# PATH 설정
MSG_INSTALL_PATH_UPDATING="PATH 업데이트 중..."
MSG_INSTALL_PATH_NOT_NEEDED="실행파일이 /usr/local/bin에 설치되어 PATH 업데이트가 필요하지 않습니다"

# 설치 확인
MSG_INSTALL_VERIFYING="설치 확인 중..."
MSG_INSTALL_SUCCESS_TITLE="🎉 tarsync v%s 설치 완료!"
MSG_INSTALL_LOCATIONS="📍 설치 위치:"
MSG_INSTALL_EXECUTABLE="• 실행파일: %s"
MSG_INSTALL_VERSION_FILE="• 버전파일: %s"
MSG_INSTALL_LIBRARY="• 라이브러리: %s"
MSG_INSTALL_BASH_COMPLETION="• Bash 자동완성: %s"
MSG_INSTALL_ZSH_COMPLETION="• ZSH 자동완성: %s"

# 자동완성 설정
MSG_INSTALL_COMPLETION_IMMEDIATE="🚀 자동완성을 바로 사용하려면:"
MSG_INSTALL_CONTAINER_DETECTED="📦 컨테이너 환경이 감지되었습니다"
MSG_INSTALL_BASH_DETECTED="🐚 Bash 환경이 감지되었습니다"
MSG_INSTALL_ZSH_DETECTED="🐚 ZSH 환경이 감지되었습니다"
MSG_INSTALL_COMPLETION_OPTIONS="다음 중 하나를 실행하세요:"
MSG_INSTALL_COMPLETION_RELOAD_BASHRC="1) source ~/.bashrc              # 설정 파일 다시 로드"
MSG_INSTALL_COMPLETION_LOAD_DIRECT="2) source /etc/bash_completion   # completion 직접 로드"
MSG_INSTALL_COMPLETION_NEW_SESSION="3) exec bash                     # 새 쉘 세션 시작 (권장)"
MSG_INSTALL_COMPLETION_RELOAD_ZSHRC="1) source ~/.zshrc               # 설정 파일 다시 로드"
MSG_INSTALL_COMPLETION_REINIT_ZSH="2) autoload -U compinit && compinit  # completion 재초기화"
MSG_INSTALL_COMPLETION_NEW_ZSH="3) exec zsh                      # 새 쉘 세션 시작 (권장)"
MSG_INSTALL_COMPLETION_COPY_TIP="💡 명령어를 복사해서 터미널에 붙여넣으세요"

# 사용 예시
MSG_INSTALL_USAGE_EXAMPLES="📖 tarsync 명령어 사용법:"
MSG_INSTALL_USAGE_HELP="      tarsync help                    # 도움말"
MSG_INSTALL_USAGE_VERSION="      tarsync version                 # 버전 확인"  
MSG_INSTALL_USAGE_BACKUP="      tarsync backup /home/user       # 백업"
MSG_INSTALL_USAGE_LIST="      tarsync list                    # 목록"
MSG_INSTALL_COMPLETION_TIP="💡 탭 키를 눌러서 자동완성 기능을 사용해보세요!"

# 추가 설치 메시지 (하드코딩된 메시지에서 추가)
MSG_INSTALL_MANUAL_GUIDE_HEADER="📋 수동 설치 안내:"
MSG_INSTALL_DEPS_INSTALLING="의존성을 자동으로 설치합니다..."
MSG_INSTALL_DEPS_COMMAND="   실행 명령어: %s"
MSG_INSTALL_DEPS_SUCCESS="✅ 의존성 설치가 완료되었습니다!"
MSG_INSTALL_DEPS_FAILED="❌ 자동 설치에 실패했습니다"
MSG_INSTALL_DEPS_MISSING_TOOLS="⚠️  다음 필수 도구들이 설치되지 않았습니다: %s"
MSG_INSTALL_LINUX_DETECTED="🚀 Linux 시스템이 감지되었습니다 (%s)"
MSG_INSTALL_MACOS_DETECTED="🍎 macOS 시스템이 감지되었습니다"
MSG_INSTALL_HOMEBREW_MISSING="Homebrew가 설치되지 않았습니다"
MSG_INSTALL_HOMEBREW_INSTALL="Homebrew 설치: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
MSG_INSTALL_CONFIRM_AUTO_INSTALL="자동으로 설치하시겠습니까? (Y/n): "
MSG_INSTALL_SOME_TOOLS_MISSING="일부 도구가 여전히 설치되지 않았습니다: %s"
MSG_INSTALL_UNSUPPORTED_SYSTEM="자동 설치를 지원하지 않는 시스템입니다: %s"
MSG_INSTALL_BASH_REQUIRED="Bash 쉘이 필요합니다"
MSG_INSTALL_SUDO_REQUIRED="전역 설치를 위해서는 sudo 권한이 필요합니다"
MSG_INSTALL_SUDO_HINT="다음과 같이 실행해주세요: sudo ./bin/install.sh"
MSG_INSTALL_WRITE_PERMISSION_ERROR="시스템 디렉토리에 쓰기 권한이 없습니다"

# 백업 디렉토리 설정 메시지
MSG_INSTALL_BACKUP_DIR_NOT_EXIST="백업 디렉토리가 존재하지 않습니다. 생성을 시도합니다..."
MSG_INSTALL_BACKUP_DIR_CREATED="✅ 백업 디렉토리가 생성되었습니다: %s"
MSG_INSTALL_BACKUP_DIR_CREATE_FAILED="⚠️ 디렉토리 생성에 실패했습니다. sudo 권한이 필요할 수 있습니다."
MSG_INSTALL_BACKUP_DIR_COMMAND_TIP="다음 명령어를 실행해보세요:"
MSG_INSTALL_BACKUP_DIR_RETRY_PROMPT="위 명령어를 실행하고 다시 설치하시겠습니까? (y/N): "
MSG_INSTALL_BACKUP_DIR_SUDO_SUCCESS="✅ sudo를 사용하여 백업 디렉토리가 생성되었습니다"
MSG_INSTALL_BACKUP_DIR_SUDO_FAILED="❌ 백업 디렉토리 생성에 실패했습니다"
MSG_INSTALL_BACKUP_DIR_CANNOT_CREATE="❌ 백업 디렉토리를 생성할 수 없어 설치를 중단합니다"
MSG_INSTALL_BACKUP_DIR_NO_WRITE="⚠️ 백업 디렉토리에 쓰기 권한이 없습니다: %s"
MSG_INSTALL_BACKUP_DIR_FIX_PERMISSION="권한 수정을 시도하시겠습니까?"
MSG_INSTALL_BACKUP_DIR_FIX_COMMAND="   실행할 명령어: sudo chown \$USER:\$USER '%s'"
MSG_INSTALL_BACKUP_DIR_FIX_PROMPT="권한을 수정하시겠습니까? (y/N): "
MSG_INSTALL_BACKUP_DIR_PERMISSION_FIXED="✅ 권한이 수정되어 백업 디렉토리를 사용할 수 있습니다"
MSG_INSTALL_BACKUP_DIR_FIX_FAILED="❌ 권한 수정에 실패했습니다"
MSG_INSTALL_BACKUP_DIR_USE_OTHER="다른 백업 디렉토리를 사용하시겠습니까? (Y/n): "
MSG_INSTALL_BACKUP_DIR_ENTER_NEW="다른 백업 디렉토리를 입력하세요:"
MSG_INSTALL_BACKUP_DIR_INPUT_PROMPT="   백업 디렉토리: "
MSG_INSTALL_BACKUP_DIR_NEW_PATH="새로운 백업 디렉토리: %s"
MSG_INSTALL_BACKUP_DIR_NEW_SUCCESS="✅ 새 백업 디렉토리가 생성되었습니다: %s"
MSG_INSTALL_BACKUP_DIR_NEW_FAILED="❌ 새 백업 디렉토리 생성에 실패했습니다"
MSG_INSTALL_BACKUP_DIR_NEW_NO_WRITE="❌ 새 백업 디렉토리에도 쓰기 권한이 없습니다: %s"
MSG_INSTALL_BACKUP_DIR_NEW_PERMISSION_OK="✅ 새 백업 디렉토리 권한이 확인되었습니다"
MSG_INSTALL_BACKUP_DIR_INVALID="❌ 유효한 백업 디렉토리가 입력되지 않았습니다"
MSG_INSTALL_BACKUP_DIR_NO_AVAILABLE="❌ 사용 가능한 백업 디렉토리가 없어 설치를 중단합니다"
MSG_INSTALL_BACKUP_DIR_PERMISSION_ERROR="❌ 백업 디렉토리 권한 문제로 설치를 중단합니다"

# 언어 선택
MSG_INSTALL_DEFAULT_MARK=" (기본값)"
MSG_INSTALL_LANGUAGE_INPUT="언어를 선택하세요 (0-%d): "

# 설치 확인
MSG_INSTALL_VERIFY_FAILED="tarsync 설치에 실패했습니다"
MSG_INSTALL_SCRIPT_NOT_FOUND="tarsync 스크립트를 찾을 수 없습니다: %s"
MSG_INSTALL_SUCCESS_HEADER="🎉 tarsync v%s 설치 완료!"
MSG_INSTALL_LOCATIONS_HEADER="📍 설치 위치:"
MSG_INSTALL_LOCATION_EXECUTABLE="   • 실행파일: %s"
MSG_INSTALL_LOCATION_VERSION="   • 버전파일: %s"
MSG_INSTALL_LOCATION_LIBRARY="   • 라이브러리: %s"
MSG_INSTALL_LOCATION_BASH_COMPLETION="   • Bash 자동완성: %s"
MSG_INSTALL_LOCATION_ZSH_COMPLETION="   • ZSH 자동완성: %s"

# 쉘 자동완성 메시지
MSG_INSTALL_BASH_ENV_DETECTED="🐚 Bash 환경이 감지되었습니다"
MSG_INSTALL_ZSH_ENV_DETECTED="🐚 ZSH 환경이 감지되었습니다"
MSG_INSTALL_SHELL_ENV="🐚 쉘 환경: %s"
MSG_INSTALL_COMPLETION_CHOOSE_ONE="다음 중 하나를 실행하세요:"
MSG_INSTALL_COMPLETION_COPY_COMMAND="💡 명령어를 복사해서 터미널에 붙여넣으세요"
MSG_INSTALL_COMPLETION_TITLE="🚀 자동완성을 바로 사용하려면:"
MSG_INSTALL_CONTAINER_ENV_DETECTED="📦 컨테이너 환경이 감지되었습니다"

# bash-completion 시스템
MSG_INSTALL_BASH_COMPLETION_SETUP="bash-completion 시스템 설정 중..."
MSG_INSTALL_BASH_COMPLETION_INSTALLING="bash-completion 패키지를 설치합니다..."
MSG_INSTALL_BASH_COMPLETION_UNSUPPORTED="자동 설치를 지원하지 않는 시스템입니다: %s"
MSG_INSTALL_BASH_COMPLETION_MANUAL="다음 명령어로 수동 설치해주세요:"
MSG_INSTALL_BASH_COMPLETION_SUCCESS="✅ bash-completion 패키지가 설치되었습니다"
MSG_INSTALL_BASH_COMPLETION_FAILED="❌ bash-completion 패키지 설치에 실패했습니다"
MSG_INSTALL_BASH_COMPLETION_INSTALLED="bash-completion 패키지가 이미 설치되어 있습니다"
MSG_INSTALL_BASH_COMPLETION_ACTIVE="bash completion이 이미 활성화되어 있습니다"
MSG_INSTALL_BASH_COMPLETION_ACTIVATING="bash completion을 활성화합니다..."
MSG_INSTALL_BASH_COMPLETION_ACTIVATED="✅ bash completion이 활성화되었습니다"
MSG_INSTALL_BASH_COMPLETION_ACTIVATE_FAILED="❌ bash completion 활성화에 실패했습니다"
MSG_INSTALL_BASH_COMPLETION_BASHRC_NOT_FOUND="/etc/bash.bashrc 파일을 찾을 수 없습니다"
MSG_INSTALL_BASH_COMPLETION_SYSTEM_COMPLETE="bash-completion 시스템 설정이 완료되었습니다"

# 헤더 및 최종 메시지
MSG_INSTALL_HEADER_TITLE="TARSYNC 설치 도구"
MSG_INSTALL_HEADER_SUBTITLE="Shell Script 백업 시스템"
MSG_INSTALL_EXISTING_DIR_FOUND="기존 설치 디렉토리 발견: %s"
MSG_INSTALL_CHECKING_DEPS_HEADER="필수 의존성 확인 중..."
MSG_INSTALL_REMOVING_EXISTING="기존 설치 제거 중..."

# 제거 프로세스
MSG_UNINSTALL_START="tarsync 제거를 시작합니다..."
MSG_UNINSTALL_CONFIRM="정말로 tarsync를 제거하시겠습니까? (y/N)"
MSG_UNINSTALL_CANCELLED="제거가 취소되었습니다"
MSG_UNINSTALL_COMPLETE="✅ Tarsync가 성공적으로 제거되었습니다"
MSG_UNINSTALL_BACKUP_PRESERVED="백업 데이터가 다음 위치에 보존되었습니다: %s"

# ======================
# 일반 메시지
# ======================

MSG_YES="y"
MSG_NO="n"
MSG_CONTINUE="계속"
MSG_CANCEL="취소"
MSG_LOADING="로딩 중..."
MSG_PLEASE_WAIT="잠시 기다려주세요..."
MSG_DONE="완료"
MSG_SUCCESS="성공"
MSG_FAILED="실패"
MSG_WARNING="경고"
MSG_ERROR="오류"
MSG_INFO="정보"

# ======================
# 설정 메시지
# ======================

MSG_HELP_CONFIG="config [lang|reset|help]    사용자 설정 관리"
MSG_HELP_EXAMPLE_CONFIG="  %s config lang ko       # 언어를 한국어로 설정"
MSG_CONFIG_RESTART_HINT="💡 새로운 %s 세션에서 변경사항이 적용됩니다"