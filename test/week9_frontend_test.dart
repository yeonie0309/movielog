import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:movielog/core/network/auth_interceptor.dart';
import 'package:movielog/core/network/workbook_client.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/core/session/session_guard.dart';
import 'package:movielog/core/session/auth_session_bridge.dart';
import 'package:movielog/core/utils/map_bounded.dart';
import 'package:movielog/data/models/favorite_models.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/favorite_api_service.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/screens/movie_search_screen.dart';
import 'package:movielog/widgets/movie/rating_dialog.dart';
import 'package:movielog/widgets/movie/movie_rating_input.dart';
import 'package:movielog/widgets/movielog_button.dart';
import 'package:movielog/view_models/auth_view_model.dart';
import 'package:movielog/view_models/load_phase.dart';
import 'package:movielog/view_models/paged_movies_view_model.dart';
import 'package:movielog/view_models/favorites_view_model.dart';
import 'package:movielog/view_models/favorite_detail_view_model.dart';

import 'week8_auth_test.dart' show AuthFake, MemoryTokenStorage, authError;

TmdbMovieDto movie(int id) =>
    TmdbMovieDto.fromJson({'id': id, 'title': '영화 $id'});
TmdbMoviePageDto page(int n, List<int> ids, {int total = 3}) =>
    TmdbMoviePageDto(
      page: n,
      results: ids.map(movie).toList(),
      totalPages: total,
      totalResults: 60,
    );
FavoriteResponseDto favorite(int id) => FavoriteResponseDto(
  favoriteId: id + 1000,
  movieId: id,
  createdAt: DateTime(2026),
);

class CatalogFake
    implements MovieCatalogService, MovieSearchService, MovieDetailService {
  final calls = <({int page, String? query, int? genre})>[];
  Future<TmdbMoviePageDto> Function(int, String?, int?)? responder;
  final failedDetails = <int>{};
  final detailCalls = <int>[];
  int active = 0;
  int maxActive = 0;
  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    calls.add((page: page, query: null, genre: genreId));
    return responder?.call(page, null, genreId) ?? Future.value(weekPage(page));
  }

  TmdbMoviePageDto weekPage(int n) =>
      page(n, List.generate(20, (i) => (n - 1) * 20 + i + 1));
  @override
  Future<TmdbMoviePageDto> searchMovies({
    required String query,
    int page = 1,
  }) async {
    calls.add((page: page, query: query, genre: null));
    return responder?.call(page, query, null) ?? Future.value(weekPage(page));
  }

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async => weekPage(page);
  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => [
    const TmdbGenreDto(id: 28, name: '액션'),
  ];
  @override
  Future<TmdbMovieDto> fetchMovieDetail(int movieId) async {
    detailCalls.add(movieId);
    active++;
    if (active > maxActive) maxActive = active;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    active--;
    if (failedDetails.contains(movieId)) {
      throw StateError('injected TMDB failure');
    }
    return movie(movieId);
  }
}

class FavoriteFake extends FavoriteApiService {
  FavoriteFake() : super(Dio());
  List<FavoriteResponseDto> rows = [];
  bool current = false;
  int writes = 0;
  int reads = 0;
  Object? writeError;
  Object? listError;
  Completer<List<FavoriteResponseDto>>? pending;
  @override
  Future<List<FavoriteResponseDto>> fetchFavorites() async {
    if (listError != null) throw listError!;
    return pending?.future ?? rows;
  }

  @override
  Future<bool> isFavorite(int movieId) async {
    reads++;
    return current;
  }

  @override
  Future<FavoriteResponseDto> addFavorite(int movieId) async {
    writes++;
    if (writeError != null) throw writeError!;
    current = true;
    return favorite(movieId);
  }

  @override
  Future<void> removeFavorite(int movieId) async {
    writes++;
    if (writeError != null) throw writeError!;
    current = false;
  }
}

void main() {
  testWidgets(
    'integrated rating retains inputs on transport failure and closes on contract conflict',
    (tester) async {
      var conflict = false;
      bool? requestedFavorite;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => RatingDialog(
                    showAddToFavorite: true,
                    onRecordSubmit: (score, comment, addToFavorites) async {
                      requestedFavorite = addToFavorites;
                      if (conflict) {
                        throw const RatingDialogClosed('이미 평점을 남겼습니다.');
                      }
                      throw StateError('네트워크 실패');
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
      tester
          .widget<MovieRatingInput>(find.byType(MovieRatingInput))
          .onRatingUpdate(4);
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('rating-comment-field')),
        '입력 유지',
      );
      await tester.tap(find.byKey(const Key('add-to-favorites-checkbox')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('confirm-rating-button')));
      await tester.pumpAndSettle();
      expect(requestedFavorite, isTrue);
      expect(find.byType(RatingDialog), findsOneWidget);
      expect(find.text('입력 유지'), findsOneWidget);
      expect(find.text('선택한 평점: 4.0'), findsOneWidget);
      conflict = true;
      await tester.tap(find.byKey(const Key('confirm-rating-button')));
      await tester.pumpAndSettle();
      expect(find.byType(RatingDialog), findsNothing);
      expect(find.text('이미 평점을 남겼습니다.'), findsOneWidget);
    },
  );
  test(
    'TMDB client does not leak its own bearer to an absolute external URL',
    () async {
      final dio = createTmdbClient('test-only-tmdb');
      addTearDown(dio.close);
      final attached = <bool>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            attached.add(o.headers.containsKey('Authorization'));
            h.resolve(Response(requestOptions: o, statusCode: 200));
          },
        ),
      );
      for (final path in [
        '/search/movie',
        'https://workbook.devnoco.com/v8/favorites',
        'https://api.themoviedb.org.evil.example/3/movie',
        'http://api.themoviedb.org/3/movie',
      ]) {
        await dio.get(path);
      }
      expect(attached, [true, false, false, false]);
    },
  );
  test(
    'first page only, append over 30, dedupe, same failed page retry, end',
    () async {
      final service = CatalogFake();
      final vm = PagedMoviesViewModel(service);
      addTearDown(vm.dispose);
      await vm.loadInitial();
      expect(service.calls.map((r) => r.page), [1]);
      service.responder = (n, _, _) async => throw StateError('offline');
      await vm.loadNextPage();
      expect(vm.items.length, 20);
      expect(vm.nextPage, 2);
      expect(vm.nextPageError, isNotNull);
      service.responder = (n, _, _) async =>
          page(n, [20, ...List.generate(20, (i) => i + 21)], total: 2);
      await vm.loadNextPage();
      expect(service.calls.map((r) => r.page), [1, 2, 2]);
      expect(vm.items.length, 40);
      expect(vm.hasMore, isFalse);
      await vm.loadNextPage();
      expect(service.calls.length, 3);
    },
  );

  test('in-flight next page blocked; stale success/error/finally cannot modify new genre', () async {
    final service = CatalogFake();
    final vm = PagedMoviesViewModel(service);
    addTearDown(vm.dispose);
    await vm.loadInitial();
    final old = Completer<TmdbMoviePageDto>();
    service.responder = (n, _, _) => old.future;
    final pending = vm.loadNextPage();
    await vm.loadNextPage();
    expect(service.calls.length, 2);
    final fresh = Completer<TmdbMoviePageDto>();
    service.responder = (n, _, _) => fresh.future;
    final changed = vm.loadInitial(selectedGenre: 28);
    expect(vm.items, isEmpty);
    expect(vm.loadingMore, isFalse);
    old.completeError(StateError('old request'));
    await pending;
    expect(vm.phase, LoadPhase.loading);
    expect(vm.nextPageError, isNull);
    fresh.complete(page(1, [900], total: 1));
    await changed;
    expect(vm.items.single.id, 900);
  });

  test('edited query invalidates old response before debounce; blank never requests; dispose safe', () async {
    final service = CatalogFake();
    final vm = PagedMoviesViewModel(
      service,
      searchService: service,
      searchMode: true,
    );
    await vm.loadInitial(searchQuery: '   ');
    expect(service.calls, isEmpty);
    expect(vm.phase, LoadPhase.idle);
    final old = Completer<TmdbMoviePageDto>();
    service.responder = (n, q, g) => old.future;
    final pending = vm.loadInitial(searchQuery: '배트맨');
    vm.invalidateQuery('슈퍼맨');
    old.complete(page(1, [1]));
    await pending;
    expect(vm.items, isEmpty);
    expect(vm.phase, LoadPhase.idle);
    final another = Completer<TmdbMoviePageDto>();
    service.responder = (n, q, g) => another.future;
    final disposed = vm.loadInitial(searchQuery: '슈퍼맨');
    vm.dispose();
    another.completeError(StateError('after dispose'));
    await disposed;
  });

  test('empty/error/retry and page 500 cap', () async {
    final service = CatalogFake();
    final vm = PagedMoviesViewModel(service);
    addTearDown(vm.dispose);
    service.responder = (n, q, g) async => page(n, []);
    await vm.loadInitial();
    expect(vm.phase, LoadPhase.empty);
    service.responder = (n, q, g) async => throw StateError('offline');
    await vm.refresh();
    expect(vm.phase, LoadPhase.error);
    service.responder = (n, q, g) async => page(n, [n], total: 1000);
    await vm.refresh();
    for (var n = 2; n <= 500; n++) {
      await vm.loadNextPage();
    }
    expect(vm.nextPage, 501);
    expect(vm.hasMore, isFalse);
    await vm.loadNextPage();
    expect(service.calls.last.page, 500);
  });

  test(
    'bounded TMDB enrichment preserves order; one failure and per-card retry',
    () async {
      final api = FavoriteFake()
        ..rows = List.generate(12, (i) => favorite(i + 1));
      final movies = CatalogFake()..failedDetails.add(3);
      final session = SessionGuard()..sync(1, 'a@example.com');
      final vm = FavoritesViewModel(api, movies, session);
      addTearDown(vm.dispose);
      addTearDown(session.dispose);
      await vm.refresh();
      expect(vm.phase, LoadPhase.success);
      expect(vm.items.length, 12);
      expect(movies.maxActive, lessThanOrEqualTo(5));
      expect(vm.items[2].failed, isTrue);
      movies.failedDetails.clear();
      movies.detailCalls.clear();
      await vm.retryMovie(3);
      expect(movies.detailCalls, [3]);
      expect(vm.items[2].movie!.id, 3);
    },
  );

  test(
    'favorites empty differs from API failure; refresh removes released row',
    () async {
      final api = FavoriteFake();
      final session = SessionGuard()..sync(1, 'a@example.com');
      final vm = FavoritesViewModel(api, CatalogFake(), session);
      addTearDown(vm.dispose);
      addTearDown(session.dispose);
      await vm.refresh();
      expect(vm.phase, LoadPhase.empty);
      api.listError = StateError('offline');
      await vm.refresh();
      expect(vm.phase, LoadPhase.error);
      api.listError = null;
      api.rows = [favorite(1), favorite(2)];
      await vm.refresh();
      expect(vm.items.length, 2);
      api.rows = [favorite(2)];
      await vm.refresh();
      expect(vm.items.single.favorite.movieId, 2);
    },
  );

  test('logout/account switch clears cache immediately; late account A response ignored', () async {
    final api = FavoriteFake()..pending = Completer();
    final session = SessionGuard()..sync(1, 'a@example.com');
    final vm = FavoritesViewModel(api, CatalogFake(), session);
    addTearDown(vm.dispose);
    addTearDown(session.dispose);
    final old = vm.refresh();
    session.sync(2, null);
    expect(vm.items, isEmpty);
    session.sync(3, 'b@example.com');
    api.pending!.complete([favorite(1)]);
    await old;
    expect(vm.items, isEmpty);
    expect(vm.phase, LoadPhase.idle);
    api.pending = null;
    api.rows = [favorite(2)];
    await vm.refresh();
    expect(vm.items.single.movie!.id, 2);
  });

  test(
    'same account new login invalidates, nickname update does not',
    () async {
      final auth = AuthViewModel(AuthFake(), MemoryTokenStorage());
      final guard = SessionGuard();
      final bridge = AuthSessionBridge(auth, guard);
      addTearDown(() {
        bridge.dispose();
        guard.dispose();
        auth.dispose();
      });
      await auth.login('a@example.com', 'test');
      await auth.loadMember();
      final first = guard.generation;
      await auth.updateNickname('새이름');
      expect(guard.generation, first);
      await auth.logout();
      await auth.login('a@example.com', 'test');
      await auth.loadMember();
      expect(guard.generation, greaterThan(first));
    },
  );

  test('favorite POST/DELETE success; 409/404 reconcile without replay; timeout preserves state', () async {
    final api = FavoriteFake();
    final session = SessionGuard()..sync(1, 'a@example.com');
    final vm = FavoriteDetailViewModel(api, session, 550);
    addTearDown(vm.dispose);
    addTearDown(session.dispose);
    await vm.load();
    await vm.toggle();
    expect(vm.isFavorite, isTrue);
    await vm.toggle();
    expect(vm.isFavorite, isFalse);
    api.current = true;
    api.writeError = authError('FAVORITE409_1', 409);
    await vm.toggle();
    expect(vm.isFavorite, isTrue);
    api.current = false;
    api.writeError = authError('FAVORITE404_1', 404);
    await vm.toggle();
    expect(vm.isFavorite, isFalse);
    final writes = api.writes;
    api.writeError = DioException(
      requestOptions: RequestOptions(),
      type: DioExceptionType.receiveTimeout,
    );
    await vm.toggle();
    expect(vm.isFavorite, isFalse);
    expect(api.writes, writes + 1);
    expect(vm.busy, isFalse);
  });

  test('v8 favorites wrapper list/status/delete200-null; movie-record false accepts null favorite', () async {
    final dio = Dio();
    addTearDown(dio.close);
    final paths = <String>[];
    final row = {
      'favoriteId': 9,
      'movieId': 550,
      'createdAt': '2026-11-27T00:00:00Z',
    };
    final rating = {
      'ratingId': 1,
      'movieId': 550,
      'score': 4,
      'comment': null,
      'createdAt': '2026-11-27T00:00:00Z',
      'updatedAt': '2026-11-27T00:00:00Z',
    };
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          paths.add('${o.method} ${o.path}');
          final Object? result = o.path.endsWith('movie-records')
              ? {'rating': rating, 'favorite': null}
              : o.method == 'DELETE'
              ? null
              : o.method == 'POST'
              ? row
              : o.path.endsWith('/550')
              ? {'isFavorite': false}
              : [row];
          h.resolve(
            Response(
              requestOptions: o,
              statusCode: o.method == 'POST' ? 201 : 200,
              data: {
                'isSuccess': true,
                'code': 'COMMON200',
                'message': 'ok',
                'result': result,
              },
            ),
          );
        },
      ),
    );
    final api = FavoriteApiService(dio);
    expect((await api.fetchFavorites()).single.movieId, 550);
    expect(await api.isFavorite(550), isFalse);
    await api.addFavorite(550);
    await api.removeFavorite(550);
    final record = await MovieRecordApiService(dio)
        .create(movieId: 550, score: 4, addToFavorites: false);
    expect(record.favorite, isNull);
    expect(record.rating.score, 4);
    expect(paths, [
      'GET /v8/favorites',
      'GET /v8/favorites/550',
      'POST /v8/favorites',
      'DELETE /v8/favorites/550',
      'POST /v8/movie-records',
    ]);
  });

  test('v8 JWT allowlist does not send token to TMDB, public paths, HTTP or hostile host', () async {
    final dio = createWorkbookClient();
    addTearDown(dio.close);
    final storage = MemoryTokenStorage()..token = 'test-only-token';
    dio.interceptors.add(
      AuthInterceptor(
        storage,
        sessionVersion: () => 1,
        onExpired: (_) async {},
      ),
    );
    final attached = <bool>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          attached.add(o.headers.containsKey('Authorization'));
          h.resolve(Response(requestOptions: o, statusCode: 200));
        },
      ),
    );
    for (final path in [
      '/v8/favorites',
      '/v8/favorites/550',
      '/v8/movie-records',
      '/v8/members/me',
      '/v8/auth/login',
      '/v8/members/1/ratings',
      'https://api.themoviedb.org/3/search/movie',
      'http://workbook.devnoco.com/v8/favorites',
      'https://workbook.devnoco.com.evil.example/v8/favorites',
    ]) {
      await dio.get(path);
    }
    expect(attached, [
      true,
      true,
      true,
      true,
      false,
      false,
      false,
      false,
      false,
    ]);
  });

  test('mapBounded preserves order and rejects invalid concurrency', () async {
    expect(await mapBounded([3, 2, 1], (n) async => n * 2, concurrency: 2), [
      6,
      4,
      2,
    ]);
    await expectLater(
      mapBounded<int, int>([1], (n) async => n, concurrency: 0),
      throwsArgumentError,
    );
  });

  testWidgets(
    'search defaults to submit only; 500ms debounce and explicit submit cancels timer',
    (tester) async {
      final service = CatalogFake();
      final vm = PagedMoviesViewModel(
        service,
        searchService: service,
        searchMode: true,
      );
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: vm,
          child: const MaterialApp(home: MovieSearchScreen()),
        ),
      );
      final field = find.byKey(const Key('movie-search-field'));
      await tester.enterText(field, '배트맨');
      await tester.pump(const Duration(milliseconds: 600));
      expect(service.calls, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(service.calls.single.query, '배트맨');
      await tester.tap(find.byKey(const Key('debounce-toggle')));
      await tester.pump();
      await tester.enterText(field, '슈퍼맨');
      await tester.pump(const Duration(milliseconds: 499));
      expect(service.calls.length, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(service.calls.last.query, '슈퍼맨');
      await tester.enterText(field, '인터스텔라');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      final count = service.calls.length;
      await tester.pump(const Duration(milliseconds: 600));
      expect(service.calls.length, count);
      await tester.enterText(field, '미완료');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      expect(service.calls.length, count);
      vm.dispose();
    },
  );
}
