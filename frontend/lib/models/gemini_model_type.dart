enum GeminiModelType {
  flash,
  pro,
  advanced;

  String get displayName {
    switch (this) {
      case GeminiModelType.flash:
        return 'Gemini 2.5 Flash';
      case GeminiModelType.pro:
        return 'Gemini 1.5 Pro';
      case GeminiModelType.advanced:
        return 'Gemini Advanced';
    }
  }

  String get description {
    switch (this) {
      case GeminiModelType.flash:
        return 'Fast & lightweight for everyday tasks';
      case GeminiModelType.pro:
        return 'Deep reasoning, analysis and coding';
      case GeminiModelType.advanced:
        return 'Ultra capability with thinking process';
    }
  }

  String get badge {
    switch (this) {
      case GeminiModelType.flash:
        return 'Flash';
      case GeminiModelType.pro:
        return 'Pro';
      case GeminiModelType.advanced:
        return 'Advanced';
    }
  }

  int get delayMs {
    switch (this) {
      case GeminiModelType.flash:
        return 12;
      case GeminiModelType.pro:
        return 22;
      case GeminiModelType.advanced:
        return 35;
    }
  }

  static GeminiModelType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pro':
        return GeminiModelType.pro;
      case 'advanced':
        return GeminiModelType.advanced;
      case 'flash':
      default:
        return GeminiModelType.flash;
    }
  }
}
