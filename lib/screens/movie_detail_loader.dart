import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../data/services/tmdb_movie_service.dart';
import '../data/services/rating_api_service.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/movie_detail_view_model.dart';
import '../view_models/tmdb_movie_mapper.dart';
import 'movie_detail_screen.dart';

class MovieDetailLoader extends StatefulWidget {
  const MovieDetailLoader({
    super.key,
    required this.movieId,
    this.initialMovie,
  });
  final int movieId;
  final TmdbMovieDto? initialMovie;
  @override
  State<MovieDetailLoader> createState() => _MovieDetailLoaderState();
}

class _MovieDetailLoaderState extends State<MovieDetailLoader> {
  late Future<TmdbMovieDto> _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.initialMovie != null
        ? Future.value(widget.initialMovie!)
        : context.read<MovieDetailService>().fetchMovieDetail(widget.movieId);
  }

  @override
  void didUpdateWidget(covariant MovieDetailLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movieId != widget.movieId) _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<TmdbMovieDto>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError || snapshot.data == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('영화 상세')),
          body: Center(
            child: TextButton(
              onPressed: () => setState(_load),
              child: const Text('영화를 불러오지 못했습니다. 다시 시도'),
            ),
          ),
        );
      }
      final memberId = context.watch<LearningMemberSession>().memberId;
      return ChangeNotifierProvider(
        key: ValueKey('detail-${widget.movieId}-$memberId'),
        create: (context) => MovieDetailViewModel(
          context.read<RatingApiService>(),
          memberId,
          snapshot.data!.id,
        ),
        child: MovieDetailScreen(
          movie: movieFromTmdb(snapshot.data!),
          serverLinked: true,
        ),
      );
    },
  );
}
