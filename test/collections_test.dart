// Collections (to‘plamlar), the unsorted list and chat type filters.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fokus/auth/mock_auth.dart';
import 'package:fokus/data/chat_source.dart';
import 'package:fokus/data/local_store.dart';
import 'package:fokus/data/mock_source.dart';
import 'package:fokus/data/models.dart';
import 'package:fokus/main.dart';
import 'package:fokus/state/app_state.dart';
import 'package:fokus/state/settings.dart';
import 'package:fokus/ui/chats/chat_list.dart';
import 'package:fokus/ui/chats/info_panel.dart';
import 'package:fokus/ui/collections/collections_screen.dart';
import 'package:fokus/ui/rail.dart';

import 'helpers/fonts.dart';

/// Logged-in mock whose session uses a store prepared by the test.
class _StoreAuth extends MockAuth {
  _StoreAuth(this.store) : super(loggedIn: true, delay: Duration.zero);

  final LocalStore store;

  @override
  Future<ChatSession> openSession() async => ChatSession(source: MockChatSource(), store: store, initialChatId: 'dilshod');
}

Future<void> _pump(WidgetTester tester, {LocalStore? store, Size size = const Size(1440, 900), bool dark = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(FokusApp(
    settings: Settings.inMemory(dark ? ThemeMode.dark : ThemeMode.light),
    auth: _StoreAuth(store ?? LocalStore.memory()),
  ));
  await tester.pumpAndSettle();
}

Future<void> _openCollections(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.grid_view_outlined)));
  await tester.pumpAndSettle();
}

/// "To‘plamlar" side of the switch above the chat list.
Future<void> _openCollectionList(WidgetTester tester) async {
  await tester.tap(find.descendant(of: find.byType(ChatList), matching: find.text('To‘plamlar')));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadSegoeUi);

  group('AppState', () {
    AppState make() => AppState(source: MockChatSource(), store: LocalStore.memory());

    test('deleted collections leave their chats unsorted', () {
      final s = make();
      final dilshod = s.source.chatById('dilshod')!;
      expect(s.collectionOf(dilshod), 'mijoz');
      s.pickCollection('mijoz');
      s.deleteCollection('mijoz');
      expect(s.collectionOf(dilshod), '');
      expect(s.collection, 'all', reason: 'the open collection was deleted');
      expect(s.unsorted().map((c) => c.id), containsAll(['dilshod', 'nodira', 'kamola']));
    });

    test('unsorted list by type and moving all at once', () {
      final s = make();
      s.deleteCollection('jamoa');
      s.deleteCollection('hamjam');
      expect(s.unsorted(type: ChatType.group).map((c) => c.id), containsAll(['team', 'flutter']));
      expect(s.unsorted(type: ChatType.channel).map((c) => c.id), ['itpark']);

      final created = s.createCollection('Hamjamiyat', 'public');
      s.assignAll(s.unsorted(type: ChatType.group), created.id);
      expect(s.unsorted(type: ChatType.group), isEmpty);
      expect(s.countIn(created.id), greaterThanOrEqualTo(2));
    });

    test('type filter and hiding muted chats', () {
      final s = make();
      final all = s.visibleChats.length;
      s.toggleType(ChatType.channel);
      expect(s.visibleChats.map((c) => c.id), ['itpark']);
      s.toggleType(ChatType.group);
      expect(s.visibleChats.every((c) => c.kind == ChatKind.channel || c.kind == ChatKind.group), isTrue);
      s.setHideMuted(true);
      expect(s.visibleChats.any((c) => c.muted), isFalse);
      expect(s.typeFilterCount, 3);
      s.clearTypeFilter();
      expect(s.visibleChats.length, all);
    });
  });

  for (final dark in [false, true]) {
    for (final size in const [Size(1440, 900), Size(800, 600), Size(420, 560)]) {
      testWidgets('collections screen lays out at ${size.width.toInt()}x${size.height.toInt()} ${dark ? 'dark' : 'light'}',
          (tester) async {
        final store = LocalStore.memory()
          ..setCollection('dilshod', '')
          ..setCollection('team', '')
          ..setCollection('itpark', '');
        await _pump(tester, store: store, size: size, dark: dark);
        await _openCollections(tester);
        expect(find.text('To‘plamlar'), findsWidgets);
        // Small windows: the unsorted section is below the cards.
        await tester.scrollUntilVisible(
          find.text('Saralanmagan'),
          200,
          scrollable: find.descendant(of: find.byType(CollectionsScreen), matching: find.byType(Scrollable)).first,
        );
        expect(find.text('Saralanmagan'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('create, rename and delete a collection', (tester) async {
    await _pump(tester);
    await _openCollections(tester);

    await tester.tap(find.text('Yangi to‘plam').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Ishchi guruh');
    await tester.tap(find.byIcon(Icons.local_shipping_outlined));
    await tester.tap(find.widgetWithText(FilledButton, 'Yaratish'));
    await tester.pumpAndSettle();
    expect(find.text('Ishchi guruh'), findsWidgets);

    // A duplicate name is refused.
    await tester.tap(find.text('Yangi to‘plam').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'ishchi GURUH');
    await tester.tap(find.widgetWithText(FilledButton, 'Yaratish'));
    await tester.pumpAndSettle();
    expect(find.text('Bu nomdagi to‘plam allaqachon bor.'), findsOneWidget);
    await tester.tap(find.text('Bekor qilish'));
    await tester.pumpAndSettle();

    // Rename via the card menu.
    // The new collection is the last card.
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tahrirlash'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Yetkazuvchilar');
    await tester.tap(find.widgetWithText(FilledButton, 'Saqlash'));
    await tester.pumpAndSettle();
    expect(find.text('Yetkazuvchilar'), findsWidgets);
    expect(find.text('Ishchi guruh'), findsNothing);

    // Delete via the context menu of its row in the collections list
    // ("To‘plamlar" side of the switch above the chat list).
    await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.chat_bubble_outline)));
    await tester.pumpAndSettle();
    await _openCollectionList(tester);
    final row = find.descendant(of: find.byType(ChatList), matching: find.text('Yetkazuvchilar'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('O‘chirish').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('o‘chirilsinmi'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'O‘chirish'));
    await tester.pumpAndSettle();
    expect(find.text('Yetkazuvchilar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the info panel shows the collection as one badge that opens the move menu', (tester) async {
    await _pump(tester);
    final panel = find.byType(InfoPanel);
    expect(find.descendant(of: panel, matching: find.text('Mijozlar')), findsOneWidget);
    expect(find.descendant(of: panel, matching: find.text('Oila')), findsNothing, reason: 'no chip list any more');
    await tester.tap(find.descendant(of: panel, matching: find.text('Mijozlar')));
    await tester.pumpAndSettle();
    expect(find.text('To‘plamga qo‘shish'), findsOneWidget);
    await tester.tap(find.text('Oila').last);
    await tester.pumpAndSettle();
    expect(find.descendant(of: panel, matching: find.text('Oila')), findsOneWidget);
  });

  testWidgets('right click on a chat pins it in Telegram', (tester) async {
    await _pump(tester);
    Finder inList(String t) => find.descendant(of: find.byType(ChatList), matching: find.text(t));
    final before = tester.widget<Text>(inList('Dilshod Karimov')).data;
    expect(before, 'Dilshod Karimov');
    await tester.tap(inList('Dilshod Karimov'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Qadash'));
    await tester.pumpAndSettle();
    // Mock source: the chat moves to the top and the menu now offers to unpin.
    final names = tester.widgetList<Text>(find.descendant(of: find.byType(ChatList), matching: find.byType(Text)));
    expect(names.map((t) => t.data).contains('Dilshod Karimov'), isTrue);
    await tester.tap(inList('Dilshod Karimov'), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Qadalganini yechish'), findsOneWidget);
    await tester.tap(find.text('Qadalganini yechish'));
    await tester.pumpAndSettle();
    expect(find.text('Qadalganini yechish'), findsNothing);
  });

  testWidgets('right click on a chat moves it to a collection', (tester) async {
    await _pump(tester);
    // Dilshod is in "Mijozlar"; move him to "Oila".
    await tester.tap(find.text('Dilshod Karimov').first, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('To‘plamga qo‘shish'), findsOneWidget);
    await tester.tap(find.text('Oila').last);
    await tester.pumpAndSettle();

    // The "Oila" row in the collections list now opens a list with him.
    await _openCollectionList(tester);
    final row = find.descendant(of: find.byType(ChatList), matching: find.text('Oila'));
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(find.text('Dilshod Karimov'), findsWidgets);
    expect(find.text('Oila'), findsWidgets);
  });

  testWidgets('switch: chats, collections list, a collection and back', (tester) async {
    await _pump(tester);
    Finder inList(String t) => find.descendant(of: find.byType(ChatList), matching: find.text(t));

    // "Chatlar" side: every chat, header "Barcha chatlar".
    expect(inList('Barcha chatlar'), findsOneWidget);
    expect(inList('Dilshod Karimov'), findsOneWidget);

    // "To‘plamlar" side: one row per collection and "+ Yangi to‘plam".
    await _openCollectionList(tester);
    expect(inList('Mijozlar'), findsOneWidget);
    expect(inList('Yangi to‘plam'), findsOneWidget);
    expect(inList('Dilshod Karimov'), findsNothing, reason: 'the chat list is replaced by the collections');

    // A collection: only its chats, header with its name leads back.
    await tester.tap(inList('Mijozlar'));
    await tester.pumpAndSettle();
    expect(inList('Dilshod Karimov'), findsOneWidget);
    expect(inList('Yangi to‘plam'), findsNothing);
    await tester.tap(find.byTooltip('To‘plamlar'));
    await tester.pumpAndSettle();
    expect(inList('Yangi to‘plam'), findsOneWidget);

    // Back to "Chatlar".
    await tester.tap(inList('Chatlar'));
    await tester.pumpAndSettle();
    expect(inList('Barcha chatlar'), findsOneWidget);
    expect(inList('Dilshod Karimov'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk move in the unsorted list', (tester) async {
    final store = LocalStore.memory()
      ..setCollection('team', '')
      ..setCollection('flutter', '')
      ..setCollection('itpark', '');
    await _pump(tester, store: store);
    await _openCollections(tester);
    expect(find.text('3 ta chat hech qaysi to‘plamda emas'), findsOneWidget);

    await tester.tap(find.text('Guruhlar 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Barcha guruhlar (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jamoa').last);
    await tester.pumpAndSettle();
    expect(find.text('1 ta chat hech qaysi to‘plamda emas'), findsOneWidget);
    expect(store.collectionOf('team'), 'jamoa');
    expect(store.collectionOf('flutter'), 'jamoa');
  });

  testWidgets('type filter menu keeps open while ticking types', (tester) async {
    await _pump(tester);
    await tester.tap(find.byTooltip('Chat turi bo‘yicha filtr'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kanallar'));
    await tester.pumpAndSettle();
    expect(find.text('Ovozsizlarni yashirish'), findsOneWidget, reason: 'menu stays open');
    await tester.tapAt(const Offset(900, 600)); // close the menu
    await tester.pumpAndSettle();
    expect(find.text('1 ta chat'), findsOneWidget);
    Finder inList(String t) => find.descendant(of: find.byType(ChatList), matching: find.text(t));
    expect(inList('Buxoro IT Park'), findsOneWidget);
    expect(inList('Dilshod Karimov'), findsNothing);
  });
}
