import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/gemini_colors.dart';

class ResponseActionsBar extends StatefulWidget {
  final String messageId;
  final String text;
  final VoidCallback? onRegenerate;
  final Function(String style)? onModify;

  const ResponseActionsBar({
    super.key,
    required this.messageId,
    required this.text,
    this.onRegenerate,
    this.onModify,
  });

  @override
  State<ResponseActionsBar> createState() => _ResponseActionsBarState();
}

class _ResponseActionsBarState extends State<ResponseActionsBar> {
  bool? _liked; // true = thumbs up, false = thumbs down, null = none

  Future<void> _copyMessage() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showModifyMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: const [
        PopupMenuItem(value: 'shorter', child: Text('Shorter')),
        PopupMenuItem(value: 'longer', child: Text('Longer')),
        PopupMenuItem(value: 'simpler', child: Text('Simpler')),
        PopupMenuItem(value: 'casual', child: Text('More casual')),
        PopupMenuItem(value: 'professional', child: Text('More professional')),
      ],
    ).then((selected) {
      if (selected != null && widget.onModify != null) {
        widget.onModify!(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Thumbs Up
          IconButton(
            icon: Icon(
              _liked == true ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 16,
              color: _liked == true ? GeminiColors.gradientBlue : iconColor,
            ),
            tooltip: 'Good response',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() => _liked = _liked == true ? null : true);
            },
          ),
          // Thumbs Down
          IconButton(
            icon: Icon(
              _liked == false ? Icons.thumb_down : Icons.thumb_down_outlined,
              size: 16,
              color: _liked == false ? GeminiColors.gradientCoral : iconColor,
            ),
            tooltip: 'Bad response',
            visualDensity: VisualDensity.compact,
            onPressed: () {
              setState(() => _liked = _liked == false ? null : false);
            },
          ),
          // Copy
          IconButton(
            icon: Icon(Icons.copy, size: 16, color: iconColor),
            tooltip: 'Copy',
            visualDensity: VisualDensity.compact,
            onPressed: _copyMessage,
          ),
          // Modify Response Popover
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(Icons.tune, size: 16, color: iconColor),
              tooltip: 'Modify response',
              visualDensity: VisualDensity.compact,
              onPressed: () => _showModifyMenu(ctx),
            ),
          ),
          // Regenerate
          if (widget.onRegenerate != null)
            IconButton(
              icon: Icon(Icons.refresh, size: 16, color: iconColor),
              tooltip: 'Regenerate',
              visualDensity: VisualDensity.compact,
              onPressed: widget.onRegenerate,
            ),
        ],
      ),
    );
  }
}
