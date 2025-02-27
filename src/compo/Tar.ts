import util from "../util/util.ts";

class Tar {
  target: string;
  tarDirPathFileName: string;
  excludeDirs: string;
  constructor(target: string = "", tarDirPathFileName: string = "", excludeDirs: string = "") {
    this.target = target
    this.tarDirPathFileName = tarDirPathFileName;
    this.excludeDirs = excludeDirs;
  }
  async create(): Promise<void> {
    try {
      // `tar` 명령어를 실행하여 대상 경로의 데이터를 압축하고 저장합니다.
      await util.$(`sudo tar cf - -P --one-file-system --acls --xattrs ${this.excludeDirs} ${this.target} | pv | gzip > ${this.tarDirPathFileName}`);
    } catch (error) {
      // 오류 처리: 백업 중 오류가 발생한 경우
      console.error("묶는 중 오류 발생:", (error as Error).message);
      throw error; // 에러를 다시 던져서 호출자에게 전달합니다.
    }
  }
  async extract(restoreWorkDirPath: string): Promise<void> {
    try {
      // pv 명령어를 통해 압축 해제 진행률을 표시하고, tar 명령어로 파일을 해제합니다.
      await util.$(`pv ${this.tarDirPathFileName}/tarsync.tar.gz | tar -xzf - -C ${restoreWorkDirPath}`);
    } catch (error) {
      // 오류 메시지를 로그로 출력하고, 호출자에게 예외를 다시 던집니다.
      console.error("tar 파일 압축 해제 중 오류 발생:", (error as Error).message);
      throw error;
    }
  }
}

export default Tar;