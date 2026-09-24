import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/mock_movies.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie/movie_card.dart';
import '../widgets/movie/movie_poster.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openMovie(BuildContext context, Movie movie) {
    context.push('/movies/${movie.id}');
  }

  @override
  Widget build(BuildContext context) {
    final featured = mockMovies.first;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            sliver: SliverToBoxAdapter(
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
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            sliver: SliverToBoxAdapter(
              child: _FeaturedMovie(
                movie: featured,
                onTap: () => _openMovie(context, featured),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
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
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 270,
              child: ListView.separated(
                key: const Key('home-movie-list'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                itemCount: mockMovies.length - 1,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final movie = mockMovies[index + 1];
                  return SizedBox(
                    width: 144,
                    child: MovieCard(
                      movie: movie,
                      onTap: () => _openMovie(context, movie),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedMovie extends StatelessWidget {
  const _FeaturedMovie({required this.movie, required this.onTap});

  final Movie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('movie-card-${movie.id}'),
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MoviePoster(movie: movie),
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
                    style: TextStyle(
                      color: AppColors.violetContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movie.genre} · ${movie.year} · ${movie.runtimeMinutes}분',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
