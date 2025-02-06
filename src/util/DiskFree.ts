import util from "./util.ts";

/**
 * DiskFree 클래스는 특정 경로에 대한 디스크 정보를 제공합니다.
 * 이 클래스는 `df` 명령어를 기반으로 동작하며, 디스크 장치 이름, 마운트 지점, 용량 정보 등을 포함합니다.
 * 
 * ### 사용법:
 * ```ts
 * const diskFree = new DiskFree("/path/to/directory");
 * await diskFree.load(); // 디스크 정보 로드
 * console.log(diskFree.toString()); // 디스크 정보 출력
 * console.log(`사용률: ${diskFree.getUsagePercentage()}%`); // 사용률 확인
 * ```
 */
export default class DiskFree {
  private path: string; // 디스크 정보를 조회할 경로
  public device: string = ""; // 디스크 장치 이름 (예: "/dev/sda1")
  public mount: string = ""; // 마운트 지점 (예: "/")
  public total: number = 0; // 총 용량(KB 단위)
  public used: number = 0; // 사용 중인 용량(KB 단위)
  public available: number = 0; // 사용 가능한 용량(KB 단위)

  /**
   * DiskFree 클래스의 인스턴스를 생성합니다.
   * 
   * @param path - 디스크 정보를 조회할 파일 또는 디렉토리의 경로
   */
  constructor(path: string) {
    this.path = path; // 조회할 경로를 저장합니다.
  }

  /**
   * 디스크 정보를 초기화하고 로드합니다.
   * 
   * `df` 명령어를 실행하여 디스크 정보를 가져오고, 속성들을 초기화합니다.
   * 
   * @throws 오류가 발생하면 에러 메시지를 출력하고 호출자에게 에러를 전달합니다.
   */
  async load(): Promise<void> {
    try {
      // `df` 명령어를 실행하여 디스크 정보를 가져옵니다.
      const result = await util.$$(`df -k --output=source,fstype,size,used,avail,target "${this.path}" | tail -n 1`);
      // 결과 문자열을 공백으로 분리하여 배열로 변환합니다.
      const [device, _, totalKb, usedKb, availKb, mount] = result.trim().split(/\s+/);
      // 속성 초기화
      this.device = device || ""; // 디스크 장치 이름
      this.mount = mount || ""; // 마운트 지점
      this.total = parseInt(totalKb, 10) || 0; // 총 용량(KB 단위)
      this.used = parseInt(usedKb, 10) || 0; // 사용 중인 용량(KB 단위)
      this.available = parseInt(availKb, 10) || 0; // 사용 가능한 용량(KB 단위)
    } catch (error) {
      // 오류 처리: 디스크 정보를 로드하는 중 오류가 발생한 경우
      console.error("디스크 정보를 로드하는 중 오류 발생:", (error as Error).message);
      throw error; // 에러를 다시 던져서 호출자에게 전달합니다.
    }
  }

  /**
   * 디스크 사용률을 백분율로 반환합니다.
   * 
   * @returns 디스크 사용률을 백분율(%)로 반환합니다. 총 용량이 0인 경우 0을 반환합니다.
   */
  getUsagePercentage(): number {
    if (this.total === 0) return 0; // 총 용량이 0인 경우 사용률은 0%
    return Math.floor((this.used / this.total) * 100); // 사용률 계산 후 정수로 반올림
  }

  /**
   * 디스크 정보를 문자열로 반환합니다.
   * 
   * @returns 디스크 정보를 사람이 읽기 쉬운 형식으로 반환합니다.
   */
  toString(): string {
    return `디스크 장치: ${this.device}\n마운트 지점: ${this.mount}\n총 용량: ${this.total}KB\n사용 중: ${this.used}KB\n사용 가능: ${this.available}KB\n사용률: ${this.getUsagePercentage()}%`;
  }
}