import util from "../util/util.ts";

class Rsync {
  options: string = "-aAXv --hard-links --progress --numeric-ids";
  exclude: string = "";
  storeWorkPath: string = "";
  restoreWorkDirPath: string = "";
  #logData: string = "";
  constructor(restoreWorkDirPath: string = "", targetPath: string = "", options:string = "") {
    this.restoreWorkDirPath = restoreWorkDirPath;
    this.storeWorkPath = targetPath;
    this.options += ` ${options}`;
  }
  get logData(): string { return this.#logData }

  async #core(name: string = "", options: string = "") {
    const rsyncCommand = `rsync ${this.options} ${options} ${this.exclude} ${this.restoreWorkDirPath}/ ${this.storeWorkPath}`
    const res = await util.runShellWithProgress(rsyncCommand, name);
    util.parseRsyncOutput(res);
    return res;
  }
  // 시뮬레이션 모드
  async test() {
    await this.#core("시뮬레이션", "--dry-run");
  }

  async start() {
    this.#logData = await this.#core("복구");
  }
}

export default Rsync;