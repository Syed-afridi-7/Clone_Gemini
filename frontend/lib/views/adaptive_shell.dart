import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/breakpoints.dart';
import '../state/chat_controller.dart';
import 'components/empty_state_view.dart';
import 'components/gemini_app_bar.dart';
import 'components/message_bubble.dart';
import 'components/prompt_input_bar.dart';
import 'components/sidebar_drawer.dart';

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = Breakpoints.isMobile(context);

    // Auto-scroll when new messages or tokens stream in
    if (controller.isStreaming) {
      _scrollToBottom();
    }

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: SidebarDrawerWidget(
          onClose: () => _scaffoldKey.currentState?.closeDrawer(),
        ),
        appBar: GeminiAppBar(
          onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        body: _buildChatArea(context, controller, isDark),
      );
    }

    // Desktop & Tablet View (Side-by-side)
    return Scaffold(
      body: Row(
        children: [
          // Collapsible Left Navigation Drawer
          if (controller.isSidebarOpen)
            const SidebarDrawerWidget(),

          // Main Chat Experience
          Expanded(
            child: Scaffold(
              appBar: const GeminiAppBar(),
              body: _buildChatArea(context, controller, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea(
    BuildContext context,
    ChatController controller,
    bool isDark,
  ) {
    final messages = controller.messages;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Column(
          children: [
            // Chat Feed or Empty State
            Expanded(
              child: messages.isEmpty
                  ? EmptyStateView(
                      onSuggestionSelected: (prompt) {
                        controller.sendMessage(prompt);
                      },
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 12.0, bottom: 20.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        return MessageBubbleWidget(
                          key: ValueKey(msg.id),
                          message: msg,
                          onRegenerate: () {
                            // Find user message before this model message
                            String prompt = 'Previous prompt';
                            for (int i = index - 1; i >= 0; i--) {
                              if (messages[i].isUser) {
                                prompt = messages[i].text;
                                break;
                              }
                            }
                            controller.sendMessage(prompt);
                          },
                          onModify: (style) {
                            controller.modifyResponse(msg.id, style);
                          },
                        );
                      },
                    ),
            ),

            // Bottom Floating Prompt Input Bar
            const PromptInputBarWidget(),
          ],
        ),
      ),
    );
  }
}
