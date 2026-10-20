import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/gemini_colors.dart';
import '../../state/chat_controller.dart';
import 'voice_wave_dialog.dart';

class PromptInputBarWidget extends StatefulWidget {
  final TextEditingController? externalController;

  const PromptInputBarWidget({
    super.key,
    this.externalController,
  });

  @override
  State<PromptInputBarWidget> createState() => _PromptInputBarWidgetState();
}

class _PromptInputBarWidgetState extends State<PromptInputBarWidget> {
  late TextEditingController _textController;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController = widget.externalController ?? TextEditingController();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasContent = _textController.text.trim().isNotEmpty;
    if (_hasText != hasContent) {
      setState(() => _hasText = hasContent);
    }
  }

  @override
  void dispose() {
    if (widget.externalController == null) {
      _textController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ChatController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path ?? result.files.first.name;
        controller.addAttachment(path);
      }
    } catch (_) {
      // Fallback for environments without native picker permissions
    }
  }

  void _handleSend(ChatController controller) {
    final text = _textController.text.trim();
    if (text.isEmpty && controller.stagedAttachments.isEmpty) return;

    controller.sendMessage(text);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerColor = isDark ? GeminiColors.darkSurface : GeminiColors.lightSurface;
    final borderColor = isDark ? GeminiColors.darkBorder : GeminiColors.lightBorder;
    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;
    final hintColor = isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary;

    final canSend = _hasText || controller.stagedAttachments.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Staged Attachments Preview
          if (controller.stagedAttachments.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: controller.stagedAttachments.map((path) {
                  final filename = path.split(RegExp(r'[\\/]')).last;
                  return Chip(
                    backgroundColor: isDark ? GeminiColors.darkHover : GeminiColors.lightHover,
                    avatar: const Icon(Icons.image, size: 16, color: GeminiColors.gradientBlue),
                    label: Text(
                      filename,
                      style: TextStyle(fontSize: 12, color: textColor),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    deleteIconColor: hintColor,
                    onDeleted: () => controller.removeAttachment(path),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: borderColor),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Main Floating Pill Box
          Container(
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(28.0),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Plus Attachment Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: IconButton(
                    icon: Icon(Icons.add_photo_alternate_outlined, color: hintColor, size: 22),
                    tooltip: 'Add image or file',
                    onPressed: () => _pickImage(controller),
                  ),
                ),

                // Text Input Field
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: 5,
                    minLines: 1,
                    style: TextStyle(fontSize: 15, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Ask Gemini...',
                      hintStyle: TextStyle(color: hintColor, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    ),
                    onSubmitted: (_) {
                      if (!controller.isStreaming) {
                        _handleSend(controller);
                      }
                    },
                  ),
                ),

                // Mic Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: IconButton(
                    icon: Icon(Icons.mic, color: hintColor, size: 22),
                    tooltip: 'Use microphone (Gemini Live)',
                    onPressed: () => VoiceWaveDialog.show(context),
                  ),
                ),

                // Send or Stop Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: controller.isStreaming
                      ? IconButton(
                          icon: const Icon(Icons.stop_circle, color: GeminiColors.gradientCoral, size: 26),
                          tooltip: 'Stop generation',
                          onPressed: controller.stopStreaming,
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.arrow_upward_rounded,
                            size: 24,
                            color: canSend
                                ? (isDark ? Colors.white : Colors.black)
                                : hintColor.withValues(alpha: 0.4),
                          ),
                          tooltip: 'Send message',
                          style: canSend
                              ? IconButton.styleFrom(
                                  backgroundColor: isDark
                                      ? const Color(0xFF282A2C)
                                      : const Color(0xFFE1E5EA),
                                  shape: const CircleBorder(),
                                )
                              : null,
                          onPressed: canSend ? () => _handleSend(controller) : null,
                        ),
                ),
              ],
            ),
          ),

          // Disclaimer Footer
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              'Gemini may display inaccurate info, including about people, so double-check its responses.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: hintColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
