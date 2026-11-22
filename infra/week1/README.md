# Infra 1주차 — MovieLog 배포 실습

이 디렉터리는 기존 Flutter·도서 API·MovieLog API 과제를 보존하면서 MovieLog 백엔드만 AWS에 배포하는 실습이다. 원본은 [Infra 레아의 워크북 1주차](https://app.notion.com/p/makeus-challenge/1-c78b57f4596b8297958e819532236eee)다. CI/CD 구축은 범위에 포함하지 않는다.

## 구성

- Sydney 기본 VPC의 EC2 → 비공개 RDS MySQL. EC2/DB 스토리지는 암호화한다.
- Before: 한 대의 EC2에서 컨테이너를 직접 교체. 측정기 IP만 3000 포트에 접근한다.
- After: ALB → ASG EC2 두 대. 앱 3000 포트의 접근 소스는 ALB 보안 그룹만 허용한다.
- 공개 HTTP 리스너는 `/health`만 전달한다. 나머지 경로는 404로 차단한다. 인증·개인정보 API를 HTTP로 호출하지 않는다.
- EC2는 SSH 대신 SSM으로 관리한다. AMI에 기본 설치된 AWS CLI를 사용한다.
- ECR에는 버전·날짜·빌드 번호를 사용한 immutable 태그를 저장한다.
- 설정은 `/umc/app/*`의 SSM Parameter Store에 저장한다. 비밀번호·JWT 비밀키는 SecureString이다.
- 앱 DB 사용자는 실습 DB의 SELECT/INSERT/UPDATE/DELETE만 허용한다. 초기화용 master 파라미터는 초기화 후 삭제한다.
- ASG는 EC2 상태 확인을 사용한다. 의도적인 앱 헬스 체크 실패를 자동 교체로 숨기지 않고 중단·복구 과정을 관찰하기 위한 실습 설정이다.

## 파일

| 파일 | 역할 |
| --- | --- |
| `manage.py` | AWS 생성·상태·단일 EC2·ALB/ASG·배포·감사·정리 |
| `swap.sh` | SSM/ECR 설정 읽기 → 이미지 pull → SIGTERM 종료 → 컨테이너 교체 → readiness 확인 |
| `deploy.sh` | 워크북 형태의 진입점. 동일한 Python 배포 루프를 실행 |
| `lab.py` | 공식 측정 도구 API로 실제 before/after·실패/롤백 측정 및 원본 JSON 보관 |
| `test_manage.py` | 실패 후 다음 서버 진행 방지·정상 peer 보존·복구 순서 테스트 |
| `Dockerfile.fault` | 선택 미션 전용 /health HTTP 500 이미지. 일반 배포 빌드와 분리 |
| `monitor-ui-recovery.patch` | 공식 도구에서 새로고침 시 실제 실행 조건 복원·완료된 run 조회를 위한 UI 보정 |
| `build_report.py` | 보관한 실제 JSON·CLI 로그를 읽는 제출용 증빙 뷰어 생성 |

운영 상태와 생성된 비밀값은 Git에서 제외된 `.local/`에만 보관한다. 상태 파일은 0600, 디렉터리는 0700이다. 비밀값을 CLI 인자나 로그에 직접 넣지 않는다. AWS 요청 본문은 권한 0600 임시 JSON 파일로 전달하고 즉시 제거한다.

## 단계별 재현

이 명령들은 AWS 리소스와 크레딧을 사용한다. 프로필·리전을 확인하고 개인 실습 계정에서만 실행한다. 이미 정리한 실습의 상태 파일을 재활용해 새 리소스를 생성하지 않는다.

```bash
aws login --profile umc-infra --region ap-southeast-2
python3 infra/week1/manage.py inspect
python3 infra/week1/manage.py foundation
```

MovieLog Docker 이미지를 ARM64로 빌드한 뒤 `MOVIELOG_IMAGE_TAG`에 같은 태그를 지정해 `manage.py push-image`로 ECR에 업로드한다. RDS가 available이 되면 `baseline` → `init-db`를 실행한다. `status`에서 단일 서버 public IP를 기록한다.

공식 도구: [zero-downtime-lab](https://github.com/UMC-11th-Workbook-Infra/zero-downtime-lab), 사용 커밋 `7377201431ee6477a35f447b6b1667385560167a`. Mac의 127.0.0.1:9376에만 실행한다. 측정 엔진·통계·순단 판정 코드는 수정하지 않았다. UI 보정은 실제 run의 export JSON에서 폼을 복원하며, `?run=<runId>`로 과거 실행을 표시한다. 변경 내용은 patch로 공개한다.

```bash
# 공식 도구가 실행 중이어야 한다.
python3 infra/week1/lab.py before
# before 원본 저장 및 사진 캡처 후에만 단일 서버를 정리한다.
python3 infra/week1/manage.py end-baseline
# 단일 서버 terminated 확인 후 실행한다.
python3 infra/week1/manage.py cluster
python3 infra/week1/manage.py targets
# healthy 두 대를 확인하고 다음 이미지 버전을 올린 후 실행한다.
python3 infra/week1/lab.py after
```

배포는 peer가 healthy인지 확인한 뒤 한 대씩 수행한다. `deregister` 후 draining 완료를 기다리고, SSM의 Pending/InProgress/Delayed를 모두 대기한다. 컨테이너 readiness와 ALB healthy까지 확인해야 다음 서버로 진행한다. 실패하면 다음 서버를 건드리지 않고 신규 인스턴스용 이미지 포인터를 이전 값으로 복구한다. 이미 실패한 서버는 별도 롤백으로 복구하며, 이때 out-of-service 서버부터 처리한다.

선택 미션은 `Dockerfile.fault`로 별도 이미지를 빌드하고 `MOVIELOG_IMAGE_KIND=fault`로 업로드한 다음 `lab.py fault-rollback`을 실행한다. 실패 이미지의 실제 HTTP 500, 남은 healthy 서버의 HTTP 200, 중단 지점, 정상 이미지 롤백을 확인한다.

## 완료 기준

- 측정 전 baseline이 완료되고 실패율 0인지 확인한다.
- GET `/health`, RPS, 타임아웃, 순단 판정 임계값을 before/after에서 동일하게 사용한다.
- 최종 표의 수치는 `evidence/before.json`, `evidence/after.json`의 실제 summary에서 가져온다.
- 실패·중단된 사전 시도도 별도 JSON으로 보관하며 최종 성공 결과와 구분한다.
- `dropped`, baseline, warnings, 실패 유형을 확인한다. 0건/0ms는 해당 측정 구간에서 관측한 결과이지 모든 상황의 무중단 보장은 아니다.
- `audit`으로 DB 비공개·보안 그룹·SecureString 타입·실행 이미지·타겟 상태를 검증한다.
- 증빙 보관 후 `cleanup-start` → 삭제 완료 확인 → `cleanup-finish`를 실행한다. 기본 VPC·서브넷과 기존 로컬 DB는 정리 대상에서 제외한다.

## 공식 참고 자료

- [ALB 타겟 그룹 속성 — deregistration delay](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/edit-target-group-attributes.html)
- [ALB 헬스 체크](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/target-group-health-checks.html)
- [SSM SecureString과 KMS](https://docs.aws.amazon.com/systems-manager/latest/userguide/secure-string-parameter-kms-encryption.html)
- [EC2 instance profile](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)
- [NestJS lifecycle과 shutdown hook](https://docs.nestjs.com/fundamentals/lifecycle-events)
