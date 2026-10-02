import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/genre_preference.dart';
import '../data/mock_movies.dart';
import '../screens/home_screen.dart';
import '../screens/main_screen.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/movie_list_screen.dart';
import '../screens/my_page_screen.dart';
import '../screens/rating_input_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/start_screen.dart';
import '../services/fake_movie_service.dart';

abstract final class AppRouter {
  static final router = create();

  static GoRouter create({
    String initialLocation = '/start',
    GenrePreferenceStore? genrePreference,
    FakeMovieService movieService = const FakeMovieService(),
    Duration movieRequestTimeout = const Duration(seconds: 4),
  }) {
    final rootNavigatorKey = GlobalKey<NavigatorState>();

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/start',
          builder: (context, state) => const StartScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/rating-practice',
          builder: (context, state) => const RatingInputScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainScreen(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movies',
                  builder: (context, state) {
                    final genres = state.uri.queryParameters['genres'];
                    final selectedGenres = genres == null || genres.isEmpty
                        ? <String>{}
                        : genres.split(',').toSet();
                    final stateName = state.uri.queryParameters['state'];
                    final loadMode = MovieLoadMode.values.firstWhere(
                      (mode) => mode.name == stateName,
                      orElse: () => MovieLoadMode.success,
                    );
                    return MovieListScreen(
                      selectedGenres: selectedGenres,
                      initialMode: loadMode,
                      movieService: movieService,
                      requestTimeout: movieRequestTimeout,
                      genrePreference: genrePreference,
                    );
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my',
                  builder: (context, state) => const MyPageScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/movies/:movieId',
          builder: (context, state) {
            final movieId = int.tryParse(state.pathParameters['movieId'] ?? '');
            return MovieDetailScreen(movie: findMovieById(movieId));
          },
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('페이지를 찾을 수 없어요')),
        body: Center(child: Text(state.error?.toString() ?? '잘못된 경로입니다.')),
      ),
    );
  }
}
