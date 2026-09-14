import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const schemaPath = 'docs/week1-data-modeling/schema.sql';

  late String schema;

  setUpAll(() {
    schema = File(schemaPath).readAsStringSync();
  });

  test('IA와 와이어프레임에서 도출한 엔티티 12개가 모두 정의되어 있다', () {
    const requiredTables = <String>{
      'members',
      'social_accounts',
      'regions',
      'food_categories',
      'terms',
      'member_terms',
      'member_food_categories',
      'stores',
      'missions',
      'member_missions',
      'reviews',
      'review_images',
    };

    final tableNames = RegExp(r'CREATE TABLE ([a-z_]+)')
        .allMatches(schema)
        .map((match) => match.group(1))
        .toSet();

    expect(tableNames, requiredTables);
  });

  test('모든 테이블이 동일한 BIGINT 자동 증가 PK를 사용한다', () {
    final tableDefinitions = RegExp(
      r'CREATE TABLE [a-z_]+ \((.*?)\) ENGINE',
      dotAll: true,
    ).allMatches(schema);

    expect(tableDefinitions.length, 12);
    for (final table in tableDefinitions) {
      final definition = table.group(1)!;
      expect(
        definition,
        contains('id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT'),
      );
      expect(definition, contains('PRIMARY KEY (id)'));
    }
  });

  test('회원-미션 매핑과 Soft Delete가 설계되어 있다', () {
    expect(schema, contains('UNIQUE KEY uk_member_missions_member_mission'));
    expect(schema, contains('FOREIGN KEY (member_id) REFERENCES members (id)'));
    expect(
      schema,
      contains('FOREIGN KEY (mission_id) REFERENCES missions (id)'),
    );
    expect(schema, contains('deleted_at DATETIME(6) NULL'));
  });

  test('가입 선호 조사와 리뷰 관계가 정규화되어 있다', () {
    expect(schema, contains('CREATE TABLE member_terms'));
    expect(schema, contains('CREATE TABLE member_food_categories'));
    expect(schema, contains('CREATE TABLE reviews'));
    expect(schema, contains('CREATE TABLE review_images'));
    expect(schema, contains('UNIQUE KEY uk_reviews_member_mission_id'));
  });
}
