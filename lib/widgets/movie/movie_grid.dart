import 'package:flutter/material.dart';

import '../../models/movie.dart';
import 'movie_card.dart';

class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    required this.onMovieTap,
    required this.onRefresh,
  });

  final List<Movie> movies;
  final ValueChanged<Movie> onMovieTap;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : 2;
        final aspectRatio = constraints.maxWidth >= 620 ? 0.72 : 0.65;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: GridView.builder(
            key: const Key('movie-grid'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: aspectRatio,
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return MovieCard(movie: movie, onTap: () => onMovieTap(movie));
            },
          ),
        );
      },
    );
  }
}
