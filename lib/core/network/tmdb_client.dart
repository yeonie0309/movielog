import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'tmdb_logging_interceptor.dart';

Dio createTmdbClient(String accessToken) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final uri = options.uri;
        if (uri.scheme != 'https' ||
            uri.host != 'api.themoviedb.org' ||
            uri.port != 443) {
          options.headers.remove('Authorization');
        }
        handler.next(options);
      },
    ),
  );
  if (kDebugMode) dio.interceptors.add(TmdbLoggingInterceptor());
  return dio;
}
