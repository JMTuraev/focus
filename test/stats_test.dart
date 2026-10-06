// "Statistika" module: the local numbers and the screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/stats/stats.dart';
import 'package:fokus/ui/rail.dart';
import 'package:fokus/ui/stats/stats_screen.dart';

import 'helpers/fonts.dart';

void main() {
  setUpAll(loadSegoeUi);

  test('Stats.compute counts chats, collections, types and waiting replies', () {
    final s = AppState(source: MockChatSource(), store: LocalStore.memory());
    final st = Stats.compute(s, now: DateTime(2026, 10, 4, 12));
    expect(st.chats, s.source.chats.length);
    expect(st.unreadChats, s.source.chats.where((c) => s.unreadOf(c) > 0).length);
    expect(st.waiting, s.source.chats.where(s.waitingOf).length);
    expect(st.longestWaiting.length, lessThanOrEqualTo(5));
    expect(st.longestWaiting.every((w) => s.waitingOf(w.chat)), isTrue);

    // Collections: sorted by size, the unsorted entry (if any) last.
    final sizes = st.byCollection.where((c) => c.collection != null).map((c) => c.chats).toList();
    expect(sizes, List.of(sizes)..sort((a, b) => b.compareTo(a)));
    expect(st.byCollection.fold(0, (n, c) => n + c.chats), st.chats);
    expect(st.byType.values.fold(0, (a, b) => a + b), st.chats);
    expect(st.byType[ChatType.channel], 1);

    // Seven days ending today, oldest first; mock chats carry no dates.
    expect(st.activeByDay.length, 7);
    expect(st.activeByDay.last.day, DateTime(2026, 10, 4));
    expect(st.activeByDay.first.day, DateTime(2026, 9, 28));
    expect(st.activeToday, 0);
    expect(st.tasksByColumn.length, 4);
  });

  testWidgets('statistics screen renders its tiles and sections', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(FokusApp(settings: Settings.inMemory(ThemeMode.dark), auth: MockAuth(loggedIn: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.bar_chart)));
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsOneWidget);
    Finder inStats(String text) => find.descendant(of: find.byType(StatsScreen), matching: find.text(text));
    for (final text in ['Statistika', 'O‘qilmagan chatlar', 'To‘plamlar bo‘yicha', 'Chat turlari']) {
      expect(inStats(text), findsOneWidget, reason: text);
    }
    // The last section is below the fold of the lazy list.
    await tester.scrollUntilVisible(inStats('Vazifalar ustunlar bo‘yicha'), 200,
        scrollable: find.descendant(of: find.byType(StatsScreen), matching: find.byType(Scrollable)).first);
    expect(inStats('Vazifalar ustunlar bo‘yicha'), findsOneWidget);
    await tester.drag(find.byType(StatsScreen), const Offset(0, 1200));
    await tester.pumpAndSettle();
    expect(find.text('Mijozlar'), findsWidgets, reason: 'collection bar');

    // A collection bar opens that collection in the chats module.
    await tester.tap(find.descendant(of: find.byType(StatsScreen), matching: find.text('Mijozlar')));
    await tester.pumpAndSettle();
    expect(find.byType(StatsScreen), findsNothing);
    expect(find.text('Dilshod Karimov'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
