import 'package:flutter/foundation.dart';

import '../data/services/member_check_service.dart';

enum CheckStatus { idle, checking, available, duplicated, error }

class _FieldCheck {
  String input = '';
  String? lastDuplicated;
  String? error;
  int version = 0;
  CheckStatus status = CheckStatus.idle;
}

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel(this._service);
  final MemberCheckService _service;
  final _nickname = _FieldCheck();
  final _email = _FieldCheck();
  bool _disposed = false;

  CheckStatus get nicknameCheckStatus => _nickname.status;
  CheckStatus get emailCheckStatus => _email.status;
  String? get nicknameErrorText => _nickname.error;
  String? get emailErrorText => _email.error;
  bool get canCheckNickname =>
      _canCheck(_nickname) && _nickname.input.length >= 2;
  bool get canCheckEmail =>
      _canCheck(_email) &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.input);
  bool get hasBlockingCheck => [
    _nickname,
    _email,
  ].any((field) => field.error != null || field.status == CheckStatus.checking);

  bool _canCheck(_FieldCheck field) =>
      field.status != CheckStatus.checking &&
      field.status != CheckStatus.duplicated;

  void onNicknameChanged(String value) => _changed(_nickname, value, '닉네임');
  void onEmailChanged(String value) => _changed(_email, value, '이메일');

  void _changed(_FieldCheck field, String value, String label) {
    final input = value.trim();
    if (field.input == input) return;
    field.input = input;
    field.version++;
    final duplicate = input == field.lastDuplicated;
    field.status = duplicate ? CheckStatus.duplicated : CheckStatus.idle;
    field.error = duplicate ? '이미 사용 중인 $label입니다.' : null;
    if (!_disposed) notifyListeners();
  }

  Future<void> checkNickname(String value) =>
      _check(_nickname, value, '닉네임', canCheckNickname, _service.checkNickname);
  Future<void> checkEmail(String value) =>
      _check(_email, value, '이메일', canCheckEmail, _service.checkEmail);

  Future<void> _check(
    _FieldCheck field,
    String value,
    String label,
    bool canCheck,
    Future<bool> Function(String) request,
  ) async {
    if (_disposed || !canCheck || value.trim() != field.input) return;
    final input = field.input;
    final version = ++field.version;
    field.status = CheckStatus.checking;
    field.error = null;
    notifyListeners();
    bool isCurrent() =>
        !_disposed && version == field.version && input == field.input;
    try {
      final available = await request(input);
      if (!isCurrent()) return;
      field.status = available ? CheckStatus.available : CheckStatus.duplicated;
      if (!available) {
        field.lastDuplicated = input;
        field.error = '이미 사용 중인 $label입니다.';
      }
    } catch (_) {
      if (!isCurrent()) return;
      field.status = CheckStatus.error;
      field.error = '중복 확인에 실패했습니다. 다시 시도해 주세요.';
    }
    if (isCurrent()) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _nickname.version++;
    _email.version++;
    super.dispose();
  }
}
