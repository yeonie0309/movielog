import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/data/genre_preference.dart';
import 'package:movielog/movie_log_app.dart';
import 'package:movielog/router/app_router.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pause(WidgetTester tester, Duration duration) async {
    await tester.runAsync(() => Future<void>.delayed(duration));
    await tester.pump();
  }

  testWidgets('Error에서 Retry 후 Success가 표시된다', (tester) async {
    final preference = GenrePreference();
    await preference.save(<String>{});
    final router = AppRouter.create(
      initialLocation: '/movies?state=failure',
      movieService: const FakeMovieService(delay: Duration(seconds: 1)),
      genrePreference: preference,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MovieLogApp(routerConfig: router));
    await pause(tester, const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movie-list-error')), findsOneWidget);
    await pause(tester, const Duration(seconds: 2));

    await tester.tap(find.byKey(const Key('movie-list-retry-button')));
    await tester.pump();
    expect(find.byKey(const Key('movie-list-loading')), findsOneWidget);
    await pause(tester, const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('movie-grid')), findsOneWidget);
    await pause(tester, const Duration(seconds: 3));
  });

  testWidgets('앱 화면을 다시 생성하면 저장한 장르가 복원된다', (tester) async {
    final preference = GenrePreference();
    await preference.save(<String>{});
    final firstRouter = AppRouter.create(
      initialLocation: '/movies',
      movieService: const FakeMovieService(delay: Duration(seconds: 1)),
      genrePreference: preference,
    );

    await tester.pumpWidget(MovieLogApp(routerConfig: firstRouter));
    await pause(tester, const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('genre-chip-드라마')));
    await tester.pumpAndSettle();
    await pause(tester, const Duration(seconds: 3));
    expect(
      tester
          .widget<FilterChip>(find.byKey(const Key('genre-chip-드라마')))
          .selected,
      isTrue,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('앱을 다시 시작하는 중...'),
              ],
            ),
          ),
        ),
      ),
    );
    firstRouter.dispose();
    await pause(tester, const Duration(seconds: 2));

    final restartedRouter = AppRouter.create(
      initialLocation: '/movies',
      movieService: const FakeMovieService(delay: Duration(seconds: 1)),
      genrePreference: preference,
    );
    addTearDown(restartedRouter.dispose);
    await tester.pumpWidget(MovieLogApp(routerConfig: restartedRouter));
    await pause(tester, const Duration(milliseconds: 1300));
    await tester.pumpAndSettle();

    final restoredChip = tester.widget<FilterChip>(
      find.byKey(const Key('genre-chip-드라마')),
    );
    expect(restoredChip.selected, isTrue);
    expect(find.byKey(const Key('movie-card-1')), findsOneWidget);
    expect(find.byKey(const Key('movie-card-2')), findsNothing);
    await pause(tester, const Duration(seconds: 3));
  });
}
