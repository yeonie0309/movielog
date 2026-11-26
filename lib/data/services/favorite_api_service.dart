import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_models.dart';
import '../models/rating_request.dart';
import 'auth_api_service.dart';

class FavoriteApiService {
  FavoriteApiService(this.client);
  final Dio client;

  Future<List<FavoriteResponseDto>> fetchFavorites() async {
    final response = await client.get<Map<String, dynamic>>('/v8/favorites');
    if (response.statusCode != 200 || response.data == null) {
      throw const FormatException('즐겨찾기 목록 응답 오류');
    }
    final common = CommonResponse<List<FavoriteResponseDto>>.fromJson(
      response.data!,
      (raw) => (raw as List)
          .map(
            (row) => FavoriteResponseDto.fromJson(row as Map<String, dynamic>),
          )
          .toList(),
    );
    if (!common.isSuccess || common.result == null) {
      throw const FormatException('즐겨찾기 목록 result 오류');
    }
    return common.result!;
  }

  Future<bool> isFavorite(int movieId) async => parseV7Result(
    await client.get('/v8/favorites/$movieId'),
    200,
    (json) => FavoriteCheckDto.fromJson(movieId, json).isFavorite,
  );

  Future<FavoriteResponseDto> addFavorite(int movieId) async => parseV7Result(
    await client.post('/v8/favorites', data: {'movieId': movieId}),
    201,
    FavoriteResponseDto.fromJson,
  );

  Future<void> removeFavorite(int movieId) async {
    final response = await client.delete('/v8/favorites/$movieId');
    final data = response.data;
    if (response.statusCode != 200 ||
        data is! Map ||
        data['isSuccess'] != true ||
        !data.containsKey('result') ||
        data['result'] != null) {
      throw const FormatException('즐겨찾기 해제 응답 오류');
    }
  }
}

class MovieRecordApiService {
  MovieRecordApiService(this.client);
  final Dio client;
  Future<MovieRecordResponse> create({
    required int movieId,
    required int score,
    String? comment,
    required bool addToFavorites,
  }) async {
    validateServerScore(score.toDouble());
    return parseV7Result(
      await client.post(
        '/v8/movie-records',
        data: {
          'movieId': movieId,
          'score': score,
          if (comment?.trim().isNotEmpty ?? false) 'comment': comment!.trim(),
          'addToFavorites': addToFavorites,
        },
      ),
      201,
      MovieRecordResponse.fromJson,
    );
  }
}
