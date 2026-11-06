const fs=require('node:fs');const path=require('node:path');
const {execFileSync}=require('node:child_process');
const root=path.resolve(__dirname,'..');const out=path.join(root,'evidence/week7-frontend');
const names=fs.readdirSync(out);const images=names.filter(n=>n.endsWith('.png'));
if(images.length!==17)throw Error('Expected 17 images');
const supplementalImages=names.filter(n=>n.endsWith('.jpg')).sort();
if(supplementalImages.length!==15)throw Error('Expected 15 supplemental screenshots');
for(const name of supplementalImages){
  const b=fs.readFileSync(path.join(out,name));
  if(b[0]!==0xff||b[1]!==0xd8||b.length<1000)throw Error('Invalid JPEG '+name);
}
const dimensions=images.map(name=>{
  const b=fs.readFileSync(path.join(out,name));
  if(b.subarray(0,8).toString('hex')!=='89504e470d0a1a0a')throw Error('Invalid PNG '+name);
  return {name,width:b.readUInt32BE(16),height:b.readUInt32BE(20)};
});
function duration(b,start=0,end=b.length){
  for(let p=start;p+8<=end;){
    const size32=b.readUInt32BE(p);
    const size=size32===1?Number(b.readBigUInt64BE(p+8)):size32===0?end-p:size32;
    const type=b.toString('ascii',p+4,p+8);
    if(size<8||p+size>end)break;
    if(type==='mvhd')return b[p+8]===0 ? b.readUInt32BE(p+24)/b.readUInt32BE(p+20) :
      Number(b.readBigUInt64BE(p+32))/b.readUInt32BE(p+28);
    if(type==='moov'){const value=duration(b,p+8,p+size);if(value)return value;}
    p+=size;
  }
}
const videos=['01-live-crud.mp4','02-injected-recovery.mp4'].map(name=>{
  const b=fs.readFileSync(path.join(out,name));const seconds=duration(b);
  if(!seconds||seconds<3)throw Error('Invalid video '+name);
  return {name,seconds,bytes:b.length};
});
const log=fs.readFileSync(path.join(out,'flutter-test.txt'),'utf8');
const integration=fs.readFileSync(path.join(out,'flutter-integration-test.txt'),'utf8');
if(!log.includes('+79: All tests passed!'))throw Error('Unit/Widget tests incomplete');
if(!integration.includes('+2: All tests passed!'))throw Error('Integration tests incomplete');
if(integration.includes('Warning: A call to tap()'))throw Error('Missed UI tap in evidence run');
const live=JSON.parse(fs.readFileSync(path.join(out,'live-api-results.json')));
for(const status of [200,201,204,400,403,404,409]){
  if(!live.requests.some(r=>r.status===status))throw Error('Missing status '+status);
}
const finalGet=live.requests.filter(r=>r.method==='GET'&&r.path===`/v6/members/${live.memberId}/ratings`).at(-1);
if(!Array.isArray(finalGet.response)||finalGet.response.length)throw Error('Fixture ratings remain');
const changed=execFileSync('git',['diff','--name-only','origin/feature/week-6-frontend'],{cwd:root,encoding:'utf8'}).trim().split('\n');
const newFiles=execFileSync('git',['ls-files','--others','--exclude-standard'],{cwd:root,encoding:'utf8'}).trim().split('\n');
const files=[...new Set([...changed,...newFiles])].filter(f=>f && !f.startsWith('backend/evidence/week4-postman/') &&
  f!=='evidence/week4/flutter_analyze.local.txt').sort();
fs.writeFileSync(path.join(out,'changed-files.txt'),files.join('\n')+'\n');
const summary={tests:79,integrationScenarios:2,realApiRequests:live.requests.length,
  account:{memberId:live.memberId,email:live.email,nickname:live.nickname},
  movieId:live.movieId,ratingId:live.ratingId,images:dimensions,videos,
  actualServerVsInjected:'01-11 actual v6+TMDB; 12-17 injected failures in actual Android app',
  supplementalImages,
  manualVerification:'Chrome direct UI: member19/TMDB155; availability/duplicate/input invalidation; rating 0-disabled to 4-enabled; create/GET/edit5/GET/delete cancel/delete empty. Signup by user. Server400/final signup409/inflight guards/write and GET failure recovery remain automated-only; do not check ALL manual verification yet.',
  files};
fs.writeFileSync(path.join(out,'verification-summary.json'),JSON.stringify(summary,null,2)+'\n');
console.log(JSON.stringify({tests:79,integration:2,requests:live.requests.length,images:images.length,videos},null,2));
