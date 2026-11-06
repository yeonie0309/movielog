import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';

class SignUpHeader extends StatelessWidget {
  const SignUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.violetContainer,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/logos/movielog_logo.svg',
                semanticsLabel: 'MovieLog 로고',
              ),
            ),
            const Positioned(
              right: -2,
              bottom: -2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.violet,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('MovieLog 시작하기', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '나만의 영화 기록을 위해\n기본 정보를 입력해 주세요.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
