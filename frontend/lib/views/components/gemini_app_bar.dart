import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/gemini_colors.dart';
import '../../models/gemini_model_type.dart';
import '../../state/chat_controller.dart';
import '../settings/settings_dialog.dart';

class GeminiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;

  const GeminiAppBar({
    super.key,
    this.onMenuPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;
    final secColor = isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary;

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.menu, color: textColor),
        tooltip: 'Main menu',
        onPressed: onMenuPressed ?? () => controller.toggleSidebar(),
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Gemini',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          // Model Selector Dropdown
          Flexible(
            child: _buildModelSelector(context, controller, isDark),
          ),
        ],
      ),
      actions: [
        if (screenWidth >= 960)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () {
                controller.switchModel(GeminiModelType.advanced);
              },
              icon: const Icon(Icons.auto_awesome, size: 16, color: GeminiColors.gradientPurple),
              label: Text(
                'Try Gemini Advanced',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: isDark ? GeminiColors.darkHover : GeminiColors.lightHover,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ),

        // User Avatar Circle with popup menu
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: PopupMenuButton<String>(
            tooltip: 'Google Account',
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: isDark ? GeminiColors.darkSurface : GeminiColors.lightSurface,
            onSelected: (val) {
              if (val == 'settings') {
                SettingsDialog.show(context);
              } else if (val == 'theme') {
                controller.setThemeMode(
                  controller.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini User',
                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    Text(
                      'user@gemini.google.com',
                      style: TextStyle(fontSize: 12, color: secColor),
                    ),
                    const Divider(),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      controller.themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      controller.themeMode == ThemeMode.dark
                          ? 'Switch to Light Theme'
                          : 'Switch to Dark Theme',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: const Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 17,
              backgroundColor: GeminiColors.gradientPurple,
              child: const Text(
                'G',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelector(
    BuildContext context,
    ChatController controller,
    bool isDark,
  ) {
    final textColor = isDark ? GeminiColors.darkTextPrimary : GeminiColors.lightTextPrimary;
    final borderColor = isDark ? GeminiColors.darkBorder : GeminiColors.lightBorder;
    final cardBg = isDark ? GeminiColors.darkSurface : GeminiColors.lightSurface;

    return PopupMenuButton<GeminiModelType>(
      tooltip: 'Select Gemini model',
      offset: const Offset(0, 36),
      constraints: const BoxConstraints(minWidth: 300, maxWidth: 360),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      color: cardBg,
      onSelected: (model) => controller.switchModel(model),
      itemBuilder: (context) => GeminiModelType.values.map((model) {
        final isSelected = controller.selectedModel == model;
        return PopupMenuItem<GeminiModelType>(
          value: model,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              model.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: model == GeminiModelType.advanced
                                  ? GeminiColors.gradientPurple.withValues(alpha: 0.2)
                                  : isDark
                                      ? GeminiColors.darkHover
                                      : GeminiColors.lightHover,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              model.badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: model == GeminiModelType.advanced
                                    ? GeminiColors.gradientPurple
                                    : textColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        model.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? GeminiColors.darkTextSecondary : GeminiColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(Icons.check, size: 18, color: GeminiColors.gradientBlue),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? GeminiColors.darkHover : GeminiColors.lightHover,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                controller.selectedModel.displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: textColor),
          ],
        ),
      ),
    );
  }
}
