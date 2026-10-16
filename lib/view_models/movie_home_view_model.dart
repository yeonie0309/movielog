import 'package:flutter/foundation.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'movie_load_status.dart';

class MovieHomeViewModel extends ChangeNotifier {
  MovieHomeViewModel(this._service);

  final MovieCatalogService _service;
  bool _disposed = false;

  MovieLoadStatus status = MovieLoadStatus.idle;
  List<TmdbMovieDto> popularMovies = const [];
  List<TmdbGenreDto> genres = const [];
  String? message;

  Future<void> loadPopular() async {
    status = MovieLoadStatus.loading;
    message = null;
    notifyListeners();

    try {
      final page = await _service.fetchPopular();
      try {
        genres = await _service.fetchGenres();
      } catch (_) {
        genres = const [];
      }
      if (_disposed) return;
      popularMovies = page.results.take(5).toList();
      status = popularMovies.isEmpty
          ? MovieLoadStatus.empty
          : MovieLoadStatus.success;
    } catch (error) {
      if (_disposed) return;
      status = MovieLoadStatus.error;
      message = error is StateError
          ? error.message.toString()
          : '인기 영화를 불러오지 못했어요. 다시 시도해 주세요.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
