// 설정 파일의 구조 정의
export interface Config {
  /**
   * 백업 대상 디스크 경로
   */
  backupDisk: string;

  /**
   * 백업 저장 디렉토리 경로
   */
  backupPath: string;

  /**
   * 제외 경로 설정
   */
  exclude: {
    /**
     * 기본 제외 경로 목록
     */
    default: string[];

    /**
     * 사용자 정의 제외 경로 목록
     */
    custom?: string[]; // 선택적 필드
  };
}

// 실제 설정 값
export const config: Config = {
  backupDisk: "/",
  backupPath: "/mnt/backup",
  exclude: {
    default: [
      "/swap.img",        // 스왑 파일
      "/proc",            // 프로세스 정보
      "/sys",             // 시스템 정보
      "/dev",             // 장치 파일
      "/run",             // 실행 중인 프로세스 데이터
      "/tmp",             // 임시 파일
      "/media",           // 외부 저장 매체
      "/var/run",         // 실행 중인 서비스 데이터
      "/var/tmp",         // 임시 파일
      "/lost+found",      // 손실된 파일 복구 디렉토리
      "/var/lib/docker",  // Docker 이미지 및 컨테이너
      "/var/lib/containerd",  // Containerd 데이터
      "/var/run/docker.sock"  // Docker 소켓 파일
    ],
    custom: [
      "/home/user/temp",  // 사용자가 추가로 제외하고 싶은 경로
      "/opt/logs"         // 다른 사용자 정의 경로
    ]
  }
};