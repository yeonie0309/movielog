import 'package:dio/dio.dart';

/// Public workbook API; each Service selects v5 (legacy) or v6 explicitly.
/// Never attach the TMDB bearer token or request/response body logger here.
Dio createWorkbookClient() => Dio(
  BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);
