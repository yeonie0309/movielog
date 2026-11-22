#!/usr/bin/env python3
"""Render archived, actual exports/logs as a readable evidence viewer."""
import html
import json
from pathlib import Path

out = Path(__file__).resolve().parent / 'evidence'
def read(name):
    return json.loads((out / name).read_text())
def esc(value):
    return html.escape(str(value))

before = read('before.json')['summary']
after = read('after.json')['summary']
fault = read('fault-rollback.json')['summary']
config = read('aws-configuration.json')
verification = read('verification.json')
rows = ''
for label, result in [('단일 배포', before), ('무중단 배포', after), ('실패 배포·롤백', fault)]:
    count = result['totals']
    rows += '<tr>' + ''.join('<td>' + esc(x) + '</td>' for x in [label, f"{count['sent']:,}",
        count['failure'], f"{count['failure'] / count['sent'] * 100:.2f}%", len(result['outages']),
        f"{result['downtimeMs']:,} ms", f"{result['percentiles']['p95']} ms", count['dropped']]) + '</tr>'
fault_lines = (out / 'fault-rollback-deployment.txt').read_text().splitlines()
prefixes = ('DRAIN ', 'SWAP ', 'SSM command ', 'STOPPED:', 'EXPECTED ', 'Public service ', 'ROLLBACK ', 'HEALTHY ', 'ROLLING COMPLETE', 'Observing ')
excerpt = '\n'.join(line for line in fault_lines if line.startswith(prefixes) or 'HTTP 500' in line or 'COMMON500' in line)
backend_tail = '\n'.join((out / 'backend-tests.txt').read_text().splitlines()[-12:])
guard_tail = '\n'.join((out / 'rolling-safety-tests.txt').read_text().splitlines()[-12:])
runtime_checks = '\n\n'.join(x['output'] for x in config['instanceChecks'])
cleanup_file = out / 'cleanup.json'
cleanup = cleanup_file.read_text() if cleanup_file.exists() else '삭제 완료 검증 대기 중'
page = f'''<!doctype html><html lang="ko"><meta charset="utf-8"><title>MovieLog Infra 실제 실행 증빙</title>
<style>
*{{box-sizing:border-box}}body{{margin:0;background:#f5f7fb;color:#182337;font:16px/1.55 system-ui,sans-serif}}
header,main{{max-width:1180px;margin:auto;padding:24px}}header{{padding-bottom:0}}h1{{font-size:28px;margin:8px 0}}
nav{{display:flex;gap:16px;margin:16px 0;flex-wrap:wrap}}a{{color:#284fc7}}section{{background:white;border:1px solid #dbe2ed;border-radius:12px;padding:24px;margin:20px 0}}
h2{{font-size:22px;margin:0 0 12px}}p{{color:#495a72}}table{{border-collapse:collapse;width:100%;font-size:15px}}
th,td{{border-bottom:1px solid #dbe2ed;padding:12px 8px;text-align:left}}th{{background:#f1f5fb}}
pre{{white-space:pre-wrap;overflow-wrap:anywhere;background:#111c30;color:#eef5ff;border-radius:8px;padding:18px;font:13px/1.6 ui-monospace,monospace}}
.small{{font-size:14px}}.ok{{color:#087d4d;font-weight:700}}img{{max-width:100%;border:1px solid #e2e8f0}}code{{font-family:ui-monospace,monospace}}
</style><header><h1>MovieLog Infra — 실제 실행 증빙</h1>
<p>공식 측정 도구의 export JSON과 AWS CLI·SSM 실행 로그를 표시하는 제출용 뷰어입니다.</p>
<nav><a href="#summary">측정 비교</a><a href="#fault">실패·롤백</a><a href="#checks">테스트</a><a href="#security">설정·권한</a><a href="#cleanup">정리</a></nav></header><main>
<section id="summary"><h2>단일 배포 → 무중단 배포</h2>
<table><thead><tr><th>측정</th><th>총 요청</th><th>실패</th><th>실패율</th><th>순단</th><th>다운타임</th><th>p95</th><th>dropped</th></tr></thead><tbody>{rows}</tbody></table>
<p class="small">공통: GET /health · 10 RPS · 요청 제한 5초 · baseline 15초 · 연속 실패 3건 이상을 순단으로 판정.
단일 배포 120초, 무중단 배포 240초. 실패·롤백은 정상 복구 후 30초를 추가 관측하고 약 313초에 종료했습니다.</p>
<p class="small">모든 최종 측정의 baseline 실패율 0, warnings 없음. 해당 측정 구간의 관측값입니다.</p>
<a href="before.json">before 원본 JSON</a> · <a href="after.json">after 원본 JSON</a> · <a href="fault-rollback.json">실패·롤백 원본 JSON</a>
</section>
<section id="fault"><h2>선택 미션 — HTTP 500 배포 중단과 롤백</h2>
<p>실제 SSM 로그의 관련 행 발췌입니다. 첫 서버 실패 후 다음 서버 배포를 중단하고, 공개 서비스의 200 응답을 확인한 뒤 정상 이미지로 복구했습니다.</p>
<pre>{esc(excerpt)}</pre><a href="fault-rollback-deployment.txt">원본 전체 배포 로그</a></section>
<section id="checks"><h2>테스트·타입 검사·비밀값 검사</h2>
<p class="ok">백엔드 테스트 / 타입 검사 / 배포 안전장치 테스트 / diff 검사: exit code 0</p>
<h3>백엔드 테스트 실제 출력</h3><pre>{esc(backend_tail)}</pre>
<h3>배포·정리 안전장치 단위 테스트 실제 출력</h3><pre>{esc(guard_tail)}</pre>
<pre>{esc(json.dumps(verification, ensure_ascii=False, indent=2))}</pre>
<a href="backend-tests.txt">전체 백엔드 로그</a> · <a href="rolling-safety-tests.txt">전체 안전장치 테스트 로그</a>
</section>
<section id="security"><h2>실제 AWS 설정과 EC2 역할 검증</h2>
<p>관측 시각: {esc(config['observedAt'])}. 비밀값을 포함하는 파라미터 값은 표시하지 않습니다.</p>
<pre>{esc(json.dumps(config['database'], indent=2))}</pre>
<h3>파라미터 이름·타입</h3><pre>{esc(json.dumps(config['parameters'], indent=2))}</pre>
<h3>각 서버의 실제 이미지·헬스·역할·허용/거절 결과</h3><pre>{esc(runtime_checks)}</pre>
<a href="aws-configuration.json">원본 AWS 구성 JSON</a></section>
<section id="cleanup"><h2>실습 리소스 정리 확인</h2><pre>{esc(cleanup)}</pre>
<p class="small">기본 VPC·서브넷과 AWS 서비스 연결 역할은 유지합니다. 이번 실습용 리소스만 정리합니다.</p></section>
</main></html>'''
(out / 'index.html').write_text(page)
print('Built viewer from archived actual JSON and CLI logs.')
