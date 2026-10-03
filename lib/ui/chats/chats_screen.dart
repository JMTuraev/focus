import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../layout.dart';
import 'chat_list.dart';
import 'chat_view.dart';
import 'info_panel.dart';

/// Chat list + chat + info panel, arranged per [LayoutMode]
/// the way Telegram Desktop does it.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key, required this.state, required this.mode});

  final AppState state;
  final LayoutMode mode;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      LayoutMode.wide => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChatList(state: state),
            Expanded(
              child: ChatView(state: state, infoActive: state.infoOpen, onInfo: state.toggleInfo),
            ),
            if (state.infoOpen) InfoPanel(state: state, onClose: state.toggleInfo),
          ],
        ),
      LayoutMode.medium => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChatList(state: state, width: MediaQuery.sizeOf(context).width < 1000 ? 300 : 340),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => Stack(
                  children: [
                    Positioned.fill(
                      child: ChatView(state: state, infoActive: state.infoOverlayOpen, onInfo: state.toggleInfoOverlay),
                    ),
                    if (state.infoOverlayOpen) ...[
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: state.toggleInfoOverlay,
                          child: const ColoredBox(color: Color(0x33000000)),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: Material(
                          elevation: 8,
                          child: InfoPanel(
                            state: state,
                            width: math.min(320, box.maxWidth),
                            onClose: state.toggleInfoOverlay,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      LayoutMode.narrow => !state.narrowChatOpen
          ? ChatList(state: state, width: double.infinity)
          : state.infoOverlayOpen
              ? InfoPanel(state: state, width: double.infinity, onClose: state.toggleInfoOverlay)
              : ChatView(
                  state: state,
                  infoActive: false,
                  onInfo: state.toggleInfoOverlay,
                  onBack: state.closeChat,
                ),
    };
  }
}
