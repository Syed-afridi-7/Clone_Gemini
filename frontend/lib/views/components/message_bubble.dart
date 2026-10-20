import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/gemini_colors.dart';
import '../../models/chat_message.dart';
import '../../models/gemini_model_type.dart';
import 'code_block_view.dart';
import 'gemini_sparkle_icon.dart';
import 'response_actions.dart';

class MessageBubbleWidget extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRegenerate;
  final Function(String style)? onModify;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    this.onRegenerate,
    this.onModify,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isUser) {
      return _buildUserBubble(context);
    } else {
      return _buildGeminiBubble(context);
    }
  }

  Widget _buildUserBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isDark ? GeminiColors.darkHover : GeminiColors.lightHover;
    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(6.0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Staged Attachments
            if (message.attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: message.attachments.map((path) {
                    final name = path.split(RegExp(r'[\\/]')).last;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1F20) : const Color(0xFFF0F4F9),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: isDark ? GeminiColors.darkBorder : GeminiColors.lightBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image, size: 14, color: GeminiColors.gradientBlue),
                          const SizedBox(width: 4),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            // User Text
            SelectableText(
              message.text,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeminiBubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gemini Sparkle Logo
          const Padding(
            padding: EdgeInsets.only(top: 2.0, right: 14.0),
            child: GeminiSparkleIcon(size: 26),
          ),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thinking shimmer state for Gemini Advanced
                if (message.isStreaming &&
                    message.text.isEmpty &&
                    message.model == GeminiModelType.advanced)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(GeminiColors.gradientPurple),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: GeminiColors.gradientPurple,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  MarkdownBody(
                    data: message.text.isEmpty && message.isStreaming
                        ? '●'
                        : message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: TextStyle(fontSize: 15, height: 1.6, color: textColor),
                      h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      h3: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                      code: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: isDark ? const Color(0xFFF0F4F9) : const Color(0xFF1E1F20),
                        backgroundColor: isDark ? const Color(0xFF282A2C) : const Color(0xFFE1E5EA),
                      ),
                      listBullet: TextStyle(fontSize: 15, color: textColor),
                    ),
                    builders: {
                      'code': _CodeElementBuilder(),
                    },
                  ),

                // Response Actions (displayed when generation finishes)
                if (!message.isStreaming && message.text.isNotEmpty)
                  ResponseActionsBar(
                    messageId: message.id,
                    text: message.text,
                    onRegenerate: onRegenerate,
                    onModify: onModify,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(mdElement, TextStyle? preferredStyle) {
    var language = '';
    if (mdElement.attributes['class'] != null) {
      String lg = mdElement.attributes['class'] as String;
      language = lg.replaceAll('language-', '');
    }

    final code = mdElement.textContent;
    if (code.contains('\n')) {
      return CodeBlockView(code: code, language: language);
    }
    return null; // Let MarkdownBody handle inline code
  }
}
