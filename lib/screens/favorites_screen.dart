import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/favorites_view_model.dart';
import '../view_models/load_phase.dart';
import '../view_models/tmdb_movie_mapper.dart';
import '../widgets/movie/movie_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    final body = switch (vm.phase) {
      LoadPhase.idle => const Center(child: Text('로그인 정보를 확인해 주세요.')),
      LoadPhase.loading => const Center(child: CircularProgressIndicator()),
      LoadPhase.empty => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark_border, size: 48),
            const Text('아직 즐겨찾기한 영화가 없습니다.'),
            TextButton(onPressed: vm.refresh, child: const Text('새로고침')),
          ],
        ),
      ),
      LoadPhase.error => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('즐겨찾기 목록을 불러오지 못했습니다.'),
            TextButton(onPressed: vm.refresh, child: const Text('다시 시도')),
          ],
        ),
      ),
      LoadPhase.success => LayoutBuilder(
        builder: (context, box) => RefreshIndicator(
          onRefresh: vm.refresh,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: box.maxWidth >= 620 ? 3 : 2,
              childAspectRatio: .60,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: vm.items.length,
            itemBuilder: (context, index) {
              final row = vm.items[index];
              Future<void> open() async {
                await context.push(
                  '/movies/${row.favorite.movieId}',
                  extra: row.movie,
                );
                if (context.mounted && !vm.isDisposed) await vm.refresh();
              }

              if (row.movie == null) {
                return Card(
                  key: Key('favorite-failed-${row.favorite.movieId}'),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image_outlined, size: 48),
                        Text('영화 ${row.favorite.movieId}'),
                        const Text(
                          '영화 정보를 불러오지 못했습니다.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: vm.retrying.contains(row.favorite.movieId)
                              ? null
                              : () => vm.retryMovie(row.favorite.movieId),
                          child: Text(
                            vm.retrying.contains(row.favorite.movieId)
                                ? '조회 중'
                                : '이 영화만 다시 시도',
                          ),
                        ),
                        TextButton(onPressed: open, child: const Text('상세 보기')),
                      ],
                    ),
                  ),
                );
              }
              return MovieCard(movie: movieFromTmdb(row.movie!), onTap: open);
            },
          ),
        ),
      ),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('내 즐겨찾기'), centerTitle: true),
      body: SafeArea(child: body),
    );
  }
}
