import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../view_models/load_phase.dart';
import '../../view_models/paged_movies_view_model.dart';
import '../../view_models/tmdb_movie_mapper.dart';
import 'movie_card.dart';
import 'movie_list_loading.dart';
import 'movie_page_footer.dart';

class PagedMovieResults extends StatelessWidget {
  const PagedMovieResults({
    super.key,
    required this.vm,
    this.controller,
    this.infinite = false,
  });
  final PagedMoviesViewModel vm;
  final ScrollController? controller;
  final bool infinite;
  @override
  Widget build(BuildContext context) {
    switch (vm.phase) {
      case LoadPhase.idle:
        return const Center(child: Text('검색어를 입력해 주세요.'));
      case LoadPhase.loading:
        return const MovieListLoading();
      case LoadPhase.empty:
        return Center(
          child: Text(vm.searchMode ? '검색 결과가 없습니다.' : '표시할 영화가 없습니다.'),
        );
      case LoadPhase.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(vm.error!),
              TextButton(onPressed: vm.refresh, child: const Text('다시 시도')),
            ],
          ),
        );
      case LoadPhase.success:
        break;
    }
    return LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 920
            ? 4
            : box.maxWidth >= 620
            ? 3
            : 2;
        return RefreshIndicator(
          onRefresh: vm.refresh,
          child: CustomScrollView(
            key: const Key('paged-movie-scroll'),
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: box.maxWidth >= 620 ? .72 : .65,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final dto = vm.items[index];
                    return MovieCard(
                      movie: movieFromTmdb(dto, genres: vm.genres),
                      onTap: () =>
                          context.push('/movies/${dto.id}', extra: dto),
                    );
                  }, childCount: vm.items.length),
                ),
              ),
              SliverToBoxAdapter(
                child: MoviePageFooter(vm: vm, infinite: infinite),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }
}
