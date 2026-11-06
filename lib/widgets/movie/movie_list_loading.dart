import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class MovieListLoading extends StatelessWidget {
  const MovieListLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const Key('movie-list-loading'),
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 920
            ? 4
            : constraints.maxWidth >= 620
            ? 3
            : 2;
        final aspectRatio = constraints.maxWidth >= 620 ? 0.72 : 0.65;

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: crossAxisCount * 2,
          itemBuilder: (context, index) {
            return Semantics(
              label: '영화 목록을 불러오는 중',
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
