// Official workbook engine, isolated VPC load generator; synthetic members only.
import fs from 'node:fs';
import crypto from 'node:crypto';
import os from 'node:os';
import zlib from 'node:zlib';
import { createRun } from './src/run/run.js';
import { createProber } from './src/prober/index.js';

const [base, rpsText, durationText = '40', label = 'load'] = process.argv.slice(2);
const rps = Number(rpsText), durationSec = Number(durationText);
if (!/^http:\/\/internal-movielog-infra2-alb-[\w.-]+$/.test(base) || ![200,400,600,800].includes(rps) || durationSec > 120) {
  throw new Error('Refusing an unapproved target or load');
}
const prefix = 'i2' + crypto.randomBytes(4).toString('hex');
const password = 'Aa9!' + crypto.randomBytes(16).toString('hex');
async function request(path, body, token) {
  const response = await fetch(base + path, {
    method: 'POST', headers: {'Content-Type':'application/json', ...(token ? {Authorization:'Bearer '+token} : {})},
    body: JSON.stringify(body), signal: AbortSignal.timeout(15000),
  });
  if (response.status !== 201 && response.status !== 200) throw new Error('Preflight HTTP ' + response.status);
  return response.json();
}
const member = await request('/members',{email:prefix+'@example.com',nickname:prefix,password});
const login = await request('/auth/login',{email:prefix+'@example.com',password});
const token = login.result.accessToken;
await request('/movie-records',{movieId:1000000000000,score:5,comment:'preflight',addToFavorites:true},token);
const scenario = {name:`Infra2 VPC ${rps}RPS ${label}`,target:{
  url:base+'/movie-records',method:'POST',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},
  body:'{"movieId": {{counter}}, "score": 5, "comment": "lab", "addToFavorites": true}',timeoutMs:5000,
},success:{statusCodes:[201]},load:{rps,durationSec},analysis:{slowThresholdMs:1000,baselineSec:8,minConsecutiveFailures:3}};
const run = createRun({scenario,prober:createProber('internal')});
const processBefore = process.cpuUsage();
const hostBefore = os.cpus().map(cpu=>cpu.times);
await run.start();
const safeScenario = {...scenario,target:{...scenario.target,headers:{...scenario.target.headers,Authorization:'[REDACTED]'}}};
const elapsedMs = run.finishedAt - run.startedAt;
const processUsed = process.cpuUsage(processBefore);
const hostAfter = os.cpus().map(cpu=>cpu.times);
let idle=0,total=0;
hostAfter.forEach((times,index)=>Object.keys(times).forEach(key=>{const delta=times[key]-hostBefore[index][key];total+=delta;if(key==='idle')idle+=delta;}));
const result = {scenario:safeScenario,summary:run.summary(),buckets:run.buckets(),syntheticMemberId:member.result.memberId,
  generator:{nodeVersion:process.version,processCpuPercent:(processUsed.user+processUsed.system)/1000/elapsedMs*100,hostCpuPercent:total?100*(1-idle/total):0,freeMemoryBytes:os.freemem()}};
const file = `/opt/infra2/results/${label}-${rps}.json`;
fs.writeFileSync(file,JSON.stringify(result,null,2)+'\n',{mode:0o600});
const {outages,...compact} = result.summary;
console.log(JSON.stringify({...compact,outageCount:outages.length,resultFile:file}));
console.log('SAFE_EXPORT='+zlib.gzipSync(JSON.stringify(result)).toString('base64'));
