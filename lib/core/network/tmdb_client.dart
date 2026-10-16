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
  if (kDebugMode) dio.interceptors.add(TmdbLoggingInterceptor());
  return dio;
}
