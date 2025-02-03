# 현재 작업 디렉토리를 기준으로 백업 디렉토리 설정
BASE_PATH=$(dirname "$(realpath "$0")")
STORE_DIR=$BASE_PATH/store