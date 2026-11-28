# Infra 2주차 진행 상태
기준: 2026-11-28 KST.

## 완료
- 원본 MakeUs Infra 워크북 전체 검토. 별도 codex/infra-week-2 브랜치로 이전 주차 작업 보존.
- 앱 /metrics opt-in, 최종 HTTP 상태의 Counter/Histogram, Node 지표, 고정 라벨 구현.
- 백엔드79개, 실습 안전장치11개, Alloy설정4개, promtool시나리오3개 및 타입 검사 통과.
- 실제 AWS 앱 EC2 두 대/RDS/internal ALB, Alloy Fleet2대 healthy와3개 파이프라인 활성·실제 대시보드 수신 검증.
- SSM 경로에서 발생한600RPS 연결 문제 진단, 별도 부하 EC2 한 대를 승인받아 공식 엔진으로 내부망 재측정.
- 최종200/400/600/800 각40초 측정과 CPU/DB 동시 관측. 목표800에서680.77RPS·p951.911초·미전송4,676건 관측. 측정기 영향을 분리해 리포트 작성.
- p95>1초/1분 실제 Firing과 지정한 본인 Gmail의15:18 KST 수신 사진 보존. 최종22시대 측정과 구분.
- AWS EC2/RDS/ALB/EBS0개. 실습 권한·보안 그룹·SSM파라미터·ECR 정리 검증. 승인받은 Grafana 실습 토큰 폐기.
- SLO, 한계 리포트, 원시JSON, 사진별 안내, 원본 작성 가이드 준비.

## 최종 정리
- 코드·비밀정보·증빙 최종 검토 후 커밋/푸시와 PR#22 생성 완료: https://github.com/yeonie0309/movielog/pull/22
- 원본 Notion에는 아무 내용도 입력하지 않았고 UMC 제출도 하지 않았다.
- 사용자 할 일: 실제 스터디 사진, 본인 이해 확인, SUBMISSION_GUIDE.md에 따라 원본 노션 반영과 제출.

## 보존
Infra1 상태와 증빙, PE9주차 로그 stash 및 사용자의 기존 untracked 자료를 유지했다.
