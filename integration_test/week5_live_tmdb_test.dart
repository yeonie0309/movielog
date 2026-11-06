import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/screens/movie_detail_screen.dart';
import 'package:movielog/screens/tmdb_home_screen.dart';
import 'package:movielog/screens/tmdb_movie_list_screen.dart';
import 'package:movielog/view_models/movie_home_view_model.dart';
import 'package:movielog/view_models/movie_list_view_model.dart';
import 'package:movielog/widgets/movie/rating_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('실제 TMDB 홈·목록·장르·상세·평점 ID 흐름', (tester) async {
    await dotenv.load(fileName: '.env');
    final router = AppRouter.create(initialLocation: '/home', useTmdb: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(MovieLogApp(routerConfig: router));

    await _waitFor(tester, find.byKey(const Key('tmdb-popular-list')));
    final homeContext = tester.element(find.byType(TmdbHomeScreen));
    final homeModel = homeContext.read<MovieHomeViewModel>();
    expect(homeModel.popularMovies.length, 5);

    await tester.tap(find.byTooltip('영화 검색'));
    await tester.pump();
    await _waitFor(tester, find.byKey(const Key('movie-grid')));
    final listContext = tester.element(find.byType(TmdbMovieListScreen));
    final listModel = listContext.read<MovieListViewModel>();
    expect(listModel.genres, isNotEmpty);
    expect(listModel.movies.length, 30);
    expect(listModel.movies.map((movie) => movie.id).toSet().length, 30);

    await tester.tap(find.byKey(const Key('tmdb-genre-28')));
    await tester.pump();
    await _waitFor(tester, find.byKey(const Key('movie-grid')));
    expect(listModel.selectedGenreId, 28);
    expect(listModel.movies, isNotEmpty);
    expect(
      listModel.movies.every((movie) => movie.genreIds.contains(28)),
      isTrue,
    );

    final movieId = listModel.movies.first.id;
    await tester.tap(find.byKey(Key('movie-card-$movieId')));
    await tester.pump();
    await _waitFor(tester, find.byType(MovieDetailScreen));
    expect(
      tester
          .widget<MovieDetailScreen>(find.byType(MovieDetailScreen))
          .movie
          ?.id,
      movieId,
    );

    final ratingButton = find.byKey(const Key('open-rating-dialog-button'));
    await tester.ensureVisible(ratingButton);
    await tester.tap(ratingButton);
    await tester.pumpAndSettle();
    expect(
      tester.widget<RatingDialog>(find.byType(RatingDialog)).movieId,
      movieId,
    );
  });
}

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 30; attempt++) {
    await tester.pump(const Duration(seconds: 1));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('30초 안에 예상한 TMDB 화면이 표시되지 않았습니다.');
}
