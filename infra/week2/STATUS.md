# Infra 2주차 진행 상태
기준: 2026-11-28 KST. 완료 보고가 아닌 중간 보존 상태다.

## 완료
- MakeUs Infra 원본의 본문·필수/선택 미션 검토. 선택 토글 비어 있음, 로그/trace 설치는 이번주 제외.
- 별도 codex/infra-week-2 브랜치. Infra1 상태/증빙과 PE9주차 로컬 로그 변경 보존.
- 앱 /metrics opt-in, Counter/Histogram/Node 지표 구현. 백엔드79개 통과.
- 안전장치9개, 공식 Alloy 설정4개 검증, promtool 알림3개시나리오 통과.
- 실제 로컬 앱+MySQL의 health200, 인증401, 입력400, 404 및 /metrics200 확인·브라우저 캡처. DB 쓰기 없음.
- ARM64 이미지 movielog-infra:v0.2.0-26-11-28-1 build 성공, 실행user=node.
- AWS 임시 로그인 갱신, read-only 점검. /umc/app 파라미터0개. 새 클라우드자원 생성 안 함.
- SLO 정의 초안, 단계별 새회원/고유probe/토큰비노출 부하 도구, 별도 상태의 배포·정리 진입점 준비.

## 사용자 입력 대기
사용자는 Grafana Cloud 계정이 없어 무료 가입을 진행하겠다고 응답했다. 아직 가입/로그인 완료 응답을 받지 않았다.
계정이 준비되면 실제 무료스택·Fleet/Prometheus·토큰권한을 확인해야 한다. 신규 토큰발급·알림수신처는 구체적으로 확인하고 진행한다.
계정 준비 전에 불필요한 AWS 재생성 비용을 만들지 않는다.

## 아직 미완료
- Grafana Cloud 무료스택, Alloy access policy/token, SSM 실제설정.
- AWS EC2 두대/RDS/internal ALB 재구성 및 exporter 사용자.
- Fleet Inventory 두대·up·대시보드 실제데이터.
- 200/400/600/800 RPS 실제부하·CPU·DB동시관측, 꺾이는지점 확정.
- p951초/1분 알림의 실제 이메일 수신·사진.
- 최종실측보고서·제출증빙·PR. 원본 Notion반영·UMC제출은 하지 않음.

미완료측정값을 이전주차/워크북예시/로컬결과로 대체하지 않는다.
