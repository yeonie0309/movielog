import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nickname;
  late final String _original;
  bool _allowPop = false;
  bool _confirming = false;
  @override
  void initState() {
    super.initState();
    _original = context.read<AuthViewModel>().member?.nickname ?? '';
    _nickname = TextEditingController(text: _original)..addListener(_changed);
  }

  void _changed() => setState(() {});
  Future<void> _leave() async {
    final auth = context.read<AuthViewModel>();
    if (auth.savingProfile || _confirming) return;
    if (_nickname.text.trim() != _original) {
      _confirming = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('변경 내용을 취소할까요?'),
          content: const Text('저장하지 않은 닉네임 변경이 있습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속 수정'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('나가기'),
            ),
          ],
        ),
      );
      _confirming = false;
      if (discard != true || !mounted) return;
    }
    _pop();
  }

  void _pop() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.canPop() ? context.pop() : context.go('/my');
    });
  }

  Future<void> _save() async {
    final saved = await context.read<AuthViewModel>().updateNickname(
      _nickname.text,
    );
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('닉네임을 수정했습니다.')));
    _pop();
  }

  @override
  void dispose() {
    _nickname.removeListener(_changed);
    _nickname.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final value = _nickname.text.trim();
    final lengthError = value.length < 2 || value.length > 12;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 수정'),
          leading: IconButton(
            onPressed: _leave,
            tooltip: '뒤로 가기',
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextField(
                    key: const Key('profile-nickname'),
                    controller: _nickname,
                    enabled: !auth.savingProfile,
                    maxLength: 12,
                    decoration: InputDecoration(
                      labelText: '닉네임',
                      errorText: lengthError
                          ? '닉네임은 2~12자로 입력해 주세요.'
                          : auth.profileError,
                    ),
                  ),
                  const SizedBox(height: 24),
                  MovieLogButton(
                    key: const Key('profile-save'),
                    label: '저장',
                    isLoading: auth.savingProfile,
                    onPressed:
                        lengthError || auth.savingProfile || value == _original
                        ? null
                        : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
