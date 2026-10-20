import 'dart:async';
import '../models/gemini_model_type.dart';

class MockGeminiEngine {
  final Duration? defaultDelay;

  const MockGeminiEngine({this.defaultDelay});

  Stream<String> streamResponse(
    String prompt, {
    GeminiModelType model = GeminiModelType.flash,
    String? modifyStyle,
    bool hasAttachments = false,
    Duration? delayOverride,
  }) async* {
    final delay = delayOverride ?? defaultDelay ?? Duration(milliseconds: model.delayMs);
    final text = _generateResponseText(
      prompt: prompt,
      model: model,
      modifyStyle: modifyStyle,
      hasAttachments: hasAttachments,
    );

    // Split text into small token chunks (words and punctuation)
    final chunks = _tokenize(text);

    // Simulate thinking state for Gemini Advanced if requested
    if (model == GeminiModelType.advanced && modifyStyle == null) {
      if (delay > Duration.zero) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
    }

    for (final chunk in chunks) {
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
      yield chunk;
    }
  }

  List<String> _tokenize(String text) {
    final tokens = <String>[];
    final regex = RegExp(r'(\s+|[^\s\w]+|\w+)');
    final matches = regex.allMatches(text);
    for (final match in matches) {
      tokens.add(match.group(0)!);
    }
    return tokens.isNotEmpty ? tokens : [text];
  }

  String _generateResponseText({
    required String prompt,
    required GeminiModelType model,
    String? modifyStyle,
    required bool hasAttachments,
  }) {
    if (modifyStyle != null) {
      return _generateModifiedResponse(prompt, modifyStyle);
    }

    final lower = prompt.toLowerCase();

    if (hasAttachments) {
      return '''I have analyzed the image you uploaded! 🖼️

Here is what I observe:
- **Visual Subject:** Clear high-resolution content with distinct focal elements.
- **Composition & Palette:** Well-balanced colors and modern design characteristics.
- **Contextual Understanding:** The visual structure directly complements your prompt: "$prompt".

Let me know if you would like me to extract text, identify specific UI components, or generate corresponding Flutter code!''';
    }

    if (lower.contains('flutter') ||
        lower.contains('code') ||
        lower.contains('dart') ||
        lower.contains('widget') ||
        lower.contains('state') ||
        lower.contains('python') ||
        lower.contains('function')) {
      return '''Here is a complete, production-ready implementation tailored to your request:

### Solution Overview
In modern Flutter, we separate presentation from state using clean reactive patterns (`ChangeNotifier` or `ValueNotifier`). This ensures high frame rates and modular testability.

```dart
import 'package:flutter/material.dart';

class GeminiFeatureWidget extends StatefulWidget {
  final String title;

  const GeminiFeatureWidget({
    super.key,
    required this.title,
  });

  @override
  State<GeminiFeatureWidget> createState() => _GeminiFeatureWidgetState();
}

class _GeminiFeatureWidgetState extends State<GeminiFeatureWidget> {
  bool _isActive = false;

  void _toggleState() {
    setState(() {
      _isActive = !_isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _isActive ? const Color(0xFF1E1F20) : Colors.transparent,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF3C4043)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE3E3E3),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _toggleState,
            icon: Icon(_isActive ? Icons.check_circle : Icons.play_arrow),
            label: Text(_isActive ? 'Active' : 'Activate'),
          ),
        ],
      ),
    );
  }
}
```

### Key Highlights:
1. **Zero-Lag Animations:** Uses `AnimatedContainer` with `Curves.easeInOut` for 60fps transitions.
2. **Material 3 Tokens:** Color values aligned with Gemini Dark obsidian surfaces.
3. **Encapsulated State:** Self-contained logic preventing unnecessary parent rebuilds.''';
    }

    if (lower.contains('write') || lower.contains('email') || lower.contains('draft')) {
      return '''Subject: Project Strategy Update & Collaborative Next Steps

Dear Team,

I hope this message finds you well.

Following our recent design exploration, I am pleased to share that the cross-platform Google Gemini user interface architecture has been successfully synthesized.

### Core Milestones Achieved:
- **Responsive Layout Engine:** Fluid adaptation between mobile ergonomics and desktop web workflows.
- **Design Token Fidelity:** Pixel-accurate Material 3 color variables matching Google Gemini's obsidian palette (`#131314` and `#1E1F20`).
- **Simulated Streaming Intelligence:** Real-time token streaming with contextual reasoning.

Please review the attached specifications and let me know your feedback by tomorrow afternoon.

Best regards,  
Lead Architect''';
    }

    return '''Here is a structured overview for: **$prompt**

### 1. Key Insights
- **First-Principles Thinking:** Breaking down the problem into fundamental components allows for cleaner, more scalable solutions.
- **Architectural Modularity:** Decoupling user interaction from internal state management guarantees long-term maintainability.
- **User-Centric Design:** Prioritizing fluid micro-interactions, responsive ergonomics, and clear typography elevates the entire product experience.

### 2. Recommended Next Steps
1. Prototype the core interaction loop to validate performance.
2. Verify cross-platform rendering across mobile, desktop, and browser viewports.
3. Establish robust unit and widget test suites for regression safety.

Let me know if you would like to explore any of these points in greater depth!''';
  }

  String _generateModifiedResponse(String originalPrompt, String style) {
    switch (style.toLowerCase()) {
      case 'shorter':
        return '''**Summary:**
- $originalPrompt addresses core functionality efficiently.
- Implemented with lightweight, verified components ensuring optimal speed and stability.''';
      case 'longer':
        return '''### Comprehensive In-Depth Breakdown

Regarding your request: "$originalPrompt":

#### Architectural Foundations
When addressing this requirement at scale, several interrelated architectural vectors must be considered:
1. **Computational Efficiency:** Ensuring minimal CPU overhead during rendering and data parsing.
2. **State Hygiene:** Preserving predictable single-directional data flow.
3. **Resilience & Graceful Degradation:** Providing deterministic fallback states across varying network and device constraints.

#### Practical Recommendations
- Adopt clear interface boundaries.
- Cache high-frequency data structures locally to ensure offline-first capability.
- Maintain comprehensive test coverage across both unit and end-to-end integration tiers.''';
      case 'simpler':
        return '''Here is the simple explanation:

Think of it like building with LEGO blocks. Each piece has one specific job, and when we snap them together carefully, the whole thing works smoothly and won't fall apart!''';
      case 'casual':
        return '''Hey there! 🙌

So regarding "$originalPrompt" — it's looking super clean! Everything is hooked up nicely, the animations are buttery smooth, and it just works like magic ✨.

Hit me up if you want to tweak anything else! 🚀''';
      case 'professional':
        return '''Executive Memorandum:

Re: Strategic Evaluation of $originalPrompt

The proposed technical implementation adheres to industry-standard software engineering paradigms. Reliability, fault-tolerance, and design consistency have been systematically verified to align with enterprise expectations.''';
      default:
        return _generateResponseText(
          prompt: originalPrompt,
          model: GeminiModelType.flash,
          hasAttachments: false,
        );
    }
  }
}
