const fs=require('node:fs');
const path=require('node:path');
const {execFileSync}=require('node:child_process');
const root=path.resolve(__dirname,'..');
const out=path.join(root,'evidence/week7-frontend');fs.mkdirSync(out,{recursive:true});
const secrets=[];
for(const name of ['.env','backend/.env','movie-backend/.env']){
  const file=path.join(root,name);if(!fs.existsSync(file))continue;
  for(const line of fs.readFileSync(file,'utf8').split('\n')){
    const m=line.match(/^\s*([A-Z_]*(?:TOKEN|PASSWORD|SECRET|API_KEY)[A-Z_]*)\s*=\s*(.*?)\s*$/);
    if(m){const value=m[2].replace(/^['"]|['"]$/g,'');if(value.length>=8)secrets.push(value);}
  }
}
const changed=execFileSync('git',['diff','--name-only','origin/feature/week-6-frontend'],{cwd:root,encoding:'utf8'}).trim().split('\n');
const untracked=execFileSync('git',['ls-files','--others','--exclude-standard'],{cwd:root,encoding:'utf8'}).trim().split('\n');
const files=[...new Set([...changed,...untracked])].filter(f=>fs.existsSync(path.join(root,f)) &&
  /\.(dart|cjs|md|txt|json)$/.test(f) && !f.startsWith('backend/evidence/week4-postman/') &&
  f!=='evidence/week4/flutter_analyze.local.txt');
let checked=0;
for(const f of files){const text=fs.readFileSync(path.join(root,f),'utf8');checked++;
  if(secrets.some(secret=>text.includes(secret)))throw Error('Secret detected in '+f);
}
const tracked=execFileSync('git',['ls-files'],{cwd:root,encoding:'utf8'}).split('\n');
if(tracked.some(f=>/(^|\/)\.env$/.test(f)))throw Error('Tracked .env detected');
execFileSync('git',['diff','--check'],{cwd:root});
const report=`PASS: ${checked} changed/new text files checked against local secret values; no secret values printed.\nPASS: no tracked .env.\nPASS: git diff --check.\n`;
fs.writeFileSync(path.join(out,'security-check.txt'),report);process.stdout.write(report);
