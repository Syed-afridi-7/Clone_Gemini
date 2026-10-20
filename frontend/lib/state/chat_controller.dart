import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/gemini_model_type.dart';
import '../services/mock_gemini_engine.dart';
import '../services/storage_service.dart';

class ChatController extends ChangeNotifier {
  final MockGeminiEngine engine;
  final StorageService storage;

  List<ChatSession> _sessions = [];
  String? _activeSessionId;
  GeminiModelType _selectedModel = GeminiModelType.flash;
  bool _isStreaming = false;
  final List<String> _stagedAttachments = [];
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isSidebarOpen = true;

  StreamSubscription<String>? _activeStreamSub;

  ChatController({
    required this.engine,
    required this.storage,
  });

  // Getters
  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  String? get activeSessionId => _activeSessionId;
  GeminiModelType get selectedModel => _selectedModel;
  bool get isStreaming => _isStreaming;
  List<String> get stagedAttachments => List.unmodifiable(_stagedAttachments);
  ThemeMode get themeMode => _themeMode;
  bool get isSidebarOpen => _isSidebarOpen;

  ChatSession? get activeSession {
    if (_activeSessionId == null) return null;
    try {
      return _sessions.firstWhere((s) => s.id == _activeSessionId);
    } catch (_) {
      return null;
    }
  }

  List<ChatMessage> get messages => activeSession?.messages ?? const [];

  // Initialization
  Future<void> initialize() async {
    _sessions = storage.loadSessions();
    _activeSessionId = storage.loadActiveSessionId();

    final storedTheme = storage.loadThemeMode();
    if (storedTheme != null) {
      if (storedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (storedTheme == 'system') {
        _themeMode = ThemeMode.system;
      } else {
        _themeMode = ThemeMode.dark;
      }
    }

    // If no sessions exist, create an initial one
    if (_sessions.isEmpty) {
      await createNewSession();
    } else if (_activeSessionId == null ||
        !_sessions.any((s) => s.id == _activeSessionId)) {
      _activeSessionId = _sessions.first.id;
    }

    notifyListeners();
  }

  Future<ChatSession> createNewSession({String? initialTitle}) async {
    final now = DateTime.now();
    final newSession = ChatSession(
      id: 'session_${now.millisecondsSinceEpoch}',
      title: initialTitle ?? 'New Chat',
      messages: const [],
      createdAt: now,
      updatedAt: now,
    );

    _sessions.insert(0, newSession);
    _activeSessionId = newSession.id;
    await _persist();
    notifyListeners();
    return newSession;
  }

  Future<void> selectSession(String id) async {
    if (_activeSessionId == id) return;
    if (_isStreaming) {
      stopStreaming();
    }
    _activeSessionId = id;
    await storage.saveActiveSessionId(id);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    if (_activeSessionId == id && _isStreaming) {
      stopStreaming();
    }
    _sessions.removeWhere((s) => s.id == id);
    if (_sessions.isEmpty) {
      await createNewSession();
    } else if (_activeSessionId == id) {
      _activeSessionId = _sessions.first.id;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> renameSession(String id, String newTitle) async {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(
        title: newTitle.trim().isEmpty ? 'Untitled Chat' : newTitle.trim(),
        updatedAt: DateTime.now(),
      );
      await _persist();
      notifyListeners();
    }
  }

  Future<void> togglePinSession(String id) async {
    final index = _sessions.indexWhere((s) => s.id == id);
    if (index != -1) {
      _sessions[index] = _sessions[index].copyWith(
        isPinned: !_sessions[index].isPinned,
        updatedAt: DateTime.now(),
      );
      await _persist();
      notifyListeners();
    }
  }

  void switchModel(GeminiModelType model) {
    if (_selectedModel != model) {
      _selectedModel = model;
      notifyListeners();
    }
  }

  void addAttachment(String path) {
    if (!_stagedAttachments.contains(path)) {
      _stagedAttachments.add(path);
      notifyListeners();
    }
  }

  void removeAttachment(String path) {
    _stagedAttachments.remove(path);
    notifyListeners();
  }

  void clearAttachments() {
    _stagedAttachments.clear();
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  void setSidebarOpen(bool open) {
    if (_isSidebarOpen != open) {
      _isSidebarOpen = open;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      final modeStr = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.system
              ? 'system'
              : 'dark';
      await storage.saveThemeMode(modeStr);
      notifyListeners();
    }
  }

  Future<void> clearAllChats() async {
    if (_isStreaming) {
      stopStreaming();
    }
    _sessions.clear();
    await storage.clearAll();
    await createNewSession();
  }

  // Messaging and Streaming
  Future<void> sendMessage(String text, {Duration? delayOverride}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && _stagedAttachments.isEmpty) return;

    // Ensure we have an active session
    if (_activeSessionId == null || activeSession == null) {
      await createNewSession();
    }

    final currentSession = activeSession!;
    final now = DateTime.now();

    // Create user message
    final userMessage = ChatMessage(
      id: 'msg_user_${now.millisecondsSinceEpoch}',
      role: 'user',
      text: trimmed,
      attachments: List.from(_stagedAttachments),
      timestamp: now,
      model: _selectedModel,
    );

    // Update session title if first prompt
    String newTitle = currentSession.title;
    if (currentSession.messages.isEmpty && newTitle == 'New Chat') {
      newTitle = trimmed.isNotEmpty
          ? (trimmed.length > 28 ? '${trimmed.substring(0, 28)}...' : trimmed)
          : 'Image Query';
    }

    final updatedMessages = List<ChatMessage>.from(currentSession.messages)
      ..add(userMessage);

    final aiMessageId = 'msg_model_${now.millisecondsSinceEpoch + 1}';
    final placeholderAiMessage = ChatMessage(
      id: aiMessageId,
      role: 'model',
      text: '',
      timestamp: now,
      isStreaming: true,
      model: _selectedModel,
    );

    updatedMessages.add(placeholderAiMessage);

    final sessionIndex = _sessions.indexWhere((s) => s.id == currentSession.id);
    _sessions[sessionIndex] = currentSession.copyWith(
      title: newTitle,
      messages: updatedMessages,
      updatedAt: now,
    );

    final hasAttachments = _stagedAttachments.isNotEmpty;
    _stagedAttachments.clear();
    _isStreaming = true;
    notifyListeners();

    // Start streaming response
    final responseBuffer = StringBuffer();
    _activeStreamSub = engine
        .streamResponse(
      trimmed,
      model: _selectedModel,
      hasAttachments: hasAttachments,
      delayOverride: delayOverride,
    )
        .listen(
      (token) {
        responseBuffer.write(token);
        _updateModelMessage(currentSession.id, aiMessageId, responseBuffer.toString(), true);
      },
      onDone: () async {
        _isStreaming = false;
        _activeStreamSub = null;
        _updateModelMessage(currentSession.id, aiMessageId, responseBuffer.toString(), false);
        await _persist();
        notifyListeners();
      },
      onError: (e) {
        _isStreaming = false;
        _activeStreamSub = null;
        responseBuffer.write('\n\n*(Error generating response)*');
        _updateModelMessage(currentSession.id, aiMessageId, responseBuffer.toString(), false);
        _persist();
        notifyListeners();
      },
    );
  }

  void stopStreaming() {
    if (!_isStreaming) return;
    _activeStreamSub?.cancel();
    _activeStreamSub = null;
    _isStreaming = false;

    if (activeSession != null) {
      final msgs = List<ChatMessage>.from(activeSession!.messages);
      if (msgs.isNotEmpty && msgs.last.isModel && msgs.last.isStreaming) {
        msgs[msgs.length - 1] = msgs.last.copyWith(isStreaming: false);
        final index = _sessions.indexWhere((s) => s.id == activeSession!.id);
        if (index != -1) {
          _sessions[index] = _sessions[index].copyWith(messages: msgs);
          _persist();
        }
      }
    }
    notifyListeners();
  }

  Future<void> modifyResponse(
    String messageId,
    String style, {
    Duration? delayOverride,
  }) async {
    if (_isStreaming || activeSession == null) return;

    final session = activeSession!;
    final index = session.messages.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    // Find the corresponding user prompt
    String userPrompt = 'Previous query';
    for (int i = index - 1; i >= 0; i--) {
      if (session.messages[i].isUser) {
        userPrompt = session.messages[i].text;
        break;
      }
    }

    _isStreaming = true;
    final buffer = StringBuffer();
    _updateModelMessage(session.id, messageId, '', true);
    notifyListeners();

    _activeStreamSub = engine
        .streamResponse(
      userPrompt,
      model: _selectedModel,
      modifyStyle: style,
      delayOverride: delayOverride,
    )
        .listen(
      (token) {
        buffer.write(token);
        _updateModelMessage(session.id, messageId, buffer.toString(), true);
      },
      onDone: () async {
        _isStreaming = false;
        _activeStreamSub = null;
        _updateModelMessage(session.id, messageId, buffer.toString(), false);
        await _persist();
        notifyListeners();
      },
    );
  }

  void _updateModelMessage(
    String sessionId,
    String messageId,
    String text,
    bool isStreaming,
  ) {
    final sIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sIndex == -1) return;

    final msgs = List<ChatMessage>.from(_sessions[sIndex].messages);
    final mIndex = msgs.indexWhere((m) => m.id == messageId);
    if (mIndex == -1) return;

    msgs[mIndex] = msgs[mIndex].copyWith(
      text: text,
      isStreaming: isStreaming,
    );

    _sessions[sIndex] = _sessions[sIndex].copyWith(
      messages: msgs,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> _persist() async {
    await storage.saveSessions(_sessions);
    if (_activeSessionId != null) {
      await storage.saveActiveSessionId(_activeSessionId);
    }
  }

  @override
  void dispose() {
    _activeStreamSub?.cancel();
    super.dispose();
  }
}
