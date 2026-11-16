import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/common_app_bar.dart';
import '../widgets/sign_up/sign_up_header.dart';
import '../widgets/sign_up/sign_up_text_field.dart';
import '../view_models/sign_up_view_model.dart';
import '../view_models/learning_member_session.dart';
import '../data/models/create_member_request.dart';
import '../widgets/movielog_button.dart';

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
  late final SignUpViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SignUpViewModel(context.read())..addListener(_onCheckChanged);
  }

  void _onCheckChanged() => setState(() {});

  bool get _canSubmit =>
      _nicknameController.text.trim().length >= 2 &&
      _nicknameController.text.trim().length <= 12 &&
      _isValidEmail(_emailController.text.trim()) &&
      validatePasswordFormat(_passwordController.text) == null &&
      _agreedToTerms &&
      _viewModel.checksAvailable &&
      !_viewModel.isSubmitting &&
      !_viewModel.hasBlockingCheck;

  static bool _isValidEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  void _refreshFormState(String _) {
    setState(() {});
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || !_canSubmit) return;

    FocusScope.of(context).unfocus();
    await _viewModel.submit(
      CreateMemberRequest(
        email: _emailController.text,
        nickname: _nicknameController.text,
        password: _passwordController.text,
      ),
    );
    if (!mounted) return;
    if (_viewModel.submitStatus == SubmitStatus.success) {
      context.read<LearningMemberSession>().setMemberId(
        _viewModel.createdMemberId!,
      );
      _passwordController.clear();
      context.go('/movies');
    } else if (_viewModel.snackbarMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_viewModel.snackbarMessage!)));
    }
  }

  void _openRatingPractice() {
    context.push('/rating-practice');
  }

  String? _validateNickname(String? value) {
    final nickname = value?.trim() ?? '';
    if (nickname.isEmpty) return '닉네임을 입력해 주세요.';
    if (nickname.length < 2) return '닉네임은 두 글자 이상 입력해 주세요.';
    if (nickname.length > 12) return '닉네임은 12자 이하로 입력해 주세요.';
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return '이메일을 입력해 주세요.';
    if (!_isValidEmail(email)) return '올바른 이메일 형식을 입력해 주세요.';
    return null;
  }

  String? _validatePassword(String? value) {
    return validatePasswordFormat(value);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onCheckChanged);
    _viewModel.dispose();
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
    return PopScope(
      canPop: !_viewModel.isSubmitting,
      child: Scaffold(
        appBar: const CommonAppBar(title: '회원가입'),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final maxFormWidth = isWide ? 560.0 : double.infinity;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  isWide ? 48 : 24,
                  24,
                  isWide ? 48 : 24,
                  40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxFormWidth),
                    child: AbsorbPointer(
                      absorbing: _viewModel.isSubmitting,
                      child: Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SignUpHeader(),
                            const SizedBox(height: 32),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SignUpTextField(
                                    fieldKey: const Key('nickname-field'),
                                    controller: _nicknameController,
                                    focusNode: _nicknameFocusNode,
                                    label: '닉네임',
                                    hint: '두 글자 이상 입력해 주세요',
                                    validator: _validateNickname,
                                    forceErrorText:
                                        _viewModel.nicknameErrorText,
                                    suffixIcon:
                                        _viewModel.nicknameCheckStatus ==
                                            CheckStatus.available
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onChanged: (value) {
                                      _viewModel.onNicknameChanged(value);
                                      _refreshFormState(value);
                                    },
                                    onFieldSubmitted: (_) =>
                                        _emailFocusNode.requestFocus(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _checkButton(true),
                              ],
                            ),
                            if (_viewModel.nicknameCheckStatus ==
                                CheckStatus.available)
                              const Text(
                                '사용 가능한 닉네임입니다.',
                                key: Key('nickname-availability-message'),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SignUpTextField(
                                    fieldKey: const Key('email-field'),
                                    controller: _emailController,
                                    focusNode: _emailFocusNode,
                                    label: '이메일',
                                    hint: 'movielog@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: _validateEmail,
                                    forceErrorText: _viewModel.emailErrorText,
                                    suffixIcon:
                                        _viewModel.emailCheckStatus ==
                                            CheckStatus.available
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                    onChanged: (value) {
                                      _viewModel.onEmailChanged(value);
                                      _refreshFormState(value);
                                    },
                                    onFieldSubmitted: (_) =>
                                        _passwordFocusNode.requestFocus(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _checkButton(false),
                              ],
                            ),
                            if (_viewModel.emailCheckStatus ==
                                CheckStatus.available)
                              const Text(
                                '사용 가능한 이메일입니다.',
                                key: Key('email-availability-message'),
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
                              forceErrorText: _viewModel.passwordErrorText,
                              onChanged: (value) {
                                _viewModel.onPasswordChanged();
                                _refreshFormState(value);
                              },
                              onFieldSubmitted: (_) {
                                if (_canSubmit) _submit();
                              },
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? '비밀번호 표시'
                                    : '비밀번호 숨기기',
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            MovieLogButton(
                              key: const Key('sign-up-button'),
                              onPressed: _canSubmit ? _submit : null,
                              label: '가입하기',
                              isLoading: _viewModel.isSubmitting,
                              width: double.infinity,
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _checkButton(bool nickname) {
    final status = nickname
        ? _viewModel.nicknameCheckStatus
        : _viewModel.emailCheckStatus;
    final enabled = nickname
        ? _viewModel.canCheckNickname
        : _viewModel.canCheckEmail;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: MovieLogButton(
        key: Key(nickname ? 'check-nickname-button' : 'check-email-button'),
        label: '중복 확인',
        isLoading: status == CheckStatus.checking,
        onPressed: enabled
            ? () {
                FocusScope.of(context).unfocus();
                if (nickname) {
                  _viewModel.checkNickname(_nicknameController.text);
                } else {
                  _viewModel.checkEmail(_emailController.text);
                }
              }
            : null,
      ),
    );
  }
}
