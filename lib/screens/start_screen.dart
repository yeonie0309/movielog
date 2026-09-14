import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 52, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WelcomeContent(),
              const Spacer(),
              SizedBox(
                height: 58,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('시작하기', style: AppTextStyles.button),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('FLUTTER 0주차', style: AppTextStyles.labelLarge),
        const SizedBox(height: 64),
        SvgPicture.asset(
          'assets/logos/movielog_logo.svg',
          width: 72,
          height: 72,
          semanticsLabel: 'MovieLog 로고',
        ),
        const SizedBox(height: 72),
        const Text(
          '영화의 순간을\n기록하세요',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.displayMedium,
        ),
        const SizedBox(height: 20),
        const Text(
          '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyLarge,
        ),
      ],
    );
  }
}
