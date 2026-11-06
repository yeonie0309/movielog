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
  MyRatingsViewModel(this._ratingsApi, this._movies);
  final RatingApiService _ratingsApi;
  final MovieDetailService _movies;
  final _movieCache = <int, TmdbMovieDto?>{};
  MyRatingsStatus status = MyRatingsStatus.idle;
  List<RatingWithMovie> ratings = const [];
  String? message;
  int _version = 0;
  bool _disposed = false;

  Future<void> load() async {
    if (_disposed) return;
    final version = ++_version;
    bool isCurrent() => !_disposed && version == _version;
    status = MyRatingsStatus.loading;
    message = null;
    notifyListeners();
    try {
      final rows = await _ratingsApi.fetchMyRatings(sampleMemberId);
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
