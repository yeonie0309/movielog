import 'package:dio/dio.dart';

import '../models/member_rating.dart';

abstract interface class MemberApiService {
  Future<bool> checkNickname(String nickname);
  Future<bool> checkEmail(String email);
  Future<List<MemberRating>> getRatings(int memberId);
}

class HttpMemberApiService implements MemberApiService {
  HttpMemberApiService(this._dio);
  final Dio _dio;

  Future<bool> _check(String kind, String value) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/members/$kind/${Uri.encodeComponent(value)}',
    );
    return response.data!['available'] as bool;
  }

  @override
  Future<bool> checkNickname(String nickname) => _check('nickname', nickname);

  @override
  Future<bool> checkEmail(String email) => _check('email', email);

  @override
  Future<List<MemberRating>> getRatings(int memberId) async {
    final response = await _dio.get<List<dynamic>>(
      '/members/$memberId/ratings',
    );
    return response.data!
        .map((row) => MemberRating.fromJson(row as Map<String, dynamic>))
        .toList();
  }
}

String memberApiErrorMessage(Object error) {
  if (error is DioException) {
    if (error.response?.statusCode == 404) return '존재하지 않는 유저입니다.';
    if (error.response?.statusCode == 400) return '입력 형식을 확인해 주세요.';
  }
  return '서버에 연결하지 못했어요. 서버 실행 후 다시 시도해 주세요.';
}
