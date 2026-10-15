import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/data/models/tmdb_movie_dto.dart';
import 'package:movielog/data/models/tmdb_movie_page_dto.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/view_models/movie_load_status.dart';
import 'package:movielog/widgets/movie/rating_dialog.dart';

void main() {
  test('TMDB DTO는 snake_case, null, num을 변환한다', () {
    final movie = TmdbMovieDto.fromJson({
      'id': 550,
      'title': '테스트 영화',
      'poster_path': null,
      'genre_ids': [18, 28],
      'vote_average': 8,
      'popularity': 12.5,
    });
    expect(movie.id, 550);
    expect(movie.posterPath, isNull);
    expect(movie.overview, isEmpty);
    expect(movie.genreIds, [18, 28]);
    expect(movie.voteAverage, 8.0);
  });

  test('Service는 Popular/Discover/Genre 경로와 쿼리를 전송한다', () async {
    final requests = <RequestOptions>[];
    final dio = createTmdbClient('test-token');
    dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: options.path == '/genre/movie/list'
                  ? {
                      'genres': [
                        {'id': 18, 'name': '드라마'},
                      ],
                    }
                  : {
                      'page': 1,
                      'results': [_movieJson(550)],
                      'total_pages': 1,
                      'total_results': 1,
                    },
            ),
          );
        },
      ),
    );
    final service = TmdbMovieService(dio);

    await service.fetchPopular();
    await service.discoverMovies(page: 1, genreId: 18);
    await service.discoverMovies(page: 1);
    await service.fetchGenres();

    expect(requests.map((request) => request.path), [
      '/movie/popular',
      '/discover/movie',
      '/discover/movie',
      '/genre/movie/list',
    ]);
    expect(requests[0].queryParameters['language'], 'ko-KR');
    expect(requests[1].queryParameters['with_genres'], 18);
    expect(requests[2].queryParameters.containsKey('with_genres'), isFalse);
    expect(requests[1].queryParameters['include_adult'], isFalse);
    expect(requests[3].queryParameters['language'], 'ko');
    expect(requests[0].headers['Authorization'], 'Bearer test-token');
  });

  test('Popular 결과는 최대 5개만 사용한다', () async {
    final service = _FakeCatalogService()
      ..popular = _page(1, List.generate(8, (index) => _movie(index + 1)));
    final viewModel = MovieHomeViewModel(service);
    addTearDown(viewModel.dispose);

    await viewModel.loadPopular();

    expect(viewModel.status, MovieLoadStatus.success);
    expect(viewModel.popularMovies.map((movie) => movie.id), [1, 2, 3, 4, 5]);
  });

  test('Discover는 페이지를 이어 받고 TMDB ID로 중복 제거해 30개로 자른다', () async {
    final service = _FakeCatalogService()
      ..pages[1] = _page(1, List.generate(20, (index) => _movie(index + 1)), 3)
      ..pages[2] = _page(
        2,
        List.generate(20, (index) => _movie(index + 16)),
        3,
      );
    final viewModel = MovieListViewModel(service);
    addTearDown(viewModel.dispose);

    await viewModel.loadInitial();

    expect(viewModel.status, MovieLoadStatus.success);
    expect(viewModel.movies.length, 30);
    expect(viewModel.movies.map((movie) => movie.id).toSet().length, 30);
    expect(service.requestedPages, [1, 2]);
  });

  test('장르 선택 시 page 1부터 재조회하고 로딩 중 선택을 막는다', () async {
    final service = _FakeCatalogService()..pages[1] = _page(1, [_movie(1)]);
    final viewModel = MovieListViewModel(service);
    addTearDown(viewModel.dispose);
    await viewModel.loadInitial();

    final pending = Completer<TmdbMoviePageDto>();
    service.nextDiscover = pending.future;
    final selection = viewModel.selectGenre(18);
    expect(viewModel.status, MovieLoadStatus.loading);
    await viewModel.selectGenre(28);
    expect(viewModel.selectedGenreId, 18);

    pending.complete(_page(1, [_movie(550)]));
    await selection;
    expect(viewModel.movies.single.id, 550);
    expect(service.requestedGenres.last, 18);

    await viewModel.selectGenre(null);
    expect(service.requestedGenres.last, isNull);
    expect(service.requestedPages.last, 1);
  });

  test('빈 목록, 오류, 다시 시도 상태를 구분한다', () async {
    final service = _FakeCatalogService();
    final viewModel = MovieListViewModel(service);
    addTearDown(viewModel.dispose);

    await viewModel.loadInitial();
    expect(viewModel.status, MovieLoadStatus.empty);

    service.failNextDiscover = true;
    await viewModel.selectGenre(18);
    expect(viewModel.status, MovieLoadStatus.error);
    expect(viewModel.message, isNotEmpty);

    service.pages[1] = _page(1, [_movie(550)]);
    await viewModel.retry();
    expect(viewModel.status, MovieLoadStatus.success);
    expect(viewModel.movies.single.id, 550);
    expect(service.requestedGenres.last, 18);
  });

  testWidgets('TMDB 카드의 ID가 상세 화면과 평점 Dialog까지 전달된다', (tester) async {
    final service = _FakeCatalogService()..pages[1] = _page(1, [_movie(550)]);
    final router = AppRouter.create(initialLocation: '/movies', useTmdb: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MovieLogApp(routerConfig: router, catalogService: service),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movie-card-550')), findsOneWidget);
    expect(find.byKey(const Key('tmdb-poster-placeholder')), findsOneWidget);
    await tester.tap(find.byKey(const Key('movie-card-550')));
    await tester.pumpAndSettle();
    expect(find.text('테스트 영화 550'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('open-rating-dialog-button')),
    );
    await tester.tap(find.byKey(const Key('open-rating-dialog-button')));
    await tester.pumpAndSettle();
    expect(tester.widget<RatingDialog>(find.byType(RatingDialog)).movieId, 550);
  });
}

Map<String, dynamic> _movieJson(int id) => {
  'id': id,
  'title': '테스트 영화 $id',
  'overview': '테스트 줄거리',
  'poster_path': null,
  'backdrop_path': null,
  'release_date': '2026-10-16',
  'genre_ids': [18],
  'vote_average': 8.0,
  'popularity': 100.0,
};

TmdbMovieDto _movie(int id) => TmdbMovieDto.fromJson(_movieJson(id));

TmdbMoviePageDto _page(
  int page,
  List<TmdbMovieDto> movies, [
  int totalPages = 1,
]) => TmdbMoviePageDto(
  page: page,
  results: movies,
  totalPages: totalPages,
  totalResults: movies.length,
);

class _FakeCatalogService implements MovieCatalogService {
  TmdbMoviePageDto popular = _page(1, [_movie(1)]);
  final Map<int, TmdbMoviePageDto> pages = {};
  final List<int> requestedPages = [];
  final List<int?> requestedGenres = [];
  Future<TmdbMoviePageDto>? nextDiscover;
  bool failNextDiscover = false;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async => popular;

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    requestedPages.add(page);
    requestedGenres.add(genreId);
    if (failNextDiscover) {
      failNextDiscover = false;
      throw StateError('테스트 네트워크 오류');
    }
    final pending = nextDiscover;
    nextDiscover = null;
    return pending ?? pages[page] ?? _page(page, []);
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => [
    const TmdbGenreDto(id: 18, name: '드라마'),
  ];
}
