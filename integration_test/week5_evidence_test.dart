import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('5주차 상태 화면 증빙: Loading → Empty → Error → 재시도 성공', (tester) async {
    final service = _EvidenceCatalogService();
    final router = AppRouter.create(initialLocation: '/movies', useTmdb: true);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MovieLogApp(routerConfig: router, catalogService: service),
    );
    await tester.pump();
    expect(find.byKey(const Key('movie-list-loading')), findsOneWidget);
    await _pauseForCapture(tester, '04-loading-test-service');

    service.initialRequest.complete(_emptyPage());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-list-empty')), findsOneWidget);
    await _pauseForCapture(tester, '05-empty-test-service');

    await tester.tap(find.byKey(const Key('tmdb-genre-28')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-list-error')), findsOneWidget);
    await _pauseForCapture(tester, '06-error-test-service');

    await tester.tap(find.byKey(const Key('movie-list-retry-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-grid')), findsOneWidget);
    expect(find.byKey(const Key('tmdb-poster-placeholder')), findsOneWidget);
    await _pauseForCapture(tester, '07-retry-success-placeholder-test-service');
  });
}

Future<void> _pauseForCapture(WidgetTester tester, String name) async {
  // Capture the physical emulator with adb while this test state is visible.
  // The fake service is labeled in the filename so it cannot be confused with
  // a live TMDB response.
  // ignore: avoid_print
  print('WEEK5_EVIDENCE_READY=$name');
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(seconds: 18)),
  );
}

TmdbMoviePageDto _emptyPage() => const TmdbMoviePageDto(
  page: 1,
  results: [],
  totalPages: 1,
  totalResults: 0,
);

class _EvidenceCatalogService implements MovieCatalogService {
  final initialRequest = Completer<TmdbMoviePageDto>();
  var _discoverCalls = 0;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async => _emptyPage();

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => const [
    TmdbGenreDto(id: 28, name: '액션'),
  ];

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    _discoverCalls++;
    if (_discoverCalls == 1) return initialRequest.future;
    if (_discoverCalls == 2) throw StateError('테스트용 네트워크 오류');
    return TmdbMoviePageDto(
      page: 1,
      results: [
        TmdbMovieDto.fromJson({
          'id': 550,
          'title': '포스터가 없는 테스트 영화',
          'overview': '재시도 후 표시되는 테스트 데이터입니다.',
          'poster_path': null,
          'backdrop_path': null,
          'release_date': '2026-10-16',
          'genre_ids': [28],
          'vote_average': 8.0,
          'popularity': 1.0,
        }),
      ],
      totalPages: 1,
      totalResults: 1,
    );
  }
}
