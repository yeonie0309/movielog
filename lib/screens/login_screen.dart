import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _preferences = SharedPreferencesAsync();
  bool _remember = false;
  bool _obscure = true;
  bool _preparingLogin = false;
  static const _emailKey = 'movielog.remembered_email';

  @override
  void initState() {
    super.initState();
    _restoreEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showExpiryNotice());
  }

  void _showExpiryNotice() {
    if (!mounted || !context.read<AuthViewModel>().consumeSessionExpired()) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('로그인 시간이 만료되었습니다. 다시 로그인해 주세요.')),
      );
  }

  Future<void> _restoreEmail() async {
    try {
      final saved = await _preferences.getString(_emailKey);
      if (!mounted || _email.text.isNotEmpty || saved == null) return;
      setState(() {
        _email.text = saved;
        _remember = true;
      });
    } catch (_) {
      /* 이메일 자동 입력 없이 로그인할 수 있다. */
    }
  }

  Future<void> _login() async {
    if (_preparingLogin || !(_form.currentState?.validate() ?? false)) return;
    final email = _email.text.trim();
    final password = _password.text;
    final remember = _remember;
    FocusScope.of(context).unfocus();
    setState(() => _preparingLogin = true);
    try {
      try {
        if (remember) {
          await _preferences.setString(_emailKey, email);
        } else {
          await _preferences.remove(_emailKey);
        }
      } catch (_) {
        /* 이메일 저장과 인증 결과는 개별적으로 처리한다. */
      }
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      await auth.login(email, password);
      if (mounted && auth.status == AuthStatus.signedIn) _password.clear();
    } finally {
      if (mounted) setState(() => _preparingLogin = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    if (auth.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showExpiryNotice());
    }
    final busy =
        _preparingLogin ||
        auth.status == AuthStatus.authenticating ||
        auth.storageCleanupInProgress ||
        auth.storageCleanupFailed;
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('로그인'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.movie_creation_outlined, size: 72),
                        const SizedBox(height: 24),
                        Text(
                          'MovieLog에 오신 것을 환영해요',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 36),
                        TextFormField(
                          key: const Key('login-email'),
                          controller: _email,
                          enabled: !busy,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                          decoration: const InputDecoration(labelText: '이메일'),
                          validator: (value) =>
                              RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(value?.trim() ?? '')
                              ? null
                              : '올바른 이메일을 입력해 주세요.',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const Key('login-password'),
                          controller: _password,
                          enabled: !busy,
                          obscureText: _obscure,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: '비밀번호',
                            suffixIcon: IconButton(
                              tooltip: _obscure ? '비밀번호 표시' : '비밀번호 숨기기',
                              onPressed: busy
                                  ? null
                                  : () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? '비밀번호를 입력해 주세요.'
                              : null,
                          onFieldSubmitted: (_) {
                            if (!busy) _login();
                          },
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('이메일 저장'),
                          controlAffinity: ListTileControlAffinity.leading,
                          value: _remember,
                          onChanged: busy
                              ? null
                              : (value) =>
                                    setState(() => _remember = value ?? false),
                        ),
                        if (auth.message != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              auth.message!,
                              key: const Key('login-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        if (auth.storageCleanupFailed)
                          TextButton(
                            onPressed: auth.storageCleanupInProgress
                                ? null
                                : auth.logout,
                            child: const Text('인증 정보 삭제 재시도'),
                          ),
                        MovieLogButton(
                          key: const Key('login-submit'),
                          label: '로그인',
                          isLoading: busy,
                          onPressed: busy ? null : _login,
                          width: double.infinity,
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => context.push('/register'),
                          child: const Text('회원가입'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
