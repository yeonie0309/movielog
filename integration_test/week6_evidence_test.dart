import 'dart:async';

import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/network/workbook_client.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/widgets/movielog_button.dart';

import '../test/week6_frontend_test.dart' as fixtures;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실제 공개 v5·TMDB 조회 및 회원가입/마이페이지 경로 검증', (tester) async {
    await dotenv.load(fileName: '.env');
    final client = createWorkbookClient();
    final checkPaths = <String>[];
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (!options.path.endsWith('/ratings')) checkPaths.add(options.path);
          handler.next(options);
        },
      ),
    );
    final router = AppRouter.create(initialLocation: '/register');
    addTearDown(router.dispose);
    addTearDown(() => client.close());
    await tester.pumpWidget(
      MovieLogApp(
        routerConfig: router,
        memberCheckService: MemberCheckService(client),
        ratingApiService: RatingApiService(client),
      ),
    );
    await tester.pumpAndSettle();
    await capture(tester, '01-live-before');
    Future<void> enter(String key, String value) async {
      await tester.enterText(find.byKey(Key(key)), value);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
    }

    await enter('nickname-field', '영화광');
    await tester.tap(find.byKey(const Key('check-nickname-button')));
    await waitFor(tester, find.text('이미 사용 중인 닉네임입니다.'));
    await enter('email-field', 'movie@umc.com');
    await tester.tap(find.byKey(const Key('check-email-button')));
    await waitFor(tester, find.text('이미 사용 중인 이메일입니다.'));
    await capture(tester, '02-live-duplicated');

    await enter('nickname-field', '레아W6_20261103');
    await enter('email-field', 'lea.week6.20261103@example.com');
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsNothing);
    await capture(tester, '03-live-invalidated');

    // Both last-duplicate values are restored without tapping either button.
    await enter('nickname-field', '영화광');
    await enter('email-field', 'movie@umc.com');
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    expect(find.text('이미 사용 중인 이메일입니다.'), findsOneWidget);
    await capture(tester, '04-live-reentered-duplicate');
    expect(checkPaths.length, 2, reason: '편집·동일 중복 재입력은 GET 추가 호출 없음');

    await enter('nickname-field', '레아W6_20261103');
    await enter('email-field', 'lea.week6.20261103@example.com');
    await tester.tap(find.byKey(const Key('check-nickname-button')));
    await waitFor(tester, find.text('사용 가능한 닉네임입니다.'));
    await tester.tap(find.byKey(const Key('check-email-button')));
    await waitFor(tester, find.text('사용 가능한 이메일입니다.'));
    await capture(tester, '05-live-available');

    router.go('/my');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('open-my-ratings')));
    await capture(tester, '06-live-my-page');
    await tester.tap(find.byKey(const Key('open-my-ratings')));
    await waitFor(tester, find.byKey(const Key('my-ratings-success')));
    // Let real poster image requests complete; no network response is replaced.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pumpAndSettle();
    expect(find.text('일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.'), findsNothing);
    expect(find.byKey(const Key('main-navigation-bar')), findsNothing);
    expect(find.text('TMDB #13'), findsOneWidget);
    await capture(tester, '07-live-ratings-success');
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('main-navigation-bar')), findsOneWidget);
  });

  testWidgets('테스트 서비스로 통신중·실패·Empty·Error·재시도 재현', (tester) async {
    final checks = fixtures.CheckFake()..pending = Completer<bool>();
    var router = AppRouter.create(initialLocation: '/register');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      labeled(
        '테스트 서비스 · 지연 응답 재현',
        MovieLogApp(routerConfig: router, memberCheckService: checks),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('nickname-field')), '닉네임');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('check-nickname-button')));
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, '08-test-check-loading', settle: false);
    checks.pending!.completeError(fixtures.httpError(503));
    await tester.pumpAndSettle();
    await capture(tester, '09-test-check-network-error');

    await tester.pumpWidget(const SizedBox.shrink());
    final ratings = fixtures.RatingsFake()..pending = Completer();
    router = AppRouter.create(initialLocation: '/my/ratings');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      labeled(
        '테스트 서비스 · 평점 상태 재현 (회원 1 고정)',
        MovieLogApp(
          routerConfig: router,
          ratingApiService: ratings,
          movieDetailService: fixtures.DetailFake(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, '10-test-ratings-loading', settle: false);
    ratings.pending!.complete([]);
    ratings.pending = null;
    ratings.rows = [];
    await tester.pumpAndSettle();
    await capture(tester, '11-test-ratings-empty');
    ratings.failureCode = 503;
    await tester.tap(find.byTooltip('새로고침'));
    await tester.pumpAndSettle();
    await capture(tester, '12-test-ratings-error');
    ratings.failureCode = null;
    ratings.rows = [fixtures.sampleRating];
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-ratings-success')), findsOneWidget);
    await capture(tester, '13-test-ratings-retry-success');

    await tester.pumpWidget(
      labeled(
        '테스트 서비스 · MovieLogButton 너비 비교',
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            appBar: AppBar(title: const Text('MovieLogButton · width')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('null · Row에서 내용만큼'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      MovieLogButton(label: '중복 확인', onPressed: () {}),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('double.infinity · 부모 너비 전체'),
                  const SizedBox(height: 8),
                  MovieLogButton(
                    label: '가입하기',
                    width: double.infinity,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 24),
                  const Text('96 · 고정 너비'),
                  const SizedBox(height: 8),
                  MovieLogButton(label: '중복 확인', width: 96, onPressed: () {}),
                  const SizedBox(height: 24),
                  const Text('isLoading · 비활성 + 중앙 인디케이터'),
                  const SizedBox(height: 8),
                  MovieLogButton(
                    label: '라벨 숨김',
                    width: 96,
                    isLoading: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, '14-test-button-widths', settle: false);
    expect(tester.takeException(), isNull);
  });
}

Widget labeled(String label, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Material(
        color: Colors.amber.shade100,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black),
            ),
          ),
        ),
      ),
      Expanded(child: child),
    ],
  ),
);

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 75; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
  }
  fail('공개 API 결과 대기 시간 초과: $finder');
}

Future<void> capture(
  WidgetTester tester,
  String name, {
  bool settle = true,
}) async {
  if (settle) await tester.pumpAndSettle();
  // ignore: avoid_print
  print('WEEK6_CAPTURE=$name');
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
}
