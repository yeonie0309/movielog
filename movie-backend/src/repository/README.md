# Repository 레이어

워크북 NestJS 예제와 같이 `TypeOrmModule.forFeature([Member, Rating])`와
`@InjectRepository`로 TypeORM `Repository<Entity>`를 Service에 주입합니다.
단순 조회를 다시 감싸는 사용자 정의 Repository는 만들지 않습니다.
