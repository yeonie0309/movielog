// Read-only viewer for actual verification output and the transaction source.
const { createServer } = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root=path.resolve(__dirname,'../..');
const evidence=path.join(root,'evidence/week8-backend');
const escape=value=>String(value).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;');
const card=(title,value)=>`<article><h2>${escape(title)}</h2><pre>${escape(value)}</pre></article>`;
createServer((req,res)=>{
 const report=JSON.parse(fs.readFileSync(path.join(evidence,'live-api-results.json'),'utf8'));
 let title,content;
 if(req.url==='/transaction'){
  title='두 저장을 묶은 실제 트랜잭션 코드';
  content=card('movie-backend/src/service/movie-record.service.ts',fs.readFileSync(path.join(root,'movie-backend/src/service/movie-record.service.ts'),'utf8'));
 }else if(req.url==='/rollback'){
  title='실제 MySQL 롤백·동시 중복 검증';
  content=card('검증 환경',report.environment)+card('두 번째 저장에 실패 주입 → 실제 DB rollback',JSON.stringify(report.rollback,null,2))+card('동시 사전 검사 이후 DB UNIQUE',JSON.stringify(report.forcedUniqueRace,null,2))+card('검증 데이터 정리',report.cleanup);
 }else{
  title='실제 백엔드·Flutter 검증 결과';
  content=card('백엔드 70개 테스트',fs.readFileSync(path.join(evidence,'backend-tests-final.txt'),'utf8').split('\n').slice(-18).join('\n'))+card('Flutter 94개 테스트',fs.readFileSync(path.join(evidence,'flutter-tests.txt'),'utf8').slice(-1200))+card('Flutter analyze',fs.readFileSync(path.join(evidence,'flutter-analyze.txt'),'utf8'));
 }
 res.writeHead(200,{'Content-Type':'text/html; charset=utf-8'});
 res.end(`<!doctype html><html lang="ko"><meta charset="utf-8"><title>${escape(title)}</title><style>body{font:17px system-ui;margin:28px auto;max-width:1180px;color:#20232b;background:#f3f5f8}h1{font-size:28px}h2{font-size:19px}article{background:white;border:1px solid #d8dce3;padding:16px;margin:14px 0;border-radius:10px}pre{font:15px/1.55 ui-monospace,monospace;white-space:pre-wrap;overflow-wrap:anywhere}nav a{margin-right:20px}</style><h1>${escape(title)}</h1><p>실제 실행 기록을 표시한 읽기 전용 뷰어 · 토큰·비밀번호 제외</p><nav><a href="/transaction">트랜잭션 코드</a><a href="/rollback">롤백·동시 요청</a><a href="/checks">검증 결과</a></nav>${content}</html>`);
}).listen(5188,'127.0.0.1',()=>console.log('Evidence viewer http://127.0.0.1:5188'));
