import 'package:dio/dio.dart';

import '../models/member_rating.dart';
import '../models/common_response.dart';
import '../models/rating_request.dart';
import 'sign_up_service.dart';

const sampleMemberId = 1;

class RatingApiService {
  RatingApiService(this._dio, {this.version = 'v6'});
  final Dio _dio;
  final String version;

  Future<List<MemberRating>> fetchMyRatings(int memberId) async {
    final response = await _dio.get<List<dynamic>>(
      '/$version/members/$memberId/ratings',
    );
    return response.data!
        .map((json) => MemberRating.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> createRating({
    required int memberId,
    required CreateRatingRequest request,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v6/members/$memberId/ratings',
      data: request.toJson(),
    );
    _validateWrite(response, 201);
  }

  Future<void> updateRating({
    required int memberId,
    required int ratingId,
    required int score,
    String? comment,
  }) async {
    validateServerScore(score.toDouble());
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v6/members/$memberId/ratings/$ratingId',
      data: {'score': score, 'comment': normalizedComment(comment)},
    );
    _validateWrite(response, 200);
  }

  Future<void> deleteRating({
    required int memberId,
    required int ratingId,
  }) async {
    final response = await _dio.delete<void>(
      '/v6/members/$memberId/ratings/$ratingId',
    );
    if (response.statusCode != 204) throw const FormatException('삭제 응답 상태 오류');
    // A successful 204 has no JSON body, intentionally no CommonResponse parsing.
  }

  void _validateWrite(Response<Map<String, dynamic>> response, int expected) {
    if (response.statusCode != expected || response.data == null) {
      throw const FormatException('쓰기 응답 계약 오류');
    }
    final common = CommonResponse<Object?>.fromJson(
      response.data!,
      (value) => value,
    );
    if (!common.isSuccess) throw StateError(common.message);
    // POST result may be a number or null: never force-cast it to ratingId.
  }
}

String writeErrorMessage(DioException error) =>
    readApiErrorMessage(error, '요청에 실패했습니다. 잠시 후 다시 시도해 주세요.');

bool shouldRefreshAfterRatingError(DioException error) {
  final data = error.response?.data;
  final code = data is Map ? data['code'] : null;
  return code == 'COMMON403' || code == 'COMMON404';
}

String writeMyRatingsErrorMessage(DioException error) =>
    readApiErrorMessage(error, switch (error.response?.statusCode) {
      400 => '회원 ID 형식이 올바르지 않습니다.',
      404 => '존재하지 않는 회원입니다.',
      _ => '평점을 불러오지 못했습니다. 다시 시도해 주세요.',
    });
