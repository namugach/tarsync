

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
  async $$(cmd: string, ...args: string[]) {
    const command = new Deno.Command(cmd, {
      args: [...args],  // 명령어에 전달할 인자들
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
    return new URL('..', import.meta.url).pathname;
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

  getExcludeDirs(): string {
    return [
      "/proc",
      "/swap.img",
      "/sys",
      "/cdrom",
      "/dev",
      "/run",
      "/tmp",
      "/mnt",
      "/media",
      "/var/run",
      "/var/tmp",
      "/lost+found",
      "/var/lib/docker",
      "/var/lib/containerd",
      "/var/run/docker.sock",
      "/swapfile"
    ]
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

  
}


export default util