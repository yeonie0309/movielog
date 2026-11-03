import 'package:dio/dio.dart';

import '../models/check_result.dart';

class MemberCheckService {
  MemberCheckService(this._dio);
  final Dio _dio;

  Future<bool> checkNickname(String value) => _check('nickname', value);
  Future<bool> checkEmail(String value) => _check('email', value);

  Future<bool> _check(String field, String value) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v5/members/$field/${Uri.encodeComponent(value.trim())}',
    );
    return CheckResult.fromJson(response.data!).available;
  }
}
