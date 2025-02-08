import util from "./src/util/util.ts";
import Logger from "./src/compo/Logger.ts";
import DiskFree from "./src/util/DiskFree.ts";

const TEST_OFF = false; 
const 
  { $, $$ } = util,
  STORE_DIR_PATH = util.getStoreDirPath(),
  WORK_DIR_PATH = await util.getWorkDirPath(),
  BACKUP_FILE_PATH = `${WORK_DIR_PATH}/tarsync.tar.gz`,
  logger = new Logger(WORK_DIR_PATH);

if(TEST_OFF) {
  
  await util.checkInstalledProgram("vim");
  await util.checkInstalledProgram("gzip");
  await util.checkInstalledProgram("pv");

  await util.createStoreDir();
  await util.mkdir(WORK_DIR_PATH);
  logger.choiceWirte();
}




const backupDisk = "/";
const diskfree = await util.getDiskFree(backupDisk);
const rootTotalUsedKb = await util.getDiskFreeWithPathKb(diskfree.mount);
const fanalSize = await util.calculateFinalDiskUsage(diskfree, rootTotalUsedKb);


await util.ensureCommandExists("pv", "sudo apt install pv");
await util.ensureCommandExists("rsync", "sudo apt install rsync");
await util.ensureCommandExists("tar", "sudo apt install tar");

console.log(fanalSize);
console.log(util.getStoreDirPath());
console.log(util.getBasePath());
const df = new DiskFree("/mnt");
await df.load();
util.checkBackupStoreSize(df, fanalSize);
