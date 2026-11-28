# 원본 Infra 2주차 검토
원본: https://app.notion.com/p/makeus-challenge/2-498b57f4596b83ad9042814939cec684
경로: MakeUs → Infra → 레아의 워크북 → 2주차 - 관측 가능한 시스템 만들기
검토: 2026-11-28 KST. 원본 내용·체크박스는 수정하지 않았다.

## 필수 제출
- SLO 정의서.
- 200 / 400 / 600 / 800 RPS별 처리량·p95·실패유형·CPU·threads_connected·threads_running 리포트.
- “처리량이 꺾이는 지점 N RPS”를 실제 값으로 작성. 참고 예시800RPS를 본인 결과로 복사하지 않음.
- p95 Alert 실제 수신 스크린샷.
- 미션 기록에는 결과뿐 아니라 중간 과정·판단·트러블슈팅 포함.
- 스터디 사진·본인의 이해·UMC 제출은 사용자 영역.
선택 미션 토글은 비어 있다.

## 본문 수행 범위
- Grafana Cloud 무료 계정/스택, Prometheus endpoint/user 확인.
- Alloy용 set:alloy-data-write policy. read policy는3주차용이며 필요할 때만 생성.
- SSM의 Fleet URL/user, Prometheus URL/user, GC_TOKEN SecureString, MYSQL_DSN SecureString.
- EC2 두 대 Alloy v1.20.1, Fleet remotecfg 및 linux 매칭, host/mysql/app 세 pipeline 활성.
- /metrics, http_requests_total, http_request_duration_seconds bucket, Node runtime metrics.
- 공식 dashboard.json import, RDS 중복 수집은 max로 dedup.
- 단계마다 새 회원/JWT, counter 재시작 충돌 방지, 사전201 probe는 분리 ID.
- metrics만 필수. 본문에서 logs/trace 이번주 설치 제외라고 명시.

## 원문과 구현에서 구분할 점
- 기존 Infra는 ap-southeast-2(Sydney)에서 완료·정리됨. 예제 서울 리전을 무작정 섞지 않음.
- 예제 /v8/movie-records 대신 이 프로젝트 실제 경로 /movie-records 사용.
- 원문 알림 쿼리는5xx 비율인데 조건은 >1. 필수 p95 알림은 histogram_quantile(0.95,...) >1초로 별도 구성. 추가 오류율 알림은 >0.01.
- p95와p99, 1%와5%를 혼동하지 않음.
- 파라미터개수16이라는 고정 숫자보다 필요한 이름·타입·권한을 개별 확인.
- 공식 assets commit은 reference-commit.txt에 고정. 원격 Fleet 방식 사용, 대안 단일config로 Inventory등록을 대신했다고 주장하지 않음.
- 공개 HTTP에 JWT를 노출하지 않기 위해 internal ALB와 SSM tunnel을 계획. 계측기쪽 병목도 서버한계와 구분.

## 시작 상태 및 보존
브랜치: codex/infra-week-2 ← codex/infra-week-1 (29da879).
현재9주차 백엔드의 로컬 재실행 로그3개는 Git stash “preserve week9 local verification logs before Infra week2”에 보관. 원본 변경은 복원 대상이며 삭제하지 않음.
기존 backend/evidence/week4-postman/, evidence/week4/flutter_analyze.local.txt, evidence/week7-frontend/submission-responses/ 유지.
Infra1 .local은 그대로 보존하며 Infra2는 독립 .local 사용.
