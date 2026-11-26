import 'package:flutter/material.dart';

import '../../view_models/paged_movies_view_model.dart';

class MoviePageFooter extends StatelessWidget {
  const MoviePageFooter({super.key, required this.vm, this.infinite = false});
  final PagedMoviesViewModel vm;
  final bool infinite;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: vm.loadingMore
        ? const Center(
            child: CircularProgressIndicator(key: Key('next-page-progress')),
          )
        : vm.nextPageError != null
        ? Column(
            children: [
              Text(vm.nextPageError!),
              TextButton(
                key: const Key('retry-next-page'),
                onPressed: vm.loadNextPage,
                child: const Text('같은 페이지 다시 시도'),
              ),
            ],
          )
        : !vm.hasMore
        ? const Center(child: Text('마지막 페이지입니다.', key: Key('page-end')))
        : infinite
        ? const SizedBox.shrink()
        : Center(
            child: FilledButton(
              key: const Key('load-next-page'),
              onPressed: vm.loadNextPage,
              child: const Text('더 보기'),
            ),
          ),
  );
}
