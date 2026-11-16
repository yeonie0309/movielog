import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'submit_status.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this.memberId, this.movieId);
  final RatingApiService _service;
  final int? memberId;
  final int movieId;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({required int score, String? comment}) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    final id = memberId;
    if (id == null) throw StateError('먼저 학습용 회원가입을 완료해 주세요.');
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      await _service.createRating(
        memberId: id,
        request: CreateRatingRequest(
          movieId: movieId,
          score: score,
          comment: comment,
        ),
      );
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = error is DioException
          ? writeErrorMessage(error)
          : '저장 결과를 확인하지 못했습니다. 재등록 전에 내 평점 목록을 확인해 주세요.';
      notifyListeners();
      throw StateError(submitMessage!);
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
