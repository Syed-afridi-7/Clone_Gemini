import 'package:flutter/material.dart';
import '../../core/theme/gemini_colors.dart';

class EmptyStateView extends StatelessWidget {
  final Function(String prompt)? onSuggestionSelected;

  const EmptyStateView({
    super.key,
    this.onSuggestionSelected,
  });

  static const List<Map<String, dynamic>> _suggestions = [
    {
      'title': 'Help me write',
      'subtitle': 'Draft a professional follow-up email',
      'icon': Icons.edit_note,
      'color': GeminiColors.gradientBlue,
      'prompt': 'Help me draft a professional follow-up email for a project proposal.',
    },
    {
      'title': 'Analyze & code',
      'subtitle': 'Write a responsive Flutter widget with animations',
      'icon': Icons.code,
      'color': GeminiColors.gradientPurple,
      'prompt': 'Write a responsive Flutter widget with smooth animations and Material 3 design.',
    },
    {
      'title': 'Brainstorm ideas',
      'subtitle': 'Brainstorm innovative startup concepts in AI',
      'icon': Icons.lightbulb_outline,
      'color': GeminiColors.gradientCoral,
      'prompt': 'Brainstorm 5 innovative startup ideas leveraging edge AI and real-time interaction.',
    },
    {
      'title': 'Plan an itinerary',
      'subtitle': 'Create a 3-day travel itinerary for Tokyo',
      'icon': Icons.explore_outlined,
      'color': GeminiColors.gradientBlue,
      'prompt': 'Create an exciting 3-day travel itinerary for exploring Tokyo, Japan.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secColor = isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Title with Gradient ShaderMask
            ShaderMask(
              shaderCallback: (bounds) => GeminiColors.geminiGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: const Text(
                'Hello, Human',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'How can I help you today?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: secColor,
              ),
            ),
            const SizedBox(height: 36),

            // Responsive Suggestion Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 580;
                if (isWide) {
                  return Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: _suggestions.map((s) {
                      return SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _buildSuggestionCard(context, s, isDark),
                      );
                    }).toList(),
                  );
                } else {
                  return Column(
                    children: _suggestions
                        .map((s) => Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _buildSuggestionCard(context, s, isDark),
                            ))
                        .toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    final cardBg = isDark ? GeminiColors.darkSurface : GeminiColors.lightSurface;
    final borderColor = isDark ? GeminiColors.darkBorder : GeminiColors.lightBorder;
    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;
    final secColor = isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary;

    return Material(
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () {
          if (onSuggestionSelected != null) {
            onSuggestionSelected!(data['prompt'] as String);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    data['title'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Icon(
                    data['icon'] as IconData,
                    size: 20,
                    color: data['color'] as Color,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                data['subtitle'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: secColor,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
