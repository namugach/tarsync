import util from "./src/util/util.ts";
import Logger from "./src/compo/Logger.ts";
import DiskFree from "./src/util/DiskFree.ts";
import BackupManager from "./src/compo/BackupManager.ts";
import { urlToHttpOptions } from "node:url";


async function _warp() {
  const BACKUP_DISK_PATH = "/";
  const STORE_DIR_PATH = util.getStoreDirPath();
  const WORK_DIR_PATH = await util.getWorkDirPath();
  const BACKUP_FILE_PATH = `${WORK_DIR_PATH}/tarsync.tar.gz`;
  const logger = new Logger(WORK_DIR_PATH);
  const diskfree = await util.getDiskFree(BACKUP_DISK_PATH);
  const rootTotalUsedByte = await util.getDiskFreeWithPathByte(diskfree.mount);
  const fanalSize = await util.calculateFinalDiskUsage(diskfree, rootTotalUsedByte);
  const df = new DiskFree(STORE_DIR_PATH);
  await df.load();

  /* 실행할 때 프로그램 유효성 검사 */
  await util.ensureCommandExists("pv", "sudo apt install pv");
  await util.ensureCommandExists("rsync", "sudo apt install rsync");
  await util.ensureCommandExists("tar", "sudo apt install tar");

  /* 용량 확인 */
  util.checkBackupStoreSize(df, fanalSize);

  /* 디렉토리 생성 */
  await util.createStoreDir();
  await util.mkdir(WORK_DIR_PATH);

  /* log.md 파일 작성 */
  await logger.choiceWirte();

  /* 백업 시작 메시지 */
  console.log("📂 백업을 시작합니다.");
  console.log(`📌 저장 경로: ${BACKUP_FILE_PATH}`);

  /* 백업 시작 */
  await util.backup(BACKUP_DISK_PATH, BACKUP_FILE_PATH, util.getExclude());

  const bm = new BackupManager(STORE_DIR_PATH);
  console.log(await bm.printBackups(5, -1, -1));
}

await _warp();
