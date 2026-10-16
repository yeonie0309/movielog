import 'package:dio/dio.dart';

import '../models/tmdb_genre_dto.dart';
import '../models/tmdb_movie_page_dto.dart';

abstract class MovieCatalogService {
  Future<TmdbMoviePageDto> fetchPopular({int page = 1});
  Future<TmdbMoviePageDto> discoverMovies({required int page, int? genreId});
  Future<List<TmdbGenreDto>> fetchGenres();
}

class TmdbMovieService implements MovieCatalogService {
  TmdbMovieService(this._dio);

  final Dio _dio;

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/movie/popular',
      queryParameters: {'language': 'ko-KR', 'page': page},
    );
    return TmdbMoviePageDto.fromJson(response.data!);
  }

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/discover/movie',
      queryParameters: {
        'language': 'ko-KR',
        'page': page,
        'sort_by': 'popularity.desc',
        'include_adult': false,
        'include_video': false,
        'with_genres': ?genreId,
      },
    );
    return TmdbMoviePageDto.fromJson(response.data!);
  }

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/genre/movie/list',
      queryParameters: {'language': 'ko'},
    );
    final rawGenres = response.data?['genres'] as List<dynamic>? ?? const [];
    return rawGenres
        .map((item) => TmdbGenreDto.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class MissingTokenMovieService implements MovieCatalogService {
  const MissingTokenMovieService();

  Never _missing() =>
      throw StateError('프로젝트 루트 .env 파일에 TMDB_ACCESS_TOKEN을 설정해 주세요.');

  @override
  Future<TmdbMoviePageDto> fetchPopular({int page = 1}) async => _missing();

  @override
  Future<TmdbMoviePageDto> discoverMovies({
    required int page,
    int? genreId,
  }) async => _missing();

  @override
  Future<List<TmdbGenreDto>> fetchGenres() async => _missing();
}
