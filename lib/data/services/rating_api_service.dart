import 'package:dio/dio.dart';

import '../models/member_rating.dart';

const sampleMemberId = 1;

class RatingApiService {
  RatingApiService(this._dio);
  final Dio _dio;

  Future<List<MemberRating>> fetchMyRatings(int memberId) async {
    final response = await _dio.get<List<dynamic>>(
      '/v5/members/$memberId/ratings',
    );
    return response.data!
        .map((json) => MemberRating.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

String writeMyRatingsErrorMessage(DioException error) =>
    switch (error.response?.statusCode) {
      400 => '회원 ID 형식이 올바르지 않습니다.',
      404 => '존재하지 않는 회원입니다.',
      _ => '평점을 불러오지 못했습니다. 다시 시도해 주세요.',
    };
