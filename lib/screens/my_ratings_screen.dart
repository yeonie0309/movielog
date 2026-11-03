import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movie/tmdb_poster_image.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    return Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        centerTitle: true,
        onBack: () => context.canPop() ? context.pop() : context.go('/my'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: vm.status == MyRatingsStatus.loading ? null : vm.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('학습용 공개 데이터 · memberId 1 (로그인한 내 계정 아님)'),
            ),
            Expanded(
              child: switch (vm.status) {
                MyRatingsStatus.idle || MyRatingsStatus.loading => const Center(
                  key: Key('my-ratings-loading'),
                  child: CircularProgressIndicator(),
                ),
                MyRatingsStatus.error => Center(
                  key: const Key('my-ratings-error'),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.message!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        MovieLogButton(label: '다시 시도', onPressed: vm.load),
                      ],
                    ),
                  ),
                ),
                MyRatingsStatus.empty => const Center(
                  key: Key('my-ratings-empty'),
                  child: Text('등록된 평점이 없습니다.'),
                ),
                MyRatingsStatus.success => ListView(
                  key: const Key('my-ratings-success'),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (vm.message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(vm.message!),
                      ),
                    Text('공개 회원 1 · 평점 ${vm.ratings.length}건'),
                    const SizedBox(height: 8),
                    ...vm.ratings.map(_card),
                  ],
                ),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(RatingWithMovie item) {
    final rating = item.rating;
    final date = rating.createdAt;
    final comment = rating.comment;
    return Card(
      key: Key('my-rating-${rating.ratingId}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 72,
              height: 108,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TmdbPosterImage(posterPath: item.movie?.posterPath),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.movie?.title ?? '영화 정보를 찾을 수 없어요',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  Text('TMDB #${rating.movieId}'),
                  Text('★ ${rating.score} / 5'),
                  if (comment != null && comment.isNotEmpty) Text(comment),
                  Text(
                    '등록일 ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
