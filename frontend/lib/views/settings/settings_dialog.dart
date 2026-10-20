import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/gemini_colors.dart';
import '../../state/chat_controller.dart';
import '../components/gemini_sparkle_icon.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? GeminiColors.darkSurface : GeminiColors.lightSurface;
    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;
    final secColor = isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary;
    final borderColor = isDark ? GeminiColors.darkBorder : GeminiColors.lightBorder;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(color: borderColor),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GeminiSparkleIcon(size: 26),
                const SizedBox(width: 12),
                Text(
                  'Gemini Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Theme Mode',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: secColor,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_outlined, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_outlined, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings_system_daydream_outlined, size: 16),
                ),
              ],
              selected: {controller.themeMode},
              onSelectionChanged: (set) {
                controller.setThemeMode(set.first);
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Chat Management',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: secColor,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete all chats?'),
                    content: const Text('This will permanently delete all conversation history.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: GeminiColors.gradientCoral,
                        ),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await controller.clearAllChats();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18, color: GeminiColors.gradientCoral),
              label: const Text('Clear all chat history', style: TextStyle(color: GeminiColors.gradientCoral)),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Google Gemini Clone • Flutter 3.47+ Cross-Platform',
                style: TextStyle(fontSize: 11, color: secColor.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
