import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/workbook_client.dart';
import 'package:movielog/data/models/common_response.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/rating_request.dart';
import 'package:movielog/data/models/sign_up_models.dart';
import 'package:movielog/data/models/member_rating.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/rating_api_service.dart';
import 'package:movielog/view_models/sign_up_view_model.dart';
import 'package:movielog/view_models/my_ratings_view_model.dart';
import 'package:movielog/view_models/movie_detail_view_model.dart';
import 'package:movielog/view_models/learning_member_session.dart';
import 'package:movielog/widgets/movie/rating_dialog.dart';
import 'package:movielog/widgets/movie/delete_rating_dialog.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/screens/my_ratings_screen.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';

import 'week6_frontend_test.dart' show DetailFake;

Map<String, dynamic> common({
  Object? result,
  bool success = true,
  String code = 'COMMON201',
  String message = '성공',
}) => {
  'isSuccess': success,
  'code': code,
  'message': message,
  'result': result,
};
DioException apiError(int status, String message) => DioException(
  requestOptions: RequestOptions(path: '/test'),
  type: DioExceptionType.badResponse,
  response: Response(
    requestOptions: RequestOptions(path: '/test'),
    statusCode: status,
    data: common(success: false, code: 'COMMON$status', message: message),
  ),
);

const request = CreateMemberRequest(
  email: 'w7@example.com',
  nickname: '레아7',
  password: 'Test1234!',
);

class SignUpFake extends SignUpService {
  SignUpFake() : super(Dio());
  Object? failure;
  Completer<void>? gate;
  int posts = 0;
  @override
  Future<bool> checkNickname(String value) async => true;
  @override
  Future<bool> checkEmail(String value) async => true;
  @override
  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    posts++;
    await gate?.future;
    if (failure != null) throw failure!;
    return CommonResponse(
      isSuccess: true,
      code: 'COMMON201',
      message: '성공',
      result: SignUpResult(
        memberId: 77,
        email: request.email,
        nickname: request.nickname,
      ),
    );
  }
}

class RatingsWriteFake extends RatingApiService {
  RatingsWriteFake() : super(Dio());
  List<MemberRating> rows = [makeRating(11), makeRating(12)];
  int gets = 0;
  int writes = 0;
  bool failGet = false;
  Object? failure;
  Completer<void>? gate;
  final Set<int> failDeleteIds = {};
  @override
  Future<List<MemberRating>> fetchMyRatings(int memberId) async {
    gets++;
    if (failGet) throw apiError(500, '목록 조회 실패');
    return List.of(rows);
  }

  @override
  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    writes++;
    await gate?.future;
    if (failure != null) throw failure!;
    rows = rows
        .map(
          (r) => r.ratingId == ratingId
              ? makeRating(ratingId, score: score, comment: comment)
              : r,
        )
        .toList();
  }

  @override
  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    writes++;
    await gate?.future;
    if (failDeleteIds.contains(ratingId)) throw apiError(500, '삭제 실패');
    if (failure != null) throw failure!;
    rows.removeWhere((row) => row.ratingId == ratingId);
  }

  @override
  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    writes++;
    await gate?.future;
    if (failure != null) throw failure!;
  }
}

MemberRating makeRating(int id, {int score = 4, String? comment = '기존 코멘트'}) =>
    MemberRating(
      ratingId: id,
      movieId: 550,
      score: score,
      comment: comment,
      createdAt: DateTime(2026, 11, 6),
      updatedAt: DateTime(2026, 11, 6),
    );

Future<SignUpViewModel> readySignUp(SignUpFake service) async {
  final vm = SignUpViewModel(service);
  vm.onNicknameChanged(request.nickname);
  vm.onEmailChanged(request.email);
  await vm.checkNickname(request.nickname);
  await vm.checkEmail(request.email);
  return vm;
}

void main() {
  testWidgets('가입 제출 중 화면 이탈·중복 탭 차단, 서버400은 비밀번호 필드, 수정 시 해제', (tester) async {
    final service = SignUpFake()
      ..gate = Completer<void>()
      ..failure = apiError(400, '비밀번호 형식을 확인해 주세요.');
    final router = AppRouter.create(initialLocation: '/start');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MovieLogApp(routerConfig: router, memberCheckService: service),
    );
    router.push('/register');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('nickname-field')),
      request.nickname,
    );
    await tester.enterText(find.byKey(const Key('email-field')), request.email);
    await tester.tap(find.byKey(const Key('check-nickname-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('check-email-button')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('password-field')),
      request.password,
    );
    await tester.ensureVisible(find.byKey(const Key('terms-checkbox')));
    await tester.tap(find.byKey(const Key('terms-checkbox')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('sign-up-button')));
    await tester.tap(find.byKey(const Key('sign-up-button')));
    await tester.pump();
    expect(service.posts, 1);
    expect(
      tester
          .widget<MovieLogButton>(find.byKey(const Key('sign-up-button')))
          .isLoading,
      isTrue,
    );
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const Key('nickname-field')), findsOneWidget);
    service.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('비밀번호 형식을 확인해 주세요.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('password-field')), 'New1234!');
    await tester.pump();
    expect(find.text('비밀번호 형식을 확인해 주세요.'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('영화의 순간을\n기록하세요'), findsOneWidget);
  });
  test('요청 JSON은 email/nickname만 trim, password 원문 보존', () {
    final json = const CreateMemberRequest(
      email: ' a@b.com ',
      nickname: ' 레아 ',
      password: ' Abc1234! ',
    ).toJson();
    expect(json, {
      'email': 'a@b.com',
      'nickname': '레아',
      'password': ' Abc1234! ',
    });
  });
  test('공통 응답은 payload 1회 파싱, null은 파서 미호출', () {
    var calls = 0;
    final response = CommonResponse<int>.fromJson(common(result: 7), (v) {
      calls++;
      return v as int;
    });
    expect(response.result, 7);
    CommonResponse<int>.fromJson(common(), (v) {
      calls++;
      return 0;
    });
    expect(calls, 1);
  });
  for (final value in [0.0, 0.5, 3.5, 6.0, double.nan, double.infinity]) {
    test(
      '서버 평점 거부: $value',
      () => expect(() => validateServerScore(value), throwsArgumentError),
    );
  }
  test('평점 JSON·빈 코멘트 생략·500자 제한', () {
    expect(
      const CreateRatingRequest(movieId: 550, score: 5, comment: ' ').toJson(),
      {'movieId': 550, 'score': 5},
    );
    expect(() => normalizedComment('a' * 501), throwsArgumentError);
    expect(validatePasswordFormat('password123'), isNotNull);
    expect(validatePasswordFormat('Test1234!'), isNull);
  });
  test('가입 응답 memberId 누락·소수·0 거부', () {
    for (final id in [null, 0, 1.5, '1']) {
      expect(
        () => SignUpResult.fromJson({'memberId': id}),
        throwsFormatException,
      );
    }
  });
  test('v6 Service 실제 path/body·직접 GET·wrapper·204·토큰 격리', () async {
    final requests = <RequestOptions>[];
    final dio = createWorkbookClient();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          final data = o.method == 'DELETE'
              ? null
              : o.method == 'GET'
              ? (o.path.endsWith('/ratings')
                    ? <dynamic>[]
                    : {'available': true})
              : common(
                  result: o.path == '/v6/members'
                      ? {
                          'memberId': 77,
                          'email': 'w7@example.com',
                          'nickname': '레아7',
                        }
                      : null,
                );
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: o.method == 'DELETE'
                  ? 204
                  : o.method == 'POST'
                  ? 201
                  : 200,
              data: data,
            ),
          );
        },
      ),
    );
    final signup = SignUpService(dio);
    expect(await signup.checkEmail('a+b@example.com'), isTrue);
    expect((await signup.signUp(request)).result!.memberId, 77);
    final ratings = RatingApiService(dio);
    await ratings.fetchMyRatings(77);
    await ratings.createRating(
      memberId: 77,
      request: const CreateRatingRequest(movieId: 550, score: 4),
    );
    await ratings.updateRating(
      memberId: 77,
      ratingId: 11,
      score: 5,
      comment: null,
    );
    await ratings.deleteRating(memberId: 77, ratingId: 11);
    expect(requests.first.path, '/v6/members/email/a%2Bb%40example.com');
    expect(requests[4].data, {'score': 5, 'comment': null});
    expect(
      requests.every(
        (r) => !r.headers.keys.any((k) => k.toLowerCase() == 'authorization'),
      ),
      isTrue,
    );
    dio.close();
  });
  test('실제 생성 memberId 세션, 재시작 시 비어 있음', () {
    final session = LearningMemberSession()..setMemberId(77);
    expect(session.memberId, 77);
    expect(LearningMemberSession().memberId, isNull);
    session.clear();
    expect(session.memberId, isNull);
    session.dispose();
  });
  test('회원가입 이중 탭 방지·성공 ID·입력 변경 무효화', () async {
    final service = SignUpFake()..gate = Completer<void>();
    final vm = await readySignUp(service);
    final pending = vm.submit(request);
    await vm.submit(request);
    expect(service.posts, 1);
    expect(vm.isSubmitting, isTrue);
    service.gate!.complete();
    await pending;
    expect(vm.createdMemberId, 77);
    vm.onNicknameChanged('새 닉네임');
    expect(vm.checksAvailable, isFalse);
    vm.dispose();
  });
  for (final status in [400, 409, 500]) {
    test('가입 $status 서버 message 및 오류 목적지', () async {
      final service = SignUpFake()
        ..failure = apiError(status, status == 400 ? '비밀번호 형식 오류' : '서버 안내');
      final vm = await readySignUp(service);
      await vm.submit(request);
      expect(vm.submitStatus, SubmitStatus.error);
      expect(
        status == 400 ? vm.passwordErrorText : vm.snackbarMessage,
        status == 400 ? '비밀번호 형식 오류' : '서버 안내',
      );
      vm.onEmailChanged('new@example.com');
      expect(vm.snackbarMessage, isNull);
      expect(vm.passwordErrorText, isNull);
      vm.dispose();
    });
  }
  test('가입 비밀번호 아닌 400은 Snackbar', () async {
    final vm = await readySignUp(
      SignUpFake()..failure = apiError(400, '이메일 형식 오류'),
    );
    await vm.submit(request);
    expect(vm.passwordErrorText, isNull);
    expect(vm.snackbarMessage, '이메일 형식 오류');
    vm.dispose();
  });
  test('dispose 뒤 가입 응답 무시', () async {
    final service = SignUpFake()..gate = Completer<void>();
    final vm = await readySignUp(service);
    final future = vm.submit(request);
    vm.dispose();
    service.gate!.complete();
    await future;
    expect(vm.createdMemberId, isNull);
  });
  test('등록 null 회원 차단·중복 탭 방지·서버 message', () async {
    final api = RatingsWriteFake()..gate = Completer<void>();
    final absent = MovieDetailViewModel(api, null, 550);
    await expectLater(absent.createRating(score: 4), throwsStateError);
    expect(api.writes, 0);
    absent.dispose();
    final vm = MovieDetailViewModel(api, 77, 550);
    final future = vm.createRating(score: 4);
    await vm.createRating(score: 4);
    expect(api.writes, 1);
    api.gate!.complete();
    await future;
    expect(vm.submitStatus, SubmitStatus.success);
    vm.dispose();
  });
  test('수정 성공 후 GET 실패는 저장 실패가 아님·GET만 재시도', () async {
    final api = RatingsWriteFake();
    final vm = MyRatingsViewModel(api, DetailFake(), 77);
    await vm.load();
    api.failGet = true;
    await vm.updateRating(ratingId: 11, score: 5, comment: '수정');
    expect(vm.refreshWarning, contains('저장은 완료'));
    expect(api.writes, 1);
    api.failGet = false;
    await vm.load();
    expect(api.writes, 1);
    expect(vm.refreshWarning, isNull);
    expect(vm.ratings.first.rating.comment, '수정');
    vm.dispose();
  });
  for (final status in [400, 403, 404, 409]) {
    test('평점 $status 메시지 구분·403/404만 재조회', () async {
      final api = RatingsWriteFake()..failure = apiError(status, '오류$status');
      final vm = MyRatingsViewModel(api, DetailFake(), 77);
      await vm.load();
      await expectLater(
        vm.updateRating(ratingId: 11, score: 4),
        throwsStateError,
      );
      expect(vm.operationMessage, '오류$status');
      expect(api.gets, status == 403 || status == 404 ? 2 : 1);
      expect(vm.isWriting, isFalse);
      vm.dispose();
    });
  }
  test('다중 삭제 일부 실패·성공만 제거·실패 선택 유지', () async {
    final api = RatingsWriteFake()..failDeleteIds.add(12);
    final vm = MyRatingsViewModel(api, DetailFake(), 77);
    await vm.load();
    vm.toggleEditing();
    vm.selectRating(11, true);
    vm.selectRating(12, true);
    await vm.deleteSelectedRatings();
    expect(vm.ratings.map((r) => r.rating.ratingId), [12]);
    expect(vm.selectedRatingIds, {12});
    expect(vm.operationMessage, contains('1개'));
    expect(vm.isDeletingSelected, isFalse);
    vm.dispose();
  });
  testWidgets('평점 Dialog 정수·코멘트·실패 입력 유지·이탈 차단', (tester) async {
    var count = 0;
    final gate = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => RatingDialog(
                  onSubmit: (score, comment) async {
                    count++;
                    expect(score, 4);
                    expect(comment, '기록');
                    await gate.future;
                    throw StateError('저장 실패 안내');
                  },
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MovieLogButton>(
            find.byKey(const Key('confirm-rating-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(find.byKey(const Key('rating-comment-field')), '기록');
    await tester.tap(find.byIcon(Icons.star_rounded).at(3));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-rating-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-rating-button')));
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(RatingDialog), findsOneWidget);
    expect(count, 1);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('저장 실패 안내'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('rating-comment-field')))
          .controller!
          .text,
      '기록',
    );
  });
  testWidgets('수정 초기값·취소 시 API 0회', (tester) async {
    var writes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => RatingDialog(
                  initialRating: 4,
                  initialComment: '기존 후기',
                  onSubmit: (s, c) async {
                    writes++;
                  },
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('기존 후기'), findsOneWidget);
    expect(find.text('선택한 평점: 4.0'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(writes, 0);
  });
  testWidgets('단일 삭제 취소는 요청 0회', (tester) async {
    var writes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (_) => DeleteRatingDialog(
                  onDelete: () async {
                    writes++;
                  },
                ),
              ),
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(writes, 0);
  });
  testWidgets('평점 목록 편집·취소·마지막 삭제 Empty', (tester) async {
    final api = RatingsWriteFake()..rows = [makeRating(11)];
    final vm = MyRatingsViewModel(api, DetailFake(), 77);
    await vm.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: MyRatingsScreen()),
      ),
    );
    await tester.tap(find.text('편집'));
    await tester.pump();
    expect(find.text('0개 선택'), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(find.text('1개 선택'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pump();
    expect(vm.selectedRatingIds, isEmpty);
    await vm.deleteRating(11);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('my-ratings-empty')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    vm.dispose();
  });
}
