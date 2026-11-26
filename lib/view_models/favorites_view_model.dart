import 'package:flutter/foundation.dart';

import '../core/session/session_guard.dart';
import '../core/utils/map_bounded.dart';
import '../core/utils/safe_notify.dart';
import '../data/models/favorite_models.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/favorite_api_service.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class FavoritesViewModel extends ChangeNotifier with SafeNotify {
  FavoritesViewModel(this.api, this.movies, this.session) {
    session.addListener(_invalidate);
  }
  final FavoriteApiService api;
  final MovieDetailService movies;
  final SessionGuard session;
  LoadPhase phase = LoadPhase.idle;
  List<FavoriteListItem> items = [];
  final Map<int, TmdbMovieDto> _cache = {};
  final Set<int> retrying = {};
  int _generation = 0;
  void _invalidate() {
    _generation++;
    items = [];
    _cache.clear();
    retrying.clear();
    phase = LoadPhase.idle;
    notifyIfAlive();
  }

  bool _current(int stamp, int request) =>
      !isDisposed && session.isCurrent(stamp) && request == _generation;

  Future<void> refresh() async {
    if (isDisposed) return;
    if (!session.isSignedIn) {
      _invalidate();
      return;
    }
    final stamp = session.generation;
    final request = ++_generation;
    items = [];
    retrying.clear();
    phase = LoadPhase.loading;
    notifyIfAlive();
    try {
      final rows = await api.fetchFavorites();
      if (!_current(stamp, request)) return;
      final unique = {for (final row in rows) row.movieId: row}.values.toList();
      final results = await mapBounded(unique, (row) async {
        if (!_current(stamp, request)) return FavoriteListItem(row);
        try {
          final dto =
              _cache[row.movieId] ?? await movies.fetchMovieDetail(row.movieId);
          if (_current(stamp, request)) _cache[row.movieId] = dto;
          return FavoriteListItem(row, movie: dto);
        } catch (_) {
          return FavoriteListItem(row, failed: true);
        }
      });
      if (!_current(stamp, request)) return;
      items = results;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } catch (_) {
      if (_current(stamp, request)) phase = LoadPhase.error;
    }
    if (_current(stamp, request)) notifyIfAlive();
  }

  Future<void> retryMovie(int movieId) async {
    if (isDisposed || !session.isSignedIn || !retrying.add(movieId)) return;
    final stamp = session.generation;
    final request = _generation;
    notifyIfAlive();
    try {
      final movie = await movies.fetchMovieDetail(movieId);
      if (!_current(stamp, request)) return;
      _cache[movieId] = movie;
      items = items
          .map(
            (row) => row.favorite.movieId == movieId
                ? FavoriteListItem(row.favorite, movie: movie)
                : row,
          )
          .toList();
    } catch (_) {
      /* Retain only this card's retry affordance. */
    } finally {
      if (_current(stamp, request)) {
        retrying.remove(movieId);
        notifyIfAlive();
      }
    }
  }

  @override
  void dispose() {
    session.removeListener(_invalidate);
    _cache.clear();
    _generation++;
    super.dispose();
  }
}
