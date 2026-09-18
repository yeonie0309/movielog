import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../theme/app_colors.dart';
import '../widgets/common_app_bar.dart';

class RatingInputScreen extends StatefulWidget {
  const RatingInputScreen({super.key});

  @override
  State<RatingInputScreen> createState() => _RatingInputScreenState();
}

class _RatingInputScreenState extends State<RatingInputScreen> {
  double _rating = 0;

  void _saveRating() {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$_rating점으로 저장했어요.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: '영화 평점 남기기',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.movie_creation_outlined,
                    size: 72,
                    color: AppColors.violet,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '오늘 본 영화는 어땠나요?',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _rating == 0
                        ? '별을 눌러 평점을 선택해 주세요.'
                        : '선택한 평점: ${_rating.toStringAsFixed(1)}',
                    key: const Key('rating-label'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 44,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, _) =>
                        const Icon(Icons.star_rounded, color: AppColors.violet),
                    unratedColor: AppColors.outline,
                    onRatingUpdate: (rating) {
                      setState(() => _rating = rating);
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('save-rating-button'),
                      onPressed: _rating == 0 ? null : _saveRating,
                      child: const Text('평점 저장'),
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
