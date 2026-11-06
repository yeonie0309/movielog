int validateServerScore(double value) {
  if (!value.isFinite ||
      value < 1 ||
      value > 5 ||
      value != value.roundToDouble()) {
    throw ArgumentError('서버 평점은 1~5 사이 정수여야 합니다.');
  }
  return value.toInt();
}

String? normalizedComment(String? value) {
  final text = value?.trim();
  if (text != null && text.length > 500) throw ArgumentError('후기는 최대 500자입니다.');
  return text == null || text.isEmpty ? null : text;
}

class CreateRatingRequest {
  const CreateRatingRequest({
    required this.movieId,
    required this.score,
    this.comment,
  });
  final int movieId;
  final int score;
  final String? comment;
  Map<String, dynamic> toJson() {
    validateServerScore(score.toDouble());
    if (movieId < 1) throw ArgumentError('TMDB movieId가 필요합니다.');
    final text = normalizedComment(comment);
    return {'movieId': movieId, 'score': score, 'comment': ?text};
  }
}
