import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/core/network/workbook_client.dart';
import 'package:movielog/data/models/member_rating.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/services/member_check_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/widgets/movielog_button.dart';

void main() {
  for (final size in [const Size(320, 740), const Size(1024, 900)]) {
    testWidgets('회원가입 Row·스크롤 레이아웃 ${size.width} 너비', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = AppRouter.create(initialLocation: '/register');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MovieLogApp(routerConfig: router, memberCheckService: CheckFake()),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('nickname-field')), '중복');
      await tester.pump();
      await tester.tap(find.byKey(const Key('check-nickname-button')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('sign-up-button')));
      expect(tester.takeException(), isNull);
    });
  }

  test('v5 직접 응답 파싱·URL 인코딩·TMDB 토큰 격리', () async {
    final dio = createWorkbookClient();
    addTearDown(() => dio.close());
    expect(dio.options.baseUrl, 'https://workbook.devnoco.com');
    expect(dio.options.headers.containsKey('Authorization'), isFalse);
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(
              requestOptions: options,
              data: options.path.endsWith('/ratings')
                  ? [ratingJson]
                  : {'available': false},
            ),
          );
        },
      ),
    );
    final checks = MemberCheckService(dio);
    expect(await checks.checkNickname(' 한 글 '), isFalse);
    await checks.checkEmail(' a+b@example.com ');
    final rows = await RatingApiService(dio).fetchMyRatings(1);
    expect(
      requests[0].path,
      '/v5/members/nickname/${Uri.encodeComponent('한 글')}',
    );
    expect(requests[1].path, '/v5/members/email/a%2Bb%40example.com');
    expect(requests[2].path, '/v6/members/1/ratings');
    expect(rows.single.comment, isNull);
    expect(rows.single.score, 4);
    expect(rows.single.createdAt.isUtc, isTrue);
  });

  test('중복 기억·편집 초기화·재입력 즉시 복원, 이메일 상태 분리', () async {
    final service = CheckFake();
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('중복');
    await vm.checkNickname('중복');
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    expect(vm.canCheckNickname, isFalse);
    vm.onNicknameChanged('새값');
    expect(vm.nicknameErrorText, isNull);
    expect(vm.canCheckNickname, isTrue);
    vm.onNicknameChanged(' 중복 ');
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
    await vm.checkNickname('중복');
    expect(service.calls, 1);
    vm.onEmailChanged('duplicate@example.com');
    await vm.checkEmail('duplicate@example.com');
    expect(vm.emailCheckStatus, CheckStatus.duplicated);
    vm.onEmailChanged('new@example.com');
    await vm.checkEmail('new@example.com');
    expect(vm.emailCheckStatus, CheckStatus.available);
    expect(vm.nicknameCheckStatus, CheckStatus.duplicated);
  });

  test('입력 변경·응답 역전·연타·dispose 후 응답을 무시한다', () async {
    final service = CheckFake()..pending = Completer<bool>();
    final vm = SignUpViewModel(service);
    vm.onNicknameChanged('첫번째');
    final old = vm.checkNickname('첫번째');
    await vm.checkNickname('첫번째');
    expect(service.calls, 1);
    vm.onNicknameChanged('두번째');
    final oldPending = service.pending!;
    service.pending = Completer<bool>();
    final current = vm.checkNickname('두번째');
    service.pending!.complete(true);
    await current;
    oldPending.complete(false);
    await old;
    expect(vm.nicknameCheckStatus, CheckStatus.available);
    vm.onNicknameChanged('세번째');
    service.pending = Completer<bool>();
    final disposed = vm.checkNickname('세번째');
    vm.dispose();
    service.pending!.complete(false);
    await disposed;
  });

  test('통신 실패와 정상 중복을 구별하고 실패 후 재시도한다', () async {
    final service = CheckFake()..fail = true;
    final vm = SignUpViewModel(service);
    addTearDown(vm.dispose);
    vm.onNicknameChanged('새값');
    await vm.checkNickname('새값');
    expect(vm.nicknameCheckStatus, CheckStatus.error);
    expect(vm.nicknameErrorText, contains('실패'));
    expect(vm.canCheckNickname, isTrue);
    service.fail = false;
    await vm.checkNickname('새값');
    expect(vm.nicknameCheckStatus, CheckStatus.available);
    vm.onNicknameChanged('다른값');
    expect(vm.nicknameCheckStatus, CheckStatus.idle);
  });

  test('평점 4상태·고정 회원1·같은 영화 캐시·404/일시 실패 구분', () async {
    final api = RatingsFake()..pending = Completer<List<MemberRating>>();
    final movies = DetailFake();
    final vm = MyRatingsViewModel(api, movies);
    addTearDown(vm.dispose);
    final load = vm.load();
    expect(vm.status, MyRatingsStatus.loading);
    api.pending!.complete([sampleRating, sampleRating]);
    await load;
    expect(api.requestedIds, [1]);
    expect(vm.status, MyRatingsStatus.success);
    expect(movies.calls, 1);
    api.pending = null;
    api.rows = [];
    await vm.load();
    expect(vm.status, MyRatingsStatus.empty);
    api.failureCode = 404;
    await vm.load();
    expect(vm.status, MyRatingsStatus.error);
    expect(vm.message, '존재하지 않는 회원입니다.');
    api.failureCode = null;
    api.rows = [sampleRating];
    await vm.load();
    expect(vm.status, MyRatingsStatus.success);
    expect(movies.calls, 1);
    expect(writeMyRatingsErrorMessage(httpError(400)), contains('형식'));

    final transient = DetailFake()..failureCode = 500;
    final retryVm = MyRatingsViewModel(api, transient);
    addTearDown(retryVm.dispose);
    await retryVm.load();
    expect(retryVm.ratings.single.movie, isNull);
    expect(retryVm.message, contains('일부 영화'));
    transient.failureCode = null;
    await retryVm.load();
    expect(retryVm.ratings.single.movie?.id, 550);
    expect(transient.calls, 2);

    final missing = DetailFake()..failureCode = 404;
    final missingVm = MyRatingsViewModel(api, missing);
    addTearDown(missingVm.dispose);
    await missingVm.load();
    await missingVm.load();
    expect(missing.calls, 1);
    expect(missingVm.ratings.length, 1);
  });

  test('평점 응답 역전·dispose 후 알림 방지', () async {
    final api = RatingsFake()..pending = Completer<List<MemberRating>>();
    final vm = MyRatingsViewModel(api, DetailFake());
    final firstPending = api.pending!;
    final first = vm.load();
    api.pending = Completer<List<MemberRating>>();
    final second = vm.load();
    api.pending!.complete([]);
    await second;
    firstPending.complete([sampleRating]);
    await first;
    expect(vm.status, MyRatingsStatus.empty);
    api.pending = Completer<List<MemberRating>>();
    final last = vm.load();
    vm.dispose();
    api.pending!.complete([]);
    await last;
  });

  testWidgets('서버 중복은 Form 자체를 invalid로 만들고 수정하면 해제', (tester) async {
    final service = CheckFake();
    final router = AppRouter.create(initialLocation: '/register');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MovieLogApp(routerConfig: router, memberCheckService: service),
    );
    await tester.enterText(find.byKey(const Key('nickname-field')), '중복');
    await tester.pump();
    await tester.tap(find.byKey(const Key('check-nickname-button')));
    await tester.pumpAndSettle();
    final state = tester.state<FormFieldState<String>>(
      find.byKey(const Key('nickname-field')),
    );
    expect(state.hasError, isTrue);
    expect(state.validate(), isFalse);
    await tester.enterText(find.byKey(const Key('nickname-field')), '변경');
    await tester.pump();
    expect(state.hasError, isFalse);
    await tester.enterText(find.byKey(const Key('nickname-field')), '중복');
    await tester.pump();
    expect(state.hasError, isTrue);
    expect(service.calls, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('공용 버튼 너비 3종·로딩 라벨 숨김·disabled 연타 차단', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MovieLogButton(
                  key: const Key('natural'),
                  label: '확인',
                  onPressed: () => calls++,
                ),
                MovieLogButton(
                  key: const Key('full'),
                  label: '가입하기',
                  width: double.infinity,
                  onPressed: () {},
                ),
                MovieLogButton(
                  key: const Key('fixed'),
                  label: '숨김',
                  width: 96,
                  isLoading: true,
                  onPressed: () => calls++,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('natural'))).width,
      lessThan(300),
    );
    expect(tester.getSize(find.byKey(const Key('full'))).width, 300);
    expect(tester.getSize(find.byKey(const Key('fixed'))), const Size(96, 44));
    expect(find.text('숨김'), findsNothing);
    await tester.tap(find.byKey(const Key('fixed')));
    expect(calls, 0);
    await tester.tap(find.byKey(const Key('natural')));
    expect(calls, 1);
  });

  testWidgets('마이페이지 자식 평점 화면·뒤로가기·하단 탭 없음·null 후기 숨김', (tester) async {
    final api = RatingsFake();
    final router = AppRouter.create(initialLocation: '/my');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MovieLogApp(
        routerConfig: router,
        ratingApiService: api,
        movieDetailService: DetailFake(),
        learningSession: LearningMemberSession()..setMemberId(1),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('open-my-ratings')));
    await tester.tap(find.byKey(const Key('open-my-ratings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-ratings-success')), findsOneWidget);
    expect(find.text('파이트 클럽'), findsOneWidget);
    expect(find.text('등록일 2026-11-02'), findsOneWidget);
    expect(find.text('코멘트 없음'), findsNothing);
    expect(find.byKey(const Key('main-navigation-bar')), findsNothing);
    await tester.tap(find.byTooltip('뒤로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('마이페이지'), findsOneWidget);
    expect(find.byKey(const Key('main-navigation-bar')), findsOneWidget);
  });
}

const ratingJson = <String, dynamic>{
  'ratingId': 1.0,
  'movieId': 550,
  'score': 4.0,
  'comment': null,
  'createdAt': '2026-11-02T19:00:00Z',
  'updatedAt': '2026-11-02T19:00:00Z',
};
final sampleRating = MemberRating.fromJson(ratingJson);
DioException httpError(int code) {
  final request = RequestOptions(path: '/test');
  return DioException(
    requestOptions: request,
    response: Response(requestOptions: request, statusCode: code),
  );
}

class CheckFake extends MemberCheckService {
  CheckFake() : super(Dio());
  Completer<bool>? pending;
  bool fail = false;
  int calls = 0;
  @override
  Future<bool> checkNickname(String value) async {
    calls++;
    if (fail) throw httpError(503);
    return pending?.future ?? (value != '중복');
  }

  @override
  Future<bool> checkEmail(String value) async {
    if (fail) throw httpError(503);
    return value != 'duplicate@example.com';
  }
}

class RatingsFake extends RatingApiService {
  RatingsFake() : super(Dio());
  List<MemberRating> rows = [sampleRating];
  Completer<List<MemberRating>>? pending;
  int? failureCode;
  final requestedIds = <int>[];
  @override
  Future<List<MemberRating>> fetchMyRatings(int id) async {
    requestedIds.add(id);
    if (failureCode != null) throw httpError(failureCode!);
    return pending?.future ?? rows;
  }
}

class DetailFake implements MovieDetailService {
  int calls = 0;
  int? failureCode;
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int id) async {
    calls++;
    if (failureCode != null) throw httpError(failureCode!);
    return TmdbMovieDto.fromJson({
      'id': id,
      'title': '파이트 클럽',
      'poster_path': null,
    });
  }
}
