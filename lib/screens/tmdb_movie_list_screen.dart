import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../view_models/movie_list_view_model.dart';
import '../view_models/movie_load_status.dart';
import '../view_models/tmdb_movie_mapper.dart';
import '../widgets/movie/movie_grid.dart';
import '../widgets/movie/movie_list_empty.dart';
import '../widgets/movie/movie_list_error.dart';
import '../widgets/movie/movie_list_loading.dart';

class TmdbMovieListScreen extends StatelessWidget {
  const TmdbMovieListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '영화',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    viewModel.isLoading
                        ? '영화를 불러오는 중이에요.'
                        : '${viewModel.movies.length}편의 영화를 둘러보세요.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) => ListView.separated(
                key: const Key('tmdb-genre-chips'),
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: viewModel.genres.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final genre = index == 0 ? null : viewModel.genres[index - 1];
                  final genreId = genre?.id;
                  return FilterChip(
                    key: Key('tmdb-genre-${genreId ?? 'all'}'),
                    label: Text(genre?.name ?? '전체'),
                    selected: viewModel.selectedGenreId == genreId,
                    selectedColor: AppColors.violetContainer,
                    onSelected: viewModel.isLoading
                        ? null
                        : (_) => context.read<MovieListViewModel>().selectGenre(
                            genreId,
                          ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: Consumer<MovieListViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieLoadStatus.idle ||
                  MovieLoadStatus.loading => const MovieListLoading(),
                  MovieLoadStatus.empty => const MovieListEmpty(),
                  MovieLoadStatus.error => MovieListError(
                    message: viewModel.message ?? '영화를 불러오지 못했어요.',
                    onRetry: () => context.read<MovieListViewModel>().retry(),
                  ),
                  MovieLoadStatus.success => MovieGrid(
                    movies: viewModel.movies
                        .map(
                          (dto) => movieFromTmdb(dto, genres: viewModel.genres),
                        )
                        .toList(),
                    onMovieTap: (movie) =>
                        context.push('/movies/${movie.id}', extra: movie),
                    onRefresh: () => context.read<MovieListViewModel>().retry(),
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
