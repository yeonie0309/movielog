import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/data/genre_preference.dart';
import 'package:movielog/screens/movie_list_screen.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  late _MemoryGenrePreference preference;

  setUp(() {
    preference = _MemoryGenrePreference();
  });

  Future<GoRouter> pumpMovieList(
    WidgetTester tester, {
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    final router = GoRouter(
      initialLocation: '/movies',
      routes: [
        GoRoute(
          path: '/movies',
          builder: (context, state) {
            final genres = state.uri.queryParameters['genres'];
            return Scaffold(
              body: MovieListScreen(
                selectedGenres: genres == null || genres.isEmpty
                    ? <String>{}
                    : genres.split(',').toSet(),
                initialMode: mode,
                movieService: const FakeMovieService(delay: Duration.zero),
                genrePreference: preference,
              ),
            );
          },
        ),
        GoRoute(
          path: '/movies/:movieId',
          builder: (context, state) => const Scaffold(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    return router;
  }

  testWidgets('대기 후 성공 상태를 표시한다', (tester) async {
    await pumpMovieList(tester);

    expect(find.byKey(const Key('movie-list-loading')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-grid')), findsOneWidget);
  });

  testWidgets('빈 응답이면 Empty 위젯을 표시한다', (tester) async {
    await pumpMovieList(tester, mode: MovieLoadMode.empty);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movie-list-empty')), findsOneWidget);
  });

  testWidgets('오류에서 다시 시도하면 성공 목록을 표시한다', (tester) async {
    await pumpMovieList(tester, mode: MovieLoadMode.failure);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movie-list-error')), findsOneWidget);
    expect(find.textContaining('MovieLoadException'), findsNothing);

    await tester.tap(find.byKey(const Key('movie-list-retry-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('movie-grid')), findsOneWidget);
  });

  testWidgets('선택한 장르를 저장하고 다시 생성할 때 복원한다', (tester) async {
    await pumpMovieList(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('genre-chip-드라마')));
    await tester.pumpAndSettle();
    expect(preference.savedGenres, {'드라마'});

    final secondRouter = GoRouter(
      initialLocation: '/movies',
      routes: [
        GoRoute(
          path: '/movies',
          builder: (context, state) => Scaffold(
            body: MovieListScreen(
              selectedGenres: const <String>{},
              movieService: const FakeMovieService(delay: Duration.zero),
              genrePreference: preference,
            ),
          ),
        ),
      ],
    );
    addTearDown(secondRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: secondRouter));
    await tester.pumpAndSettle();

    final dramaChip = tester.widget<FilterChip>(
      find.byKey(const Key('genre-chip-드라마')),
    );
    expect(dramaChip.selected, isTrue);
    expect(find.byKey(const Key('movie-card-1')), findsOneWidget);
    expect(find.byKey(const Key('movie-card-2')), findsNothing);
  });
}

class _MemoryGenrePreference implements GenrePreferenceStore {
  Set<String> savedGenres = <String>{};

  @override
  Future<Set<String>> read() async => Set<String>.of(savedGenres);

  @override
  Future<void> save(Set<String> genres) async {
    savedGenres = Set<String>.of(genres);
  }
}
