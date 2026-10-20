import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/gemini_colors.dart';
import 'gemini_sparkle_icon.dart';

class VoiceWaveDialog extends StatefulWidget {
  const VoiceWaveDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const VoiceWaveDialog(),
    );
  }

  @override
  State<VoiceWaveDialog> createState() => _VoiceWaveDialogState();
}

class _VoiceWaveDialogState extends State<VoiceWaveDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GeminiColors.darkBackground : GeminiColors.lightBackground;
    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;
    final secColor = isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GeminiSparkleIcon(size: 38),
            const SizedBox(height: 24),
            Text(
              'Listening...',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gemini Live voice mode is ready',
              style: TextStyle(
                fontSize: 14,
                color: secColor,
              ),
            ),
            const SizedBox(height: 36),
            // Pulsating Waveform Bars
            AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final val = _animController.value * 2 * pi;
                return SizedBox(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWaveBar(16 + sin(val) * 12, GeminiColors.gradientBlue),
                      const SizedBox(width: 8),
                      _buildWaveBar(28 + sin(val + 1) * 18, GeminiColors.gradientPurple),
                      const SizedBox(width: 8),
                      _buildWaveBar(38 + sin(val + 2) * 16, GeminiColors.gradientCoral),
                      const SizedBox(width: 8),
                      _buildWaveBar(24 + sin(val + 3) * 14, GeminiColors.gradientPurple),
                      const SizedBox(width: 8),
                      _buildWaveBar(14 + sin(val + 4) * 10, GeminiColors.gradientBlue),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 36),
            // Close / Cancel Button
            FilledButton.tonalIcon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('End Voice Session'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveBar(double height, Color color) {
    return Container(
      width: 6,
      height: height.clamp(8.0, 60.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
