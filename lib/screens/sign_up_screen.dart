import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/sign_up/sign_up_header.dart';
import '../widgets/sign_up/sign_up_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nicknameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _agreedToTerms = false;
  bool _obscurePassword = true;

  bool get _canSubmit =>
      _nicknameController.text.trim().length >= 2 &&
      _isValidEmail(_emailController.text.trim()) &&
      _passwordController.text.length >= 8 &&
      _agreedToTerms;

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  void _refreshFormState(String _) {
    setState(() {});
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_agreedToTerms) return;

    FocusScope.of(context).unfocus();
    context.go('/home');
  }

  void _openRatingPractice() {
    context.push('/rating-practice');
  }

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
    if (nickname.length < 2) return '닉네임은 두 글자 이상 입력해 주세요.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해 주세요.';
    if (!_isValidEmail(email)) return '올바른 이메일 형식을 입력해 주세요.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return '비밀번호를 입력해 주세요.';
    if (password.length < 8) return '비밀번호는 8자 이상 입력해 주세요.';
    return null;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '회원가입'),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final maxFormWidth = isWide ? 560.0 : double.infinity;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                isWide ? 48 : 24,
                24,
                isWide ? 48 : 24,
                40,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxFormWidth),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SignUpHeader(),
                        const SizedBox(height: 32),
                        SignUpTextField(
                          fieldKey: const Key('nickname-field'),
                          controller: _nicknameController,
                          focusNode: _nicknameFocusNode,
                          label: '닉네임',
                          hint: '두 글자 이상 입력해 주세요',
                          validator: _validateNickname,
                          onChanged: _refreshFormState,
                          onFieldSubmitted: (_) =>
                              _emailFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        SignUpTextField(
                          fieldKey: const Key('email-field'),
                          controller: _emailController,
                          focusNode: _emailFocusNode,
                          label: '이메일',
                          hint: 'movielog@example.com',
                          keyboardType: TextInputType.emailAddress,
                          validator: _validateEmail,
                          onChanged: _refreshFormState,
                          onFieldSubmitted: (_) =>
                              _passwordFocusNode.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        SignUpTextField(
                          fieldKey: const Key('password-field'),
                          controller: _passwordController,
                          focusNode: _passwordFocusNode,
                          label: '비밀번호',
                          hint: '8자 이상 입력해 주세요',
                          textInputAction: TextInputAction.done,
                          obscureText: _obscurePassword,
                          validator: _validatePassword,
                          onChanged: _refreshFormState,
                          onFieldSubmitted: (_) {
                            if (_canSubmit) _submit();
                          },
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? '비밀번호 표시' : '비밀번호 숨기기',
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              key: const Key('terms-checkbox'),
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  '[필수] MovieLog 이용약관 및 개인정보 처리방침에 동의합니다.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            key: const Key('sign-up-button'),
                            onPressed: _canSubmit ? _submit : null,
                            child: const Text('가입하기'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          key: const Key('open-rating-practice-button'),
                          onPressed: _openRatingPractice,
                          icon: const Icon(Icons.star_outline_rounded),
                          label: const Text('별점 입력 미니 실습'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
