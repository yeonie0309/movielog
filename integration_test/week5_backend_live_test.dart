import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실제 NestJS/MySQL API 3개를 Flutter 화면에서 조회', (tester) async {
    final router = AppRouter.create(initialLocation: '/register');
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(routerConfig: router));

    for (final [nickname, email, result] in [
      ['수현', 'noco@umc.com', '이미 사용 중인'],
      ['새닉네임', 'new@example.com', '사용 가능한'],
    ]) {
      await tester.enterText(find.byKey(const Key('nickname-field')), nickname);
      await tester.ensureVisible(
        find.byKey(const Key('check-nickname-button')),
      );
      await tester.tap(find.byKey(const Key('check-nickname-button')));
      await waitFor(tester, find.text('$result 닉네임입니다.'));
      await tester.enterText(find.byKey(const Key('email-field')), email);
      await tester.ensureVisible(find.byKey(const Key('check-email-button')));
      await tester.tap(find.byKey(const Key('check-email-button')));
      await waitFor(tester, find.text('$result 이메일입니다.'));
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await capture(
        tester,
        nickname == '수현' ? '06-app-duplicate' : '07-app-available',
      );
    }
    router.go('/my');
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('open-member-ratings-button')),
    );
    await tester.tap(find.byKey(const Key('open-member-ratings-button')));
    await tester.pumpAndSettle();

    for (final [id, key, image] in [
      ['1', 'member-ratings-count', '08-app-ratings'],
      ['3', 'member-ratings-empty', '09-app-empty'],
      ['999', 'member-ratings-error', '10-app-not-found'],
    ]) {
      // 숫자 IME가 합성 입력을 이전 값으로 덮어쓰는 에뮬레이터 동작을 피합니다.
      // 실제 화면의 Controller 값만 설정하며 API·응답은 대체하지 않습니다.
      final field = tester.widget<TextField>(
        find.byKey(const Key('ratings-member-id-field')),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      field.controller!.value = TextEditingValue(
        text: id,
        selection: TextSelection.collapsed(offset: id.length),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('ratings-member-id-field')))
            .controller!
            .text,
        id,
      );
      await tester.ensureVisible(
        find.byKey(const Key('load-member-ratings-button')),
      );
      await tester.tap(find.byKey(const Key('load-member-ratings-button')));
      await waitFor(tester, find.byKey(Key(key)));
      if (id == '1') {
        expect(find.text('회원 1 · 평점 2건 · 최신 등록순'), findsOneWidget);
        expect(find.text('TMDB 영화 #155 · 4점'), findsOneWidget);
        expect(find.text('TMDB 영화 #550 · 5점'), findsOneWidget);
      }
      if (id == '999') expect(find.text('존재하지 않는 유저입니다.'), findsOneWidget);
      await capture(tester, image);
    }
  });
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 25; i++) {
    await tester.pump(const Duration(milliseconds: 400));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
  }
  fail('실제 API 결과를 기다리다 시간이 초과됐습니다.');
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  // ignore: avoid_print
  print('WEEK5_BACKEND_CAPTURE=$name');
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 6)));
}
