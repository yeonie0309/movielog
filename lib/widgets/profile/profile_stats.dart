import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  static const _stats = <ProfileStatData>[
    ProfileStatData(
      label: '본 영화',
      value: '342',
      iconAsset: 'assets/icons/movie.svg',
    ),
    ProfileStatData(
      label: '평점',
      value: '4.2',
      iconAsset: 'assets/icons/star.svg',
    ),
    ProfileStatData(
      label: '즐겨찾기',
      value: '58',
      iconAsset: 'assets/icons/bookmark.svg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _stats
            .map(
              (stat) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: stat == _stats.last ? 0 : 8),
                  child: StatItem(data: stat),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class ProfileStatData {
  const ProfileStatData({
    required this.label,
    required this.value,
    required this.iconAsset,
  });

  final String label;
  final String value;
  final String iconAsset;
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.data});

  final ProfileStatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        border: Border.all(color: AppColors.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                data.iconAsset,
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(
                  AppColors.gray,
                  BlendMode.srcIn,
                ),
                semanticsLabel: '${data.label} 아이콘',
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.value,
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.violet),
          ),
        ],
      ),
    );
  }
}
