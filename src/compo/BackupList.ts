import { existsSync } from "node:fs";
import util from "../util/util.ts";
const { $, $$ } = util;




/**
 * 백업 디렉토리의 존재 여부를 확인합니다.
 * 
 * @param storeDir - 확인할 백업 디렉토리 경로
 * @throws 디렉토리가 존재하지 않을 경우 오류 메시지를 출력하고 프로그램을 종료합니다.
 */
function isStoreDir(storeDir: string): void {
  if (!existsSync(storeDir)) {
    console.error(`⚠️  백업 디렉토리가 존재하지 않습니다: ${storeDir}`);
    Deno.exit(1);
  }
}


/**
 * 백업 디렉토리의 파일 목록을 가져옵니다.
 * @param storeDir - 백업 디렉토리 경로
 * @returns 파일 목록
 */
async function getFiles(storeDir: string): Promise<string[]> {
  try {
    // 디렉토리 존재 여부 확인
    if (!existsSync(storeDir)) {
      throw new Error(`⚠️  백업 디렉토리가 존재하지 않습니다: ${storeDir}`);
    }

    // 전체 파일 목록 가져오기 (공백 포함 파일명 대응)
    const rawFiles = await $$(
      `ls -lthr "${storeDir}" | tail -n +2 | awk '{if ($9 != "") print $6, $7, $8, $9}'`
    );


    return rawFiles.split("\n").filter((line) => line.trim() !== "");

  } catch (error) {
    console.error("파일 목록을 가져오는 중 오류 발생:", error);
    throw error;
  }
}




type PaginationResult = {
  items: string[]; // 페이지에 포함된 항목 배열
  pageNum: number; // 현재 페이지 번호
  totalPages: number; // 총 페이지 수
};

/**
 * 파일 배열을 페이지 단위로 나누어 반환합니다.
 * 
 * @param files - 파일 이름 또는 데이터 항목 배열 (예: ["file1.txt", "file2.txt"])
 * @param pageSize - 한 페이지에 표시할 항목 수 (예: 5)
 * @param pageNum - 현재 페이지 번호 (양수: 정상 페이지, 음수: 뒤에서 계산)
 * 
 * @returns PaginationResult 객체:
 *          - items: 현재 페이지의 항목 배열
 *          - pageNum: 보정된 현재 페이지 번호
 *          - totalPages: 총 페이지 수
 * 
 * ### 사용법:
 * ```ts
 * const files = ["file1.txt", "file2.txt", "file3.txt", "file4.txt"];
 * const result1 = paginateFiles(files, 2, 1); // 첫 페이지 결과
 * console.log(result1.items); // ["file1.txt", "file2.txt"]
 * console.log(result1.pageNum); // 1
 * console.log(result1.totalPages); // 2
 * 
 * const result2 = paginateFiles(files, 2, -1); // 마지막 페이지 결과
 * console.log(result2.items); // ["file3.txt", "file4.txt"]
 * console.log(result2.pageNum); // 2
 * console.log(result2.totalPages); // 2
 * ```
 */
function paginateFiles(files: string[], pageSize: number, pageNum: number): PaginationResult {
  // 초기 PaginationResult 객체 생성
  const res: PaginationResult = {
    items: [],
    pageNum: 1,
    totalPages: 0,
  };

  // 총 아이템 수와 총 페이지 수 계산
  const totalItems = files.length; // 파일 배열의 길이
  const totalPages = Math.ceil(totalItems / pageSize); // 총 페이지 수 (올림 처리)

  // 파일이 없는 경우 빈 결과 반환
  if (totalPages === 0) return res;

  // 페이지 번호 보정 (음수 처리 및 범위 제한)
  let _pageNum = pageNum < 0 ? totalPages + pageNum + 1 : pageNum; // 음수 페이지 번호 처리
  _pageNum = Math.max(1, Math.min(_pageNum, totalPages)); // 유효 범위 내로 조정

  // 시작 인덱스와 끝 인덱스 계산
  let start = (_pageNum - 1) * pageSize; // 현재 페이지의 시작 인덱스
  if (start + pageSize > totalItems) start = Math.max(totalItems - pageSize, 0); // 마지막 페이지 조정
  const end = Math.min(start + pageSize, totalItems); // 현재 페이지의 끝 인덱스

  // 결과 객체 업데이트
  res.items = files.slice(start, end); // 현재 페이지의 항목 추출
  res.pageNum = _pageNum; // 보정된 페이지 번호 저장
  res.totalPages = totalPages; // 총 페이지 수 저장

  return res;
}


/**
 * 백업 파일 정보를 출력하는 함수
 * 
 * @param pageSize - 한 페이지에 표시할 항목 수
 * @param pageNum - 현재 페이지 번호 (양수: 정상 페이지, 음수: 뒤에서 계산)
 * @param selectList - 선택된 디렉토리 인덱스 (1부터 시작, 음수일 경우 뒤에서부터 계산)
 * @returns 파일 정보와 페이지네이션 정보를 포함한 결과 문자열
 */
async function printBackups(
  pageSize: number,
  pageNum: number,
  selectList: number // 1부터 시작, 음수일 경우 뒤에서부터 계산
): Promise<string> {
  const STORE_DIR = util.getStoreDirPath(); // 백업 디렉토리 경로
  const files = await getFiles(STORE_DIR); // 파일 목록 가져오기
  const paginationResult = paginateFiles(files, pageSize, pageNum); // 파일 배열을 페이지 단위로 나누기

  let res = ""; // 결과 문자열
  let totalSize = 0; // 선택된 디렉토리의 총 용량

  // 현재 페이지의 파일 목록을 순회합니다.
  for (let i = 0; i < paginationResult.items.length; i++) {
    const file = paginationResult.items[i];
    const fileName = file.split(" ")[3]; // 파일 이름 추출 (awk '{print $4}'와 동일)
    const backupDir = `${STORE_DIR}/${fileName}`; // 백업 디렉토리 경로

    // 디렉토리 크기 계산
    let size = "0B"; // 기본값: 0B
    let sizeBytes = 0;
    if (await util.isPathExists(backupDir)) {
      size = await util.$$(`du -sh "${backupDir}" | awk '{print $1}'`); // 인간이 읽기 쉬운 크기
      sizeBytes = parseInt(await util.$$(`du -sb "${backupDir}" | awk '{print $1}'`), 10); // 바이트 단위 크기
    }

    // log.md 파일 존재 여부 확인
    const logIcon = await util.isPathExists(`${backupDir}/log.md`) ? "📖" : "❌";

    // 선택된 디렉토리 인덱스 처리
    const icon =
      selectList < 0 && i === paginationResult.items.length + selectList // 음수일 경우 뒤에서부터 계산
        ? "✅"
        : selectList > 0 && i === selectList - 1 // 1부터 시작하는 인덱스 처리
        ? "✅"
        : "⬜️";

    // 총 용량 계산
    totalSize += sizeBytes;

    // 결과 문자열에 추가
    res += `${icon} ${logIcon} ${size} ${file} - ${i + 1}\n`;
  }

  res += "\n";

  // 선택된 디렉토리의 총 용량 출력
  const totalSizeHuman = util.convertSize(totalSize); // 인간이 읽기 쉬운 형식으로 변환
  res += `🔳 total: ${(await util.$$(`du -sh "${STORE_DIR}" | awk '{print $1}'`)).trim()}B\n`;
  res += `🔳 page total: ${totalSizeHuman}\n`;
  console.log(totalSize);

  // 페이지네이션 정보 추가
  const totalPages = paginationResult.totalPages;
  res += `🔳 Page ${paginationResult.pageNum} / ${totalPages} (Total: ${files.length} files)\n`;

  return res;
}
const STORE_DIR_PATH = util.getStoreDirPath();

isStoreDir(STORE_DIR_PATH);

const STORE_DIR = util.getStoreDirPath();
const PAGE_SIZE = 5; // 한 페이지당 출력할 파일 개수 (고정값: 5)
const PAGE_NUM = -1; // 현재 페이지 번호 (음수면 뒤에서부터)
const files = await getFiles(STORE_DIR);

// console.log(paginateFiles(files, 5, 1));
// console.log(paginateFiles(files, 5, -1));

// Example usage
const result = await printBackups(PAGE_SIZE, PAGE_NUM, 3);
console.log(result);


export default class BackupList {

}