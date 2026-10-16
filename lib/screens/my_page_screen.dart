import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/profile/edit_profile_button.dart';
import '../widgets/profile/favorite_genres.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_stats.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '마이페이지',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 28),
            const ProfileHeader(),
            const SizedBox(height: 20),
            const Center(child: EditProfileButton()),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: const ProfileStats(),
            ),
            const FavoriteGenres(),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('open-member-ratings-button'),
              onPressed: () => context.push('/member-ratings'),
              icon: const Icon(Icons.star_outline),
              label: const Text('회원별 영화 평점 조회'),
            ),
          ],
        ),
      ),
    );
  }
}
