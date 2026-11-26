import 'package:dio/dio.dart';

import '../models/auth_models.dart';
import '../models/common_response.dart';
import '../models/member_rating.dart';
import '../models/rating_request.dart';

T parseV7Result<T>(
  Response response,
  int status,
  T Function(Map<String, dynamic>) parse,
) {
  if (response.statusCode != status || response.data is! Map<String, dynamic>) {
    throw const FormatException('서버 응답 형식이 올바르지 않습니다.');
  }
  final common = CommonResponse<T>.fromJson(
    response.data as Map<String, dynamic>,
    (value) => parse(value as Map<String, dynamic>),
  );
  if (!common.isSuccess || common.result == null) {
    throw const FormatException('성공 result가 없습니다.');
  }
  return common.result as T;
}

class AuthApiService {
  AuthApiService(this.publicClient, this.authClient, {this.version = 'v7'});
  final String version;
  final Dio publicClient;
  final Dio authClient;
  Future<LoginResult> login(LoginRequest request) async => parseV7Result(
    await publicClient.post('/$version/auth/login', data: request.toJson()),
    200,
    LoginResult.fromJson,
  );
  Future<MemberInfo> fetchMe() async => parseV7Result(
    await authClient.get('/$version/members/me'),
    200,
    MemberInfo.fromJson,
  );
  Future<MemberInfo> updateNickname(String nickname) async => parseV7Result(
    await authClient.patch(
      '/$version/members/me',
      data: {'nickname': nickname.trim()},
    ),
    200,
    MemberInfo.fromJson,
  );
}

class AuthenticatedRatingApiService {
  AuthenticatedRatingApiService(
    this.publicClient,
    this.authClient, {
    this.version = 'v7',
  });
  final String version;
  final Dio publicClient;
  final Dio authClient;
  Future<List<MemberRating>> getMemberRatings(int memberId) async {
    final response = await publicClient.get<List<dynamic>>(
      '/$version/members/$memberId/ratings',
    );
    return response.data!
        .map((row) => MemberRating.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<MemberRating> createRating(CreateRatingRequest request) async =>
      parseV7Result(
        await authClient.post('/$version/ratings', data: request.toJson()),
        201,
        MemberRating.fromJson,
      );
  Future<MemberRating> updateRating(
    int ratingId,
    int score,
    String? comment,
  ) async {
    validateServerScore(score.toDouble());
    return parseV7Result(
      await authClient.patch(
        '/$version/ratings/$ratingId',
        data: {'score': score, 'comment': normalizedComment(comment)},
      ),
      200,
      MemberRating.fromJson,
    );
  }

  Future<void> deleteRating(int ratingId) async {
    final response = await authClient.delete('/$version/ratings/$ratingId');
    final body = response.data;
    if (response.statusCode != 200 ||
        body is! Map ||
        body['isSuccess'] != true ||
        !body.containsKey('result') ||
        body['result'] != null) {
      throw const FormatException('평점 삭제 응답 형식 오류');
    }
  }
}
