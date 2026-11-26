import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/profile/profile_header.dart';

class AuthMyPageScreen extends StatelessWidget {
  const AuthMyPageScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;
    final date = member?.createdAt.toLocal();
    final body = switch (auth.memberStatus) {
      MemberLoadStatus.idle || MemberLoadStatus.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      MemberLoadStatus.error => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(auth.message ?? '내 정보 조회에 실패했습니다.'),
            TextButton(
              onPressed: () => auth.loadMember(force: true),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      MemberLoadStatus.success => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ProfileHeader(nickname: member?.nickname, description: member?.email),
          if (date != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')} 가입',
                textAlign: TextAlign.center,
              ),
            ),
          OutlinedButton(
            onPressed: () => context.push('/my/profile/edit'),
            child: const Text('프로필 수정'),
          ),
          const SizedBox(height: 24),
          ListTile(
            key: const Key('open-my-ratings'),
            leading: const Icon(Icons.star_outline),
            title: const Text('이번 로그인에서 등록한 평점'),
            subtitle: Text('${auth.sessionRatings.length}건'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/my/ratings'),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '현재 API는 로그인한 회원의 전체 평점 조회를 제공하지 않습니다. 재시작하면 이 목록은 비워집니다.',
            ),
          ),
          ListTile(
            key: const Key('open-my-favorites'),
            leading: const Icon(Icons.bookmark_border),
            title: const Text('내 즐겨찾기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: member == null ? null : () => context.push('/my/favorites'),
          ),
          OutlinedButton(
            onPressed: () => context.push('/member-ratings'),
            child: const Text('공개 회원별 평점 조회'),
          ),
        ],
      ),
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            key: const Key('logout-button'),
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}
