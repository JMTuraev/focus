import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import 'chat_list.dart';
import 'chat_view.dart';
import 'info_panel.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChatList(state: state),
        Expanded(child: ChatView(state: state)),
        if (state.infoOpen) InfoPanel(state: state),
      ],
    );
  }
}
