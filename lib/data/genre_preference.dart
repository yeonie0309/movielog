import 'package:shared_preferences/shared_preferences.dart';

abstract interface class GenrePreferenceStore {
  Future<Set<String>> read();

  Future<void> save(Set<String> genres);
}

class GenrePreference implements GenrePreferenceStore {
  GenrePreference({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const String key = 'selected_genre';

  final SharedPreferencesAsync _preferences;

  @override
  Future<Set<String>> read() async {
    final storedValue = await _preferences.getString(key);
    if (storedValue == null || storedValue.isEmpty) {
      return <String>{};
    }

    return storedValue
        .split(',')
        .where((genre) => genre.trim().isNotEmpty)
        .map((genre) => genre.trim())
        .toSet();
  }

  @override
  Future<void> save(Set<String> genres) async {
    if (genres.isEmpty) {
      await _preferences.remove(key);
      return;
    }

    final sortedGenres = genres.toList()..sort();
    await _preferences.setString(key, sortedGenres.join(','));
  }
}
