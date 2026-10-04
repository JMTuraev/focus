import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';
import 'collection_dialogs.dart';

/// "To‘plamlar": collection cards, and the "Saralanmagan" list for sorting
/// chats that are in no collection yet.
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key, required this.state});

  final AppState state;

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  /// Tab of the unsorted list; null = all types.
  ChatType? _type;

  AppState get s => widget.state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final unsorted = s.unsorted(type: _type);
    final allUnsorted = s.unsorted();
    return LayoutBuilder(
      builder: (context, box) {
        final pad = box.maxWidth < 600 ? 16.0 : 28.0;
        final quickButtons = box.maxWidth >= 900;
        return Container(
          color: c.bg,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 24, pad, 12),
                sliver: SliverToBoxAdapter(child: _header(c)),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: 128,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate([
                    for (final col in s.collections) _CollectionCard(state: s, collection: col),
                    _NewCard(onTap: () => showCollectionEditor(context, s)),
                  ]),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(pad, 28, pad, 10),
                sliver: SliverToBoxAdapter(child: _unsortedHeader(c, allUnsorted, unsorted)),
              ),
              if (unsorted.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        allUnsorted.isEmpty
                            ? 'Barcha chatlar to‘plamlarga ajratilgan.'
                            : 'Bu turdagi saralanmagan chat yo‘q.',
                        style: TextStyle(color: c.text2, fontSize: 14),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(pad, 0, pad, 24),
                  sliver: DecoratedSliver(
                    decoration: BoxDecoration(color: c.panel, borderRadius: BorderRadius.circular(12)),
                    sliver: SliverList.builder(
                      itemCount: unsorted.length,
                      itemBuilder: (_, i) => _UnsortedRow(state: s, chat: unsorted[i], quickButtons: quickButtons),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _header(FokusColors c) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('To‘plamlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            const SizedBox(height: 4),
            Text(
              'Chatlarni o‘zingizga qulay guruhlarga ajrating. Bu faqat Fokus’da saqlanadi, Telegram’ga ta’sir qilmaydi.',
              style: TextStyle(fontSize: 13.5, color: c.text2),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: () => showCollectionEditor(context, s),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Yangi to‘plam'),
          style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _unsortedHeader(FokusColors c, List<Chat> all, List<Chat> shown) {
    int countOf(ChatType? t) => t == null ? all.length : all.where((x) => ChatType.of(x) == t).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text('Saralanmagan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.text)),
            Text('${all.length} ta chat hech qaysi to‘plamda emas', style: TextStyle(fontSize: 13, color: c.text2)),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final t in <ChatType?>[null, ...ChatType.values])
              _TabChip(
                label: '${t?.label ?? 'Hammasi'} ${countOf(t)}',
                active: _type == t,
                onTap: () => setState(() => _type = t),
              ),
            if (shown.isNotEmpty) _BulkAssignButton(state: s, chats: shown, label: _type?.label.toLowerCase()),
          ],
        ),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Tap(
      onTap: onTap,
      radius: 15,
      color: active ? c.accentStrong : c.panel,
      hover: active ? c.accentStrong : c.hover,
      border: Border.all(color: active ? c.accentStrong : c.chipBorder),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? Colors.white : c.textSoft),
        ),
      ),
    );
  }
}

/// "Barchasini to‘plamga…": moves every chat of the current tab at once.
class _BulkAssignButton extends StatelessWidget {
  const _BulkAssignButton({required this.state, required this.chats, this.label});

  final AppState state;
  final List<Chat> chats;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return MenuAnchor(
      style: MenuStyle(backgroundColor: WidgetStatePropertyAll(c.panel)),
      menuChildren: [
        for (final col in state.collections)
          MenuItemButton(
            leadingIcon: Icon(col.icon, size: 18, color: c.icon),
            onPressed: () {
              final n = chats.length;
              state.assignAll(List.of(chats), col.id);
              showToast(
                  context,
                  (w) => SnackBar(
                      width: w < 480 ? w : 480, content: Text('$n ta chat «${col.label}» to‘plamiga o‘tkazildi')));
            },
            child: Text(col.label, style: TextStyle(color: c.text, fontSize: 14)),
          ),
      ],
      builder: (context, controller, _) => TextButton.icon(
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
        icon: Icon(Icons.drive_file_move_outline, size: 18, color: c.accentText),
        label: Text(
          label == null ? 'Barchasini to‘plamga (${chats.length})' : 'Barcha $label (${chats.length}) → to‘plamga',
          style: TextStyle(color: c.accentText, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.state, required this.collection});

  final AppState state;
  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final chats = state.chatsIn(collection.id);
    final unread = chats.where((x) => state.unreadOf(x) > 0).length;
    return Tap(
      onTap: () => state.pickCollection(collection.id),
      radius: 14,
      color: c.panel,
      border: Border.all(color: c.border),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(10)),
                  child: Icon(collection.icon, size: 20, color: c.accentText),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(collection.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.text)),
                      Text(
                        unread > 0 ? '${chats.length} ta chat · $unread o‘qilmagan' : '${chats.length} ta chat',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: c.text2),
                      ),
                    ],
                  ),
                ),
                _CardMenu(state: state, collection: collection),
              ],
            ),
            const Spacer(),
            SizedBox(
              height: 30,
              child: chats.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Bo‘sh', style: TextStyle(fontSize: 12.5, color: c.text2)),
                    )
                  : Stack(
                      children: [
                        for (var i = 0; i < chats.length && i < 5; i++)
                          Positioned(
                            left: i * 22.0,
                            child: Container(
                              decoration:
                                  BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.panel, width: 2)),
                              child: ChatAvatar(chats[i], size: 28, showOnline: false),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMenu extends StatelessWidget {
  const _CardMenu({required this.state, required this.collection});

  final AppState state;
  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return PopupMenuButton<String>(
      tooltip: 'Amallar',
      color: c.panel,
      icon: Icon(Icons.more_vert, size: 20, color: c.icon),
      onSelected: (v) {
        if (v == 'edit') showCollectionEditor(context, state, existing: collection);
        if (v == 'delete') confirmDeleteCollection(context, state, collection);
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'edit', child: Text('Tahrirlash', style: TextStyle(color: c.text))),
        PopupMenuItem(value: 'delete', child: Text('O‘chirish', style: TextStyle(color: c.danger))),
      ],
    );
  }
}

class _NewCard extends StatelessWidget {
  const _NewCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Tap(
      onTap: onTap,
      radius: 14,
      border: Border.all(color: c.chipBorder),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 28, color: c.accentText),
            const SizedBox(height: 6),
            Text('Yangi to‘plam', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.accentText)),
          ],
        ),
      ),
    );
  }
}

class _UnsortedRow extends StatelessWidget {
  const _UnsortedRow({required this.state, required this.chat, required this.quickButtons});

  final AppState state;
  final Chat chat;

  /// Wide windows: one icon button per collection for one-click sorting.
  final bool quickButtons;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
      child: Row(
        children: [
          ChatAvatar(chat, size: 40, showOnline: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: c.text)),
                Text(
                  '${ChatType.of(chat).label} · ${chat.last}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: c.text2),
                ),
              ],
            ),
          ),
          if (quickButtons)
            for (final col in state.collections.take(8))
              IconButton(
                tooltip: col.label,
                visualDensity: VisualDensity.compact,
                onPressed: () => state.moveToCollection(chat.id, col.id),
                icon: Icon(col.icon, size: 19, color: c.icon),
              ),
          Builder(
            builder: (context) => TextButton(
              onPressed: () {
                final box = context.findRenderObject()! as RenderBox;
                showAssignMenu(context, state, chat, box.localToGlobal(Offset(0, box.size.height)));
              },
              style: TextButton.styleFrom(foregroundColor: c.accentText),
              child: Text(quickButtons ? 'Boshqa…' : 'To‘plamga'),
            ),
          ),
        ],
      ),
    );
  }
}
