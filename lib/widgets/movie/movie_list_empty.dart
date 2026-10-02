import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class MovieListEmpty extends StatelessWidget {
  const MovieListEmpty({super.key, this.filtered = false});

  final bool filtered;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('movie-list-empty'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.movie_filter_outlined,
              size: 64,
              color: AppColors.violet,
            ),
            const SizedBox(height: 18),
            Text(
              filtered ? '선택한 장르의 영화가 없어요' : '등록된 영화가 없어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              filtered ? '다른 장르를 선택해 보세요.' : '새로운 영화가 추가되면 알려드릴게요.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}
