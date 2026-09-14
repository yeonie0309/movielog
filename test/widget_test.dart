import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/screens/start_screen.dart';

void main() {
  testWidgets('1주차 프로필 화면의 필수 정보를 표시한다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('무비러버'), findsOneWidget);
    expect(find.text('342'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('58'), findsOneWidget);
    expect(find.text('드라마'), findsOneWidget);
    expect(find.text('SF'), findsOneWidget);
    expect(find.text('애니메이션'), findsOneWidget);
    expect(find.text('프로필 수정'), findsOneWidget);
  });

  testWidgets('0주차 시작 화면을 보존하고 실제 로고를 표시한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: StartScreen()));

    expect(find.text('FLUTTER 0주차'), findsOneWidget);
    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
