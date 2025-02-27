import util from "./util/util.ts";
import Logger from "./compo/Logger.ts";
import DiskFree from "./compo/DiskFree.ts";
import StoreManager from "./compo/StoreManager.ts";
import Meta from "./type/Meta.ts";
import Tar from "./compo/Tar.ts";
import Rsync from "./compo/Rsync.ts";

class Tarsync {
  private BACKUP_DISK_PATH: string;
  private STORE_DIR_PATH: string;
  private RESTORE_DIR_PATH: string;
  private storeWorkDirPath: string;
  private restoreWorkDirPath: string;
  private storeTarGzFilePath: string;
  private tar: Tar;
  private rsync: Rsync;
  private storeLogger: Logger;
  private restoreLogger: Logger;

  constructor() {
    // 경로 및 설정 초기화
    this.BACKUP_DISK_PATH = "/";
    this.STORE_DIR_PATH = util.getStoreDirPath();
    this.RESTORE_DIR_PATH = util.getReStoreDirPath();
    this.storeWorkDirPath = ""; // 저장소 작업 디렉토리는 비동기로 초기화
    this.restoreWorkDirPath = ""; // 복구 작업 디렉토리는 비동기로 초기화
    this.storeTarGzFilePath = ""; // 백업 파일 경로는 작업 디렉토리 초기화 후 설정
    this.tar = new Tar();
    this.rsync = new Rsync();
    this.storeLogger = new Logger(this.storeWorkDirPath);
    this.restoreLogger = new Logger(this.restoreWorkDirPath);
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
    await Deno.writeTextFile(`${this.storeWorkDirPath}/meta.ts`, fileContent);
  }

  /**
   * 저장소 용량 체크
   * @param targetSize 저장할 것의 용량 Byte
   */
  async #checkDiskSize(targetSize: number) {

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
      this.storeWorkDirPath = await util.getStoreWorkDirPath();
      this.storeTarGzFilePath = `${this.storeWorkDirPath}/tarsync.tar.gz`;
      this.#checkDiskSize(finalSize);

      // 필수 도구 유효성 검사
      await this.#validateRequiredTools();


      // 작업 디렉토리 및 저장소 디렉토리 생성
      await util.createStoreDir();
      await util.mkdir(this.storeWorkDirPath);

      /**
       * meta data 파일 작성
       */
      await this.#createMetaData(finalSize);

      // log.md 파일 작성
      await this.storeLogger.choiceWirte(this.storeWorkDirPath);

      // 백업 시작 메시지 출력
      console.log("📂 백업을 시작합니다.");
      console.log(`📌 저장 경로: ${this.storeTarGzFilePath}`);

      // 백업 실행
      this.tar.target = this.BACKUP_DISK_PATH;
      this.tar.tarDirPathFileName = this.storeTarGzFilePath;
      this.tar.excludeDirs = util.getExclude();
      await this.tar.create();

      // 백업 결과 출력
      const bm = new StoreManager(this.STORE_DIR_PATH);
      console.log(await bm.printBackups(5, -1, -1));
    } catch (error) {
      console.error("백업 중 오류 발생:", (error as Error).message);
      throw error;
    }
  }

  /**
 * 복구 작업 로그를 기록합니다.
 */
  async #writeRestoreLog(message: string): Promise<void> {
    const logFilePath = `${this.RESTORE_DIR_PATH}/restore.log`;
    const timestamp = new Date().toISOString();
    const logContent = `[${timestamp}] ${message}\n\n`;

    await util.$$(`echo "${logContent}" >> "${logFilePath}"`);
  }

  async #importMetaData(backupDir: string): Promise<Meta> {
    return (await import(`${backupDir}/meta.ts`)).meta;
  }

  /**
   * 백업 데이터를 복구합니다.
   * 
   * 이 메서드는 지정된 백업 디렉토리의 데이터를 대상 경로로 복구합니다.
   * `rsync` 명령어를 사용하며, 삭제 옵션 및 시뮬레이션 모드를 선택적으로 활성화할 수 있습니다.
   * 
   * ### 사용법:
   * ```ts
   * const tarsync = new Tarsync();
   * await tarsync.restore("2025_02_09_AM_05_08_46", "/mnt/restore", { delete: true, dryRun: false });
   * ```
   * 
   * @param backupDirName - 복구할 백업 디렉토리 이름 (예: "2025_02_09_AM_05_08_46").
   * @param storeWorkPath - 복구 대상 경로 (예: "/mnt/restore").
   * @param options - 복구 옵션 객체.
   * @param options.delete - 대상 경로에서 원본 백업 디렉토리에 없는 파일을 삭제할지 여부.
   *                         활성화 시, 대상 경로의 불필요한 파일을 정리합니다.
   * @param options.dryRun - 시뮬레이션 모드로 실행할지 여부.
   *                         활성화 시, 실제 복구 작업은 수행되지 않고 결과만 출력됩니다.
   * 
   * @throws {Error} - 백업 디렉토리가 존재하지 않거나 복구 작업 중 오류가 발생한 경우 예외를 던집니다.
   */
  async restore(
    backupDirName: string,
    storeWorkPath: string,
    options: { delete: boolean; dryRun: boolean } = { delete: true, dryRun: true }
  ): Promise<void> {
    try {
      this.storeWorkDirPath = `${this.STORE_DIR_PATH}/${backupDirName}`;
      this.restoreWorkDirPath = await util.getReStoreWorkDirPath(backupDirName);

      // 1. 백업 디렉토리 존재 여부 확인
      if (!(await util.isPathExists(this.storeWorkDirPath))) {
        throw new Error(`⚠️  백업 디렉토리가 존재하지 않습니다: ${this.storeWorkDirPath}`);
      }
      // 필수 도구 유효성 검사
      await this.#validateRequiredTools();
      // 작업 디렉토리 및 백업 파일 경로 초기화

      // console.log(backupDir);
      const metaData = await this.#importMetaData(this.storeWorkDirPath);

      // 압축 되기 전의 용량 불러오기
      const finalSize = metaData.size;

      // 디스크에 압축 풀 용량 체크
      this.#checkDiskSize(finalSize);

      // 작업 디렉토리 생성
      await util.createReStoreDir();
      await util.mkdir(this.restoreWorkDirPath);

      this.tar.tarDirPathFileName = this.storeWorkDirPath;
      await this.tar.extract(this.restoreWorkDirPath);

      // 3. rsync 옵션 구성
      if (options.delete) this.rsync.options += " --delete"; // 삭제 옵션 추가



      const workDirPath = "/mnt/backup/tarsync/restore/2025_02_27_AM_03_20_02__to__2025_02_21_AM_05_58_44";
      // this.rsync.restoreWorkDirPath = workDirPath;
      this.rsync.restoreWorkDirPath = this.restoreWorkDirPath;
      this.rsync.storeWorkPath = storeWorkPath;
      this.rsync.exclude = util.getExclude(metaData.exclude);
      // 시뮬레이션 모드
      if (options.dryRun) {
        await this.rsync.test();
      }


      // 복구
      await this.rsync.start();
      await this.#writeRestoreLog(this.rsync.logData);
      console.log("📜 복구 로그가 저장되었습니다.");
    } catch (error) {
      console.error("❌ 복구 작업 중 오류 발생:", (error as Error).message);
      throw error;
    }
  }



}

export default Tarsync;