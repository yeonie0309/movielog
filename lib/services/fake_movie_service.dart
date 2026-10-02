import '../data/mock_movies.dart';
import '../models/movie.dart';

enum MovieLoadMode { success, empty, failure }

class MovieLoadException implements Exception {
  const MovieLoadException();
}

class FakeMovieService {
  const FakeMovieService({this.delay = const Duration(seconds: 1)});

  final Duration delay;

  Future<List<Movie>> fetchMovies({
    MovieLoadMode mode = MovieLoadMode.success,
  }) async {
    await Future<void>.delayed(delay);

    // TODO(5주차 유저별 평점 조회 API): Mock 응답을 실제 서버 응답으로 교체한다.
    return switch (mode) {
      MovieLoadMode.success => List<Movie>.unmodifiable(mockMovies),
      MovieLoadMode.empty => const <Movie>[],
      MovieLoadMode.failure => throw const MovieLoadException(),
    };
  }
}
