import 'package:dio/dio.dart';

import '../../data/token_storage.dart';
import 'api_error.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this.storage, {
    required this.sessionVersion,
    required this.onExpired,
  });
  final TokenStorage storage;
  final int Function() sessionVersion;
  final Future<void> Function(int version) onExpired;

  bool _protected(RequestOptions options) {
    final uri = options.uri;
    return uri.scheme == 'https' &&
        uri.port == 443 &&
        uri.host == 'workbook.devnoco.com' &&
        RegExp(
          r'^/v[78]/(members/me|ratings(?:/\d+)?|favorites(?:/\d+)?|movie-records)$',
        ).hasMatch(uri.path);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Dio request headers use case-insensitive keys.
    options.headers.remove('Authorization');
    if (!_protected(options)) {
      handler.next(options);
      return;
    }
    final version = sessionVersion();
    options.extra['sessionVersion'] = version;
    String? token;
    try {
      token = await storage.readAccessToken();
      if (version != sessionVersion()) throw const SessionChangedException();
    } catch (_) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: StateError('인증 저장소를 확인하지 못했습니다. 다시 시도해 주세요.'),
        ),
      );
      return;
    }
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final version = err.requestOptions.extra['sessionVersion'];
    if (_protected(err.requestOptions) &&
        isSessionError(err) &&
        version is int) {
      await onExpired(version);
    }
    handler.next(err);
  }
}
