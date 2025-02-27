import Tarsync from "./src/Tarsync.ts";

const tarsync = new Tarsync();
// await tarsync.backup();
/**
 * backup 할 때 swap 파일을 포함 함.
 * 이유 찾아내고 제외 시킬 것.
 */
await tarsync.restore("2025_02_28_AM_04_36_28", "/");
// const content = `sent 3,266,705 bytes  received 2,697,633 bytes  290,943.32 bytes/sec
// total size is 4,865,994,599  speedup is 815.85 (DRY RUN)`
// console.log(util.parseRsyncOutput(content));

// await tarsync.backup();