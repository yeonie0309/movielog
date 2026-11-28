# 최종 증빙과 첨부 위치

사진은 실제 브라우저 화면이다. 15/16/17은 각각 실제 JSON·CLI 로그·AWS 조회 결과를 보여주는 문서 뷰어 캡처이며 터미널 앱 화면으로 설명하지 않는다.

| 파일 | 원본 노션 위치 | 확인할 내용 |
|---|---|---|
| 07-pipelines-active.jpg | 미션 기록 · 클라우드 설정 | host/mysql/app3개 활성, Linux 매칭 |
| 08-fleet-two-healthy.jpg | 미션 기록 · 클라우드 설정 | 수집기2대 Healthy |
| 09-app-up-two.jpg | 미션 기록 · 수집 검증 | up{job="app"}=1 두 개 |
| 12-dashboard-load.jpg | 미션 기록 · 최종 부하 | 실제 요청량·지연·DB 연결 |
| 13-dashboard-infrastructure.jpg | 미션 기록 · 최종 부하 | CPU·메모리·디스크·살아 있는 앱2대 |
| 15-measurement-report.jpg | 필수 한계 리포트 보조 / 미션 기록 | 4단계 실제 표와 미전송·판단 |
| 06-alert-configured.jpg | 미션 기록 · 알림 보조 | p95>1초, pending1분,20초 평가 |
| 10-alert-firing.jpg | 미션 기록 · 알림 보조 | 실제 Firing 상태 |
| 11-alert-received.jpg | **필수 p95 Alert 수신 스크린샷** / 미션 기록 | 실제 본인 Gmail 수신.15:18KST 낮 검증 구간 |
| 16-verification-logs.jpg | 미션 기록 · 검증 | 백엔드79, 안전11, 설정4, 알림3 실제 실행 로그 |
| 17-cleanup.jpg | 미션 기록 · 자원 정리 | EC2/RDS/ALB/EBS0, 역할·SG·SSM·ECR 제거 |
| 19-token-revoked.jpg | 미션 기록 · 자원 정리 | 실습 정책의 No tokens |
| 18-pr.jpg | 미션 기록 · PR | 생성한 PR과 기준/작업 브랜치 |

01은 로컬 초기 메트릭 실험,02는 발급 전 정책 검토 화면,03/04는 비활성 초안,05는 데이터 수신 전 대시보드다. 최종 완료 증빙으로03/04/05를 사용하지 않는다. 14는 폐기 전 확인 대상이며 폐기 완료 증빙은19다.

## 원시 데이터
- vpc-load-200/400/600/800.json:22시대 최종 내부망 부하 결과. 토큰 제거.
- samples-i-*.json:2초 간격 실제 CPU/DB 표본. measurement-summary.json과 LIMIT_REPORT.md는 해당40초 구간만 계산.
- load-*.json:낮 Mac→SSM 경로 진단 결과. 최종 표와 섞지 않음.
- diagnostic-pre-resume-vpc-200.json, vpc-200-run.txt, vpc-400-run.txt:낮 내부망 예비 측정. 최종 재측정과 구분.
- backend-tests.txt/backend-types.txt/infra-safety-tests.txt/config-validation.txt/promql-tests.txt:실제 검증 원문.
- cleanup.json:AWS 실제 조회로 확인한 정리 결과.
- verification.json:수행 여부. SLO 달성·서버 절대 한계와 미션 수행을 구분한다.

원본 노션은 수정하지 않았고 제출도 하지 않았다. 실제 스터디 사진과 이해 확인은 사용자가 직접 한다. 자세한 복사 문구는 ../SUBMISSION_GUIDE.md.
