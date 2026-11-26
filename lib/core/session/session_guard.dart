import 'package:flutter/foundation.dart';

class SessionGuard extends ChangeNotifier {
  int generation = 0;
  int? _authVersion;
  String? email;
  bool get isSignedIn => email != null;

  void sync(int version, String? account) {
    if (version == _authVersion && email == account) return;
    _authVersion = version;
    email = account;
    generation++;
    notifyListeners();
  }

  bool isCurrent(int stamp) => isSignedIn && generation == stamp;
}
