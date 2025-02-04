#!/bin/bash
BASE_PATH=$(dirname "$(realpath "$0")")
FILE_PATH=$BASE_PATH/"${1:-./main.ts}"
sudo env "PATH=$PATH" deno run --allow-run "$FILE_PATH"