import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/services/fake_movie_service.dart';

void main() {
  const service = FakeMovieService(delay: Duration.zero);

  test('성공 모드는 영화 목록을 반환한다', () async {
    final movies = await service.fetchMovies();

    expect(movies, isNotEmpty);
  });

  test('빈 모드는 빈 목록을 반환한다', () async {
    final movies = await service.fetchMovies(mode: MovieLoadMode.empty);

    expect(movies, isEmpty);
  });

  test('실패 모드는 MovieLoadException을 던진다', () async {
    expect(
      service.fetchMovies(mode: MovieLoadMode.failure),
      throwsA(isA<MovieLoadException>()),
    );
  });
}
