import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/movielog_client.dart';
import 'package:movielog/data/models/member_rating.dart';
import 'package:movielog/data/services/member_api_service.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  test('자체 API Client에는 TMDB Authorization이 없다', () async {
    final dio = createMovieLogClient();
    expect(dio.options.headers.containsKey('Authorization'), isFalse);
    final requests = <RequestOptions>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response(requestOptions: options, data: {'available': false}),
          );
        },
      ),
    );
    final service = HttpMemberApiService(dio);
    expect(await service.checkNickname('수현'), isFalse);
    await service.checkEmail('noco+demo@umc.com');
    expect(requests[0].path, '/members/nickname/${Uri.encodeComponent('수현')}');
    expect(
      requests[1].path,
      '/members/email/${Uri.encodeComponent('noco+demo@umc.com')}',
    );
  });

  testWidgets('중복 확인 결과와 입력 변경 시 이전 결과 무효화', (tester) async {
    final service = _MemberService();
    final router = AppRouter.create(initialLocation: '/register');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MovieLogApp(routerConfig: router, memberApiService: service),
    );
    await tester.enterText(find.byKey(const Key('nickname-field')), '수현');
    await tester.tap(find.byKey(const Key('check-nickname-button')));
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    final field = tester.widget<TextFormField>(
      find.byKey(const Key('nickname-field')),
    );
    field.controller!.selection = const TextSelection.collapsed(offset: 0);
    await tester.pump();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('nickname-field')), '새닉네임');
    await tester.pump();
    expect(
      find.byKey(const Key('nickname-availability-message')),
      findsNothing,
    );
  });

  testWidgets('입력 변경 중 도착한 오래된 중복 확인 응답 무시', (tester) async {
    final service = _MemberService()..pending = Completer<bool>();
    final router = AppRouter.create(initialLocation: '/register');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MovieLogApp(routerConfig: router, memberApiService: service),
    );
    await tester.enterText(find.byKey(const Key('nickname-field')), '수현');
    await tester.tap(find.byKey(const Key('check-nickname-button')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('nickname-field')), '다른닉네임');
    service.pending!.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 닉네임입니다.'), findsNothing);
  });

  testWidgets('회원 평점 성공·빈 목록·오류·재시도와 잘못된 ID 처리', (tester) async {
    final service = _MemberService();
    final router = AppRouter.create(initialLocation: '/member-ratings');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MovieLogApp(routerConfig: router, memberApiService: service),
    );
    Future<void> load(String id) async {
      await tester.enterText(
        find.byKey(const Key('ratings-member-id-field')),
        id,
      );
      await tester.tap(find.byKey(const Key('load-member-ratings-button')));
      await tester.pumpAndSettle();
    }

    await load('1');
    expect(find.text('회원 1 · 평점 1건 · 최신 등록순'), findsOneWidget);
    expect(find.text('TMDB 영화 #550 · 5점'), findsOneWidget);
    await load('3');
    expect(find.byKey(const Key('member-ratings-empty')), findsOneWidget);
    service.fail = true;
    await load('1');
    expect(find.byKey(const Key('member-ratings-error')), findsOneWidget);
    service.fail = false;
    await load('1');
    expect(find.byKey(const Key('member-rating-1')), findsOneWidget);
    await load('0');
    expect(find.byKey(const Key('member-rating-1')), findsNothing);
    expect(find.text('양의 정수 회원 ID를 입력해 주세요.'), findsOneWidget);
  });
}

class _MemberService implements MemberApiService {
  Completer<bool>? pending;
  bool fail = false;

  @override
  Future<bool> checkNickname(String nickname) async =>
      pending == null ? nickname != '수현' : pending!.future;
  @override
  Future<bool> checkEmail(String email) async => email != 'noco@umc.com';
  @override
  Future<List<MemberRating>> getRatings(int memberId) async {
    if (fail) throw StateError('테스트 실패');
    if (memberId == 3) return [];
    return [
      MemberRating(
        ratingId: 1,
        movieId: 550,
        score: 5,
        comment: null,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    ];
  }
}
