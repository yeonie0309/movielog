import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'movie_rating_input.dart';
import '../../data/models/rating_request.dart';
import '../../widgets/movielog_button.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({
    super.key,
    this.movieId,
    this.initialRating = 0,
    this.initialComment,
    this.onSubmit,
  });

  // Legacy practice metadata; server writes use the ViewModel's TMDB movie ID.
  final int? movieId;
  final double initialRating;
  final String? initialComment;
  final Future<void> Function(int score, String? comment)? onSubmit;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late double _rating;
  late final TextEditingController _comment;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _comment = TextEditingController(text: widget.initialComment ?? '');
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSubmitting || _rating == 0) return;
    final submit = widget.onSubmit;
    if (submit == null) {
      Navigator.pop(context, _rating);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await submit(
        validateServerScore(_rating),
        normalizedComment(_comment.text),
      );
      if (!mounted) return;
      // Rebuild PopScope before a successful programmatic pop.
      setState(() => _isSubmitting = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, true);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error is StateError
            ? error.message.toString()
            : '저장에 실패했습니다. 입력을 유지했습니다. 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
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
                    integerOnly: widget.onSubmit != null,
                    enabled: !_isSubmitting,
                    onRatingUpdate: (value) => setState(() => _rating = value),
                  ),
                  if (widget.onSubmit != null) ...[
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('rating-comment-field'),
                      controller: _comment,
                      enabled: !_isSubmitting,
                      maxLength: 500,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: '코멘트 (선택)'),
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        key: const Key('rating-submit-error'),
                        style: const TextStyle(color: Colors.red),
                      ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      TextButton(
                        key: const Key('reset-rating-button'),
                        onPressed: _rating == 0 || _isSubmitting
                            ? null
                            : () => setState(() => _rating = 0),
                        child: const Text('초기화'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(
                                context,
                                widget.onSubmit == null ? null : false,
                              ),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      MovieLogButton(
                        key: const Key('confirm-rating-button'),
                        onPressed: _rating == 0 ? null : _save,
                        label: '평점 저장',
                        isLoading: _isSubmitting,
                      ),
                    ],
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
