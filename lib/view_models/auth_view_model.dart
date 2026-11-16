import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../data/models/auth_models.dart';
import '../data/models/member_rating.dart';
import '../data/services/auth_api_service.dart';
import '../data/token_storage.dart';

enum AuthStatus {
  initializing,
  signedOut,
  authenticating,
  signedIn,
  retryRequired,
}

enum MemberLoadStatus { idle, loading, success, error }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this.api, this.storage);
  final AuthApiService api;
  final TokenStorage storage;
  AuthStatus status = AuthStatus.initializing;
  MemberLoadStatus memberStatus = MemberLoadStatus.idle;
  MemberInfo? member;
  String? message;
  bool sessionExpired = false;
  bool storageCleanupInProgress = false;
  bool storageCleanupFailed = false;
  bool savingProfile = false;
  String? profileError;
  int _version = 0;
  bool _disposed = false;
  Future<void>? _tokenWrite;
  final List<MemberRating> _ratings = [];
  int get sessionVersion => _version;
  List<MemberRating> get sessionRatings => List.unmodifiable(_ratings);
  bool isCurrent(int version) => !_disposed && _version == version;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> login(String email, String password) async {
    if (_disposed ||
        storageCleanupInProgress ||
        storageCleanupFailed ||
        status == AuthStatus.authenticating) {
      return;
    }
    final version = ++_version;
    status = AuthStatus.authenticating;
    member = null;
    _ratings.clear();
    message = null;
    sessionExpired = false;
    memberStatus = MemberLoadStatus.idle;
    _notify();
    try {
      final result = await api.login(LoginRequest(email, password));
      if (!isCurrent(version)) return;
      final writing = storage.saveAccessToken(result.accessToken);
      _tokenWrite = writing;
      try {
        await writing;
      } finally {
        if (identical(_tokenWrite, writing)) _tokenWrite = null;
      }
      if (!isCurrent(version)) return;
      status = AuthStatus.signedIn;
    } catch (error) {
      if (!isCurrent(version)) return;
      status = AuthStatus.signedOut;
      message = apiErrorCode(error) == 'AUTH401_1'
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : '로그인 또는 보안 저장에 실패했습니다. 다시 시도해 주세요.';
    }
    if (isCurrent(version)) _notify();
  }

  Future<void> restoreSession() async {
    if (_disposed || storageCleanupInProgress || storageCleanupFailed) return;
    final version = ++_version;
    status = AuthStatus.initializing;
    member = null;
    _ratings.clear();
    message = null;
    memberStatus = MemberLoadStatus.idle;
    _notify();
    try {
      final token = await storage.readAccessToken();
      if (!isCurrent(version)) return;
      if (token == null || token.isEmpty) {
        status = AuthStatus.signedOut;
      } else {
        final me = await api.fetchMe();
        if (!isCurrent(version)) return;
        member = me;
        memberStatus = MemberLoadStatus.success;
        status = AuthStatus.signedIn;
      }
    } catch (error) {
      if (!isCurrent(version)) return;
      if (isSessionError(error)) {
        await expireSession(version);
        return;
      }
      status = AuthStatus.retryRequired;
      message = '로그인 상태를 확인하지 못했습니다. 다시 시도해 주세요.';
    }
    if (isCurrent(version)) _notify();
  }

  Future<void> loadMember({bool force = false}) async {
    if (status != AuthStatus.signedIn ||
        memberStatus == MemberLoadStatus.loading ||
        (member != null && !force)) {
      return;
    }
    final version = _version;
    memberStatus = MemberLoadStatus.loading;
    message = null;
    _notify();
    try {
      final me = await api.fetchMe();
      if (!isCurrent(version)) return;
      member = me;
      memberStatus = MemberLoadStatus.success;
    } catch (error) {
      if (!isCurrent(version)) return;
      if (isSessionError(error)) {
        await expireSession(version);
        return;
      }
      memberStatus = MemberLoadStatus.error;
      message = '내 정보를 불러오지 못했습니다. 다시 시도해 주세요.';
    }
    if (isCurrent(version)) _notify();
  }

  Future<bool> updateNickname(String nickname) async {
    if (savingProfile || status != AuthStatus.signedIn) return false;
    if (nickname.trim().length < 2 || nickname.trim().length > 12) {
      profileError = '닉네임은 2~12자로 입력해 주세요.';
      _notify();
      return false;
    }
    final version = _version;
    savingProfile = true;
    profileError = null;
    _notify();
    try {
      final me = await api.updateNickname(nickname);
      if (!isCurrent(version)) return false;
      member = me;
      memberStatus = MemberLoadStatus.success;
      return true;
    } catch (error) {
      if (!isCurrent(version)) return false;
      if (isSessionError(error)) {
        await expireSession(version);
        return false;
      }
      profileError = apiErrorMessage(error, '저장에 실패했습니다. 다시 시도해 주세요.');
      return false;
    } finally {
      if (isCurrent(version)) {
        savingProfile = false;
        _notify();
      }
    }
  }

  void keepRating(MemberRating rating, int version) {
    if (!isCurrent(version) || status != AuthStatus.signedIn) return;
    _ratings.removeWhere((row) => row.ratingId == rating.ratingId);
    _ratings.insert(0, rating);
    _notify();
  }

  void removeRating(int id, int version) {
    if (!isCurrent(version)) return;
    _ratings.removeWhere((row) => row.ratingId == id);
    _notify();
  }

  Future<void> expireSession(int version) async {
    if (!isCurrent(version)) return;
    await _clear(expired: true);
  }

  Future<void> logout() => _clear(expired: false);
  Future<void> _clear({required bool expired}) async {
    if (_disposed || storageCleanupInProgress) return;
    ++_version;
    storageCleanupInProgress = true;
    storageCleanupFailed = false;
    member = null;
    _ratings.clear();
    savingProfile = false;
    profileError = null;
    memberStatus = MemberLoadStatus.idle;
    status = AuthStatus.signedOut;
    sessionExpired = expired;
    message = null;
    _notify();
    try {
      try {
        await _tokenWrite;
      } catch (_) {
        /* 삭제를 계속 시도한다. */
      }
      await storage.deleteAccessToken();
    } catch (_) {
      storageCleanupFailed = true;
      message = '저장된 인증 정보 삭제에 실패했습니다. 삭제를 다시 시도해 주세요.';
    } finally {
      storageCleanupInProgress = false;
      _notify();
    }
  }

  bool consumeSessionExpired() {
    final expired = sessionExpired;
    sessionExpired = false;
    return expired;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_version;
    super.dispose();
  }
}
