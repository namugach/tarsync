import { config } from "../../config.ts";
import DiskFree from "../compo/DiskFree.ts";



const util = {
  async $(...args: string[]) {
    const command = new Deno.Command("/bin/sh", {
      args: ["-c", args.join(" ")],  // 명령어에 전달할 인자들
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

  getReStoreDirPath(): string {
    return `${this.getBasePath()}restore`;
  },

  async getStoreWorkDirPath(): Promise<string> {
    return `${this.getStoreDirPath()}/${await this.getDate()}`;
  },

  async getReStoreWorkDirPath(sotrePath: string): Promise<string> {
    return `${this.getReStoreDirPath()}/${await this.getDate()}__to__${sotrePath}`;
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
  getExclude(list: string[] = []): string {
    list = list.length === 0 ? this.getExcludeList(): list;
    return list
      .map(elem => `--exclude=${elem}`)
      .join(" ");
  },

  async mkdir(path: string): Promise<void> {
    await this.$$("mkdir", "-p", path);
  },

  async createStoreDir(): Promise<void> {
    await this.mkdir(this.getStoreDirPath());
  },

  async createReStoreDir(): Promise<void> {
    await this.mkdir(this.getReStoreDirPath());
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

  convertStringNunber(stringNumber: string) {
    return parseInt(stringNumber.split(",").join(""));
  },

  convertSize(size: number | string): string {
    if (typeof size ==="string") size = this.convertStringNunber(size);

    if (size >= 1024 * 1024 * 1024) {
      return `${(size / (1024 * 1024 * 1024)).toFixed(2)} GB`;
    } else if (size >= 1024 * 1024) {
      return `${(size / (1024 * 1024)).toFixed(2)} MB`;
    } else if (size >= 1024) { // 올바른 KB 체크
      return `${(size / 1024).toFixed(2)} KB`;
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
  async getDiskFreeWithPathByte(path: string): Promise<number> {
    // `df --output=used` 명령어를 실행하여 경로가 속한 디스크의 사용 중인 크기를 확인합니다.
    // `tail -n 1`을 사용하여 마지막 줄만 추출하고, parseInt()로 정수로 변환합니다.
    return parseInt(await this.$$(`df --output=used "${path}" | tail -n 1`), 10) * 1024;
  },

  /**
   * 주어진 경로의 디스크 사용량(KB 단위)을 계산합니다.
   * 
   * @param path - 확인할 파일 또는 디렉토리의 경로
   * @returns 해당 경로의 디스크 사용량(KB 단위)을 숫자로 반환합니다.
   */
  async getDiskUsageWithPathByte(path: string): Promise<number> {
    // `du -sk --one-file-system` 명령어를 실행하여 경로의 디스크 사용량을 확인합니다.
    // `awk '{print $1}'`을 사용하여 첫 번째 열(크기)만 추출하고, parseInt()로 정수로 변환합니다.
    return parseInt(await this.$$(`du -sk --one-file-system "${path}" 2>/dev/null | awk '{print $1}'`), 10) * 1024;
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
   * @param totalUsedByte - 디스크의 초기 전체 사용량(KB 단위)
   * @returns 제외 경로들을 고려한 최종 사용량(KB 단위)을 반환합니다.
   */
  async calculateFinalDiskUsage(diskinfo: DiskFree, totalUsedByte: number): Promise<number> {
    let res = totalUsedByte; // 초기 사용량을 저장합니다.

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
        const excludedSizeByte = await this.getDiskUsageWithPathByte(path);

        if (excludedSizeByte > 0) {
          // 제외 경로의 크기를 전체 사용량에서 차감합니다.
          res -= excludedSizeByte;
          console.log(
            `제외 경로 '${path}'의 크기: ${this.convertSize(excludedSizeByte)}`
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
      console.log(`전체 사용량 (${diskinfo.mount}): ${this.convertSize(totalUsedByte)}`);
      console.log(`최종 사용량 (제외 경로 제거 후): ${this.convertSize(res)}`);
    }

    // 최종 사용량을 반환합니다.
    return res;
  },

  /**
   * 지정된 대상 디렉토리 또는 파일을 백업합니다.
   * 
   * 이 메서드는 `tar` 명령어를 사용하여 대상 경로의 데이터를 압축하고, 
   * `pv`를 통해 진행 상황을 표시하며, `gzip`으로 최종적으로 압축한 결과를 저장합니다.
   * 
   * ### 동작:
   * 1. `tar` 명령어를 실행하여 대상 경로의 데이터를 아카이브로 생성합니다.
   *    - `-P`: 절대 경로를 유지합니다.
   *    - `--one-file-system`: 다른 파일 시스템(예: `/boot`, `/home`)으로 넘어가지 않도록 제한합니다.
   *    - `--acls`: ACL(액세스 제어 목록) 정보를 포함합니다.
   *    - `--xattrs`: 확장 속성(xattr)을 포함합니다.
   *    - `${excludeDirs}`: 제외할 디렉토리 또는 파일 목록을 지정합니다.
   * 2. `pv`를 통해 진행 상황을 표시합니다.
   * 3. `gzip`으로 압축한 결과를 지정된 파일 경로에 저장합니다.
   * 
   * @param target - tar로 묶을 대상 디렉토리 또는 파일의 경로입니다.
   *                 예: `/`, `/home/user`, `/var/www`
   * @param tarDirPathFileName - tar로 묶을 파일을 저장할 경로와 파일 이름입니다.
   *                             예: `/mnt/backup/tarsync/store/backup.tar.gz`
   * @param excludeDirs - tar로 묶을 때 제외할 디렉토리 또는 파일 목록입니다.
   *                      예: `--exclude=/proc --exclude=/sys --exclude=/tmp`
   * 
   * @throws 오류가 발생하면 에러 메시지를 출력하고 호출자에게 에러를 전달합니다.
   */
  async createTarFile(target: string, tarDirPathFileName: string, excludeDirs: string): Promise<void> {
    try {
      // `tar` 명령어를 실행하여 대상 경로의 데이터를 압축하고 저장합니다.
      await this.$(`sudo tar cf - -P --one-file-system --acls --xattrs ${excludeDirs} ${target} | pv | gzip > ${tarDirPathFileName}`);
    } catch (error) {
      // 오류 처리: 백업 중 오류가 발생한 경우
      console.error("묶는 중 오류 발생:", (error as Error).message);
      throw error; // 에러를 다시 던져서 호출자에게 전달합니다.
    }
  },


  parseRsyncOutput(output: string) {
    const lines = output.split("\n");
    let temp:RegExpMatchArray | null; 
    let totalSize: string | number = "";
    let sentBytes: string = "";
    let receivedBytes: string = "";
    let speedup: string = "";
    let printMesage = "";


    for (const line of lines) {
      if (line.includes("total size is")) {
        temp = line.match(/total size is ([\d,]+)/);
        totalSize = temp ? temp[1] : ""
        totalSize = util.convertSize(totalSize);
      }
      if (line.includes("sent")) {
        const sentMatch = line.match(/sent ([\d,]+) bytes/);
        const receivedMatch = line.match(/received ([\d,]+) bytes/);
        if (sentMatch) {
          sentBytes = this.convertSize(sentMatch[1])
        }
        if (receivedMatch) {
          receivedBytes = this.convertSize(receivedMatch[1]);
        }
      }
      if (line.includes("speedup")) {
        temp = line.match(/speedup is ([\d.]+)/);
        speedup = temp ? temp[1] : "";
      }
    }
  
    printMesage += "✅ 파일이 정상적으로 분석됨!\n"
    printMesage += `✅ 총 복구 데이터 크기: ${totalSize}\n`
    printMesage += `✅ 전송된 데이터: 약 ${sentBytes}\n`
    printMesage += `✅ 수신된 데이터: 약 ${receivedBytes}\n`
    printMesage += `✅ speedup ${speedup} → rsync가 최적화된 전송을 수행하고 있음\n`
    console.log(printMesage);
  },
  async runShellWithProgress(shellCommand: string, workName:string=""): Promise<string> {
    console.log(`♻️  ${workName} 작업을 시작합니다.`);
      
    let frameIndex = 0;
    let dotCount = 0;
    const frames = ["⏳", "🔄", "⌛", "🔃"]; // 회전 애니메이션 효과
  
    // 진행 메시지를 같은 줄에서 업데이트하는 인터벌 실행
    const progressIndicator = setInterval(() => {
      frameIndex = (frameIndex + 1) % frames.length;
      dotCount = (dotCount + 1) % 6; // 0 ~ 5까지 증가 후 다시 0으로 순환
      let dots = ".".repeat(dotCount); // 점 개수 증가

      if(dotCount === 0) {
        dots = "     ";
      }
  
      Deno.stdout.writeSync(new TextEncoder().encode(`\r${frames[frameIndex]} 진행 중${dots}`));
    }, 400); // 0.4초마다 업데이트
  
    try {
      // rsync 실행
      return await this.$$(`${shellCommand}`);
    } finally {
      clearInterval(progressIndicator); // 인터벌 정리
      console.log(`\r✅ ${workName} 작업 완료!     `); // 기존 진행 메시지를 덮어씌우기 위해 공백 추가
    }
  }
}


export default util