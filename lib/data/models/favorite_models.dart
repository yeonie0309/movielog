import 'member_rating.dart';
import 'tmdb_movie_dto.dart';

class FavoriteResponseDto {
  const FavoriteResponseDto({
    required this.favoriteId,
    required this.movieId,
    required this.createdAt,
  });
  final int favoriteId;
  final int movieId;
  final DateTime createdAt;
  factory FavoriteResponseDto.fromJson(Map<String, dynamic> json) =>
      FavoriteResponseDto(
        favoriteId: (json['favoriteId'] as num).toInt(),
        movieId: (json['movieId'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class FavoriteListItem {
  const FavoriteListItem(this.favorite, {this.movie, this.failed = false});
  final FavoriteResponseDto favorite;
  final TmdbMovieDto? movie;
  final bool failed;
}

class FavoriteCheckDto {
  const FavoriteCheckDto({required this.movieId, required this.isFavorite});
  final int movieId;
  final bool isFavorite;
  factory FavoriteCheckDto.fromJson(int movieId, Map<String, dynamic> json) =>
      FavoriteCheckDto(
        movieId: movieId,
        isFavorite: json['isFavorite'] as bool,
      );
}

class MovieRecordResponse {
  const MovieRecordResponse(this.rating, this.favorite);
  final MemberRating rating;
  final FavoriteResponseDto? favorite;
  factory MovieRecordResponse.fromJson(Map<String, dynamic> json) =>
      MovieRecordResponse(
        MemberRating.fromJson(json['rating'] as Map<String, dynamic>),
        json['favorite'] == null
            ? null
            : FavoriteResponseDto.fromJson(
                json['favorite'] as Map<String, dynamic>,
              ),
      );
}
