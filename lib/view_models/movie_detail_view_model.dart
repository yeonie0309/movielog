import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/rating_request.dart';
import '../data/services/rating_api_service.dart';
import 'submit_status.dart';
import 'auth_view_model.dart';
import '../data/services/auth_api_service.dart';
import '../core/network/api_error.dart';
import '../data/services/favorite_api_service.dart';

class MovieDetailViewModel extends ChangeNotifier {
  MovieDetailViewModel(this._service, this.memberId, this.movieId);
  MovieDetailViewModel.authenticated(
    this._service,
    this.movieId,
    AuthViewModel auth,
    AuthenticatedRatingApiService tokenApi,
  ) : memberId = null,
      _auth = auth,
      _tokenApi = tokenApi;
  AuthViewModel? _auth;
  AuthenticatedRatingApiService? _tokenApi;
  final RatingApiService _service;
  final int? memberId;
  final int movieId;
  SubmitStatus submitStatus = SubmitStatus.idle;
  String? submitMessage;
  bool _disposed = false;

  Future<void> createRating({
    required int score,
    String? comment,
    bool preserveApiError = false,
  }) async {
    if (_disposed || submitStatus == SubmitStatus.submitting) return;
    final id = memberId;
    if (_auth == null && id == null) throw StateError('먼저 학습용 회원가입을 완료해 주세요.');
    final version = _auth?.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    submitMessage = null;
    notifyListeners();
    try {
      final request = CreateRatingRequest(
        movieId: movieId,
        score: score,
        comment: comment,
      );
      if (_auth == null) {
        await _service.createRating(memberId: id!, request: request);
      } else {
        final rating = await _tokenApi!.createRating(request);
        if (!_auth!.isCurrent(version!)) throw const SessionChangedException();
        _auth!.keepRating(rating, version);
      }
      if (_disposed) return;
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (_auth != null && isSessionError(error)) {
        await _auth!.expireSession(version!);
      }
      if (_disposed) return;
      submitStatus = SubmitStatus.error;
      submitMessage = error is DioException
          ? writeErrorMessage(error)
          : '저장 결과를 확인하지 못했습니다. 재등록 전에 내 평점 목록을 확인해 주세요.';
      notifyListeners();
      if (preserveApiError) rethrow;
      throw StateError(submitMessage!);
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> createMovieRecord(
    MovieRecordApiService api, {
    required int score,
    String? comment,
    required bool addToFavorites,
  }) async {
    final auth = _auth;
    if (_disposed || auth == null || auth.status != AuthStatus.signedIn) {
      throw const SessionChangedException();
    }
    if (submitStatus == SubmitStatus.submitting) return;
    final version = auth.sessionVersion;
    submitStatus = SubmitStatus.submitting;
    notifyListeners();
    try {
      final record = await api.create(
        movieId: movieId,
        score: score,
        comment: comment,
        addToFavorites: addToFavorites,
      );
      if (_disposed || !auth.isCurrent(version)) {
        throw const SessionChangedException();
      }
      auth.keepRating(record.rating, version);
      submitStatus = SubmitStatus.success;
    } catch (error) {
      if (!_disposed && auth.isCurrent(version)) {
        submitStatus = SubmitStatus.error;
        submitMessage = apiErrorMessage(
          error,
          '저장 결과를 확인하지 못했습니다. 평점과 즐겨찾기를 확인해 주세요.',
        );
      }
      rethrow;
    } finally {
      if (!_disposed && auth.isCurrent(version)) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
