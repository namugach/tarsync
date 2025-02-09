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
    const rawFiles = await util.$$(
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

const STORE_DIR_PATH = util.getStoreDirPath();

isStoreDir(STORE_DIR_PATH);

const STORE_DIR = "/mnt/backup/tarsync/store";
const PAGE_SIZE = 5; // 한 페이지당 출력할 파일 개수 (고정값: 5)
const PAGE_NUM = -1; // 현재 페이지 번호 (음수면 뒤에서부터)
const files = await getFiles(STORE_DIR);

console.log(paginateFiles(files, 5, 1));
console.log(paginateFiles(files, 5, -1));


export default class BackupList {

}