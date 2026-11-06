import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'movie_rating_input.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.initialRating = 0});

  final double initialRating;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.movie_creation_outlined,
                size: 52,
                color: AppColors.violet,
              ),
              const SizedBox(height: 16),
              Text(
                '이 영화는 어땠나요?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 20),
              MovieRatingInput(
                rating: _rating,
                onRatingUpdate: (value) => setState(() => _rating = value),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    key: const Key('reset-rating-button'),
                    onPressed: _rating == 0
                        ? null
                        : () => setState(() => _rating = 0),
                    child: const Text('초기화'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('confirm-rating-button'),
                    onPressed: _rating == 0
                        ? null
                        : () => Navigator.pop(context, _rating),
                    child: const Text('평점 저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
