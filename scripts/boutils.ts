import { exec } from 'child_process';
import { ethers } from 'hardhat';

export function ReplaceLine(filename: string, srcStr: string, dstStr: string): any {
  let cmdStr = "sed -i -e   's/" + srcStr + '/' + dstStr + "/g' " + filename;
  console.log(cmdStr);
  exec(cmdStr, function (err, stdout, stderr) {});
}
export function GetUnixTimestamp(): number {
  return Math.floor(Date.now() / 1000);
}

//触发一个区块自增
export async function advanceBlock() {
  return ethers.provider.send('evm_mine', []);
}

export async function Sleep(msec: number) {
  return new Promise((resolve) => {
    setTimeout(() => {
      console.log('xxxxxxxx:');
      resolve(null);
    }, msec);
  });
}
