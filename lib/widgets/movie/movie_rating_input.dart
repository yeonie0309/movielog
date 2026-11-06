import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../theme/app_colors.dart';

class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onRatingUpdate,
    this.integerOnly = false,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onRatingUpdate;
  final bool integerOnly;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          rating == 0
              ? '별을 눌러 평점을 선택해 주세요.'
              : '선택한 평점: ${rating.toStringAsFixed(1)}',
          key: const Key('dialog-rating-label'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        RatingBar.builder(
          initialRating: rating,
          minRating: integerOnly ? 1 : 0.5,
          allowHalfRating: !integerOnly,
          ignoreGestures: !enabled,
          itemCount: 5,
          itemSize: 42,
          itemPadding: const EdgeInsets.symmetric(horizontal: 3),
          itemBuilder: (context, index) =>
              const Icon(Icons.star_rounded, color: AppColors.violet),
          unratedColor: AppColors.outline,
          onRatingUpdate: onRatingUpdate,
        ),
      ],
    );
  }
}
