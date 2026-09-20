import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const directory = 'docs/week2-sql';

  late String schema;
  late String seed;
  late String requiredQueries;
  late String extensionQuery;

  setUpAll(() {
    schema = File('$directory/01_schema.sql').readAsStringSync();
    seed = File('$directory/02_seed.sql').readAsStringSync();
    requiredQueries = File('$directory/03_required_queries.sql')
        .readAsStringSync();
    extensionQuery = File('$directory/05_movielog_extension_query.sql')
        .readAsStringSync();
  });

  test('공통 ERD의 8개 테이블과 PK/FK 관계를 정의한다', () {
    const requiredTables = <String>{
      'users',
      'category',
      'book',
      'rental',
      'tag',
      'book_tag',
      'book_like',
      'notification',
    };

    final tableNames = RegExp(r'CREATE TABLE ([a-z_]+)')
        .allMatches(schema)
        .map((match) => match.group(1))
        .toSet();

    expect(tableNames, requiredTables);
    expect(schema, contains('FOREIGN KEY (category_id) REFERENCES category'));
    expect(schema, contains('FOREIGN KEY (user_id) REFERENCES users'));
    expect(schema, contains('FOREIGN KEY (book_id) REFERENCES book'));
    expect(schema, contains('FOREIGN KEY (tag_id) REFERENCES tag'));
  });

  test('공통 더미 데이터가 모든 실습 관계를 포함한다', () {
    for (final table in <String>[
      'users',
      'category',
      'book',
      'rental',
      'tag',
      'book_tag',
      'book_like',
      'notification',
    ]) {
      expect(seed, contains('INSERT INTO $table'));
    }

    expect(seed, contains("'달빛 도서관'"));
    expect(seed, contains("'겨울의 편지'"));
    expect(seed, contains("'우주를 읽는 법'"));
  });

  test('Required Mission 3개가 JOIN, WHERE, 정렬과 범위를 사용한다', () {
    expect(RegExp(r'-- 미션 [123]').allMatches(requiredQueries).length, 3);
    expect(requiredQueries, contains('WHERE b.is_available = TRUE'));
    expect(requiredQueries, contains('JOIN category AS c'));
    expect(requiredQueries, contains('JOIN book AS b'));
    expect(requiredQueries, contains('LEFT JOIN book_tag AS bt'));
    expect(requiredQueries, contains("WHERE c.name = '문학'"));
    expect(requiredQueries, contains('r.returned_at IS NULL'));
    expect(requiredQueries, contains('WHERE b.book_id = @book_id'));
    expect(requiredQueries, contains('ORDER BY b.book_id DESC'));
    expect(requiredQueries, contains('LIMIT 10 OFFSET 0'));
  });

  test('MovieLog 확장 쿼리는 진행 중 미션을 높은 보상순으로 조회한다', () {
    expect(extensionQuery, contains('FROM member_missions AS mm'));
    expect(extensionQuery, contains('JOIN missions AS m'));
    expect(extensionQuery, contains('JOIN stores AS s'));
    expect(extensionQuery, contains('mm.member_id = @member_id'));
    expect(
      extensionQuery,
      contains("'accepted', 'in_progress', 'verification_requested'"),
    );
    expect(extensionQuery, contains('ORDER BY m.reward_points DESC'));
    expect(extensionQuery, contains('LIMIT 10 OFFSET 0'));
  });
}
