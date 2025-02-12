import util from "../util/util.ts";
const { $ } = util;

class Logger {
  #isWirte:boolean = true;
  #workDirName: string
  constructor(workDirName: string) {
    this.#workDirName = workDirName;
  }
  #setIsWirte(isWirte:string): boolean {
    return isWirte === "Y" ? true : false;
  }

  selectChoice() {
    const isWirte = prompt("로그를 기록하시겠습니까? (Y/n): ")?.trim() || "Y";
    this.#isWirte = this.#setIsWirte(isWirte);
  }
  async write(workDirName: string = this.#workDirName) {
    await $("vi", `${workDirName}/log.md`);
  }
  async choiceWirte(workDirName: string) {
    this.selectChoice()
    if(this.#isWirte) await this.write(workDirName);
  }
}


export default Logger