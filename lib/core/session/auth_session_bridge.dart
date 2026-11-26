import '../../view_models/auth_view_model.dart';
import 'session_guard.dart';

class AuthSessionBridge {
  AuthSessionBridge(this.auth, this.guard) {
    auth.addListener(_sync);
    _sync();
  }
  final AuthViewModel auth;
  final SessionGuard guard;
  void _sync() => guard.sync(
    auth.sessionVersion,
    auth.status == AuthStatus.signedIn ? auth.member?.email : null,
  );
  void dispose() => auth.removeListener(_sync);
}
