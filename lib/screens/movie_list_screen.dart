import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../theme/app_colors.dart';
import '../widgets/movie/genre_filter_sheet.dart';
import '../widgets/movie/movie_card.dart';

class MovieListScreen extends StatelessWidget {
  const MovieListScreen({super.key, required this.selectedGenres});

  final Set<String> selectedGenres;

  Future<void> _openFilter(BuildContext context) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GenreFilterSheet(
        genres: movieGenres,
        initialSelection: selectedGenres,
      ),
    );

    if (result == null || !context.mounted) return;

    final sortedGenres = result.toList()..sort();
    final location = Uri(
      path: '/movies',
      queryParameters: sortedGenres.isEmpty
          ? null
          : {'genres': sortedGenres.join(',')},
    ).toString();
    context.go(location);
  }

  @override
  Widget build(BuildContext context) {
    final filteredMovies = selectedGenres.isEmpty
        ? mockMovies
        : mockMovies
              .where((movie) => selectedGenres.contains(movie.genre))
              .toList();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
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
                            : '${selectedGenres.join(', ')} · ${filteredMovies.length}편',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Badge(
                  isLabelVisible: selectedGenres.isNotEmpty,
                  label: Text('${selectedGenres.length}'),
                  child: IconButton(
                    key: const Key('open-genre-filter-button'),
                    tooltip: '장르 필터',
                    onPressed: () => _openFilter(context),
                    icon: const Icon(Icons.filter_list_rounded),
                  ),
                ),
              ],
            ),
          ),
          if (selectedGenres.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: selectedGenres.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final genre = selectedGenres.elementAt(index);
                  return Chip(
                    label: Text(genre),
                    avatar: const Icon(Icons.check_rounded, size: 16),
                    side: BorderSide.none,
                    backgroundColor: AppColors.violetContainer,
                  );
                },
              ),
            ),
          Expanded(
            child: filteredMovies.isEmpty
                ? const _EmptyMovieList()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth >= 900
                          ? 5
                          : constraints.maxWidth >= 600
                          ? 3
                          : 2;
                      return GridView.builder(
                        key: const Key('movie-grid'),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                        itemCount: filteredMovies.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 22,
                          childAspectRatio: 0.56,
                        ),
                        itemBuilder: (context, index) {
                          final movie = filteredMovies[index];
                          return MovieCard(
                            movie: movie,
                            onTap: () => context.push('/movies/${movie.id}'),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMovieList extends StatelessWidget {
  const _EmptyMovieList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.movie_filter_outlined,
            size: 56,
            color: AppColors.gray,
          ),
          const SizedBox(height: 12),
          Text(
            '선택한 장르의 영화가 없어요.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
