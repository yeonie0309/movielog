import 'package:dio/dio.dart';

import '../models/check_result.dart';
import '../models/common_response.dart';
import '../models/create_member_request.dart';
import '../models/sign_up_models.dart';
import 'member_check_service.dart';

// Keep the earlier read-only service as a compatibility adapter for week 6.
class SignUpService extends MemberCheckService {
  SignUpService(this._client) : super(_client);
  final Dio _client;
  @override
  Future<bool> checkNickname(String value) => _check('nickname', value);
  @override
  Future<bool> checkEmail(String value) => _check('email', value);
  Future<bool> _check(String field, String value) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/v6/members/$field/${Uri.encodeComponent(value.trim())}',
    );
    return CheckResult.fromJson(response.data!).available;
  }

  Future<CommonResponse<SignUpResult>> signUp(
    CreateMemberRequest request,
  ) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/v6/members',
      data: request.toJson(),
    );
    if (response.statusCode != 201) {
      throw const FormatException('회원가입 상태 코드 오류');
    }
    final common = CommonResponse<SignUpResult>.fromJson(
      response.data!,
      (value) => SignUpResult.fromJson(value as Map<String, dynamic>),
    );
    if (!common.isSuccess || common.result == null) {
      throw const FormatException('회원가입 결과에 memberId가 없습니다.');
    }
    return common;
  }
}

String writeSignUpErrorMessage(DioException error) =>
    readApiErrorMessage(error, '회원가입에 실패했습니다. 잠시 후 다시 시도해 주세요.');

String readApiErrorMessage(DioException error, String fallback) {
  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    try {
      final common = CommonResponse<Object?>.fromJson(data, (value) => value);
      if (common.message.isNotEmpty) return common.message;
    } catch (_) {
      /* Non-contract errors must still release the UI. */
    }
  }
  return fallback;
}
