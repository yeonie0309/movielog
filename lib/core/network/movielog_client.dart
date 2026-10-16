import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// TMDB 토큰과 interceptor를 자체 API에 전달하지 않는 별도 Client입니다.
Dio createMovieLogClient() {
  const configuredUrl = String.fromEnvironment('MOVIELOG_API_BASE_URL');
  final defaultUrl = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:3000'
      : 'http://localhost:3000';
  return Dio(
    BaseOptions(
      baseUrl: configuredUrl.isEmpty ? defaultUrl : configuredUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {'accept': 'application/json'},
    ),
  );
}
