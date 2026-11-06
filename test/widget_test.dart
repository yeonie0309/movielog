import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/profile_screen.dart';
import 'package:movielog/screens/start_screen.dart';

void main() {
  Future<void> pumpMovieLogAt(
    WidgetTester tester,
    String initialLocation,
  ) async {
    final router = AppRouter.create(initialLocation: initialLocation);
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(routerConfig: router));
    await tester.pumpAndSettle();
  }

  testWidgets('2주차 회원가입 화면의 필수 입력과 비활성 버튼을 표시한다', (tester) async {
    await pumpMovieLogAt(tester, '/register');

    expect(find.text('회원가입'), findsOneWidget);
    expect(find.byKey(const Key('nickname-field')), findsOneWidget);
    expect(find.byKey(const Key('email-field')), findsOneWidget);
    expect(find.byKey(const Key('password-field')), findsOneWidget);
    expect(find.byKey(const Key('terms-checkbox')), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('sign-up-button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('잘못된 입력에 Validation 메시지를 표시한다', (tester) async {
    await pumpMovieLogAt(tester, '/register');

    await tester.enterText(find.byKey(const Key('nickname-field')), '가');
    await tester.enterText(find.byKey(const Key('email-field')), 'wrong-email');
    await tester.enterText(find.byKey(const Key('password-field')), '1234');
    await tester.pump();

    expect(find.text('닉네임은 두 글자 이상 입력해 주세요.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식을 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상 입력해 주세요.'), findsOneWidget);
  });

  testWidgets('모든 입력과 약관 동의가 유효하면 가입할 수 있다', (tester) async {
    await pumpMovieLogAt(tester, '/register');

    await tester.enterText(find.byKey(const Key('nickname-field')), '무비러버');
    await tester.enterText(
      find.byKey(const Key('email-field')),
      'movie@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('terms-checkbox')));
    await tester.tap(find.byKey(const Key('terms-checkbox')));
    await tester.pump();

    final enabledButton = tester.widget<FilledButton>(
      find.byKey(const Key('sign-up-button')),
    );
    expect(enabledButton.onPressed, isNotNull);

    await tester.ensureVisible(find.byKey(const Key('sign-up-button')));
    await tester.tap(find.byKey(const Key('sign-up-button')));
    await tester.pumpAndSettle();

    expect(find.text('오늘의 영화 한 편을 기록해 보세요.'), findsOneWidget);
    expect(find.byKey(const Key('main-navigation-bar')), findsOneWidget);
  });

  testWidgets('별점을 선택하면 평점 저장 버튼이 활성화된다', (tester) async {
    await pumpMovieLogAt(tester, '/register');

    await tester.ensureVisible(
      find.byKey(const Key('open-rating-practice-button')),
    );
    await tester.tap(find.byKey(const Key('open-rating-practice-button')));
    await tester.pumpAndSettle();

    expect(find.text('영화 평점 남기기'), findsOneWidget);
    var saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('save-rating-button')),
    );
    expect(saveButton.onPressed, isNull);

    await tester.tap(find.byIcon(Icons.star_rounded).at(3));
    await tester.pump();

    saveButton = tester.widget<FilledButton>(
      find.byKey(const Key('save-rating-button')),
    );
    expect(saveButton.onPressed, isNotNull);
    expect(find.textContaining('선택한 평점:'), findsOneWidget);
  });

  testWidgets('1주차 프로필 화면을 보존한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));

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
