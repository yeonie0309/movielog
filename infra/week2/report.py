#!/usr/bin/env python3
"""Build a traceable report from actual redacted runs and non-secret samples."""
from datetime import datetime, timezone, timedelta
import html
import json
from pathlib import Path
import statistics

HERE = Path(__file__).resolve().parent
EVIDENCE = HERE/'evidence'
KST = timezone(timedelta(hours=9))

def build():
    samples = {path.stem.replace('samples-',''):json.loads(path.read_text()) for path in sorted(EVIDENCE.glob('samples-*.json'))}
    rows=[]
    for rps in [200,400,600,800]:
        value=json.loads((EVIDENCE/f'vpc-load-{rps}.json').read_text())
        summary=value['summary']; totals=summary['totals']
        start=summary['startedAt']; end=start+40000
        cpu={}
        db=[]
        for instance,records in samples.items():
            window=[record for record in records if start<=record['at']<=end]
            if len(window)<15:raise RuntimeError(f'Insufficient CPU/DB samples: {rps} {instance}')
            cpu[instance]={'count':len(window),'meanPercent':statistics.mean(x['cpuPercent'] for x in window),'maxPercent':max(x['cpuPercent'] for x in window)}
            db.extend(window)
        rows.append({'targetRps':rps,'startKst':datetime.fromtimestamp(start/1000,KST).isoformat(),
            'startedAt':start,'finishedAt':summary['finishedAt'],'sendWindowSeconds':40,
            'successThroughputRps':totals['success']/((summary['finishedAt']-start)/1000),
            'sentRps':totals['sent']/40,'p95Ms':summary['percentiles']['p95'],'totals':totals,
            'successRatioOfSent':totals['success']/totals['sent'],'deliveryRatio':totals['sent']/(rps*40),
            'cpu':cpu,'threadsConnectedMax':max(x['Threads_connected'] for x in db),
            'threadsRunningMax':max(x['Threads_running'] for x in db),'generator':value.get('generator')})
    assert rows[-1]['p95Ms']>1000 and rows[-1]['successThroughputRps']-rows[-2]['successThroughputRps'] < (rows[-2]['successThroughputRps']-rows[-3]['successThroughputRps'])*0.6
    report={'source':'Official workbook engine, dedicated VPC generator, four sequential 40-second stages',
        'rows':rows,'observedTargetInflectionRps':800,'absoluteServerCapacityProven':False,
        'conclusion':'이 실험에서 처리량 증가가 꺾이는 첫 목표 부하는 800 RPS이다. 실제 처리량은 680.77 RPS, p95는 1.911초이며 측정기 미전송 4,676건의 영향도 포함한다.'}
    (EVIDENCE/'measurement-summary.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    lines=['# 한계 측정 리포트','',report['conclusion'],'',
        '| 목표 RPS | 처리량(201 req/s) | p95 | 실패(유형) | CPU 평균 A / B | threads_connected | threads_running |',
        '|---:|---:|---:|---|---:|---:|---:|']
    table=[]
    for row in rows:
        cpus=list(row['cpu'].values()); totals=row['totals']; types=totals['byType']
        failure=f"HTTP/전송 실패 {totals['failure']}건, 미전송 {totals['dropped']}건"
        cells=[str(row['targetRps']),f"{row['successThroughputRps']:.2f}",f"{row['p95Ms']} ms",failure,
            ' / '.join(f"{c['meanPercent']:.1f}%" for c in cpus),str(row['threadsConnectedMax']),str(row['threadsRunningMax'])]
        lines.append('| '+' | '.join(cells)+' |');table.append(cells)
    lines+=['','## 조건과 계산',
        '- 앱 EC2 두 대(t4g.micro), 별도 부하 EC2 한 대(t4g.micro), RDS db.t4g.micro, Sydney 내부 ALB. 앱 이미지 v0.2.0-26-11-28-1.',
        '- 공식 엔진 commit 7377201431ee6477a35f447b6b1667385560167a의 createRun/createProber 사용. 40초, timeout 5초, baseline 8초.',
        '- 단계마다 새 합성 회원/JWT. probe movieId=1000000000000, 본 부하 counter=1부터 시작. 실제 회원·로컬 DB 자료 업로드 없음.',
        '- 처리량 = 201 건수 / 실제 실행 시간(드레인 포함). 실제 발사 RPS = sent / 40초. dropped는 보내지 못한 요청이며 서버의 HTTP 실패로 세지 않는다.',
        '- p95는 공식 엔진이 측정한 응답 시간이다. timeout/network는 지연 표본에서 빠지므로 실패 수와 함께 해석한다.',
        '- CPU A/B는 샘플 파일명 정렬 순서의 두 EC2. 약 2초 간격 /proc/stat 샘플의 부하 구간 평균. DB 수치는 동일 구간 두 수집기의 최댓값이며 합산하지 않는다. 관측기 두 연결을 포함한다.',
        '- Grafana의 요청량은 1분 rate, p95와 CPU는 5분 rate이므로 40초 부하의 원시 값과 수치가 같지 않다.',
        '', '## 원시 결과와 한계']
    for row in rows:
        g=row['generator']; totals=row['totals']
        lines.append(f"- {row['targetRps']} RPS: {row['startKst']}, sent={totals['sent']}, 201={totals['success']}, failure={totals['failure']}, dropped={totals['dropped']}; 발사 {row['sentRps']:.2f} RPS, 목표 대비 {row['deliveryRatio']*100:.2f}%; 부하 프로세스 CPU {g['processCpuPercent']:.1f}% (100%=1코어), 호스트 CPU {g['hostCpuPercent']:.1f}%.")
    lines+=['','- 꺾임 판단: 목표200→400→600에서 성공 처리량 증가폭은 약197,191 RPS였지만 600→800에서는 약93 RPS로 줄었고 p95가84ms→1,911ms로 증가했다. 목표800에서 1초 SLO를 위반했다.',
        '- 이는 현재 배포·측정 조건의 관측 지점이며 서버 자체의 절대 최대 처리량을 증명하지 않는다. 목표800 중 실제 발사는683.10 RPS였다. 600/800 단계의 측정기 미전송도 함께 해석한다.',
        '- 앱 CPU는 약47~48%→50~54%로 증가했고 DB 연결 수는24로 유지됐다. 2vCPU 호스트의 약50%만으로 CPU 여유를 단정할 수 없다(Node 단일 프로세스와 수집기 포함). 앱 CPU·측정기 한계가 가능한 원인이지만 DB/코드 병목을 확정하려면 프로파일링과 별도 반복 실험이 필요하다.',
        '- 낮의 SSM 경로 실험에서는 600 RPS 이후 연결이 멈췄으나 앱 직접 /health는 약 2~3ms로 응답했다. 해당 데이터는 load-*.json 및 diagnose-600.txt에 별도 보존했고 최종 내부망 표에 섞지 않았다.',
        '- 낮의 내부망 예비400 RPS에도 timeout276건이 있었다. 야간 재측정과 조건/시간이 달라 별도 진단 기록으로 남겼다. 한 차례의 짧은 결과를 장기 안정성으로 일반화하지 않는다.',
        '- 실제 p95 알림 발생·수신 증빙은 낮의 과부하 구간이다. 야간 최종 표에서 같은 알림이 새로 발생했다고 주장하지 않는다.',
        '', '## 파일', '- vpc-load-{200,400,600,800}.json: 최종 내부망 원시 결과.',
        '- samples-i-*.json: EC2/DB 원시 관측값.', '- measurement-summary.json: 위 표의 계산값.',
        '- 07-pipelines-active.jpg, 08-fleet-two-healthy.jpg, 09-app-up-two.jpg: 수집 설정과 정상 수집.',
        '- 10-alert-firing.jpg, 11-alert-received.jpg: 실제 알림 발생과 Gmail 수신.']
    (HERE/'LIMIT_REPORT.md').write_text('\n'.join(lines)+'\n')
    headings=['목표 RPS','201 처리량','p95','실패 / 미전송','CPU 평균 A / B','DB 연결 최대','DB 실행 최대']
    markup='<!doctype html><html lang="ko"><meta charset="utf-8"><title>Infra 2주차 실제 측정 결과</title><style>body{font-family:-apple-system,sans-serif;background:#f4f7fb;color:#152238;margin:40px}h1{font-size:30px}section{background:white;padding:28px;border-radius:16px;margin:20px 0}table{border-collapse:collapse;width:100%;font-size:15px}td,th{text-align:left;border-bottom:1px solid #dce4ee;padding:17px 12px}th{background:#eaf0fb}p,li{line-height:1.7}small{color:#52647a}</style><h1>Infra 2주차 · 실제 측정 결과</h1><p>실제 실행 JSON과 CPU·DB 관측값을 계산한 보고서입니다. 터미널 화면 캡처가 아닙니다.</p><section><table><thead><tr>'+''.join('<th>'+html.escape(x)+'</th>' for x in headings)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+html.escape(x)+'</td>' for x in row)+'</tr>' for row in table)+'</tbody></table></section><section><h2>'+html.escape(report['conclusion'])+'</h2><p>내부망의 별도 부하 서버 · 단계별 40초 · 요청 timeout 5초 · 매 단계 새 회원/JWT</p><p>201 처리량은 드레인 포함 실행 시간 기준입니다. 미전송(dropped)은 HTTP 실패와 구분합니다. CPU는 각 앱 EC2의 2초 간격 표본 평균이며 DB는 중복 수집값의 최댓값입니다.</p><small>근거: vpc-load-200/400/600/800.json · samples-i-*.json · measurement-summary.json</small></section></html>'
    (EVIDENCE/'measurement-report.html').write_text(markup)
    print(json.dumps({'rows':len(rows),'conclusion':report['conclusion']},ensure_ascii=False))

if __name__=='__main__':build()
