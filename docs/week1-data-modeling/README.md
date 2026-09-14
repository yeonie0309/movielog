# 1주차 요구사항 데이터 모델링

## 범위

지역별 가게의 미션을 수행하고 보상을 얻는 서비스의 핵심 데이터를 설계했다.
워크북의 필수 범위인 로그인/회원가입, 지역·가게·음식 카테고리,
미션과 회원별 미션 수행 이력을 포함한다. IA/와이어프레임에서 확인한 가입 약관,
생년월일·주소, 선호 음식 조사, 미션 인증과 리뷰·사진 데이터도 함께 반영했다.

워크북에서 제외 가능하다고 명시한 지도·검색, 포인트 원장·알림 설정,
사장님의 점포 관리 기능은 이번 모델에서 제외했다. 따라서 “지역에서 미션 10개
완료 시 1,000 Point” 규칙은 `member_missions`의 완료 건수를 집계해 판단하되,
포인트 지급 내역 자체는 후속 범위로 남긴다.

## 요구사항에서 도출한 엔티티

| 테이블 | 역할 | 주요 관계 |
| --- | --- | --- |
| `members` | 회원 기본·거주 지역 정보와 탈퇴 상태 | 소셜 계정·수행 미션을 여러 개 가짐 |
| `social_accounts` | 소셜 로그인 제공자별 식별자 | 회원 N:1 |
| `regions` | 가게가 속한 지역, 상·하위 지역 | 자기 참조 N:1 |
| `food_categories` | 가게 음식 분류 | 가게 1:N |
| `terms` | 버전별 가입 약관 | 회원과 N:M |
| `member_terms` | 회원의 약관별 동의 여부와 시각 | 회원 N:1, 약관 N:1 |
| `member_food_categories` | 회원의 복수 선호 음식 | 회원 N:1, 카테고리 N:1 |
| `stores` | 지역별 가게 정보 | 지역 N:1, 카테고리 N:1, 미션 1:N |
| `missions` | 가게가 제공하는 수행 조건과 보상 | 가게 N:1 |
| `member_missions` | 회원과 미션의 N:M 관계 및 수행 상태 | 회원 N:1, 미션 N:1 |
| `reviews` | 완료 미션에 대한 별점·후기 | 회원 미션과 1:0..1 |
| `review_images` | 리뷰 첨부 이미지 | 리뷰 N:1 |

## 주요 설계 판단

- 모든 이름은 소문자 `snake_case`로 통일했다.
- 모든 테이블은 독립적인 `id BIGINT AUTO_INCREMENT` PK를 가진다.
- 모든 FK는 PK와 분리된 비식별 관계다.
- `member_missions`는 회원-미션 N:M 관계를 해소하는 매핑 테이블이다.
- `member_terms`, `member_food_categories`도 복수 선택을 중복 컬럼에 저장하지 않고
  N:M 매핑 테이블로 정규화했다.
- 회원은 여러 소셜 계정을 연결할 수 있지만, 같은 제공자는 한 번만 연결한다.
- 한 가게는 현재 하나의 대표 음식 카테고리를 갖는다고 가정했다. 여러 카테고리가
  필요해지면 `store_food_categories` 매핑 테이블로 확장한다.
- `members.deleted_at`으로 회원 탈퇴를 Soft Delete 처리한다. 참조 무결성과 운영
  이력을 보존하기 위해 지역·카테고리·가게·미션에도 `deleted_at`을 뒀다.
- 필수 관계와 화면 표시 필드는 `NOT NULL`, 프로필 부가 정보·이미지·기간처럼
  없을 수 있는 값은 `NULL`로 구분했다.
- 상태값은 문자열로 저장하되 `CHECK` 제약으로 허용값을 제한해 가독성과 안전성을
  함께 확보했다.
- FK 삭제 규칙은 `RESTRICT`로 두어 수행 이력이 연결된 데이터를 실수로 물리 삭제하지
  못하게 했다.
- 리뷰는 완료한 회원 미션 하나당 최대 하나만 작성할 수 있고, 첨부 사진은 별도
  `review_images`로 분리했다.
- 온보딩 배너·도움말은 정적 콘텐츠로 판단해 앱/콘텐츠 관리 영역으로 남겼다.

## 산출물

- [`schema.sql`](./schema.sql): ERDCloud/MySQL에서 사용할 수 있는 DDL과 제약조건
- [`schema.dbml`](./schema.dbml): DBML 지원 도구에서 바로 시각화할 수 있는 모델
- [`erd.mmd`](./erd.mmd): GitHub에서 관계를 빠르게 확인할 Mermaid ERD 원본

## ERDCloud 반영 절차

1. ERDCloud에서 새 프로젝트를 만들고 DB 종류를 MySQL로 선택한다.
2. DDL 가져오기 기능이 보이면 `schema.sql`을 붙여 넣어 테이블을 생성한다.
3. 가져오기 기능을 사용할 수 없다면 `schema.sql`의 순서대로 7개 테이블과 컬럼을
   만들고, 파일 하단의 FK 제약을 기준으로 관계를 연결한다.
4. 관계선은 모두 비식별 관계인지, 필수 FK는 `NOT NULL`인지 확인한다.
5. 전체 테이블명·컬럼명·타입·관계선이 보이도록 ERD를 캡처한다.

## 완료 집계 예시

포인트 테이블 없이도 아래처럼 회원이 특정 지역에서 완료한 서로 다른 미션 수를
계산할 수 있다. 결과가 10 이상이면 지역 완료 보상 지급 조건을 충족한다.

```sql
SELECT COUNT(DISTINCT mm.mission_id) AS completed_mission_count
FROM member_missions AS mm
JOIN missions AS m ON m.id = mm.mission_id
JOIN stores AS s ON s.id = m.store_id
WHERE mm.member_id = :member_id
  AND s.region_id = :region_id
  AND mm.status IN ('completed', 'claimed')
  AND m.deleted_at IS NULL
  AND s.deleted_at IS NULL;
```

## 체크리스트 자체 검토

- [x] IA/와이어프레임에서 저장이 필요한 12개 엔티티를 도출했다.
- [x] ERD 원본 3종(SQL, DBML, Mermaid)을 작성했다.
- [x] 테이블명과 컬럼명은 모두 소문자 `snake_case`다.
- [x] 모든 테이블의 PK는 `id BIGINT AUTO_INCREMENT`다.
- [x] 1:N 관계는 별도 PK를 가진 비식별 관계로 설계했다.
- [x] 회원-미션 N:M 관계에 `member_missions`를 뒀다.
- [x] 필수값과 선택값의 `NOT NULL` 여부를 구분했다.
- [x] 회원 탈퇴 및 운영 데이터 삭제를 위한 `deleted_at`을 고려했다.
- [ ] ERDCloud 새 프로젝트 생성 및 최종 캡처는 제출자가 직접 수행한다.
