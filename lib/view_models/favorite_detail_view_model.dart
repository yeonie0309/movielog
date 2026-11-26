import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel(this.api, this.session, this.movieId) {
    session.addListener(_invalidate);
  }
  final FavoriteApiService api;
  final SessionGuard session;
  final int movieId;
  bool? isFavorite;
  bool busy = false;
  String? error;
  int _generation = 0;
  void _invalidate() {
    _generation++;
    isFavorite = null;
    busy = false;
    error = null;
    notifyIfAlive();
  }

  bool _current(int stamp, int request) =>
      !isDisposed && session.isCurrent(stamp) && request == _generation;

  Future<void> load() async {
    if (busy || !session.isSignedIn || isDisposed) return;
    final stamp = session.generation;
    final request = ++_generation;
    busy = true;
    error = null;
    notifyIfAlive();
    try {
      final result = await api.isFavorite(movieId);
      if (_current(stamp, request)) isFavorite = result;
    } catch (_) {
      if (_current(stamp, request)) error = '즐겨찾기 여부를 확인하지 못했습니다. 다시 시도해 주세요.';
    } finally {
      if (_current(stamp, request)) {
        busy = false;
        notifyIfAlive();
      }
    }
  }

  Future<String?> toggle() async {
    if (busy || isFavorite == null || !session.isSignedIn || isDisposed) {
      return null;
    }
    final stamp = session.generation;
    final request = ++_generation;
    final before = isFavorite!;
    busy = true;
    error = null;
    notifyIfAlive();
    try {
      if (before) {
        await api.removeFavorite(movieId);
      } else {
        await api.addFavorite(movieId);
      }
      if (!_current(stamp, request)) return null;
      isFavorite = !before;
      return before ? '즐겨찾기에서 해제했습니다.' : '즐겨찾기에 추가했습니다.';
    } catch (failure) {
      if (!_current(stamp, request)) return null;
      final code = apiErrorCode(failure);
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final actual = await api.isFavorite(movieId);
          if (!_current(stamp, request)) return null;
          isFavorite = actual;
          return '서버의 현재 즐겨찾기 상태로 갱신했습니다.';
        } catch (_) {
          /* No automatic write replay. Preserve the previous icon. */
        }
      }
      if (!_current(stamp, request)) return null;
      error = code == 'MEMBER404_1'
          ? '회원 정보를 찾을 수 없습니다.'
          : '변경 결과를 확인하지 못했습니다. 다시 등록하기 전에 상태를 새로고침해 주세요.';
      return error;
    } finally {
      if (_current(stamp, request)) {
        busy = false;
        notifyIfAlive();
      }
    }
  }

  @override
  void dispose() {
    session.removeListener(_invalidate);
    _generation++;
    super.dispose();
  }
}
