import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/paged_movies_view_model.dart';
import '../widgets/movie/paged_movie_results.dart';

class TmdbMovieListScreen extends StatefulWidget {
  const TmdbMovieListScreen({super.key});
  @override
  State<TmdbMovieListScreen> createState() => _TmdbMovieListScreenState();
}

class _TmdbMovieListScreenState extends State<TmdbMovieListScreen> {
  final _scroll = ScrollController();
  bool _infinite = false;
  void _next() {
    if (!_infinite ||
        !_scroll.hasClients ||
        _scroll.position.extentAfter > 280) {
      return;
    }
    final vm = context.read<PagedMoviesViewModel>();
    if (vm.nextPageError == null) vm.loadNextPage();
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_next);
  }

  @override
  void dispose() {
    _scroll.removeListener(_next);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PagedMoviesViewModel>();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(
              children: [
                Text('영화', style: Theme.of(context).textTheme.headlineMedium),
                const Spacer(),
                IconButton(
                  key: const Key('open-movie-search'),
                  tooltip: '영화 검색',
                  onPressed: () => context.push('/movies/search'),
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              key: const Key('tmdb-genre-chips'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: vm.genres.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final genre = index == 0 ? null : vm.genres[index - 1];
                return FilterChip(
                  key: Key('tmdb-genre-${genre?.id.toString() ?? 'all'}'),
                  label: Text(genre?.name ?? '전체'),
                  selected: vm.genreId == genre?.id,
                  onSelected: (_) {
                    if (_scroll.hasClients) _scroll.jumpTo(0);
                    vm.loadInitial(selectedGenre: genre?.id);
                  },
                );
              },
            ),
          ),
          SwitchListTile(
            key: const Key('infinite-toggle'),
            dense: true,
            title: const Text('무한 스크롤'),
            value: _infinite,
            onChanged: (value) {
              setState(() => _infinite = value);
              if (value) _next();
            },
          ),
          Expanded(
            child: PagedMovieResults(
              vm: vm,
              controller: _scroll,
              infinite: _infinite,
            ),
          ),
        ],
      ),
    );
  }
}
