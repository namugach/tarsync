import { config } from "../../config.ts";
import DiskFree from "./DiskFree.ts";



const util = {
  async $(cmd: string, ...args: string[]) {
    const command = new Deno.Command(cmd, {
      args: [...args],
      stdin: "inherit",
      stdout: "inherit",
      stderr: "inherit",
    });

    const process = command.spawn();
    await process.output(); // 프로세스가 종료될 때까지 기다림
  },
  async $$(...args: string[]) {
    const command = new Deno.Command("/bin/sh", {
      args: ["-c", args.join(" ")],  // 명령어에 전달할 인자들
      stdout: "piped", // 표준 출력 파이프
      stderr: "piped", // 표준 에러 파이프
    });

    const process = command.spawn();  // 프로세스 실행

    // output()을 사용하여 명령어의 출력을 받기
    const { stdout, stderr } = await process.output();  // 출력과 에러를 비동기적으로 받아옴

    const error = new TextDecoder().decode(stderr);  // 표준 에러 출력
    if (error === "") {
      return new TextDecoder().decode(stdout).trim();  // 표준 출력;
    }
    else {
      throw error;
    }
  },
  async getDate(): Promise<string> {
    return (await this.$$("date", "+%Y_%m_%d_%p_%I_%M_%S")).trim();
  },

  getBasePath(): string {
    return new URL('../../', import.meta.url).pathname;
  },

  getStoreDirPath(): string {
    return `${this.getBasePath()}store`;
  },

  async getWorkDirPath(): Promise<string> {
    return `${this.getStoreDirPath()}/${await this.getDate()}`;
  },

  getTarFile(workDir: string): string {
    return `${this.getStoreDirPath()}/${workDir}/tarsync.tar.gz`
  },
  getExcludeList() {
    return [
      config.backupPath,
      ...config.exclude.default,
      ...(config.exclude.custom || [])
    ]
  },
  getExclude(): string {
    return this.getExcludeList()
      .map(elem => `--exclude=${elem}`)
      .join(" ");
  },

  async mkdir(path: string): Promise<void> {
    await this.$$("mkdir", "-p", path);
  },

  async createStoreDir(): Promise<void> {
    await this.mkdir(this.getStoreDirPath());
  },


  async getEditorList(): Promise<string> {
    return await this.$$("update-alternatives", "--display", "editor");
  },

  async checkInstalledProgram(name: string) {
    if (await this.$$("which", name) === "") {
      console.error(`⚠️ 'pv' 명령어가 설치되어 있지 않습니다. 다음 명령어로 설치해주세요:\nsudo apt install ${name}`);
      Deno.exit(1);
    }
  },

  convertSize(size: number): string {
    if (size >= 1024 * 1024) {
      return `${(size / (1024 * 1024)).toFixed(2)} GB`;
    } else if (size >= 1024) {
      return `${(size / 1024).toFixed(2)} MB`;
    } else if (size) {
      return `${(size).toFixed(2)} KB`;
    } else {
      return `${size} Bytes`;
    }
  },


  /**
   * 주어진 경로에 대한 디스크 정보를 로드하고 DiskFree 인스턴스를 반환합니다.
   * 
   * @param path - 디스크 정보를 조회할 파일 또는 디렉토리의 경로
   * @returns 초기화된 DiskFree 인스턴스를 반환합니다.
   * @throws 디스크 정보를 로드하는 중 오류가 발생하면 예외가 던져집니다.
   * 
   * ### 사용법:
   * ```ts
   * const diskInfo = await getDiskFree("/path/to/directory");
   * console.log(diskInfo.toString()); // 디스크 정보 출력
   * ```
   */
  async getDiskFree(path: string): Promise<DiskFree> {
    const df = new DiskFree(path); // DiskFree 인스턴스 생성
    await df.load(); // 디스크 정보 로드
    return df; // 초기화된 DiskFree 인스턴스 반환
  },

  /**
   * 주어진 경로가 속한 디스크의 사용 중인 크기(KB 단위)를 반환합니다.
   * 
   * @param path - 확인할 파일 또는 디렉토리의 경로
   * @returns 사용 중인 디스크 크기(KB 단위)를 숫자로 반환합니다.
   */
  async getDiskFreeWithPathKb(path: string): Promise<number> {
    // `df --output=used` 명령어를 실행하여 경로가 속한 디스크의 사용 중인 크기를 확인합니다.
    // `tail -n 1`을 사용하여 마지막 줄만 추출하고, parseInt()로 정수로 변환합니다.
    return parseInt(await this.$$(`df --output=used "${path}" | tail -n 1`), 10);
  },

  /**
   * 주어진 경로의 디스크 사용량(KB 단위)을 계산합니다.
   * 
   * @param path - 확인할 파일 또는 디렉토리의 경로
   * @returns 해당 경로의 디스크 사용량(KB 단위)을 숫자로 반환합니다.
   */
  async getDiskUsageWithPathKb(path: string): Promise<number> {
    // `du -sk --one-file-system` 명령어를 실행하여 경로의 디스크 사용량을 확인합니다.
    // `awk '{print $1}'`을 사용하여 첫 번째 열(크기)만 추출하고, parseInt()로 정수로 변환합니다.
    return parseInt(await this.$$(`du -sk --one-file-system "${path}" 2>/dev/null | awk '{print $1}'`), 10);
  },


  /**
   * 주어진 명령어가 시스템에 설치되어 있는지 확인합니다.
   * 설치되어 있지 않으면 오류 메시지를 출력하고 프로그램을 종료합니다.
   * 
   * @param command - 확인할 명령어 이름 (예: "pv")
   * @param installCommand - 설치 명령어 (예: "sudo apt install pv")
   */
  async ensureCommandExists(command: string, installCommand: string): Promise<void> {
    try {
      // 명령어 존재 여부 확인
      await this.$$(`command -v ${command}`);
    } catch {
      // 명령어가 없는 경우 오류 메시지 출력 및 종료
      console.error(`${command}가 설치되어 있지 않습니다. 다음 명령어로 설치하세요: ${installCommand}`);
      Deno.exit(1);
    }
  },

  /**
   * 주어진 경로가 존재하는지 확인합니다.
   * 
   * @param path - 확인할 파일 또는 디렉토리의 경로
   * @returns Deno.FileInfo 객체를 반환하거나, 경로가 존재하지 않으면 null을 반환합니다.
   */
  async isPathExists(path: string): Promise<Deno.FileInfo | null> {
    // Deno.stat()을 사용하여 파일/디렉토리 정보를 조회하고, 오류 발생 시 null을 반환합니다.
    return await Deno.stat(path).catch(() => null);
  },

  /**
   * 주어진 경로가 속한 디스크 장치(파티션)를 확인합니다.
   * 
   * @param path - 확인할 파일 또는 디렉토리의 경로
   * @returns 해당 경로가 속한 디스크 장치(예: "/dev/sda1")를 문자열로 반환합니다.
   */
  async getPathDevice(path: string): Promise<string> {
    // `df --output=source` 명령어를 실행하여 경로가 속한 디스크 장치를 확인합니다.
    // `tail -n 1`을 사용하여 마지막 줄만 추출하고, 공백을 제거합니다.
    return (await this.$$(`df --output=source "${path}" 2>/dev/null | tail -n 1`)).trim();
  },

  /**
   * 특정 디스크의 전체 사용량에서 제외 경로들의 크기를 빼서 최종 사용량을 계산합니다.
   * @todo 제외된 용량도 추가하기
   * @param totalUsedKb - 디스크의 초기 전체 사용량(KB 단위)
   * @returns 제외 경로들을 고려한 최종 사용량(KB 단위)을 반환합니다.
   */
  async calculateFinalDiskUsage(diskinfo: DiskFree, totalUsedKb: number): Promise<number> {
    let res = totalUsedKb; // 초기 사용량을 저장합니다.

    // 제외 경로 목록을 순회하며 각 경로의 유효성과 크기를 확인합니다.
    for (const path of util.getExcludeList()) {
      try {
        // 1. 경로 존재 여부 확인
        if (!await this.isPathExists(path)) {
          console.log(`경로 '${path}'는 존재하지 않거나 접근할 수 없습니다.`);
          continue; // 다음 경로로 넘어갑니다.
        }

        // 2. 경로가 백업 대상 디스크에 속하는지 확인
        if (await this.getPathDevice(path) !== diskinfo.device) {
          console.log(`제외 경로 '${path}'는 백업 대상 디스크에 속하지 않습니다.`);
          continue; // 다음 경로로 넘어갑니다.
        }

        // 3. 제외 경로의 크기 계산
        const excludedSizeKb = await this.getDiskUsageWithPathKb(path);

        if (excludedSizeKb > 0) {
          // 제외 경로의 크기를 전체 사용량에서 차감합니다.
          res -= excludedSizeKb;
          console.log(
            `제외 경로 '${path}'의 크기: ${this.convertSize(excludedSizeKb)}`
          );
        } else {
          console.log(`제외 경로 '${path}'는 실제 디스크 공간을 차지하지 않습니다.`);
        }
      } catch (error) {
        // 예외 처리: 경로 처리 중 오류가 발생한 경우 로그를 출력합니다.
        console.error(`경로 '${path}' 처리 중 오류 발생:`, (error as Error).message);
      }
    }

    // 4. 최종 결과 검증 및 출력
    if (res < 0) {
      // 최종 사용량이 음수인 경우 오류를 출력합니다.
      console.error("오류: 최종 사용량이 음수입니다. 제외 경로들의 크기 합계가 전체 사용량보다 큽니다.");
    } else {
      // 최종 사용량을 출력합니다.
      console.log(`전체 사용량 (${diskinfo.mount}): ${this.convertSize(totalUsedKb)}`);
      console.log(`최종 사용량 (제외 경로 제거 후): ${this.convertSize(res)}`);
    }

    // 최종 사용량을 반환합니다.
    return res;
  },

  /**
   * 주어진 디스크의 사용 가능한 공간이 백업 크기 요구사항을 충족하는지 확인합니다.
   * 
   * 이 함수는 `DiskFree` 인스턴스에서 제공하는 사용 가능한 디스크 공간(`available`)과 
   * 필요한 백업 크기(`backupSize`)를 비교하여 저장 공간이 충분한지 검사합니다.
   * 
   * ### 동작:
   * 1. `diskFree.available` 값이 `backupSize`보다 작은 경우:
   *    - 오류 메시지를 출력하고 프로그램을 종료합니다.
   *    - 종료 코드는 `1`이며, 사용자에게 저장 공간 부족 경고를 제공합니다.
   * 2. 충분한 공간이 있는 경우:
   *    - 아무 작업도 수행하지 않습니다.
   * 
   * @param diskFree - 디스크 정보를 포함하는 `DiskFree` 클래스의 인스턴스입니다.
   *                   이 인스턴스는 `load()` 메서드를 통해 초기화되어야 합니다.
   * @param backupSize - 백업에 필요한 최소 디스크 공간(KB 단위)입니다.
   *                     이 값은 정수여야 하며, KB 단위로 계산됩니다.
   * 
   * @throws 저장 공간이 부족한 경우 콘솔에 오류 메시지를 출력하고 프로그램을 종료합니다.
   *         종료 코드는 `1`입니다.
   */
  checkBackupStoreSize(diskFree: DiskFree, backupSize: number): void {
    if (diskFree.available < backupSize) {
      console.error(`⚠️  저장 공간이 부족합니다. 최소 ${util.convertSize(backupSize)} 이상 필요합니다.`);
      console.error(diskFree.showAll());
      Deno.exit(1); // 저장 공간 부족으로 인해 프로그램 종료
    }
  }
}


export default util