import '../data/models/tmdb_genre_dto.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../models/movie.dart';

Movie movieFromTmdb(TmdbMovieDto dto, {List<TmdbGenreDto> genres = const []}) {
  final genreNames = {for (final genre in genres) genre.id: genre.name};
  final genre = dto.genreIds
      .map((id) => genreNames[id])
      .whereType<String>()
      .firstOrNull;

  return Movie(
    id: dto.id,
    title: dto.title,
    genre: genre ?? '영화',
    year: dto.releaseDate == null || dto.releaseDate!.length < 4
        ? 0
        : int.tryParse(dto.releaseDate!.substring(0, 4)) ?? 0,
    posterAsset: '',
    posterPath: dto.posterPath,
    overview: dto.overview,
    runtimeMinutes: 0,
    averageRating: dto.voteAverage / 2,
  );
}
