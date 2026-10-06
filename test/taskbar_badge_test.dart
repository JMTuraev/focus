// The taskbar badge counts unread chats at most once per delay, however
// many updates arrive (counting builds the whole chat list).

import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/reminders/taskbar_badge.dart';
import 'package:fokus/state/app_state.dart';

void main() {
  test('a burst of updates is counted once', () async {
    final s = AppState(source: MockChatSource(), store: LocalStore.memory());
    final badge = TaskbarBadge(s, delay: const Duration(milliseconds: 20))..start();
    final first = badge.counted;
    for (var i = 0; i < 1000; i++) {
      s.setQuery('$i');
    }
    expect(badge.counted, first, reason: 'nothing counted synchronously');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(badge.counted, first + 1, reason: 'one count for the whole burst');
    s.setQuery('x');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(badge.counted, first + 2, reason: 'later changes are counted again');
    badge.dispose();
  });
}
