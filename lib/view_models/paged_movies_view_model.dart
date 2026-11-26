import 'package:flutter/foundation.dart';

import '../core/utils/safe_notify.dart';
import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import 'load_phase.dart';

class PagedMoviesViewModel extends ChangeNotifier with SafeNotify {
  PagedMoviesViewModel(
    this.catalog, {
    this.searchService,
    this.searchMode = false,
  });
  final MovieCatalogService catalog;
  final MovieSearchService? searchService;
  final bool searchMode;
  int generation = 0;
  int nextPage = 1;
  bool hasMore = false;
  bool loadingMore = false;
  String? nextPageError;
  String? error;
  String query = '';
  int? genreId;
  List<TmdbMovieDto> items = [];
  List<TmdbGenreDto> genres = [];
  LoadPhase phase = LoadPhase.idle;

  Future<void> loadGenres() async {
    try {
      final result = await catalog.fetchGenres();
      if (isDisposed) return;
      genres = result;
      notifyIfAlive();
    } catch (_) {
      /* Movies remain usable; refresh retries genre loading. */
    }
  }

  /// Called immediately on edits, before a debounce timer can fire.
  void invalidateQuery(String value) {
    query = value.trim();
    _reset();
    notifyIfAlive();
  }

  void _reset() {
    generation++;
    items = [];
    nextPage = 1;
    hasMore = false;
    loadingMore = false;
    nextPageError = null;
    error = null;
    phase = LoadPhase.idle;
  }

  Future<void> loadInitial({String? searchQuery, int? selectedGenre}) async {
    if (isDisposed) return;
    if (searchQuery != null) query = searchQuery.trim();
    if (!searchMode) genreId = selectedGenre;
    _reset();
    if (searchMode && query.isEmpty) {
      notifyIfAlive();
      return;
    }
    phase = LoadPhase.loading;
    notifyIfAlive();
    await _fetch(first: true);
  }

  Future<void> refresh() =>
      loadInitial(searchQuery: query, selectedGenre: genreId);

  Future<void> loadNextPage() async {
    if (isDisposed || phase != LoadPhase.success || loadingMore || !hasMore) {
      return;
    }
    loadingMore = true;
    nextPageError = null;
    notifyIfAlive();
    await _fetch(first: false);
  }

  Future<void> _fetch({required bool first}) async {
    final stamp = generation;
    final pageNumber = nextPage;
    try {
      final page = searchMode
          ? await searchService!.searchMovies(query: query, page: pageNumber)
          : await catalog.discoverMovies(page: pageNumber, genreId: genreId);
      if (isDisposed || stamp != generation) return;
      final byId = {for (final movie in items) movie.id: movie};
      for (final movie in page.results) {
        byId.putIfAbsent(movie.id, () => movie);
      }
      items = byId.values.toList();
      nextPage = pageNumber + 1;
      hasMore =
          pageNumber < page.totalPages &&
          pageNumber < 500 &&
          page.results.isNotEmpty;
      phase = items.isEmpty ? LoadPhase.empty : LoadPhase.success;
    } catch (_) {
      if (isDisposed || stamp != generation) return;
      if (first) {
        phase = LoadPhase.error;
        error = '영화를 불러오지 못했습니다. 다시 시도해 주세요.';
      } else {
        nextPageError = '$pageNumber페이지 조회에 실패했습니다. 같은 페이지를 다시 시도해 주세요.';
      }
    } finally {
      if (!isDisposed && stamp == generation) {
        loadingMore = false;
        notifyIfAlive();
      }
    }
  }

  @override
  void dispose() {
    generation++;
    super.dispose();
  }
}
