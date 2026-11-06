import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/models/member_rating.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../data/services/rating_api_service.dart';
import '../data/services/tmdb_movie_service.dart';

enum MyRatingsStatus { idle, loading, success, empty, error }

class RatingWithMovie {
  const RatingWithMovie({required this.rating, this.movie});
  final MemberRating rating;
  final TmdbMovieDto? movie;
}

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(
    this._ratingsApi,
    this._movies, [
    this.memberId = sampleMemberId,
  ]);
  final RatingApiService _ratingsApi;
  final MovieDetailService _movies;
  final int memberId;
  final _movieCache = <int, TmdbMovieDto?>{};
  MyRatingsStatus status = MyRatingsStatus.idle;
  List<RatingWithMovie> ratings = const [];
  String? message;
  int _version = 0;
  bool _disposed = false;
  String? refreshWarning;
  String? operationMessage;
  bool isWriting = false;
  bool isEditing = false;
  bool isDeletingSelected = false;
  final Set<int> selectedRatingIds = {};

  void toggleEditing() {
    if (isWriting) return;
    isEditing = !isEditing;
    selectedRatingIds.clear();
    notifyListeners();
  }

  void selectRating(int id, bool selected) {
    if (isWriting || !ratings.any((row) => row.rating.ratingId == id)) return;
    selected ? selectedRatingIds.add(id) : selectedRatingIds.remove(id);
    notifyListeners();
  }

  Future<void> _refreshAfterWrite() async {
    await load();
    if (_disposed) return;
    refreshWarning = status == MyRatingsStatus.error
        ? '저장은 완료됐지만 목록을 불러오지 못했습니다. 조회만 다시 시도해 주세요.'
        : null;
    notifyListeners();
  }

  Future<void> updateRating({
    required int ratingId,
    required int score,
    String? comment,
  }) => _write(
    () => _ratingsApi.updateRating(
      memberId: memberId,
      ratingId: ratingId,
      score: score,
      comment: comment,
    ),
  );

  Future<void> deleteRating(int ratingId) => _write(
    () => _ratingsApi.deleteRating(memberId: memberId, ratingId: ratingId),
  );

  Future<void> _write(Future<void> Function() action) async {
    if (_disposed || isWriting) throw StateError('처리 중입니다.');
    isWriting = true;
    operationMessage = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      if (!_disposed) {
        operationMessage = error is DioException
            ? writeErrorMessage(error)
            : '저장 결과를 확인하지 못했습니다. 목록을 확인해 주세요.';
        if (error is DioException && shouldRefreshAfterRatingError(error)) {
          await load();
        }
      }
      throw StateError(operationMessage ?? '요청에 실패했습니다.');
    } finally {
      if (!_disposed) {
        isWriting = false;
        notifyListeners();
      }
    }
    if (!_disposed) await _refreshAfterWrite();
  }

  Future<void> deleteSelectedRatings() async {
    if (_disposed || isWriting || selectedRatingIds.isEmpty) return;
    isWriting = true;
    isDeletingSelected = true;
    operationMessage = null;
    notifyListeners();
    var failed = 0;
    try {
      for (final id in selectedRatingIds.toList()) {
        try {
          await _ratingsApi.deleteRating(memberId: memberId, ratingId: id);
          selectedRatingIds.remove(id);
        } catch (_) {
          failed++;
        }
        if (_disposed) return;
      }
      await _refreshAfterWrite();
      if (_disposed) return;
      if (failed > 0) {
        operationMessage = '$failed개 항목을 삭제하지 못했습니다. 선택된 항목을 다시 확인해 주세요.';
      } else {
        isEditing = false;
      }
    } finally {
      if (!_disposed) {
        isWriting = false;
        isDeletingSelected = false;
        notifyListeners();
      }
    }
  }

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_version;
    bool isCurrent() => !_disposed && version == _version;
    status = MyRatingsStatus.loading;
    message = null;
    refreshWarning = null;
    notifyListeners();
    try {
      final rows = await _ratingsApi.fetchMyRatings(memberId);
      if (!isCurrent()) return;
      final result = <RatingWithMovie>[];
      for (final rating in rows) {
        TmdbMovieDto? movie;
        if (_movieCache.containsKey(rating.movieId)) {
          movie = _movieCache[rating.movieId];
        } else {
          try {
            movie = await _movies.fetchMovieDetail(rating.movieId);
            if (!isCurrent()) return;
            _movieCache[rating.movieId] = movie;
          } on DioException catch (error) {
            if (!isCurrent()) return;
            // Only definite 404s are negative-cached; transient failures retry.
            if (error.response?.statusCode == 404) {
              _movieCache[rating.movieId] = null;
            }
          } catch (_) {
            if (!isCurrent()) return;
          }
        }
        result.add(RatingWithMovie(rating: rating, movie: movie));
      }
      if (!isCurrent()) return;
      ratings = List.unmodifiable(result);
      status = result.isEmpty ? MyRatingsStatus.empty : MyRatingsStatus.success;
      if (result.any((row) => row.movie == null)) {
        message = '일부 영화 정보를 가져오지 못해 제목·포스터를 대신 표시합니다.';
      }
    } on DioException catch (error) {
      if (!isCurrent()) return;
      ratings = const [];
      status = MyRatingsStatus.error;
      message = writeMyRatingsErrorMessage(error);
    } catch (_) {
      if (!isCurrent()) return;
      ratings = const [];
      status = MyRatingsStatus.error;
      message = '평점을 불러오지 못했습니다. 다시 시도해 주세요.';
    }
    if (isCurrent()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _version++;
    super.dispose();
  }
}
