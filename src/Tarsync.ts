import util from "./util/util.ts";
import Logger from "./compo/Logger.ts";
import DiskFree from "./compo/DiskFree.ts";
import ArchiveManager from "./compo/ArchiveManager.ts";
import Meta from "./type/Meta.ts";

class Tarsync {
  private BACKUP_DISK_PATH: string;
  private STORE_DIR_PATH: string;
  private workDirPath: string;
  private ArchivePath: string;
  private logger: Logger;

  constructor() {
    // 경로 및 설정 초기화
    this.BACKUP_DISK_PATH = "/";
    this.STORE_DIR_PATH = util.getStoreDirPath();
    this.workDirPath = ""; // 작업 디렉토리는 비동기로 초기화
    this.ArchivePath = ""; // 백업 파일 경로는 작업 디렉토리 초기화 후 설정
    this.logger = new Logger(this.workDirPath);
  }

  /**
   * 필수 도구(pv, rsync, tar)가 설치되어 있는지 확인하고, 필요한 경우 설치를 안내합니다.
   */
  async #validateRequiredTools(): Promise<void> {
    await util.ensureCommandExists("pv", "sudo apt install pv");
    await util.ensureCommandExists("rsync", "sudo apt install rsync");
    await util.ensureCommandExists("tar", "sudo apt install tar");
  }

  /**
   * 작업 디렉토리와 백업 파일 경로를 초기화합니다.
   */
  async #initializePaths(): Promise<void> {
    this.workDirPath = await util.getWorkDirPath();
    this.ArchivePath = `${this.workDirPath}/tarsync.tar.gz`;
  }

  /**
   * 디스크 용량 정보를 계산하고 반환합니다.
   */
  async #calculateDiskUsage(): Promise<number> {
    const diskfree = await util.getDiskFree(this.BACKUP_DISK_PATH);
    const rootTotalUsedByte = await util.getDiskFreeWithPathByte(diskfree.mount);
    return await util.calculateFinalDiskUsage(diskfree, rootTotalUsedByte);
  }

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
  #checkBackupStoreSize(diskFree: DiskFree, backupSize: number): void {
    if (diskFree.available < backupSize) {
      console.error(`⚠️  저장 공간이 부족합니다. 최소 ${util.convertSize(backupSize)} 이상 필요합니다.`);
      console.error(diskFree.showAll());
      Deno.exit(1); // 저장 공간 부족으로 인해 프로그램 종료
    }
  }
  

  async #getMetaInfo(size: number): Promise<Meta> {
    return {
      size,
      exclude: util.getExcludeList(),
      created: await util.getDate()
    }
  }

  async #createMetaData(size: number) {
    const meta = await this.#getMetaInfo(size);
    const fileContent = `export const meta = ${JSON.stringify(meta, null, 2)};\n`;
    await Deno.writeTextFile(`${this.workDirPath}/meta.ts`, fileContent);
  }

  /**
   * 저장소 용량 체크
   * @param targetSize 저장할 것의 용량 Byte
   */
  async #checkDiskSize(targetSize: number) {
    // 작업 디렉토리 및 백업 파일 경로 초기화
    await this.#initializePaths();

    // 로거 및 디스크 용량 정보 초기화
    const df = new DiskFree(this.STORE_DIR_PATH);
    await df.load();

    // 저장소 용량 확인
    this.#checkBackupStoreSize(df, targetSize);
  }

  /**
   * 백업 작업을 수행합니다.
   */
  async backup(): Promise<void> {
    try {
            const finalSize = await this.#calculateDiskUsage();
      
            this.#checkDiskSize(finalSize);

      // 필수 도구 유효성 검사
      await this.#validateRequiredTools();


      // 작업 디렉토리 및 저장소 디렉토리 생성
      await util.createStoreDir();
      await util.mkdir(this.workDirPath);

      /**
       * meta data 파일 작성
       */
      await this.#createMetaData(finalSize);

      // log.md 파일 작성
      await this.logger.choiceWirte(this.workDirPath);

      // 백업 시작 메시지 출력
      console.log("📂 백업을 시작합니다.");
      console.log(`📌 저장 경로: ${this.ArchivePath}`);

      // 백업 실행
      await util.createTarFile(this.BACKUP_DISK_PATH, this.ArchivePath, util.getExclude());

      // 백업 결과 출력
      const bm = new ArchiveManager(this.STORE_DIR_PATH);
      console.log(await bm.printBackups(5, -1, -1));
    } catch (error) {
      console.error("백업 중 오류 발생:", (error as Error).message);
      throw error;
    }
  }
}


export default Tarsync;