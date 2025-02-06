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

async function getFreeSpaceGB(store_dir_path: string): Promise<number> {
  let res: string = await $$('df', "-BG", "--output=avail", store_dir_path);
  res = res.split("\n")[1];
  res = res.replace("G", "");
  return parseInt(res, 10);
}

async function checkStoreSpace(minSpaceGB:number, store_dir_path:string) {
  if(minSpaceGB < await getFreeSpaceGB(store_dir_path)) {
    console.error(`⚠️ 저장 공간이 부족합니다. 최소 ${minSpaceGB}GB 이상 필요합니다.`);
    Deno.exit(1);
  }
}



// const backupDisk = "/";
// const diskinfo = await util.getDiskinfo(backupDisk);
// const rootTotalUsedKb = await util.getDiskFreeWithPathKb(diskinfo.mount);
// const fanalSize = await util.calculateFinalDiskUsage(diskinfo, rootTotalUsedKb);


// await util.ensureCommandExists("pv", "sudo apt install pv");
// await util.ensureCommandExists("rsync", "sudo apt install rsync");
// await util.ensureCommandExists("tar", "sudo apt install tar");

// console.log(fanalSize);



console.log(util.getStoreDirPath());
console.log(util.getBasePath());
// console.log(await util.getDiskFreeWithPathKb(util.getStoreDirPath()));

const df = new DiskFree("/".toString());
await df.load();
console.log(df);
