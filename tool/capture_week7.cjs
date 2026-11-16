// Actual Android screenshots/videos; never synthesize application UI evidence.
const {spawn,execFileSync}=require('node:child_process');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const out=path.join(root,'evidence/week7-frontend');fs.mkdirSync(out,{recursive:true});
const adb='/Users/yeonie/Library/Android/sdk/platform-tools/adb';
const run=(...args)=>execFileSync(adb,['-s','emulator-5554',...args]);
const child=spawn('flutter',['test','integration_test/week7_evidence_test.dart','-d','emulator-5554','--reporter','expanded'],
  {cwd:root,stdio:['ignore','pipe','pipe']});
let log='',buffer='',recording=null;
const seen=new Set();
function startVideo(name){
  if(recording)stopVideo();
  const remote=`/sdcard/movielog-week7-${name}.mp4`;
  const recorder=spawn(adb,['-s','emulator-5554','shell',`screenrecord --size 540x1200 --bit-rate 1800000 --time-limit 170 ${remote} & echo $!; wait`]);
  recording={name,remote,recorder,pid:null};
  recorder.stdout.on('data',data=>{const pid=data.toString().trim();if(/^\d+$/.test(pid)&&recording)recording.pid=pid;});
}
function stopVideo(){
  if(!recording)return;
  const current=recording;recording=null;
  if(current.pid)run('shell','kill','-2',current.pid);
  current.recorder.on('close',()=>{
    try{run('pull',current.remote,path.join(out,current.name+'.mp4'));}
    catch(error){process.stderr.write('Video pull failed: '+error.message+'\n');}
  });
}
function output(data){
  const text=data.toString();log+=text;buffer+=text;process.stdout.write(text);
  let end;
  while((end=buffer.indexOf('\n'))>=0){
    const line=buffer.slice(0,end);buffer=buffer.slice(end+1);
    let match;
    if((match=line.match(/WEEK7_CAPTURE=([\w-]+)/))&&!seen.has(match[1])){
      seen.add(match[1]);fs.writeFileSync(path.join(out,match[1]+'.png'),run('exec-out','screencap','-p'));
    }
    if((match=line.match(/WEEK7_VIDEO_START=([\w-]+)/)))startVideo(match[1]);
    if(line.includes('WEEK7_VIDEO_STOP='))stopVideo();
    if((match=line.match(/WEEK7_LIVE_JSON=(.*)/))){
      fs.writeFileSync(path.join(out,'live-api-results.json'),JSON.stringify(JSON.parse(match[1]),null,2)+'\n');
    }
  }
}
child.stdout.on('data',output);child.stderr.on('data',output);
child.on('exit',code=>{stopVideo();fs.writeFileSync(path.join(out,'flutter-integration-test.txt'),log.replace(/[ \t]+$/gm,''));
  process.exitCode=code??1;});
