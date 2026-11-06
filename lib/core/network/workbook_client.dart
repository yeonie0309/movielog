import 'package:dio/dio.dart';

/// Public workbook v5 API. Never attach the TMDB bearer token here.
Dio createWorkbookClient() => Dio(
  BaseOptions(
    baseUrl: 'https://workbook.devnoco.com',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ),
);
