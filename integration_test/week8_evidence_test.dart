import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/workbook_client.dart';
import 'package:movielog/data/models/auth_models.dart';
import 'package:movielog/data/models/member_rating.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/token_storage.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/movie/rating_dialog.dart';

import '../test/week8_auth_test.dart' show AuthFake, authError;

Future<void> pause(WidgetTester tester, [int ms = 300]) async {
  await tester.pump(Duration(milliseconds: ms));
  await tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await pause(tester, 100);
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets, reason: '화면 대기 시간 초과');
}

Future<void> tap(WidgetTester tester, Finder finder) async {
  await pause(tester, 300);
  await tester.ensureVisible(finder);
  await pause(tester, 200);
  await tester.tap(finder);
  await pause(tester, 400);
}

Future<void> enter(WidgetTester tester, Finder finder, String value) async {
  await tap(tester, finder);
  await tester.enterText(finder, value);
  await pause(tester, 300);
  final field = tester.widget(finder);
  final controller = field is TextField
      ? field.controller
      : (field as TextFormField).controller;
  expect(
    controller?.text == value,
    isTrue,
    reason: '입력값이 화면 controller에 반영되어야 함',
  );
}

Future<void> capture(WidgetTester tester, String name) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await pause(tester, 600);
  await pause(tester, 600);
  // ignore: avoid_print
  print('WEEK8_CAPTURE=$name');
  await pause(tester, 900);
}

Object? safe(Object? value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (!{
              'password',
              'accesstoken',
              'authorization',
            }.contains('${entry.key}'.toLowerCase()) &&
            entry.key != 'accessToken')
          '${entry.key}': safe(entry.value),
    };
  }
  if (value is List) {
    return value.map(safe).toList();
  }
  return value;
}

void observe(Dio client, List<Map<String, Object?>> trace) {
  client.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        trace.add({
          'method': response.requestOptions.method,
          'path': response.requestOptions.path,
          'status': response.statusCode,
          'body': safe(response.requestOptions.data),
          'bearerAttached': response.requestOptions.headers.containsKey(
            'Authorization',
          ),
          'response': safe(response.data),
        });
        handler.next(response);
      },
      onError: (error, handler) {
        trace.add({
          'method': error.requestOptions.method,
          'path': error.requestOptions.path,
          'status': error.response?.statusCode,
          'response': safe(error.response?.data),
        });
        handler.next(error);
      },
    ),
  );
}

void report(Map<String, Object?> result) {
  // ignore: avoid_print
  print('WEEK8_RESULT=${jsonEncode(result)}');
}

class FailureRatingApi extends AuthenticatedRatingApiService {
  FailureRatingApi() : super(Dio(), Dio());
  String code = 'RATING403_1';
  @override
  Future<MemberRating> updateRating(
    int ratingId,
    int score,
    String? comment,
  ) async {
    throw authError(code, code == 'RATING403_1' ? 403 : 401);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment('W8_PHASE', defaultValue: 'live');
  testWidgets('8주차 Android $phase 증빙', (tester) async {
    await dotenv.load(fileName: '.env');
    final storage = SecureTokenStorage();
    final public = createWorkbookClient();
    final protected = createWorkbookClient();
    final trace = <Map<String, Object?>>[];
    final api = AuthApiService(public, protected);
    final auth = AuthViewModel(api, storage);
    protected.interceptors.add(
      AuthInterceptor(
        storage,
        sessionVersion: () => auth.sessionVersion,
        onExpired: auth.expireSession,
      ),
    );
    observe(public, trace);
    observe(protected, trace);
    final ratingApi = AuthenticatedRatingApiService(public, protected);
    final tmdb = TmdbMovieService(createTmdbClient(TmdbConfig.accessToken));
    final tmdbDetail = await tester.runAsync(() => tmdb.fetchMovieDetail(155));
    Future<void> app() => tester.pumpWidget(
      MovieLogApp(
        authViewModel: auth,
        authenticatedRatingApiService: ratingApi,
        catalogService: tmdb,
        movieDetailService: tmdb,
      ),
    );
    if (phase == 'cleanup') {
      const email = String.fromEnvironment('W8_CLEANUP_EMAIL');
      const memberId = int.fromEnvironment('W8_CLEANUP_MEMBER_ID');
      expect(email, isNotEmpty);
      expect(memberId, greaterThan(0));
      await tester.runAsync(auth.restoreSession);
      expect(auth.member?.email, email);
      final rows = await tester.runAsync(
        () => ratingApi.getMemberRatings(memberId),
      );
      final owned = rows!
          .where((r) => r.movieId == 155 && r.comment == '수정 후 별점 5점')
          .toList();
      expect(owned.length, 1);
      await tester.runAsync(
        () => ratingApi.deleteRating(owned.single.ratingId),
      );
      report({
        'phase': phase,
        'passed': true,
        'email': email,
        'ratingId': owned.single.ratingId,
        'requests': trace,
      });
    } else if (phase == 'live') {
      await tester.runAsync(storage.deleteAccessToken);
      final seed = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final password = 'W8!${Random.secure().nextInt(1 << 30)}aZ';
      final email = 'lea.w8.$seed@example.com';
      final nickname = 'w8${seed}A';
      final otherNickname = 'w8${seed}B';
      final signup = SignUpService(public, version: 'v7');
      public.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            if (o.path == '/v7/auth/login') {
              trace.add({
                'loginInputMatchesFixture':
                    (o.data as Map)['password'] == password,
              });
            }
            h.next(o);
          },
        ),
      );
      await tester.runAsync(
        () => signup.signUp(
          CreateMemberRequest(
            email: email,
            nickname: nickname,
            password: password,
          ),
        ),
      );
      await tester.runAsync(
        () => signup.signUp(
          CreateMemberRequest(
            email: 'lea.w8.other.$seed@example.com',
            nickname: otherNickname,
            password: password,
          ),
        ),
      );
      try {
        await tester.runAsync(() => api.login(LoginRequest(email, password)));
      } catch (_) {
        report({
          'phase': 'control-login-failed',
          'passed': false,
          'requests': trace,
        });
        rethrow;
      }
      await app();
      await waitFor(tester, find.byKey(const Key('login-submit')));
      await enter(tester, find.byKey(const Key('login-email')), email);
      await enter(
        tester,
        find.byKey(const Key('login-password')),
        'wrong-test-password',
      );
      await tap(tester, find.byKey(const Key('login-submit')));
      await waitFor(tester, find.byKey(const Key('login-error')));
      await capture(tester, '01-login-failure');
      await tap(tester, find.byKey(const Key('login-password')));
      await enter(tester, find.byKey(const Key('login-password')), password);
      expect(
        tester
                .widget<TextFormField>(find.byKey(const Key('login-password')))
                .controller!
                .text ==
            password,
        isTrue,
      );
      // ignore: avoid_print
      print('WEEK8_VIDEO_START=01-login-profile-crud');
      await tap(tester, find.byKey(const Key('login-submit')));
      for (var i = 0; i < 60 && auth.status != AuthStatus.signedIn; i++) {
        await pause(tester, 100);
      }
      if (auth.status != AuthStatus.signedIn) {
        report({
          'phase': 'live-failed-login',
          'passed': false,
          'status': auth.status.name,
          'message': auth.message,
          'requests': trace,
        });
        await capture(tester, 'failed-login-diagnostic');
      }
      await waitFor(tester, find.byKey(const Key('main-navigation-bar')));
      await tap(tester, find.text('마이'));
      await waitFor(tester, find.text(nickname));
      await capture(tester, '02-login-me');
      expect(await tester.runAsync(storage.readAccessToken), isNotEmpty);
      await tap(tester, find.text('프로필 수정'));
      await enter(
        tester,
        find.byKey(const Key('profile-nickname')),
        otherNickname,
      );
      await tap(tester, find.byKey(const Key('profile-save')));
      for (var i = 0; i < 100 && auth.profileError == null; i++) {
        await pause(tester, 100);
      }
      expect(auth.profileError, isNotNull);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('profile-nickname')))
            .controller!
            .text,
        otherNickname,
      );
      await capture(tester, '03-profile-409');
      final updated = 'w8${seed}C';
      await enter(tester, find.byKey(const Key('profile-nickname')), updated);
      await tap(tester, find.byKey(const Key('profile-save')));
      for (var i = 0; i < 80 && auth.member?.nickname != updated; i++) {
        await pause(tester, 100);
      }
      if (auth.member?.nickname != updated) {
        report({
          'phase': 'profile-diagnostic',
          'passed': false,
          'profileError': auth.profileError,
          'requests': trace,
        });
      }
      await waitFor(tester, find.text(updated));
      await capture(tester, '04-profile-success');
      final router = GoRouter.of(
        tester.element(find.byKey(const Key('main-navigation-bar'))),
      );
      router.push('/movies/155', extra: tmdbDetail);
      await pause(tester, 700);
      await tap(tester, find.byKey(const Key('open-rating-dialog-button')));
      final stars = find.descendant(
        of: find.byType(RatingDialog),
        matching: find.byIcon(Icons.star_rounded),
      );
      await tap(tester, stars.at(3));
      await enter(
        tester,
        find.byKey(const Key('rating-comment-field')),
        '토큰으로 등록한 8주차 평점',
      );
      await capture(tester, '05-rating-ready');
      await tap(tester, find.byKey(const Key('confirm-rating-button')));
      for (var i = 0; i < 100 && auth.sessionRatings.isEmpty; i++) {
        await pause(tester, 100);
      }
      expect(auth.sessionRatings, isNotEmpty);
      final rating = auth.sessionRatings.single;
      var ratingCleaned = false;
      addTearDown(() async {
        if (!ratingCleaned) await ratingApi.deleteRating(rating.ratingId);
      });
      expect(rating.movieId, 155);
      await pause(tester, 900);
      router.go('/my/ratings');
      await waitFor(tester, find.byKey(Key('my-rating-${rating.ratingId}')));
      await capture(tester, '06-rating-created');
      await tap(tester, find.byKey(Key('edit-rating-${rating.ratingId}')));
      final editStars = find.descendant(
        of: find.byType(RatingDialog),
        matching: find.byIcon(Icons.star_rounded),
      );
      await tap(tester, editStars.at(4));
      await enter(
        tester,
        find.byKey(const Key('rating-comment-field')),
        '수정 후 별점 5점',
      );
      await tap(tester, find.byKey(const Key('confirm-rating-button')));
      for (var i = 0; i < 100 && auth.sessionRatings.single.score != 5; i++) {
        await pause(tester, 100);
      }
      await pause(tester, 1000);
      await capture(tester, '07-rating-updated');
      final otherResult = await tester.runAsync(
        () =>
            api.login(LoginRequest('lea.w8.other.$seed@example.com', password)),
      );
      final otherClient = createWorkbookClient()
        ..options.headers['Authorization'] =
            'Bearer ${otherResult!.accessToken}';
      observe(otherClient, trace);
      final deniedStatus = await tester.runAsync(() async {
        try {
          await AuthenticatedRatingApiService(
            public,
            otherClient,
          ).updateRating(rating.ratingId, 2, null);
          return 200;
        } on DioException catch (error) {
          return error.response?.statusCode;
        }
      });
      expect(deniedStatus, 403);
      expect(auth.status, AuthStatus.signedIn);
      otherClient.close();
      await tap(tester, find.byKey(Key('delete-rating-${rating.ratingId}')));
      await tap(tester, find.text('삭제').last);
      await waitFor(tester, find.byKey(const Key('my-ratings-empty')));
      ratingCleaned = true;
      await capture(tester, '08-rating-deleted');
      router.go('/my');
      await pause(tester, 500);
      // Keep only the encrypted access token for a separate process restart test.
      report({
        'phase': phase,
        'passed': true,
        'email': email,
        'nickname': updated,
        'movieId': 155,
        'ratingId': rating.ratingId,
        'ratingCleaned': auth.sessionRatings.isEmpty,
        'secureStorageRead':
            await tester.runAsync(storage.readAccessToken) != null,
        'fixtureAccountsCreated': 2,
        'requests': trace,
      });
      // ignore: avoid_print
      print('WEEK8_VIDEO_STOP=01-login-profile-crud');
    } else if (phase == 'restore') {
      expect(await tester.runAsync(storage.readAccessToken), isNotEmpty);
      // ignore: avoid_print
      print('WEEK8_VIDEO_START=02-restart-logout-invalid');
      await app();
      await waitFor(tester, find.byKey(const Key('main-navigation-bar')));
      await tap(tester, find.text('마이'));
      await waitFor(tester, find.text('프로필 수정'));
      expect(auth.member, isNotNull);
      expect(auth.sessionRatings, isEmpty);
      final restoredEmail = auth.member!.email;
      await capture(tester, '09-restart-restored');
      await tap(tester, find.byKey(const Key('logout-button')));
      await waitFor(tester, find.byKey(const Key('login-submit')));
      expect(await tester.runAsync(storage.readAccessToken), isNull);
      expect(auth.member, isNull);
      expect(find.textContaining('만료되었습니다'), findsNothing);
      await capture(tester, '10-logout');
      await enter(tester, find.byKey(const Key('login-email')), restoredEmail);
      await tap(tester, find.text('이메일 저장'));
      await enter(
        tester,
        find.byKey(const Key('login-password')),
        'wrong-test-password',
      );
      await tap(tester, find.byKey(const Key('login-submit')));
      await waitFor(tester, find.byKey(const Key('login-error')));
      expect(
        await tester.runAsync(
          () => SharedPreferencesAsync().getString('movielog.remembered_email'),
        ),
        restoredEmail,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await app();
      await waitFor(tester, find.byKey(const Key('login-submit')));
      await pause(tester, 500);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('login-email')))
            .controller!
            .text,
        restoredEmail,
      );
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('login-password')))
            .controller!
            .text
            .isEmpty,
        isTrue,
      );
      await capture(tester, '15-email-remembered');
      final router = GoRouter.of(
        tester.element(find.byKey(const Key('login-submit'))),
      );
      router.go('/my/profile/edit');
      await pause(tester, 500);
      expect(find.byKey(const Key('login-submit')), findsOneWidget);
      await tester.runAsync(
        () => storage.saveAccessToken('invalid-local-test-token'),
      );
      await tester.runAsync(auth.restoreSession);
      await pause(tester, 500);
      await capture(tester, '11-invalid-token');
      expect(auth.status, AuthStatus.signedOut);
      expect(await tester.runAsync(storage.readAccessToken), isNull);
      report({
        'phase': phase,
        'passed': true,
        'restoredAfterProcessRestart': true,
        'logoutTokenDeleted': true,
        'protectedRedirect': true,
        'invalidToken401': true,
        'requests': trace,
      });
      // ignore: avoid_print
      print('WEEK8_VIDEO_STOP=02-restart-logout-invalid');
    } else if (phase == 'invalid') {
      await tester.runAsync(
        () => storage.saveAccessToken('invalid-local-test-token'),
      );
      await app();
      await waitFor(tester, find.byKey(const Key('login-submit')));
      await waitFor(tester, find.text('로그인 시간이 만료되었습니다. 다시 로그인해 주세요.'));
      await capture(tester, '11-invalid-token');
      expect(auth.status, AuthStatus.signedOut);
      expect(await tester.runAsync(storage.readAccessToken), isNull);
      report({
        'phase': phase,
        'passed': true,
        'actualInvalidTokenNotice': true,
        'tokenDeleted': true,
        'requests': trace,
      });
    } else {
      // Controlled API failures exercise real Android storage and production UI.
      await tester.runAsync(
        () => storage.saveAccessToken('injected-test-token'),
      );
      final fake = AuthFake()..meFailure = authError('UNAVAILABLE', 503);
      final vm = AuthViewModel(fake, storage);
      final failures = FailureRatingApi();
      await tester.pumpWidget(
        MovieLogApp(
          authViewModel: vm,
          authenticatedRatingApiService: failures,
          catalogService: tmdb,
          movieDetailService: tmdb,
        ),
      );
      await waitFor(tester, find.text('다시 시도'));
      await capture(tester, '12-injected-restore-retry');
      expect(await tester.runAsync(storage.readAccessToken), isNotEmpty);
      fake.meFailure = null;
      await tap(tester, find.text('다시 시도'));
      await waitFor(tester, find.byKey(const Key('main-navigation-bar')));
      await tap(tester, find.text('마이'));
      await pause(tester, 500);
      fake.pendingMe = Completer<MemberInfo>();
      final loading = vm.loadMember(force: true);
      await capture(tester, '17-injected-member-loading');
      fake.pendingMe!.completeError(authError('UNAVAILABLE', 503));
      await loading;
      await pause(tester, 300);
      await capture(tester, '18-injected-member-retry');
      fake.pendingMe = null;
      await tap(tester, find.text('다시 시도'));
      await waitFor(tester, find.text('프로필 수정'));
      await tap(tester, find.text('프로필 수정'));
      await enter(tester, find.byKey(const Key('profile-nickname')), '변경중닉네임');
      await tap(tester, find.byTooltip('뒤로 가기'));
      await capture(tester, '16-discard-confirmation');
      await tap(tester, find.text('계속 수정'));
      await tap(tester, find.byTooltip('뒤로 가기'));
      await tap(tester, find.text('나가기'));
      vm.keepRating(
        MemberRating(
          ratingId: 9000,
          movieId: 155,
          score: 4,
          comment: '실패 주입용 평점',
          createdAt: DateTime(2026, 11, 16),
          updatedAt: DateTime(2026, 11, 16),
        ),
        vm.sessionVersion,
      );
      await tap(tester, find.byKey(const Key('open-my-ratings')));
      await waitFor(tester, find.byKey(const Key('edit-rating-9000')));
      await tap(tester, find.byKey(const Key('edit-rating-9000')));
      await tap(tester, find.byKey(const Key('confirm-rating-button')));
      await waitFor(tester, find.byKey(const Key('rating-submit-error')));
      expect(vm.status, AuthStatus.signedIn);
      await capture(tester, '13-injected-403-retained');
      failures.code = 'AUTH401_4';
      await tap(tester, find.byKey(const Key('confirm-rating-button')));
      await waitFor(tester, find.byKey(const Key('login-submit')));
      await capture(tester, '14-injected-expiry-snackbar');
      expect(vm.status, AuthStatus.signedOut);
      report({
        'phase': phase,
        'passed': true,
        'injected503RetainsToken': true,
        'injected403RetainsSession': true,
        'injectedExpired401ClearsSession': true,
      });
      await tester.pumpWidget(const SizedBox.shrink());
      vm.dispose();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    auth.dispose();
    public.close();
    protected.close();
  });
}
