class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterAsset,
    required this.overview,
    required this.runtimeMinutes,
    required this.averageRating,
  });

  final int id;
  final String title;
  final String genre;
  final int year;
  final String posterAsset;
  final String overview;
  final int runtimeMinutes;
  final double averageRating;
}
