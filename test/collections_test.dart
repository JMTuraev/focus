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

      // Waiting / unread chips count inside the type filter.
      s.toggleType(ChatType.channel);
      expect(s.waitingCount, 0);
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
    expect(find.text('Ishchi guruh'), findsWidgets, reason: 'card and rail');
    expect(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.local_shipping_outlined)), findsOneWidget);

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

    // Delete via the rail context menu.
    await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.local_shipping_outlined)), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('O‘chirish').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('o‘chirilsinmi'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'O‘chirish'));
    await tester.pumpAndSettle();
    expect(find.text('Yetkazuvchilar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('right click on a chat moves it to a collection', (tester) async {
    await _pump(tester);
    // Dilshod is in "Mijozlar"; move him to "Oila".
    await tester.tap(find.text('Dilshod Karimov').first, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('To‘plamga qo‘shish'), findsOneWidget);
    await tester.tap(find.text('Oila').last);
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(Rail), matching: find.byIcon(Icons.home_outlined)));
    await tester.pumpAndSettle();
    expect(find.text('Dilshod Karimov'), findsWidgets);
    expect(find.text('Oila'), findsWidgets);
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
