const {spawnSync}=require('node:child_process');
const fs=require('node:fs');const path=require('node:path');
const root=path.resolve(__dirname,'..');const out=path.join(root,'evidence/week7-frontend');
fs.mkdirSync(out,{recursive:true});
for(const [name,args] of [
  ['flutter-analyze.txt',['analyze','--no-fatal-infos']],
  ['flutter-test.txt',['test','--reporter','expanded']],
]){
  const result=spawnSync('flutter',args,{cwd:root,encoding:'utf8'});
  fs.writeFileSync(path.join(out,name),(result.stdout+result.stderr).replace(/[ \t]+$/gm,''));
  process.stdout.write(name+': exit '+result.status+'\n'+(result.stdout+result.stderr).slice(-1400));
  if(result.status!==0)process.exit(result.status??1);
}
