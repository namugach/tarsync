# Security Fix v1.1.1: Critical Restore Module Vulnerability

## 개요

Tarsync v1.1.1에서는 복구 모듈(`src/modules/restore.sh`)의 치명적인 보안 취약점을 수정했습니다. 이 취약점은 완전 동기화 모드에서 시스템 핵심 디렉토리가 삭제될 수 있는 심각한 문제였습니다.

## 취약점 상세 분석

### 문제 상황
- **영향 버전**: v1.1.0 이하
- **취약점**: 완전 동기화 모드(`--delete`) 사용 시 제외 경로 삭제
- **위험도**: **CRITICAL** (시스템 완전 파괴 가능)

### 기술적 원인

#### 1. rsync `--delete` 옵션의 위험한 동작
```bash
# 기존 위험한 코드 (v1.1.0)
rsync -avhP --delete --exclude=/proc --exclude=/sys "$source/" "$target/"
```

**문제점**:
- `--exclude`: 동기화에서만 제외, **삭제는 막지 않음**
- `--delete`: 소스에 없는 파일을 타겟에서 삭제
- **결과**: 제외된 경로(`/proc`, `/sys`, `/dev`)가 소스에 없으면 타겟에서 삭제됨

#### 2. 시나리오 재현
1. **백업 시**: `/`를 백업하면서 `/proc`, `/sys`, `/dev` 제외
2. **백업 파일**: 제외된 경로들이 포함되지 않음
3. **복구 시**: 완전 동기화 모드 선택
4. **rsync 판단**: 
   - 소스(백업)에 `/proc` 없음
   - 타겟(시스템)에 `/proc` 있음
   - **→ 삭제 실행** 💥

#### 3. 영향 범위
- **시스템 디렉토리**: `/proc`, `/sys`, `/dev`, `/run` 등 삭제
- **결과**: 시스템 완전 마비, 부팅 불가능
- **복구**: 시스템 재설치 필요

## 수정 사항

### 1. 함수 시그니처 개선
```bash
# 기존 (v1.1.0)
execute_rsync "$work_dir" "$target_path" exclude_array "$delete_mode"

# 수정 (v1.1.1)
execute_rsync "$work_dir" "$target_path" exclude_array "$delete_mode" protect_paths
```

### 2. 보호 필터 추가
```bash
# 새로운 보호 로직 (v1.1.1)
if [[ "$delete_mode" == "true" ]]; then
    rsync_options+=" --delete"
    
    # 제외된 경로들을 삭제로부터 보호
    if [[ ${#protect_paths_ref[@]} -gt 0 ]]; then
        for exclude_path in "${protect_paths_ref[@]}"; do
            protect_filters+=("--filter=protect $exclude_path")
        done
    fi
fi
```

### 3. 최종 rsync 명령어
```bash
# 수정된 안전한 명령어
rsync -avhP --delete \
      --exclude=/proc --exclude=/sys --exclude=/dev \
      --filter='protect /proc' --filter='protect /sys' --filter='protect /dev' \
      "$source/" "$target/"
```

### 4. 동적 보호 경로 로드
```bash
# META_EXCLUDE 또는 log.json에서 동적으로 로드
local protect_paths=()
if [[ ${#log_exclude_paths[@]} -gt 0 ]]; then
    protect_paths=("${log_exclude_paths[@]}")
else
    protect_paths=("${META_EXCLUDE[@]}")
fi
```

## 변경된 파일들

### `src/modules/restore.sh`
- `execute_rsync()` 함수 시그니처 변경
- 보호 필터 로직 추가
- 변수 스코프 개선 (전역변수 → 지역변수)

### 기타 수정사항
- 안전한 nameref 매개변수 전달 방식 도입
- 에러 처리 강화

## 테스트 검증

### 1. 기능 테스트
```bash
# 테스트 환경 구성
mkdir -p /tmp/test/{source,target}
echo "source data" > /tmp/test/source/file.txt
mkdir -p /tmp/test/target/proc
echo "critical system data" > /tmp/test/target/proc/important

# 수정된 rsync 테스트
rsync -avhP --delete \
      --exclude=/proc \
      --filter='protect /proc' \
      /tmp/test/source/ /tmp/test/target/

# 결과 검증
ls -la /tmp/test/target/proc/important  # ✅ 파일 보존됨
```

### 2. 완전 시나리오 테스트
- **백업**: 전체 시스템 백업 생성
- **복구**: 완전 동기화 모드로 복구
- **검증**: 시스템 중요 경로 보존 확인

## 보안 강화 효과

### Before (v1.1.0)
- ❌ 시스템 디렉토리 삭제 위험
- ❌ 완전 동기화 모드 사용 불가
- ❌ 데이터 손실 가능성

### After (v1.1.1)  
- ✅ 시스템 디렉토리 완벽 보호
- ✅ 안전한 완전 동기화 지원
- ✅ 동적 제외 경로 관리

## 마이그레이션 가이드

### 기존 사용자 권장사항
1. **즉시 업데이트**: v1.1.1로 업그레이드
2. **백업 검증**: 기존 백업 무결성 확인
3. **테스트 복구**: 중요 시스템에서 사용 전 테스트

### 업데이트 방법
```bash
# 저장소 업데이트
git pull origin main

# 새 버전 설치
sudo ./bin/install.sh

# 버전 확인
tarsync version  # 1.1.1 확인
```

## 관련 참고자료

- **rsync 매뉴얼**: `man rsync` - filter 옵션 상세 설명
- **보안 블로그**: rsync --delete 옵션 위험성
- **Tarsync CHANGELOG**: [CHANGELOG.md](../CHANGELOG.md)

## 결론

이번 보안 수정을 통해 Tarsync는 이제 완전 동기화 모드를 안전하게 사용할 수 있게 되었습니다. 시스템 중요 경로가 완벽하게 보호되므로, 사용자들은 안심하고 전체 시스템 복구를 수행할 수 있습니다.

**모든 사용자는 즉시 v1.1.1로 업데이트할 것을 강력히 권장합니다.**