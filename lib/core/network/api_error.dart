import 'package:dio/dio.dart';

String? apiErrorCode(Object error) {
  if (error is! DioException) return null;
  final body = error.response?.data;
  return body is Map && body['code'] is String ? body['code'] as String : null;
}

String apiErrorMessage(Object error, String fallback) {
  if (error is! DioException) return fallback;
  final body = error.response?.data;
  return body is Map && body['message'] is String
      ? body['message'] as String
      : fallback;
}

bool isSessionError(Object error) =>
    const {'AUTH401_2', 'AUTH401_3', 'AUTH401_4'}.contains(apiErrorCode(error));

class SessionChangedException implements Exception {
  const SessionChangedException();
  @override
  String toString() => '로그인 상태가 변경되었습니다.';
}
