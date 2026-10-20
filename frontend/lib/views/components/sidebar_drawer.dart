import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/theme/gemini_colors.dart';
import '../../models/chat_session.dart';
import '../../state/chat_controller.dart';
import '../settings/settings_dialog.dart';

class SidebarDrawerWidget extends StatelessWidget {
  final VoidCallback? onClose;

  const SidebarDrawerWidget({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Breakpoints.isMobile(context);

    final bgColor = isDark ? GeminiColors.darkSurface : GeminiColors.lightSurface;
    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;
    final secColor = isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary;

    final sessions = controller.sessions;
    final groupedSessions = _groupSessions(sessions);

    return Container(
      width: 280,
      color: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section: Header & New Chat Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: textColor),
                    onPressed: onClose ?? () => controller.toggleSidebar(),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            // + New Chat Pill Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: FilledButton.tonalIcon(
                onPressed: () {
                  controller.createNewSession();
                  if (isMobile && onClose != null) {
                    onClose!();
                  }
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('New chat', style: TextStyle(fontWeight: FontWeight.w600)),
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? GeminiColors.darkHover : GeminiColors.lightHover,
                  foregroundColor: textColor,
                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Scrollable History Groupings
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                children: groupedSessions.entries.map((entry) {
                  if (entry.value.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14.0, top: 16.0, bottom: 6.0),
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: secColor,
                          ),
                        ),
                      ),
                      ...entry.value.map((session) => _buildSessionTile(
                            context,
                            session,
                            controller,
                            isDark,
                            textColor,
                            secColor,
                            isMobile,
                          )),
                    ],
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 1),

            // Bottom Section: Help, Activity, Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                children: [
                  _buildBottomActionTile(
                    icon: Icons.help_outline,
                    label: 'Help',
                    textColor: textColor,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Google Gemini UI Clone - Fully functional!')),
                      );
                    },
                  ),
                  _buildBottomActionTile(
                    icon: Icons.history,
                    label: 'Activity',
                    textColor: textColor,
                    onTap: () {},
                  ),
                  _buildBottomActionTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    textColor: textColor,
                    onTap: () => SettingsDialog.show(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionTile(
    BuildContext context,
    ChatSession session,
    ChatController controller,
    bool isDark,
    Color textColor,
    Color secColor,
    bool isMobile,
  ) {
    final isActive = controller.activeSessionId == session.id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: isActive
            ? (isDark ? GeminiColors.darkHover : GeminiColors.lightHover)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20.0),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          leading: Icon(
            session.isPinned ? Icons.push_pin : Icons.chat_bubble_outline,
            size: 16,
            color: session.isPinned ? GeminiColors.gradientPurple : secColor,
          ),
          title: Text(
            session.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: textColor,
            ),
          ),
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 16, color: secColor),
            tooltip: 'Options',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'pin') {
                controller.togglePinSession(session.id);
              } else if (val == 'rename') {
                _showRenameDialog(context, session, controller);
              } else if (val == 'delete') {
                controller.deleteSession(session.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pin',
                child: Text(session.isPinned ? 'Unpin' : 'Pin'),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: Text('Rename'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: GeminiColors.gradientCoral)),
              ),
            ],
          ),
          onTap: () {
            controller.selectSession(session.id);
            if (isMobile && onClose != null) {
              onClose!();
            }
          },
        ),
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    ChatSession session,
    ChatController controller,
  ) {
    final textController = TextEditingController(text: session.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename chat'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              controller.renameSession(session.id, textController.text);
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionTile({
    required IconData icon,
    required String label,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(icon, size: 18, color: textColor),
        title: Text(label, style: TextStyle(fontSize: 13, color: textColor)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }

  Map<String, List<ChatSession>> _groupSessions(List<ChatSession> sessions) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final pastWeek = today.subtract(const Duration(days: 7));

    final Map<String, List<ChatSession>> groups = {
      'Pinned': [],
      'Today': [],
      'Yesterday': [],
      'Previous 7 Days': [],
      'Older': [],
    };

    for (final s in sessions) {
      if (s.isPinned) {
        groups['Pinned']!.add(s);
        continue;
      }

      final date = DateTime(s.updatedAt.year, s.updatedAt.month, s.updatedAt.day);
      if (date.isAtSameMomentAs(today)) {
        groups['Today']!.add(s);
      } else if (date.isAtSameMomentAs(yesterday)) {
        groups['Yesterday']!.add(s);
      } else if (date.isAfter(pastWeek)) {
        groups['Previous 7 Days']!.add(s);
      } else {
        groups['Older']!.add(s);
      }
    }

    return groups;
  }
}
