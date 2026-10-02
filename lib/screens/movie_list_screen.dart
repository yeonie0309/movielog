import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/genre_preference.dart';
import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../services/fake_movie_service.dart';
import '../theme/app_colors.dart';
import '../widgets/movie/genre_filter_sheet.dart';
import '../widgets/movie/movie_grid.dart';
import '../widgets/movie/movie_list_empty.dart';
import '../widgets/movie/movie_list_error.dart';
import '../widgets/movie/movie_list_loading.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({
    super.key,
    required this.selectedGenres,
    this.initialMode = MovieLoadMode.success,
    this.movieService = const FakeMovieService(),
    this.requestTimeout = const Duration(seconds: 4),
    this.genrePreference,
  });

  final Set<String> selectedGenres;
  final MovieLoadMode initialMode;
  final FakeMovieService movieService;
  final Duration requestTimeout;
  final GenrePreferenceStore? genrePreference;

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  late final GenrePreferenceStore _genrePreference;
  late Future<List<Movie>> _moviesFuture;
  late MovieLoadMode _loadMode;
  late Set<String> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _genrePreference = widget.genrePreference ?? GenrePreference();
    _loadMode = widget.initialMode;
    _selectedGenres = Set<String>.of(widget.selectedGenres);
    _moviesFuture = _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant MovieListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!setEquals(oldWidget.selectedGenres, widget.selectedGenres)) {
      _selectedGenres = Set<String>.of(widget.selectedGenres);
    }

    if (oldWidget.initialMode != widget.initialMode) {
      _loadMode = widget.initialMode;
      _moviesFuture = _fetchMovies(_loadMode);
    }
  }

  Future<List<Movie>> _loadInitialData() async {
    final results = await Future.wait<Object>([
      _fetchMovies(_loadMode),
      _genrePreference.read(),
    ]);
    final movies = results[0] as List<Movie>;
    final savedGenres = results[1] as Set<String>;

    if (_selectedGenres.isEmpty && savedGenres.isNotEmpty && mounted) {
      setState(() => _selectedGenres = savedGenres);
    }

    return movies;
  }

  Future<List<Movie>> _fetchMovies(MovieLoadMode mode) async {
    try {
      return await widget.movieService
          .fetchMovies(mode: mode)
          .timeout(widget.requestTimeout);
    } on TimeoutException catch (error, stackTrace) {
      debugPrint('영화 목록 Mock 요청 시간 초과: $error');
      debugPrintStack(stackTrace: stackTrace);
      throw const MovieLoadException();
    } catch (error, stackTrace) {
      debugPrint('영화 목록 Mock 요청 실패: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } finally {
      debugPrint('영화 목록 Mock 요청 종료');
    }
  }

  Future<void> _openFilter() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenreFilterSheet(
        genres: movieGenres,
        initialSelection: _selectedGenres,
      ),
    );

    if (result == null || !mounted) return;
    _applyGenres(result);
  }

  void _applyGenres(Set<String> genres) {
    final nextGenres = Set<String>.of(genres);
    setState(() => _selectedGenres = nextGenres);
    unawaited(_genrePreference.save(nextGenres));
    context.go(_movieListLocation(genres: nextGenres, mode: _loadMode));
  }

  String _movieListLocation({
    required Set<String> genres,
    required MovieLoadMode mode,
  }) {
    final sortedGenres = genres.toList()..sort();
    final queryParameters = <String, String>{};
    if (sortedGenres.isNotEmpty) {
      queryParameters['genres'] = sortedGenres.join(',');
    }
    if (mode != MovieLoadMode.success) {
      queryParameters['state'] = mode.name;
    }

    return Uri(
      path: '/movies',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    ).toString();
  }

  void _changeLoadMode(MovieLoadMode mode) {
    context.go(_movieListLocation(genres: _selectedGenres, mode: mode));
  }

  void _retry() {
    setState(() {
      _loadMode = MovieLoadMode.success;
      _moviesFuture = _fetchMovies(MovieLoadMode.success);
    });
  }

  Future<void> _refresh() async {
    final nextFuture = _fetchMovies(_loadMode);
    setState(() => _moviesFuture = nextFuture);
    await nextFuture;
  }

  @override
  Widget build(BuildContext context) {
    final visibleMovieCount = _selectedGenres.isEmpty
        ? mockMovies.length
        : mockMovies
              .where((movie) => _selectedGenres.contains(movie.genre))
              .length;

    return SafeArea(
      child: Column(
        children: [
          _MovieListHeader(
            selectedGenres: _selectedGenres,
            visibleMovieCount: visibleMovieCount,
            loadMode: _loadMode,
            onOpenFilter: _openFilter,
            onChangeLoadMode: _changeLoadMode,
          ),
          _GenreChips(selectedGenres: _selectedGenres, onChanged: _applyGenres),
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const MovieListLoading();
                }
                if (snapshot.hasError) {
                  return MovieListError(onRetry: _retry);
                }

                final movies = snapshot.data ?? const <Movie>[];
                final filteredMovies = _selectedGenres.isEmpty
                    ? movies
                    : movies
                          .where(
                            (movie) => _selectedGenres.contains(movie.genre),
                          )
                          .toList();
                if (filteredMovies.isEmpty) {
                  return MovieListEmpty(filtered: _selectedGenres.isNotEmpty);
                }

                return MovieGrid(
                  movies: filteredMovies,
                  onMovieTap: (movie) => context.push('/movies/${movie.id}'),
                  onRefresh: _refresh,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieListHeader extends StatelessWidget {
  const _MovieListHeader({
    required this.selectedGenres,
    required this.visibleMovieCount,
    required this.loadMode,
    required this.onOpenFilter,
    required this.onChangeLoadMode,
  });

  final Set<String> selectedGenres;
  final int visibleMovieCount;
  final MovieLoadMode loadMode;
  final VoidCallback onOpenFilter;
  final ValueChanged<MovieLoadMode> onChangeLoadMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '영화',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  selectedGenres.isEmpty
                      ? '모든 영화를 둘러보세요.'
                      : '${selectedGenres.join(', ')} · $visibleMovieCount편',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<MovieLoadMode>(
            key: const Key('movie-state-preview-button'),
            tooltip: '화면 상태 미리보기',
            initialValue: loadMode,
            onSelected: onChangeLoadMode,
            icon: const Icon(Icons.science_outlined),
            itemBuilder: (context) => const [
              PopupMenuItem(value: MovieLoadMode.success, child: Text('성공 상태')),
              PopupMenuItem(value: MovieLoadMode.empty, child: Text('빈 상태')),
              PopupMenuItem(value: MovieLoadMode.failure, child: Text('오류 상태')),
            ],
          ),
          Badge(
            isLabelVisible: selectedGenres.isNotEmpty,
            label: Text('${selectedGenres.length}'),
            child: IconButton(
              key: const Key('open-genre-filter-button'),
              tooltip: '장르 필터',
              onPressed: onOpenFilter,
              icon: const Icon(Icons.filter_list_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreChips extends StatelessWidget {
  const _GenreChips({required this.selectedGenres, required this.onChanged});

  final Set<String> selectedGenres;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: movieGenres.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return FilterChip(
              key: const Key('genre-chip-all'),
              label: const Text('전체'),
              selected: selectedGenres.isEmpty,
              onSelected: (_) => onChanged(<String>{}),
            );
          }

          final genre = movieGenres[index - 1];
          final selected = selectedGenres.contains(genre);
          return FilterChip(
            key: Key('genre-chip-$genre'),
            label: Text(genre),
            selected: selected,
            selectedColor: AppColors.violetContainer,
            onSelected: (isSelected) {
              final nextGenres = Set<String>.of(selectedGenres);
              isSelected ? nextGenres.add(genre) : nextGenres.remove(genre);
              onChanged(nextGenres);
            },
          );
        },
      ),
    );
  }
}
