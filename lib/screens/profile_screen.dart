import 'package:flutter/material.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/profile/edit_profile_button.dart';
import '../widgets/profile/favorite_genres.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_stats.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ProfileHeader(),
              const SizedBox(height: 20),
              const Center(child: EditProfileButton()),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                child: const ProfileStats(),
              ),
              const FavoriteGenres(),
            ],
          ),
        ),
      ),
    );
  }
}
