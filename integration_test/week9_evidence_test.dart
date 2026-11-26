import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/network/workbook_client.dart';
import 'package:movielog/data/models/create_member_request.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/auth_api_service.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/sign_up_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/data/token_storage.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/screens/main_screen.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/widgets/movie/rating_dialog.dart';
import 'package:movielog/widgets/movie/movie_card.dart';

import '../test/week9_frontend_test.dart'
    show CatalogFake, FavoriteFake, favorite, page;
import '../test/week8_auth_test.dart'
    show AuthFake, MemoryTokenStorage, authError;

Future<void> pause(WidgetTester t, [int ms = 150]) async {
  await t.pump(Duration(milliseconds: ms));
  await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));
}

Future<void> until(WidgetTester t, Finder finder, {bool recover = true}) async {
  var retries = 0;
  for (var i = 0; i < 180; i++) {
    await pause(t, 100);
    if (finder.evaluate().isNotEmpty) return;
    if (recover && retries < 3) {
      final retry = find.text('이 영화만 다시 시도').evaluate().isNotEmpty
          ? find.text('이 영화만 다시 시도')
          : find.text('영화를 불러오지 못했습니다. 다시 시도').evaluate().isNotEmpty
          ? find.text('영화를 불러오지 못했습니다. 다시 시도')
          : find.text('다시 시도');
      if (retry.evaluate().isNotEmpty) {
        await t.tap(retry.first);
        retries++;
        await pause(t, 500);
      }
    }
  }
  expect(finder, findsWidgets, reason: '화면 대기 시간 초과');
}

Future<void> tap(WidgetTester t, Finder finder) async {
  await until(t, finder);
  await t.ensureVisible(finder);
  await pause(t);
  await t.tap(finder);
  await pause(t, 350);
}

Future<void> enter(WidgetTester t, Finder finder, String value) async {
  await tap(t, finder);
  await t.enterText(finder, value);
  await pause(t, 300);
  expect(t.widget<TextField>(finder).controller!.text, value);
}

Future<void> capture(WidgetTester t, String name) async {
  FocusManager.instance.primaryFocus?.unfocus();
  for (var attempt = 0; attempt < 15; attempt++) {
    await pause(t, 300);
    if (!t
        .widgetList<RawImage>(find.byType(RawImage))
        .any((image) => image.image == null)) {
      break;
    }
  }
  await pause(t, 650);
  // ignore: avoid_print
  print('WEEK9_CAPTURE=$name');
  await pause(t, 900);
}

void marker(String value) {
  // ignore: avoid_print
  print(value);
}

Object? safe(Object? data) {
  if (data is Map) {
    return {
      for (final entry in data.entries)
        if (!{
          'password',
          'accesstoken',
          'authorization',
        }.contains('${entry.key}'.toLowerCase()))
          '${entry.key}': safe(entry.value),
    };
  }
  if (data is List) return data.map(safe).toList();
  return data;
}

void observe(Dio dio, List<Map<String, Object?>> trace) {
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (r, h) {
        trace.add({
          'method': r.requestOptions.method,
          'path': r.requestOptions.path,
          'query': r.requestOptions.queryParameters,
          'status': r.statusCode,
          'bearerAttached': r.requestOptions.headers.containsKey(
            'Authorization',
          ),
          if (r.requestOptions.path != '/v8/members' &&
              r.requestOptions.path != '/v8/auth/login')
            'body': safe(r.requestOptions.data),
          'response': r.requestOptions.uri.host == 'api.themoviedb.org'
              ? {
                  'page': r.data is Map ? r.data['page'] : null,
                  'count': r.data is Map && r.data['results'] is List
                      ? (r.data['results'] as List).length
                      : null,
                }
              : safe(r.data),
        });
        h.next(r);
      },
      onError: (e, h) {
        trace.add({
          'method': e.requestOptions.method,
          'path': e.requestOptions.path,
          'status': e.response?.statusCode,
          'response': safe(e.response?.data),
        });
        h.next(e);
      },
    ),
  );
}

class ControlledCatalog
    implements MovieCatalogService, MovieSearchService, MovieDetailService {
  ControlledCatalog(this.real);
  final TmdbMovieService real;
  bool failNextPage = false;
  bool failSearch = false;
  int? failDetail;
  @override
  Future<TmdbMoviePageDto> discoverMovies({required int page, int? genreId}) {
    if (page > 1 && failNextPage) {
      failNextPage = false;
      throw StateError('injected next-page transport failure');
    }
    return real.discoverMovies(page: page, genreId: genreId);
  }

  @override
  Future<TmdbMoviePageDto> searchMovies({required String query, int page = 1}) {
    if (failSearch) throw StateError('injected search transport failure');
    return real.searchMovies(query: query, page: page);
  }

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) =>
      real.fetchPopular(page: page);
  @override
  Future<List<TmdbGenreDto>> fetchGenres() => real.fetchGenres();
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) {
    if (movieId == failDetail) throw StateError('injected one-movie failure');
    return real.fetchMovieDetail(movieId);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment('W9_PHASE', defaultValue: 'live');
  testWidgets('9주차 Android $phase 실제 화면 검증', (t) async {
    if (phase == 'states') {
      final api = AuthFake();
      final auth = AuthViewModel(api, MemoryTokenStorage());
      final favorites = FavoriteFake();
      final catalog = CatalogFake();
      await t.pumpWidget(
        MovieLogApp(
          authViewModel: auth,
          favoriteApiService: favorites,
          catalogService: catalog,
          movieDetailService: catalog,
          movieSearchService: catalog,
        ),
      );
      await until(t, find.byKey(const Key('login-submit')));
      await auth.login('fixture@example.com', 'test-only');
      await auth.loadMember();
      await until(t, find.byType(MainScreen));
      final router = GoRouter.of(t.element(find.byType(MainScreen)));
      await tap(t, find.text('마이'));
      await tap(t, find.byKey(const Key('open-my-favorites')));
      await until(t, find.text('아직 즐겨찾기한 영화가 없습니다.'));
      await capture(t, '10-favorites-empty-fixture');
      router.pop();
      await pause(t);
      favorites.listError = StateError('injected list failure');
      await tap(t, find.byKey(const Key('open-my-favorites')));
      await until(t, find.text('즐겨찾기 목록을 불러오지 못했습니다.'));
      await capture(t, '11-favorites-error-injected');
      favorites.listError = null;
      favorites.rows = [favorite(1), favorite(2)];
      catalog.failedDetails.add(2);
      await tap(t, find.text('다시 시도'));
      await until(t, find.byKey(const Key('favorite-failed-2')));
      expect(find.byKey(const Key('movie-card-1')), findsOneWidget);
      await capture(t, '12-favorites-partial-injected');
      catalog.failedDetails.clear();
      await tap(t, find.text('이 영화만 다시 시도'));
      await until(t, find.byKey(const Key('movie-card-2')));
      await capture(t, '13-favorites-card-recovered-fixture');
      router.pop();
      await pause(t);
      router.push('/movies/550');
      await until(t, find.byTooltip('즐겨찾기 추가'));
      marker('WEEK9_VIDEO_START=05-controlled-conflicts');
      favorites.current = true;
      favorites.writeError = authError('FAVORITE409_1', 409);
      await tap(t, find.byKey(const Key('favorite-button')));
      await until(t, find.byTooltip('즐겨찾기 해제'));
      expect(favorites.writes, 1);
      await capture(t, '21-conflict409-reconciled-injected');
      favorites.current = false;
      favorites.writeError = authError('FAVORITE404_1', 404);
      await tap(t, find.byKey(const Key('favorite-button')));
      await until(t, find.byTooltip('즐겨찾기 추가'));
      expect(favorites.writes, 2);
      await capture(t, '22-conflict404-reconciled-injected');
      favorites.writeError = DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.receiveTimeout,
      );
      await tap(t, find.byKey(const Key('favorite-button')));
      await until(t, find.byTooltip('즐겨찾기 상태 다시 조회'));
      expect(favorites.current, isFalse);
      expect(favorites.writes, 3);
      await capture(t, '23-timeout-icon-retained-injected');
      marker('WEEK9_VIDEO_STOP=05-controlled-conflicts');
      router.pop();
      await pause(t);
      await tap(t, find.text('영화', skipOffstage: true).last);
      await tap(t, find.byKey(const Key('open-movie-search')));
      marker('WEEK9_VIDEO_START=06-generation-isolation');
      final oldSearch = Completer<TmdbMoviePageDto>();
      catalog.responder = (n, query, genre) => query == '이전'
          ? oldSearch.future
          : Future.value(page(1, [900], total: 1));
      final searchField = find.byKey(const Key('movie-search-field'));
      await enter(t, searchField, '이전');
      await tap(t, find.byTooltip('검색'));
      await enter(t, searchField, '최신');
      await tap(t, find.byTooltip('검색'));
      await until(t, find.byKey(const Key('movie-card-900')));
      oldSearch.complete(page(1, [100], total: 1));
      await pause(t, 500);
      expect(find.byKey(const Key('movie-card-100')), findsNothing);
      await capture(t, '25-search-generation-injected');
      router.pop();
      await pause(t);
      final oldGenre = Completer<TmdbMoviePageDto>();
      catalog.responder = (n, query, genre) => genre == null
          ? oldGenre.future
          : Future.value(page(1, [28], total: 1));
      // Trigger a new unfiltered request, then select another genre before it returns.
      await tap(t, find.byKey(const Key('tmdb-genre-all')));
      await tap(t, find.byKey(const Key('tmdb-genre-28')));
      await until(t, find.byKey(const Key('movie-card-28')));
      oldGenre.complete(page(1, [101], total: 1));
      await pause(t, 500);
      expect(find.byKey(const Key('movie-card-101')), findsNothing);
      await capture(t, '26-genre-generation-injected');
      marker('WEEK9_VIDEO_STOP=06-generation-isolation');
      final client = createWorkbookClient();
      final requests = <Map<String, Object?>>[];
      client.interceptors.add(
        AuthInterceptor(
          auth.storage,
          sessionVersion: () => auth.sessionVersion,
          onExpired: auth.expireSession,
        ),
      );
      observe(client, requests);
      await expectLater(
        FavoriteApiService(client).fetchFavorites(),
        throwsA(isA<DioException>()),
      );
      await until(t, find.byKey(const Key('login-submit')));
      expect(auth.status, AuthStatus.signedOut);
      expect(await auth.storage.readAccessToken(), isNull);
      await capture(t, '20-invalid-token-cleared-actual');
      client.close();
      marker(
        'WEEK9_RESULT=${jsonEncode({'passed': true, 'phase': phase, 'source': 'controlled fixtures plus actual invalid-token API', 'emptyErrorPartialRetry': true, 'conflict409404Reconciled': true, 'requests': requests})}',
      );
      await t.pumpWidget(const SizedBox());
      auth.dispose();
      return;
    }

    await dotenv.load(fileName: '.env');
    expect(
      TmdbConfig.accessToken,
      isNotEmpty,
      reason: 'TMDB token required, value is not printed',
    );
    final public = createWorkbookClient();
    final protected = createWorkbookClient();
    final tmdb = createTmdbClient(TmdbConfig.accessToken);
    final trace = <Map<String, Object?>>[];
    final auth = AuthViewModel(
      AuthApiService(public, protected, version: 'v8'),
      SecureTokenStorage(),
    );
    protected.interceptors.add(
      AuthInterceptor(
        auth.storage,
        sessionVersion: () => auth.sessionVersion,
        onExpired: auth.expireSession,
      ),
    );
    observe(public, trace);
    observe(protected, trace);
    observe(tmdb, trace);
    final favorites = FavoriteApiService(protected);
    final ratings = AuthenticatedRatingApiService(
      public,
      protected,
      version: 'v8',
    );
    final catalog = ControlledCatalog(TmdbMovieService(tmdb));
    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final password =
        'W9a!${List.generate(24, (_) => Random.secure().nextInt(10)).join()}';
    final emailA = 'w9a$suffix@example.com', emailB = 'w9b$suffix@example.com';
    final signup = SignUpService(public, version: 'v8');
    final a = await signup.signUp(
      CreateMemberRequest(
        email: emailA,
        nickname: 'w9a${suffix.substring(6)}',
        password: password,
      ),
    );
    final b = await signup.signUp(
      CreateMemberRequest(
        email: emailB,
        nickname: 'w9b${suffix.substring(6)}',
        password: password,
      ),
    );
    final memberIds = [a.result!.memberId, b.result!.memberId];
    await auth.storage.deleteAccessToken();
    await t.pumpWidget(
      MovieLogApp(
        authViewModel: auth,
        favoriteApiService: favorites,
        authenticatedRatingApiService: ratings,
        movieRecordApiService: MovieRecordApiService(protected),
        catalogService: catalog,
        movieDetailService: catalog,
        movieSearchService: catalog,
      ),
    );
    await until(t, find.byKey(const Key('login-submit')));
    await auth.login(emailA, password);
    await auth.loadMember();
    expect(auth.status, AuthStatus.signedIn);
    await until(t, find.byType(MainScreen));
    final router = GoRouter.of(t.element(find.byType(MainScreen)));
    var completed = false;
    try {
      marker('WEEK9_VIDEO_START=01-favorite-roundtrip');
      router.push('/movies/550');
      await until(t, find.byTooltip('즐겨찾기 추가'));
      await capture(t, '01-favorite-before');
      await tap(t, find.byKey(const Key('favorite-button')));
      await until(t, find.byTooltip('즐겨찾기 해제'));
      expect(await favorites.isFavorite(550), isTrue);
      await capture(t, '02-favorite-added');
      router.pop();
      await pause(t);
      await tap(t, find.text('마이'));
      await tap(t, find.byKey(const Key('open-my-favorites')));
      await until(t, find.byKey(const Key('movie-card-550')), recover: true);
      expect(find.byKey(const Key('main-navigation-bar')), findsNothing);
      await capture(t, '03-my-favorites');
      await tap(t, find.byKey(const Key('movie-card-550')));
      await until(t, find.byTooltip('즐겨찾기 해제'));
      await tap(t, find.byKey(const Key('favorite-button')));
      await until(t, find.byTooltip('즐겨찾기 추가'));
      router.pop();
      await until(t, find.text('아직 즐겨찾기한 영화가 없습니다.'));
      expect(await favorites.isFavorite(550), isFalse);
      await capture(t, '04-return-refresh-empty');
      marker('WEEK9_VIDEO_STOP=01-favorite-roundtrip');
      router.pop();
      await pause(t);

      marker('WEEK9_VIDEO_START=02-pagination-search');
      await tap(t, find.text('영화', skipOffstage: true).last);
      await until(t, find.byKey(const Key('paged-movie-scroll')));
      await capture(t, '05-discover-first-page');
      await t.dragUntilVisible(
        find.byKey(const Key('load-next-page')),
        find.byKey(const Key('paged-movie-scroll')),
        const Offset(0, -600),
        maxIteration: 30,
      );
      catalog.failNextPage = true;
      await tap(t, find.byKey(const Key('load-next-page')));
      await until(t, find.byKey(const Key('retry-next-page')));
      await capture(t, '06-next-page-error-injected');
      await tap(t, find.byKey(const Key('retry-next-page')));
      await pause(t, 1000);
      final successfulPages = trace
          .where((r) => r['path'] == '/discover/movie' && r['status'] == 200)
          .toList();
      expect(
        successfulPages.any((r) => (r['query'] as Map)['page'] == 2),
        isTrue,
      );
      await capture(t, '07-next-page-recovered');
      await tap(t, find.byKey(const Key('infinite-toggle')));
      await t.fling(
        find.byKey(const Key('paged-movie-scroll')),
        const Offset(0, -5000),
        4000,
      );
      await pause(t, 1500);
      expect(
        trace.any(
          (r) =>
              r['path'] == '/discover/movie' &&
              r['query'] is Map &&
              (r['query'] as Map)['page'] == 3,
        ),
        isTrue,
      );
      await capture(t, '19-infinite-scroll');
      await tap(t, find.byKey(const Key('open-movie-search')));
      final field = find.byKey(const Key('movie-search-field'));
      await enter(t, field, '배트맨');
      await pause(t);
      await tap(t, find.byTooltip('검색'));
      await until(t, find.byKey(const Key('paged-movie-scroll')));
      await capture(t, '08-search-success');
      await tap(t, find.byType(MovieCard).first);
      await until(t, find.byKey(const Key('favorite-button')));
      await capture(t, '24-search-result-detail');
      router.pop();
      await pause(t);
      await enter(t, field, 'zzqvxxunfindable$suffix');
      await pause(t);
      await tap(t, find.byTooltip('검색'));
      await until(t, find.text('검색 결과가 없습니다.'));
      await capture(t, '09-search-empty');
      catalog.failSearch = true;
      await enter(t, field, '슈퍼맨');
      await pause(t);
      await tap(t, find.byTooltip('검색'));
      await until(t, find.text('다시 시도'));
      await capture(t, '14-search-error-injected');
      catalog.failSearch = false;
      await tap(t, find.text('다시 시도'));
      await until(t, find.byKey(const Key('paged-movie-scroll')));
      await tap(t, find.byKey(const Key('debounce-toggle')));
      await enter(t, field, '인터스텔라');
      await until(t, find.byKey(const Key('paged-movie-scroll')));
      await capture(t, '15-debounce-success');
      marker('WEEK9_VIDEO_STOP=02-pagination-search');
      router.pop();
      await pause(t);

      marker('WEEK9_VIDEO_START=03-integrated-save');
      router.push('/movies/155');
      await until(t, find.byTooltip('즐겨찾기 추가'));
      await tap(t, find.byKey(const Key('open-rating-dialog-button')));
      await until(t, find.byType(RatingDialog));
      final stars = find.descendant(
        of: find.byType(RatingDialog),
        matching: find.byIcon(Icons.star_rounded),
      );
      await t.tap(stars.at(3));
      await pause(t);
      await enter(
        t,
        find.byKey(const Key('rating-comment-field')),
        '9주차 통합 저장 검증',
      );
      await tap(t, find.byKey(const Key('add-to-favorites-checkbox')));
      await capture(t, '16-integrated-save-ready');
      await tap(t, find.byKey(const Key('confirm-rating-button')));
      await until(t, find.byTooltip('즐겨찾기 해제'));
      for (
        var i = 0;
        i < 30 && find.byType(RatingDialog).evaluate().isNotEmpty;
        i++
      ) {
        await pause(t, 100);
      }
      expect(find.byType(RatingDialog), findsNothing);
      expect(await favorites.isFavorite(155), isTrue);
      await capture(t, '17-integrated-save-success');
      marker('WEEK9_VIDEO_STOP=03-integrated-save');
      router.pop();
      await pause(t);

      marker('WEEK9_VIDEO_START=04-account-isolation');
      await auth.logout();
      await until(t, find.byKey(const Key('login-submit')));
      await auth.login(emailB, password);
      await auth.loadMember();
      await until(t, find.byType(MainScreen));
      await tap(t, find.text('마이'));
      await tap(t, find.byKey(const Key('open-my-favorites')));
      await until(t, find.text('아직 즐겨찾기한 영화가 없습니다.'));
      expect(await favorites.fetchFavorites(), isEmpty);
      await capture(t, '18-account-b-empty');
      marker('WEEK9_VIDEO_STOP=04-account-isolation');
      completed = true;
    } finally {
      await auth.logout();
      await auth.login(emailA, password);
      await auth.loadMember();
      for (final row in await favorites.fetchFavorites()) {
        await favorites.removeFavorite(row.movieId);
      }
      for (final row in auth.sessionRatings.toList()) {
        await ratings.deleteRating(row.ratingId);
      }
      // Login clears the session cache, so find the fixture rating through public member API as well.
      for (final row in await ratings.getMemberRatings(memberIds.first)) {
        await ratings.deleteRating(row.ratingId);
      }
      expect(await favorites.fetchFavorites(), isEmpty);
      expect(await ratings.getMemberRatings(memberIds.first), isEmpty);
      await auth.logout();
      marker(
        'WEEK9_RESULT=${jsonEncode({'passed': completed, 'phase': phase, 'fixtureMemberIds': memberIds, 'fixtureFavoritesAndRatingsRemoved': true, 'requests': trace})}',
      );
      await t.pumpWidget(const SizedBox());
      auth.dispose();
      public.close();
      protected.close();
      tmdb.close();
    }
  });
}
