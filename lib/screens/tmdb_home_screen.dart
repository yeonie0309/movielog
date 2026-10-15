import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../view_models/movie_home_view_model.dart';
import '../view_models/movie_load_status.dart';
import '../view_models/tmdb_movie_mapper.dart';
import '../widgets/movie/movie_card.dart';
import '../widgets/movie/movie_list_error.dart';
import '../widgets/movie/movie_poster.dart';

class TmdbHomeScreen extends StatelessWidget {
  const TmdbHomeScreen({super.key});

  void _openMovie(BuildContext context, Movie movie) {
    context.push('/movies/${movie.id}', extra: movie);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MovieLog',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.violet,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '오늘의 영화 한 편을 기록해 보세요.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '영화 검색',
                  onPressed: () => context.go('/movies'),
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<MovieHomeViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieLoadStatus.idle || MovieLoadStatus.loading =>
                    const Center(child: CircularProgressIndicator()),
                  MovieLoadStatus.error => MovieListError(
                    message: viewModel.message ?? '인기 영화를 불러오지 못했어요.',
                    onRetry: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                  ),
                  MovieLoadStatus.empty => const Center(
                    child: Text('표시할 인기 영화가 없어요.'),
                  ),
                  MovieLoadStatus.success => _PopularContent(
                    movies: viewModel.popularMovies
                        .map(
                          (movie) => movieFromTmdb(
                            movie,
                            genres: viewModel.genres,
                          ),
                        )
                        .toList(),
                    onOpenMovie: (movie) => _openMovie(context, movie),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularContent extends StatelessWidget {
  const _PopularContent({required this.movies, required this.onOpenMovie});

  final List<Movie> movies;
  final ValueChanged<Movie> onOpenMovie;

  @override
  Widget build(BuildContext context) {
    final featured = movies.first;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: GestureDetector(
            key: Key('movie-card-${featured.id}'),
            onTap: () => onOpenMovie(featured),
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MoviePoster(movie: featured),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xD9000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '오늘의 추천',
                          style: TextStyle(color: AppColors.violetContainer),
                        ),
                        Text(
                          featured.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '지금 인기 있는 영화',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/movies'),
                child: const Text('전체 보기'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 270,
          child: ListView.separated(
            key: const Key('tmdb-popular-list'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            itemCount: movies.length - 1,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final movie = movies[index + 1];
              return SizedBox(
                width: 144,
                child: MovieCard(movie: movie, onTap: () => onOpenMovie(movie)),
              );
            },
          ),
        ),
      ],
    );
  }
}
