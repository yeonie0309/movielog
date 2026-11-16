import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/workbook_client.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/widgets/movie/movie_card.dart';
import 'package:movielog/widgets/movie/rating_dialog.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/screens/my_ratings_screen.dart';

import '../test/week7_frontend_test.dart' as fixtures;
import '../test/week6_frontend_test.dart' show DetailFake;

Future<void> capture(WidgetTester tester, String name) async {
  // One frame may execute the deferred Navigator.pop; a second must finish its
  // exit animation before adb captures the compositor's physical screen.
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 350)),
  );
  // Marker consumed by the adb runner: screenshot is the actual emulator surface.
  // ignore: avoid_print
  print('WEEK7_CAPTURE=$name');
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 800)),
  );
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
  }
  expect(finder, findsWidgets, reason: '화면 대기 시간 초과');
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('공개 v6 실제 계정·TMDB 등록 조회 수정 삭제·최종409', (tester) async {
    await dotenv.load(fileName: '.env');
    final client = createWorkbookClient();
    addTearDown(client.close);
    final records = <Map<String, dynamic>>[];
    client.interceptors.add(
      InterceptorsWrapper(
        onResponse: (r, h) {
          records.add({
            'method': r.requestOptions.method,
            'path': r.requestOptions.path,
            'status': r.statusCode,
            'response': r.data,
            if (r.requestOptions.data is Map)
              'body': {
                for (final e in (r.requestOptions.data as Map).entries)
                  if (e.key != 'password') '${e.key}': e.value,
              },
          });
          h.next(r);
        },
        onError: (e, h) {
          records.add({
            'method': e.requestOptions.method,
            'path': e.requestOptions.path,
            'status': e.response?.statusCode,
            'response': e.response?.data,
          });
          h.next(e);
        },
      ),
    );
    final service = SignUpService(client);
    final ratings = RatingApiService(client);
    final session = LearningMemberSession();
    addTearDown(() async {
      // Only the unique member created by this run; no sample/other member data.
      final id = session.memberId;
      if (id == null) return;
      final rows = await ratings.fetchMyRatings(id);
      for (final row in rows) {
        await ratings.deleteRating(memberId: id, ratingId: row.ratingId);
      }
    });
    final router = AppRouter.create(
      initialLocation: '/register',
      useTmdb: true,
    );
    addTearDown(router.dispose);
    final tag = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    // Random password remains in memory only; never print/store its value.
    final password =
        'Aa1!${List.generate(16, (_) => Random.secure().nextInt(10)).join()}';
    var nickname = 'r$tag';
    var email = 'lea.w7.$tag@example.com';
    await tester.pumpWidget(
      MovieLogApp(
        routerConfig: router,
        memberCheckService: service,
        ratingApiService: ratings,
        learningSession: session,
      ),
    );
    await tester.pumpAndSettle();
    Future<void> enter(String key, String value) async {
      await tester.enterText(find.byKey(Key(key)), value);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
    }

    Future<void> check() async {
      await tap(tester, find.byKey(const Key('check-nickname-button')));
      await waitFor(tester, find.text('사용 가능한 닉네임입니다.'));
      await tap(tester, find.byKey(const Key('check-email-button')));
      await waitFor(tester, find.text('사용 가능한 이메일입니다.'));
    }

    await enter('nickname-field', nickname);
    await enter('email-field', email);
    await check();
    await enter('nickname-field', '${nickname}x');
    expect(find.text('사용 가능한 닉네임입니다.'), findsNothing);
    await capture(tester, '01-live-input-invalidated');
    await enter('nickname-field', nickname);
    await check();
    await enter('password-field', password);
    await tap(tester, find.byKey(const Key('terms-checkbox')));
    // Own disposable fixture wins the race AFTER both checks and BEFORE UI POST.
    final first = await service.signUp(
      CreateMemberRequest(email: email, nickname: nickname, password: password),
    );
    await tap(tester, find.byKey(const Key('sign-up-button')));
    await waitFor(tester, find.text('이미 사용 중인 이메일입니다.'));
    await capture(tester, '02-live-final-signup-409');
    nickname = 's$tag';
    email = 'lea.w7.second.$tag@example.com';
    await enter('nickname-field', nickname);
    await enter('email-field', email);
    await check();
    await tap(tester, find.byKey(const Key('sign-up-button')));
    await waitFor(tester, find.byType(MovieCard));
    expect(session.memberId, isNotNull);
    expect(session.memberId, isNot(1));
    await capture(tester, '03-live-signup-success');
    // ignore: avoid_print
    print('WEEK7_VIDEO_START=01-live-crud');
    final card = find.byType(MovieCard).first;
    final movieId = tester.widget<MovieCard>(card).movie.id;
    await tap(tester, card);
    await waitFor(tester, find.byKey(const Key('open-rating-dialog-button')));
    await tap(tester, find.byKey(const Key('open-rating-dialog-button')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MovieLogButton>(
            find.byKey(const Key('confirm-rating-button')),
          )
          .onPressed,
      isNull,
    );
    await capture(tester, '04-live-rating-unselected');
    await tester.enterText(
      find.byKey(const Key('rating-comment-field')),
      '레아 7주차 실제 API 검증',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tap(
      tester,
      find
          .descendant(
            of: find.byType(RatingDialog),
            matching: find.byIcon(Icons.star_rounded),
          )
          .at(3),
    );
    await tap(tester, find.byKey(const Key('confirm-rating-button')));
    await waitFor(
      tester,
      find.text('평점을 등록했습니다. 마이페이지의 "내가 등록한 평점"에서 확인할 수 있습니다.'),
    );
    await capture(tester, '05-live-rating-created-snackbar');
    router.go('/my');
    await tester.pumpAndSettle();
    await tap(tester, find.byKey(const Key('open-my-ratings')));
    await waitFor(tester, find.byKey(const Key('my-ratings-success')));
    expect(find.text('TMDB #$movieId'), findsOneWidget);
    expect(find.byKey(const Key('main-navigation-bar')), findsNothing);
    await capture(tester, '06-live-rating-list');
    final ownRows = await ratings.fetchMyRatings(session.memberId!);
    final ratingId = ownRows.single.ratingId;
    await tap(tester, find.byKey(Key('edit-rating-$ratingId')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('rating-comment-field')))
          .controller!
          .text,
      '레아 7주차 실제 API 검증',
    );
    await capture(tester, '07-live-edit-prefilled');
    await tester.enterText(
      find.byKey(const Key('rating-comment-field')),
      '수정 후 서버 재조회 확인',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tap(
      tester,
      find
          .descendant(
            of: find.byType(RatingDialog),
            matching: find.byIcon(Icons.star_rounded),
          )
          .at(4),
    );
    await tap(tester, find.byKey(const Key('confirm-rating-button')));
    await waitFor(tester, find.text('평점을 수정했습니다.'));
    await capture(tester, '08-live-updated-list');
    // Only records created above are addressed; no other member's data is read/changed.
    for (final check in <Future<void> Function()>[
      () async {
        try {
          await ratings.updateRating(
            memberId: session.memberId!,
            ratingId: ratingId,
            score: 6,
          );
        } on ArgumentError {
          /* client blocks; raw request verifies server */
        }
        await client.patch(
          '/v6/members/${session.memberId}/ratings/$ratingId',
          data: {'score': 6},
        );
      },
      () async {
        await client.patch(
          '/v6/members/${first.result!.memberId}/ratings/$ratingId',
          data: {'score': 4},
        );
      },
      () async {
        await client.post(
          '/v6/members/${session.memberId}/ratings',
          data: {'movieId': movieId, 'score': 4},
        );
      },
    ]) {
      try {
        await check();
        fail('오류 응답 필요');
      } on DioException catch (e) {
        expect([400, 403, 409], contains(e.response?.statusCode));
      }
    }
    await tap(tester, find.byKey(Key('delete-rating-$ratingId')));
    await tester.pumpAndSettle();
    await capture(tester, '09-live-delete-confirm');
    final before = records.where((r) => r['method'] == 'DELETE').length;
    await tap(tester, find.text('취소'));
    await tester.pumpAndSettle();
    expect(records.where((r) => r['method'] == 'DELETE').length, before);
    await capture(tester, '10-live-delete-cancelled');
    await tap(tester, find.byKey(Key('delete-rating-$ratingId')));
    await tester.pumpAndSettle();
    await tap(tester, find.text('삭제'));
    await waitFor(tester, find.byKey(const Key('my-ratings-empty')));
    await capture(tester, '11-live-delete-empty');
    expect(await ratings.fetchMyRatings(session.memberId!), isEmpty);
    try {
      await ratings.deleteRating(
        memberId: session.memberId!,
        ratingId: ratingId,
      );
      fail('404 필요');
    } on DioException catch (e) {
      expect(e.response?.statusCode, 404);
    }
    // ignore: avoid_print
    print('WEEK7_VIDEO_STOP=01-live-crud');
    expect(
      records.any(
        (r) =>
            r['status'] == 204 &&
            (r['response'] == null || r['response'] == ''),
      ),
      isTrue,
    );
    // Safe evidence never includes password/header/token; all accounts are test-only.
    // ignore: avoid_print
    print(
      'WEEK7_LIVE_JSON=${jsonEncode({'memberId': session.memberId, 'raceFixtureMemberId': first.result!.memberId, 'email': email, 'nickname': nickname, 'movieId': movieId, 'ratingId': ratingId, 'requests': records, 'cleanup': '본 실행 평점 삭제 및 빈 배열 확인. 회원 삭제 API가 없어 테스트 회원 2명은 남음.'})}',
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('주입 테스트: 저장실패·GET만 재시도·다중삭제 부분실패', (tester) async {
    final api = fixtures.RatingsWriteFake()..rows = [fixtures.makeRating(11)];
    final vm = MyRatingsViewModel(api, DetailFake(), 77);
    await vm.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: MyRatingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('WEEK7_VIDEO_START=02-injected-recovery');
    await tap(tester, find.byKey(const Key('edit-rating-11')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('rating-comment-field')),
      '실패해도 보존할 입력',
    );
    api.failure = fixtures.apiError(400, '별점은 5점 이하여야 합니다.');
    await tap(tester, find.byKey(const Key('confirm-rating-button')));
    await waitFor(tester, find.text('별점은 5점 이하여야 합니다.'));
    await capture(tester, '12-injected-write-failure-input-retained');
    api.failure = null;
    api.failGet = true;
    await tap(tester, find.byKey(const Key('confirm-rating-button')));
    await waitFor(tester, find.byKey(const Key('my-ratings-error')));
    await capture(tester, '13-injected-write-success-get-error');
    final writes = api.writes;
    api.failGet = false;
    await tap(tester, find.text('다시 시도'));
    await waitFor(tester, find.byKey(const Key('my-ratings-success')));
    expect(api.writes, writes);
    await capture(tester, '14-injected-get-only-retry');
    api.rows = [fixtures.makeRating(11), fixtures.makeRating(12)];
    await vm.load();
    await tester.pumpAndSettle();
    await tap(tester, find.text('편집'));
    await tester.pumpAndSettle();
    await tap(tester, find.byType(Checkbox).at(0));
    await tap(tester, find.byType(Checkbox).at(1));
    await capture(tester, '15-injected-multiple-selection');
    api.failDeleteIds.add(12);
    api.gate = Completer<void>();
    await tap(tester, find.text('선택한 2개 삭제'));
    await tester.pumpAndSettle();
    await tap(tester, find.text('삭제'));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    await capture(tester, '16-injected-bulk-loading-overlay');
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(MyRatingsScreen), findsOneWidget);
    api.gate!.complete();
    await waitFor(tester, find.text('1개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.'));
    expect(vm.selectedRatingIds, {12});
    await capture(tester, '17-injected-partial-delete');
    // ignore: avoid_print
    print('WEEK7_VIDEO_STOP=02-injected-recovery');
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
