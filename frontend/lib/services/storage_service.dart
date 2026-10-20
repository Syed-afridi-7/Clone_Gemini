import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class StorageService {
  static const String _sessionsKey = 'gemini_chat_sessions';
  static const String _activeSessionIdKey = 'gemini_active_session_id';
  static const String _themeModeKey = 'gemini_theme_mode';

  final SharedPreferences _prefs;

  const StorageService(this._prefs);

  static Future<StorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  Future<void> saveSessions(List<ChatSession> sessions) async {
    final jsonList = sessions.map((s) => s.toJson()).toList();
    final jsonString = jsonEncode(jsonList);
    await _prefs.setString(_sessionsKey, jsonString);
  }

  List<ChatSession> loadSessions() {
    final jsonString = _prefs.getString(_sessionsKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((item) => ChatSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveActiveSessionId(String? id) async {
    if (id == null) {
      await _prefs.remove(_activeSessionIdKey);
    } else {
      await _prefs.setString(_activeSessionIdKey, id);
    }
  }

  String? loadActiveSessionId() {
    return _prefs.getString(_activeSessionIdKey);
  }

  Future<void> saveThemeMode(String mode) async {
    await _prefs.setString(_themeModeKey, mode);
  }

  String? loadThemeMode() {
    return _prefs.getString(_themeModeKey);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_sessionsKey);
    await _prefs.remove(_activeSessionIdKey);
  }
}
