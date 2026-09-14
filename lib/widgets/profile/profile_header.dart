import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    this.imageAsset = 'assets/images/profile/profile_movielog.jpg',
  });

  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: AppColors.violet,
            shape: BoxShape.circle,
          ),
          child: ClipOval(child: _buildProfileImage()),
        ),
        const SizedBox(height: 12),
        const Text('무비러버', style: AppTextStyles.titleMedium),
        const SizedBox(height: 8),
        const Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객.\n좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    final asset = imageAsset;
    if (asset == null) {
      return const _ProfileFallback();
    }

    return Image.asset(
      asset,
      fit: BoxFit.cover,
      semanticLabel: '무비러버 프로필 사진',
      errorBuilder: (context, error, stackTrace) => const _ProfileFallback(),
    );
  }
}

class _ProfileFallback extends StatelessWidget {
  const _ProfileFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.violetContainer,
      child: Icon(
        Icons.person,
        size: 44,
        color: AppColors.violet,
        semanticLabel: '기본 프로필 아이콘',
      ),
    );
  }
}
