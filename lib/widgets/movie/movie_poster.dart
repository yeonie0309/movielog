import 'package:flutter/material.dart';

import '../../models/movie.dart';
import '../../theme/app_colors.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.movie,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
  });

  final Movie movie;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.asset(
        movie.posterAsset,
        fit: BoxFit.cover,
        semanticLabel: '${movie.title} 포스터',
        errorBuilder: (context, error, stackTrace) => const ColoredBox(
          color: AppColors.violetContainer,
          child: Center(
            child: Icon(
              Icons.movie_outlined,
              color: AppColors.violet,
              size: 44,
            ),
          ),
        ),
      ),
    );
  }
}
