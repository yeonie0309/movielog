# Infra 2주차 — 관측 가능한 시스템 만들기

원본과 요구사항은 REQUIREMENTS.md. 현재 클라우드 완료를 주장하지 않는다.
브랜치는 codex/infra-week-2, 기준은 Infra1이다. PE9주차 코드는 해당 브랜치/PR에 그대로 있다.

## 구현
- METRICS_ENABLED=true일 때만 /metrics, per-app Registry, Node 기본 지표, 완료 요청 Counter/Histogram.
- 응답 finish에서 최종 status를 읽어 Guard/예외필터 오류를200으로 기록하지 않음.
- 라벨 method/route/status만 사용. 임의404는 /unmatched로 고정. ID·email·query·token은 라벨 금지.
- /health·/metrics·Swagger는 앱 latency에서 제외. histogram에1초 SLO 경계 포함.
- 공식 remote Fleet pipeline3개와 dashboard.json, Alloy remotecfg·SSM 설치 스크립트.
- p95 / AppDown / 오류율 알림규칙, promtool 정상·초과·데이터소실 테스트.
- SLO.md는 목표·측정정의이며 목표달성을 의미하지 않음.

## 검증 완료
- 백엔드79개 통과 (기존73 + 메트릭6).
- 배포·정리·토큰비노출 안전 테스트9개 통과.
- 공식 grafana/alloy:v1.20.1로 config와 pipeline3개 문법검사 통과.
- 공식 prom/prometheus:v3.5.0 promtool로 알림규칙3개 시나리오 통과.
- AWS 로그인 갱신 및 read-only 점검. /umc/app 기존 파라미터0개.
- AWS 새리소스 생성·DB권한변경·Grafana설정·고부하 실험·알림수신은 아직 수행하지 않음.

## 실제 실행 순서 (계정 준비 후)
1. Grafana Cloud 가입/로그인과 무료 스택 확인.
2. Fleet/Prometheus endpoint·user, Alloy쓰기정책 토큰을 로컬 .local/grafana.json에0600으로 보관. 토큰은 채팅·Git·사진에 넣지 않음.
3. cloud.py inspect로 계정/리전/기존파라미터 점검 후, 재생성할 자원과 권한 검토.
4. cloud.py foundation → ARM64 이미지build/push → RDS available → baseline → init-db → exporter → settings.
5. end-baseline으로 초기화 서버 정리 후 cluster로 internal ALB + 앱EC2 두 대 생성.
6. Fleet Inventory 두 대·pipeline3개·up{job="app"}=1 확인, dashboard import.
7. cloud.py tunnel로127.0.0.1:9377→SSM→internal ALB. 평문 인터넷에 회원 비밀번호/JWT를 보내지 않음.
8. 공식 zero-downtime-lab을127.0.0.1:9376에 실행. load.py prepare/run/collect 각200/400/600/800단계. 한 번 실행한 회원counter재사용 금지.
9. 실측으로 LIMIT_REPORT.md 작성, Grafana p95알림 수신 확인·캡처. 테스트 알림 발송은 수신처를 본인으로 지정하고 확인한 뒤 진행.
10. 실습태그/상태의 리소스만정리. cloud.py cleanup-start/cleanup-finish. 기본VPC와다른DB보존. Grafana쓰기토큰도폐기.
11. 실제결과사진·로그, 원본노션 작성가이드, PR 정리. 원본노션 반영과 UMC제출은 별도승인/사용자영역.

cloud.py는 Infra1의 구현을 재사용하되 상태는 week2/.local, 리소스태그는 movielog-infra2로 분리한다. 기존/umc/app 파라미터가 있으면 초기구성을 거부한다. endpoint는HTTPS *.grafana.net만허용한다. 앱3000 직접개방·Alloy12345 외부공개를 하지 않는다.
SSM/EC2 credentials와secret정보를원격 명령문에 직접넣지 않는다. MySQL exporter 사용자는새실습RDS에서만생성한다. 전역조회권한은실습DB에한정된계정의권한이라는뜻이아니므로별도검토필요: 실제서비스라면수집기에맞춰더좁혀야한다.

## 참고
- 원본 assets: https://github.com/UMC-11th-Workbook-Infra/zero-downtime-lab/tree/main/workbook-assets
- Alloy: https://grafana.com/docs/alloy/latest/reference/components/prometheus/prometheus.exporter.mysql/
- Nest 테스팅: https://docs.nestjs.com/fundamentals/testing
