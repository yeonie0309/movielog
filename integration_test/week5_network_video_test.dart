import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/config/tmdb_config.dart';
import 'package:movielog/core/network/tmdb_client.dart';
import 'package:movielog/data/services/tmdb_movie_service.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/tmdb_movie_list_screen.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실제 TMDB Discover 요청과 장르 전후 화면 녹화', (tester) async {
    await dotenv.load(fileName: '.env');
    final requestLines = ValueNotifier<List<String>>([]);
    addTearDown(requestLines.dispose);

    final client = createTmdbClient(TmdbConfig.accessToken);
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/discover/movie' &&
              options.queryParameters['page'] == 1) {
            final genre = options.queryParameters['with_genres'];
            requestLines.value = [
              ...requestLines.value,
              'GET /discover/movie?page=1&with_genres=${genre ?? '(없음)'}',
            ];
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (response.requestOptions.path == '/discover/movie' &&
              response.requestOptions.queryParameters['page'] == 1) {
            requestLines.value = [
              ...requestLines.value,
              '↳ HTTP ${response.statusCode}',
            ];
          }
          handler.next(response);
        },
      ),
    );

    final router = AppRouter.create(initialLocation: '/movies', useTmdb: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      Stack(
        alignment: Alignment.topLeft,
        children: [
          MovieLogApp(
            routerConfig: router,
            catalogService: TmdbMovieService(client),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 105,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: ValueListenableBuilder<List<String>>(
                valueListenable: requestLines,
                builder: (context, lines, child) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xE6212121),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      lines.isEmpty
                          ? '실제 TMDB Discover 요청 대기 중'
                          : lines.join('\n'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    await _waitFor(tester, find.byKey(const Key('movie-grid')));
    final listContext = tester.element(find.byType(TmdbMovieListScreen));
    final viewModel = listContext.read<MovieListViewModel>();
    expect(viewModel.movies.length, 30);
    expect(requestLines.value.first, contains('with_genres=(없음)'));
    // ignore: avoid_print
    print('WEEK5_VIDEO_READY=전체 30편');
    await _holdForRecording(tester, const Duration(seconds: 25));

    await tester.tap(find.byKey(const Key('tmdb-genre-28')));
    await tester.pump();
    await _waitFor(tester, find.byKey(const Key('movie-grid')));
    expect(viewModel.selectedGenreId, 28);
    expect(viewModel.movies, isNotEmpty);
    expect(
      requestLines.value.any((line) => line.contains('with_genres=28')),
      isTrue,
    );
    // ignore: avoid_print
    print('WEEK5_VIDEO_STATE=액션 30편');
    await _holdForRecording(tester, const Duration(seconds: 12));

    await tester.tap(find.byKey(const Key('tmdb-genre-all')));
    await tester.pump();
    await _waitFor(tester, find.byKey(const Key('movie-grid')));
    expect(viewModel.selectedGenreId, isNull);
    expect(viewModel.movies.length, 30);
    expect(
      requestLines.value.where((line) => line.contains('with_genres=(없음)')),
      hasLength(2),
    );
    // ignore: avoid_print
    print('WEEK5_VIDEO_STATE=전체 복귀 30편');
    await _holdForRecording(tester, const Duration(seconds: 8));
  });
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(seconds: 1));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('30초 안에 실제 TMDB 목록이 표시되지 않았습니다.');
}

Future<void> _holdForRecording(WidgetTester tester, Duration duration) async {
  await tester.runAsync(() => Future<void>.delayed(duration));
}
