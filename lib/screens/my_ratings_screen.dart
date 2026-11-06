import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import '../widgets/movie/tmdb_poster_image.dart';
import '../widgets/movie/rating_dialog.dart';
import '../widgets/movie/delete_rating_dialog.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyRatingsViewModel>();
    return PopScope(
      canPop: !vm.isDeletingSelected,
      child: Stack(
        children: [
          Scaffold(
            appBar: CommonAppBar(
              title: '내가 등록한 평점',
              centerTitle: true,
              onBack: () {
                if (vm.isDeletingSelected) return;
                context.canPop() ? context.pop() : context.go('/my');
              },
              actions: [
                IconButton(
                  tooltip: '새로고침',
                  onPressed:
                      vm.status == MyRatingsStatus.loading || vm.isWriting
                      ? null
                      : vm.load,
                  icon: const Icon(Icons.refresh),
                ),
                TextButton(
                  onPressed: vm.isWriting
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          vm.toggleEditing();
                        },
                  child: Text(vm.isEditing ? '취소' : '편집'),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      vm.isEditing
                          ? '${vm.selectedRatingIds.length}개 선택'
                          : '학습용 회원 ${vm.memberId} · 로그인 인증이 아닌 메모리 세션',
                    ),
                  ),
                  Expanded(
                    child: switch (vm.status) {
                      MyRatingsStatus.idle ||
                      MyRatingsStatus.loading => const Center(
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
                              Text(
                                vm.refreshWarning ?? vm.message!,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              MovieLogButton(
                                label: '다시 시도',
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  vm.load();
                                },
                              ),
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
                          Text(
                            '학습용 회원 ${vm.memberId} · 평점 ${vm.ratings.length}건',
                          ),
                          const SizedBox(height: 8),
                          ...vm.ratings.map((item) => _card(context, vm, item)),
                        ],
                      ),
                    },
                  ),
                  if (vm.isEditing)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: MovieLogButton(
                        label: '선택한 ${vm.selectedRatingIds.length}개 삭제',
                        onPressed: vm.selectedRatingIds.isEmpty || vm.isWriting
                            ? null
                            : () => _deleteSelected(context, vm),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (vm.isDeletingSelected) ...[
            const Positioned.fill(
              child: ModalBarrier(dismissible: false, color: Colors.black45),
            ),
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          ],
        ],
      ),
    );
  }

  Future<void> _deleteSelected(
    BuildContext context,
    MyRatingsViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('선택한 ${vm.selectedRatingIds.length}개 평점을 삭제할까요?'),
        content: const Text('삭제한 평점은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await vm.deleteSelectedRatings();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          vm.operationMessage ?? vm.refreshWarning ?? '선택한 평점을 삭제했습니다.',
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    MyRatingsViewModel vm,
    RatingWithMovie item,
  ) {
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
            if (vm.isEditing)
              Checkbox(
                value: vm.selectedRatingIds.contains(rating.ratingId),
                onChanged: vm.isWriting
                    ? null
                    : (value) =>
                          vm.selectRating(rating.ratingId, value ?? false),
              )
            else
              Column(
                children: [
                  IconButton(
                    tooltip: '평점 수정',
                    key: Key('edit-rating-${rating.ratingId}'),
                    onPressed: vm.isWriting
                        ? null
                        : () async {
                            final saved = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => RatingDialog(
                                initialRating: rating.score.toDouble(),
                                initialComment: rating.comment,
                                onSubmit: (score, comment) => vm.updateRating(
                                  ratingId: rating.ratingId,
                                  score: score,
                                  comment: comment,
                                ),
                              ),
                            );
                            if (context.mounted && saved == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    vm.refreshWarning ?? '평점을 수정했습니다.',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: '평점 삭제',
                    key: Key('delete-rating-${rating.ratingId}'),
                    onPressed: vm.isWriting
                        ? null
                        : () async {
                            final deleted = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => DeleteRatingDialog(
                                onDelete: () =>
                                    vm.deleteRating(rating.ratingId),
                              ),
                            );
                            if (context.mounted && deleted == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    vm.refreshWarning ?? '평점을 삭제했습니다.',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
