import { config } from "../../config.ts";

/**
 * 디스크 정보를 나타내는 인터페이스입니다.
 */
interface DiskInfo {
  /**
   * 디스크 장치(파티션)의 이름 또는 경로를 나타냅니다.
   * 예: "/dev/sda1", "/dev/nvme0n1p1"
   * 
   * 이 값은 `df` 명령어 또는 유사한 도구를 통해 확인할 수 있는 디스크 장치 식별자입니다.
   */
  device: string;

  /**
   * 디스크가 마운트된 경로를 나타냅니다.
   * 예: "/", "/mnt/data", "/home"
   * 
   * 이 값은 파일 시스템에서 해당 디스크가 사용 중인 위치를 나타냅니다.
   */
  mount: string;
}



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
    if (size >= 1024 * 1024 * 1024) {
      return `${(size / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    } else if (size >= 1024 * 1024) {
      return `${(size / (1024 * 1024)).toFixed(2)} MB`;
    } else if (size >= 1024) {
      return `${(size / 1024).toFixed(2)} KB`;
    } else {
      return `${size} Bytes`;
    }
  },


  /**
   * 주어진 경로가 속한 디스크의 정보를 반환합니다.
   * 
   * @param path - 확인할 파일 또는 디렉토리의 경로
   * @returns DiskInfo 객체를 반환합니다. 이 객체에는 디스크 장치 이름과 마운트 지점이 포함됩니다.
   * @throws 오류가 발생하면 에러 메시지를 출력하고 호출자에게 에러를 다시 던집니다.
   */
  async getDiskinfo(path: string): Promise<DiskInfo> {
    // `df --output=source,target` 명령어를 실행하여 경로가 속한 디스크의 정보를 가져옵니다.
    // `tail -n 1`을 사용하여 마지막 줄(실제 데이터)만 추출합니다.
    return await this.$$(`df --output=source,target "${path}" | tail -n 1`)
      .then(res => {
        // 결과 문자열을 공백으로 분리하여 배열로 변환합니다.
        const arr = res.split(/\s+/);

        // DiskInfo 객체를 생성합니다.
        const diskInfo: DiskInfo = {
          device: arr[0], // 첫 번째 열: 디스크 장치 이름 (예: "/dev/sda1")
          mount: arr[1]   // 두 번째 열: 마운트 지점 (예: "/")
        };

        // 생성된 DiskInfo 객체를 반환합니다.
        return diskInfo;
      })
      .catch(err => {
        // 오류 처리: 디스크 정보를 가져오는 중 오류가 발생한 경우
        console.error("디스크 정보를 가져오는 중 오류 발생:", err.message);
        throw err; // 에러를 다시 던져서 호출자에게 전달합니다.
      });
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
   * 
   * @param totalUsedKb - 디스크의 초기 전체 사용량(KB 단위)
   * @returns 제외 경로들을 고려한 최종 사용량(KB 단위)을 반환합니다.
   */
  async calculateFinalDiskUsage(diskinfo: DiskInfo, totalUsedKb: number): Promise<number> {
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
            `제외 경로 '${path}'의 크기: ${this.convertSize(excludedSizeKb * 1024)}`
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
      console.log(`전체 사용량 (${diskinfo.mount}): ${this.convertSize(totalUsedKb * 1024)}`);
      console.log(`최종 사용량 (제외 경로 제거 후): ${this.convertSize(res * 1024)}`);
    }

    // 최종 사용량을 반환합니다.
    return res;
  }
}


export default util