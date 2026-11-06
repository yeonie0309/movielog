import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    super.key,
    required this.posterPath,
    this.fit = BoxFit.cover,
  });

  final String? posterPath;
  final BoxFit fit;

  static const imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  @override
  Widget build(BuildContext context) {
    final path = posterPath;
    if (path == null || path.isEmpty) return _placeholder();

    return Image.network(
      '$imageBaseUrl$path',
      fit: fit,
      semanticLabel: '영화 포스터',
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() => const ColoredBox(
    key: Key('tmdb-poster-placeholder'),
    color: AppColors.violetContainer,
    child: Center(
      child: Icon(Icons.image_not_supported_outlined, color: AppColors.violet),
    ),
  );
}
