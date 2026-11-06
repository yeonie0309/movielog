import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../widgets/movie/movie_poster.dart';
import '../widgets/movie/rating_dialog.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movie});

  final Movie? movie;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  bool _isFavorite = false;
  double _myRating = 0;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? '즐겨찾기에 추가했어요.' : '즐겨찾기에서 삭제했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _openRatingDialog() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(initialRating: _myRating),
    );

    if (rating == null || !mounted) return;
    setState(() => _myRating = rating);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${rating.toStringAsFixed(1)}점으로 저장했어요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    if (movie == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: '뒤로 가기',
            onPressed: _goBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: const Text('영화 상세'),
        ),
        body: const Center(child: Text('영화를 찾을 수 없어요.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '뒤로 가기',
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('영화 상세'),
        actions: [
          IconButton(
            key: const Key('favorite-button'),
            tooltip: _isFavorite ? '즐겨찾기 삭제' : '즐겨찾기 추가',
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: _isFavorite ? AppColors.violet : null,
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Hero(
                      tag: 'movie-poster-${movie.id}',
                      child: SizedBox(
                        width: 220,
                        height: 320,
                        child: MoviePoster(movie: movie),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    movie.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${movie.genre} · ${movie.year} · ${movie.runtimeMinutes}분',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RatingBarIndicator(
                        rating: movie.averageRating,
                        itemCount: 5,
                        itemSize: 24,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star_rounded,
                          color: AppColors.violet,
                        ),
                        unratedColor: AppColors.outline,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        movie.averageRating.toStringAsFixed(1),
                        key: const Key('average-rating-label'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text('줄거리', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(
                    movie.overview,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    key: const Key('open-rating-dialog-button'),
                    onPressed: _openRatingDialog,
                    icon: const Icon(Icons.star_outline_rounded),
                    label: Text(
                      _myRating == 0
                          ? '평점 남기기'
                          : '내 평점 ${_myRating.toStringAsFixed(1)} · 다시 선택',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
