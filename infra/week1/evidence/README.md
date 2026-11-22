# 증빙과 원본 파일

| 사진 | 실제 출처 | 개인 노션 첨부 위치 |
| --- | --- | --- |
| `01-before-result.jpg` | 공식 도구 결과 영역 캡처 | 필수 미션 표 아래·미션 기록의 단일 배포 |
| `01-before.jpg` | 대상 URL·조건을 포함한 공식 도구 전체 화면 | 위 사진의 실행 조건 보충 |
| `02-targets-healthy.jpg` | 실제 AWS EC2 콘솔 | 미션 기록의 ALB·두 타겟 구성 |
| `03-draining-30s.jpg` | 실제 AWS 대상 그룹 속성 콘솔 | draining 설명·구성 |
| `04-health-check.jpg` | 실제 AWS 대상 그룹 헬스 체크 콘솔 | `/health`·성공 코드·간격 설명 |
| `05-after-result.jpg`, `05-after.jpg` | 공식 도구 결과·전체 화면 | 필수 미션 표 아래·무중단 배포 |
| `06-fault-rollback-result.jpg`, `06-fault-rollback.jpg` | 공식 도구 결과·전체 화면 | 선택 미션·실패/롤백 과정 |
| `07-measurement-table.jpg` | 실제 export JSON을 읽는 결과 뷰어 | before/after 표·선택 미션 요약 |
| `08-fault-rollback-log.jpg` | 실제 AWS CLI/SSM 로그 발췌 뷰어 | 선택 미션의 HTTP 500·STOPPED·200 유지·롤백 증거 |
| `09-verification-log.jpg` | 실제 테스트 CLI 출력·검증 JSON 뷰어 | 미션 기록의 테스트 |
| `10-aws-security-log.jpg` | 실제 AWS API/SSM 출력 뷰어 | DB 비공개·암호화·파라미터 타입·EC2 역할 검증 |
| `11-cleanup-log.jpg` | 실제 삭제 완료 조회 결과 뷰어 | 미션 기록 마지막 자원 정리 |

`*-result.jpg`는 같은 실제 화면의 결과 부분을 읽기 쉽게 캡처한 사진이다. 전체 화면도 함께 보관한다. 로그 뷰어 사진은 저장된 실제 파일을 표시한 화면이며, 원본은 아래 파일이다.

- `before.json`, `after.json`, `fault-rollback.json`: 공식 도구 export 원본. 시나리오·요약·초별 bucket 포함.
- `before-deployment.txt`, `after-deployment.txt`, `fault-rollback-deployment.txt`: 측정과 실제 배포의 실행 출력.
- `aws-configuration.json`: 실제 RDS·보안 그룹·SSM 타입·ASG·타겟·각 서버의 실행 결과.
- `cleanup.json`: 삭제 완료 확인. 실습 EC2·RDS·ALB·EBS·ALB 공인 IP 모두 0.
- `backend-tests.txt`, `backend-types.txt`, `rolling-safety-tests.txt`, `verification.json`: 최종 테스트·타입·비밀값 검사 결과.
- `preflight-timeout-2s.json`, `preflight-docker-stop-flag.json`: 중단되거나 배포가 실행되지 않은 사전 시도. 최종 성공 결과와 구분한다.
- `index.html`: 위 실제 파일로 만든 읽기용 뷰어. 재생성은 `python3 infra/week1/build_report.py`.

공식 도구 커밋은 `7377201431ee6477a35f447b6b1667385560167a`다. 실행 조건·완료 결과 복원을 위한 UI patch만 적용했고 측정 엔진은 변경하지 않았다.

0주차 사진은 저장소 루트 기준 `infra/week0/evidence/00-free-plan-user-provided.png`에 있다. 사용자가 직접 제공한 가입 직후 화면이다.

스터디 인증 칸에는 실제 스터디 사진을 직접 넣는다. 위 실행 증빙은 미션 기록과 필수/선택 미션에 첨부한다. UMC 제출은 직접 진행한다.
