import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/workbook_client.dart';
import 'package:movielog/data/models/auth_models.dart';
import 'package:movielog/data/models/member_rating.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/token_storage.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

class MemoryTokenStorage implements TokenStorage {
  String? token;
  bool failRead = false;
  bool failWrite = false;
  bool failDelete = false;
  Completer<void>? writing;
  int deletes = 0;
  @override
  Future<String?> readAccessToken() async {
    if (failRead) throw StateError('test storage unavailable');
    return token;
  }

  @override
  Future<void> saveAccessToken(String value) async {
    await writing?.future;
    if (failWrite) throw StateError('test storage unavailable');
    token = value;
  }

  @override
  Future<void> deleteAccessToken() async {
    deletes++;
    if (failDelete) throw StateError('test storage unavailable');
    token = null;
  }
}

DioException authError(String code, [int status = 401]) => DioException(
  requestOptions: RequestOptions(path: '/test'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/test'),
    statusCode: status,
    data: {
      'isSuccess': false,
      'code': code,
      'message': code == 'RATING403_1' ? '본인이 작성한 평점이 아닙니다.' : '테스트 오류',
      'result': null,
    },
  ),
);

class AuthFake extends AuthApiService {
  AuthFake() : super(Dio(), Dio());
  Object? loginFailure;
  Object? meFailure;
  Object? patchFailure;
  Completer<MemberInfo>? pendingMe;
  Completer<MemberInfo>? pendingPatch;
  int loginCalls = 0;
  int meCalls = 0;
  MemberInfo current = MemberInfo(
    email: 'lea@example.com',
    nickname: '레아',
    createdAt: DateTime(2026, 10, 10),
  );
  @override
  Future<LoginResult> login(LoginRequest request) async {
    loginCalls++;
    if (loginFailure != null) throw loginFailure!;
    return const LoginResult(nickname: '레아', accessToken: 'test-only-token');
  }

  @override
  Future<MemberInfo> fetchMe() async {
    meCalls++;
    if (pendingMe != null) return pendingMe!.future;
    if (meFailure != null) throw meFailure!;
    return current;
  }

  @override
  Future<MemberInfo> updateNickname(String nickname) async {
    if (pendingPatch != null) return pendingPatch!.future;
    if (patchFailure != null) throw patchFailure!;
    return MemberInfo(
      email: current.email,
      nickname: nickname,
      createdAt: current.createdAt,
    );
  }
}

class DelayedMovieDetail extends MovieDetailService {
  final pending = Completer<TmdbMovieDto>();
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) => pending.future;
}

void main() {
  test('이전 세션의 늦은 TMDB 결합 응답을 평점 목록에 반영하지 않는다', () async {
    final api = AuthFake();
    final auth = AuthViewModel(api, MemoryTokenStorage());
    final movies = DelayedMovieDetail();
    final vm = MyRatingsViewModel.authenticated(
      RatingApiService(Dio()),
      movies,
      auth,
      AuthenticatedRatingApiService(Dio(), Dio()),
    );
    addTearDown(vm.dispose);
    addTearDown(auth.dispose);
    await auth.login('a@example.com', 'legacy');
    auth.keepRating(
      MemberRating.fromJson({
        'ratingId': 12,
        'movieId': 155,
        'score': 4,
        'comment': null,
        'createdAt': '2026-11-16T00:00:00Z',
        'updatedAt': '2026-11-16T00:00:00Z',
      }),
      auth.sessionVersion,
    );
    final loading = vm.load();
    await auth.logout();
    await auth.login('b@example.com', 'legacy');
    movies.pending.complete(
      TmdbMovieDto.fromJson({'id': 155, 'title': '이전 세션 영화'}),
    );
    await loading;
    expect(vm.ratings, isEmpty);
    expect(auth.sessionRatings, isEmpty);
  });

  test('인증 정보 삭제 실패는 재시도 가능하고 정리 후 새 로그인 허용', () async {
    final storage = MemoryTokenStorage();
    final api = AuthFake();
    final vm = AuthViewModel(api, storage);
    addTearDown(vm.dispose);
    await vm.login('lea@example.com', 'legacy');
    storage.failDelete = true;
    await vm.logout();
    expect(vm.storageCleanupFailed, isTrue);
    expect(vm.status, AuthStatus.signedOut);
    await vm.login('b@example.com', 'legacy');
    expect(api.loginCalls, 1);
    storage.failDelete = false;
    await vm.logout();
    expect(vm.storageCleanupFailed, isFalse);
    expect(storage.token, isNull);
    await vm.login('b@example.com', 'legacy');
    expect(vm.status, AuthStatus.signedIn);
  });
  test('Interceptor는 보호 API의 만료 code만 처리하며 이전 요청 버전을 전달', () async {
    final storage = MemoryTokenStorage()..token = 'test';
    final dio = createWorkbookClient();
    addTearDown(dio.close);
    final expired = <int>[];
    dio.interceptors.add(
      AuthInterceptor(
        storage,
        sessionVersion: () => 4,
        onExpired: (version) async {
          expired.add(version);
        },
      ),
    );
    var code = 'RATING403_1';
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'code': code},
              ),
            ),
            true,
          );
        },
      ),
    );
    await expectLater(dio.get('/v7/ratings/1'), throwsA(isA<DioException>()));
    expect(expired, isEmpty);
    code = 'AUTH401_4';
    await expectLater(dio.get('/v7/ratings/1'), throwsA(isA<DioException>()));
    expect(expired, [4]);
    await expectLater(dio.get('/v7/auth/login'), throwsA(isA<DioException>()));
    expect(expired, [4]);
  });

  test('토큰 없음·서버 검증 성공·일시 실패와 재시도 복원', () async {
    final storage = MemoryTokenStorage();
    final api = AuthFake();
    final vm = AuthViewModel(api, storage);
    addTearDown(vm.dispose);
    await vm.restoreSession();
    expect(vm.status, AuthStatus.signedOut);
    expect(api.meCalls, 0);
    storage.token = 'test';
    api.meFailure = authError('UNAVAILABLE', 503);
    await vm.restoreSession();
    expect(vm.status, AuthStatus.retryRequired);
    expect(storage.token, 'test');
    api.meFailure = null;
    await vm.restoreSession();
    expect(vm.status, AuthStatus.signedIn);
    expect(vm.member?.nickname, '레아');
  });
  test('신규 로그인 토큰 저장 후 signedIn·내 정보는 한 번 호출', () async {
    final api = AuthFake();
    final storage = MemoryTokenStorage();
    final vm = AuthViewModel(api, storage);
    addTearDown(vm.dispose);
    await vm.login('lea@example.com', 'legacy');
    expect(vm.status, AuthStatus.signedIn);
    expect(api.meCalls, 0);
    await vm.loadMember();
    await vm.loadMember();
    expect(api.meCalls, 1);
    expect(storage.token, 'test-only-token');
  });
  test('저장소 실패는 재시도·로그인 실패로 해제', () async {
    final storage = MemoryTokenStorage()..failRead = true;
    final vm = AuthViewModel(AuthFake(), storage);
    addTearDown(vm.dispose);
    await vm.restoreSession();
    expect(vm.status, AuthStatus.retryRequired);
    storage.failRead = false;
    storage.failWrite = true;
    await vm.login('lea@example.com', 'legacy');
    expect(vm.status, AuthStatus.signedOut);
    expect(vm.message, isNotNull);
  });
  test('로그인 AUTH401_1 안내와 403은 세션을 만료시키지 않는다', () async {
    final api = AuthFake()..loginFailure = authError('AUTH401_1');
    final storage = MemoryTokenStorage();
    final vm = AuthViewModel(api, storage);
    addTearDown(vm.dispose);
    await vm.login('lea@example.com', 'wrong');
    expect(vm.sessionExpired, isFalse);
    expect(vm.message, contains('이메일 또는'));
    api.loginFailure = null;
    await vm.login('lea@example.com', 'legacy');
    api.patchFailure = authError('RATING403_1', 403);
    expect(await vm.updateNickname('새닉네임'), isFalse);
    expect(vm.status, AuthStatus.signedIn);
    expect(storage.token, isNotNull);
  });
  test('동시 보호401 세션 정리 한 번·Snackbar 소비 한 번', () async {
    final storage = MemoryTokenStorage();
    final vm = AuthViewModel(AuthFake(), storage);
    addTearDown(vm.dispose);
    await vm.login('lea@example.com', 'legacy');
    final version = vm.sessionVersion;
    await Future.wait([vm.expireSession(version), vm.expireSession(version)]);
    expect(storage.deletes, 1);
    expect(vm.member, isNull);
    expect(vm.consumeSessionExpired(), isTrue);
    expect(vm.consumeSessionExpired(), isFalse);
  });
  test('로그아웃 중 토큰 저장 완료를 기다린 후 삭제·새 로그인 차단', () async {
    final storage = MemoryTokenStorage()..writing = Completer<void>();
    final api = AuthFake();
    final vm = AuthViewModel(api, storage);
    addTearDown(vm.dispose);
    final login = vm.login('lea@example.com', 'legacy');
    await Future<void>.delayed(Duration.zero);
    final logout = vm.logout();
    await vm.login('other@example.com', 'legacy');
    expect(api.loginCalls, 1);
    storage.writing!.complete();
    await Future.wait([login, logout]);
    expect(storage.token, isNull);
    expect(vm.status, AuthStatus.signedOut);
    expect(vm.sessionExpired, isFalse);
  });
  test('A의 늦은 성공·401이 B의 정보·세션을 변경하지 않는다', () async {
    final api = AuthFake();
    final vm = AuthViewModel(api, MemoryTokenStorage());
    addTearDown(vm.dispose);
    await vm.login('a@example.com', 'legacy');
    api.pendingMe = Completer<MemberInfo>();
    final old = api.pendingMe!;
    final loading = vm.loadMember();
    final oldVersion = vm.sessionVersion;
    await vm.logout();
    await vm.login('b@example.com', 'legacy');
    api.pendingMe = null;
    api.current = MemberInfo(
      email: 'b@example.com',
      nickname: '회원B',
      createdAt: DateTime(2026),
    );
    await vm.loadMember();
    old.complete(
      MemberInfo(
        email: 'a@example.com',
        nickname: '회원A',
        createdAt: DateTime(2026),
      ),
    );
    await loading;
    await vm.expireSession(oldVersion);
    expect(vm.member?.nickname, '회원B');
    expect(vm.status, AuthStatus.signedIn);
  });
  test('프로필 409 입력 오류·재시도 성공·늦은 PATCH 결과 차단', () async {
    final api = AuthFake();
    final vm = AuthViewModel(api, MemoryTokenStorage());
    addTearDown(vm.dispose);
    await vm.login('lea@example.com', 'legacy');
    expect(await vm.updateNickname('a'), isFalse);
    api.patchFailure = authError('MEMBER409_1', 409);
    expect(await vm.updateNickname('중복'), isFalse);
    expect(vm.profileError, isNotNull);
    api.patchFailure = null;
    expect(await vm.updateNickname('새닉네임'), isTrue);
    expect(vm.member?.nickname, '새닉네임');
    api.pendingPatch = Completer<MemberInfo>();
    final patch = vm.updateNickname('늦은수정');
    await vm.logout();
    api.pendingPatch!.complete(api.current);
    await patch;
    expect(vm.member, isNull);
    expect(vm.savingProfile, isFalse);
  });
  test('AuthInterceptor는 정확한 목적지·보호 경로에만 토큰 전달', () async {
    final storage = MemoryTokenStorage()..token = 'test-only-token';
    final dio = createWorkbookClient();
    addTearDown(dio.close);
    var version = 1;
    final expired = <int>[];
    dio.interceptors.add(
      AuthInterceptor(
        storage,
        sessionVersion: () => version,
        onExpired: (v) async {
          if (v == version) {
            expired.add(v);
            version++;
          }
        },
      ),
    );
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          h.resolve(Response(requestOptions: o, statusCode: 200));
        },
      ),
    );
    for (final path in [
      '/v7/members/me',
      '/v7/ratings',
      '/v7/ratings/1',
      '/v7/auth/login',
      '/v7/members/1/ratings',
      'https://api.themoviedb.org/3/movie/popular',
      'https://workbook.devnoco.com.evil.example/v7/ratings',
    ]) {
      await dio.get(
        path,
        options: Options(headers: {'authorization': 'stale'}),
      );
    }
    expect(
      requests
          .take(3)
          .every((r) => r.headers['Authorization'] == 'Bearer test-only-token'),
      isTrue,
    );
    expect(
      requests
          .skip(3)
          .every(
            (r) =>
                !r.headers.keys.any((k) => k.toLowerCase() == 'authorization'),
          ),
      isTrue,
    );
    expect(expired, isEmpty);
  });
  test('v7 Rating DTO·memberId 없는 쓰기·전체 comment·삭제200·공개GET', () async {
    final public = Dio();
    final auth = Dio();
    addTearDown(public.close);
    addTearDown(auth.close);
    final requests = <RequestOptions>[];
    final json = {
      'ratingId': 12,
      'movieId': 155,
      'score': 5,
      'comment': null,
      'createdAt': '2026-10-10T00:00:00Z',
      'updatedAt': '2026-10-10T00:00:00Z',
    };
    auth.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: o.method == 'POST' ? 201 : 200,
              data: {
                'isSuccess': true,
                'code': 'COMMON200',
                'message': '성공',
                'result': o.method == 'DELETE' ? null : json,
              },
            ),
          );
        },
      ),
    );
    public.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          h.resolve(Response(requestOptions: o, statusCode: 200, data: [json]));
        },
      ),
    );
    final api = AuthenticatedRatingApiService(public, auth);
    expect(
      (await api.createRating(CreateRatingRequest(movieId: 155, score: 5)))
          .ratingId,
      12,
    );
    await api.updateRating(12, 5, null);
    await api.deleteRating(12);
    await api.getMemberRatings(8);
    expect(requests.map((r) => r.path), [
      '/v7/ratings',
      '/v7/ratings/12',
      '/v7/ratings/12',
      '/v7/members/8/ratings',
    ]);
    expect((requests[0].data as Map).containsKey('memberId'), isFalse);
    expect((requests[1].data as Map).containsKey('comment'), isTrue);
    expect((requests[1].data as Map)['comment'], isNull);
  });
  test('인증 상태별 redirect·공개 경로·보호 경로', () {
    expect(authRedirect(AuthStatus.initializing, '/my'), '/start');
    expect(authRedirect(AuthStatus.retryRequired, '/home'), '/start');
    expect(authRedirect(AuthStatus.signedOut, '/movies/155'), '/login');
    expect(authRedirect(AuthStatus.signedOut, '/register'), isNull);
    expect(authRedirect(AuthStatus.signedIn, '/login'), '/home');
    expect(authRedirect(AuthStatus.signedIn, '/my'), isNull);
  });
  testWidgets('기본 진입 로그인·실패 안내·프로필 표시·수정 취소·로그아웃 redirect', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final api = AuthFake();
    final vm = AuthViewModel(api, MemoryTokenStorage());
    addTearDown(vm.dispose);
    await tester.pumpWidget(MovieLogApp(authViewModel: vm));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('login-email')),
      'lea@example.com',
    );
    await tester.enterText(find.byKey(const Key('login-password')), 'legacy');
    api.loginFailure = authError('AUTH401_1');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.textContaining('이메일 또는 비밀번호'), findsOneWidget);
    api.loginFailure = null;
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('마이'));
    await tester.pumpAndSettle();
    expect(find.text('레아'), findsOneWidget);
    expect(find.text('2026.10.10 가입'), findsOneWidget);
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile-nickname')), '변경중');
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('변경 내용을 취소할까요?'), findsOneWidget);
    await tester.tap(find.text('계속 수정'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MovieLogButton>(find.byKey(const Key('profile-save')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('나가기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('프로필 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('profile-nickname')), '새닉네임');
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile-save')));
    await tester.pumpAndSettle();
    expect(find.text('새닉네임'), findsOneWidget);
    expect(find.byKey(const Key('profile-nickname')), findsNothing);
    await tester.tap(find.byKey(const Key('logout-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('login-submit')), findsOneWidget);
    expect(find.text('레아'), findsNothing);
    expect(find.textContaining('만료되었습니다'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
