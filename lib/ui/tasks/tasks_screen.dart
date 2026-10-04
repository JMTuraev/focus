import 'package:flutter/material.dart';

import '../../data/format.dart';
import '../../db/database.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../common.dart';
import 'task_editor.dart';

/// Kanban board: Rejada · Jarayonda · Kutilmoqda · Bajarildi.
/// Wide windows show the four columns (drag cards between them); narrow
/// windows show one column at a time with tabs.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.state});

  final AppState state;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String _query = '';
  TaskStatus _tab = TaskStatus.planned;

  AppState get s => widget.state;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return ListenableBuilder(
      listenable: s.tasks,
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 900;
          final pad = box.maxWidth < 600 ? 12.0 : 24.0;
          return Container(
            color: c.bg,
            padding: EdgeInsets.fromLTRB(pad, 20, pad, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(c, box.maxWidth),
                if (s.taskChatFilter != null) _chatFilterChip(c),
                const SizedBox(height: 14),
                Expanded(child: wide ? _board() : _tabs(c)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _header(FokusColors c, double width) {
    final tasks = s.tasks;
    final stats = [
      '${tasks.openCount} ta ochiq',
      if (tasks.overdueCount > 0) '${tasks.overdueCount} tasi muddati o‘tgan',
    ].join(' · ');
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Vazifalar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.text)),
            Text(stats, style: TextStyle(fontSize: 13, color: tasks.overdueCount > 0 ? c.danger : c.text2)),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width < 600 ? 170 : 240,
              height: 36,
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(fontSize: 14, color: c.text),
                decoration: InputDecoration(
                  hintText: 'Vazifa qidirish',
                  hintStyle: TextStyle(color: c.text2),
                  prefixIcon: Icon(Icons.search, size: 18, color: c.text2),
                  filled: true,
                  fillColor: c.panel,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton.icon(
              onPressed: () => showTaskEditor(context, s, status: _tab),
              icon: const Icon(Icons.add, size: 18),
              label: Text(width < 600 ? 'Yangi' : 'Yangi vazifa'),
              style: FilledButton.styleFrom(backgroundColor: c.accentStrong, foregroundColor: Colors.white),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chatFilterChip(FokusColors c) {
    final id = s.taskChatFilter!;
    final chat = s.source.chatById(id);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: chat == null ? null : ChatAvatar(chat, size: 22, showOnline: false),
          label: Text('Faqat: ${chat?.name ?? 'chat'}', style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
          backgroundColor: c.accentSoft,
          side: BorderSide.none,
          deleteIcon: Icon(Icons.close, size: 16, color: c.icon),
          deleteButtonTooltipMessage: 'Filtrni olib tashlash',
          onDeleted: s.clearTaskChatFilter,
        ),
      ),
    );
  }

  List<Task> _column(TaskStatus st) => s.tasks.column(st, chatId: s.taskChatFilter, query: _query);

  Widget _board() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final st in TaskStatus.values) ...[
          if (st != TaskStatus.planned) const SizedBox(width: 12),
          Expanded(child: _Column(state: s, status: st, tasks: _column(st), draggable: true)),
        ],
      ],
    );
  }

  Widget _tabs(FokusColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final st in TaskStatus.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text('${st.label} ${_column(st).length}'),
                    selected: _tab == st,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _tab = st),
                    labelStyle: TextStyle(color: _tab == st ? Colors.white : c.textSoft, fontWeight: FontWeight.w600),
                    selectedColor: c.accentStrong,
                    backgroundColor: c.panel,
                    side: BorderSide(color: _tab == st ? c.accentStrong : c.chipBorder),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _Column(state: s, status: _tab, tasks: _column(_tab), draggable: false, showHeader: false)),
      ],
    );
  }
}

Color _statusColor(FokusColors c, TaskStatus s) => switch (s) {
      TaskStatus.planned => c.accent,
      TaskStatus.inProgress => c.waiting,
      TaskStatus.waiting => c.muted,
      TaskStatus.done => c.online,
    };

class _Column extends StatelessWidget {
  const _Column({
    required this.state,
    required this.status,
    required this.tasks,
    required this.draggable,
    this.showHeader = true,
  });

  final AppState state;
  final TaskStatus status;
  final List<Task> tasks;
  final bool draggable;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => state.tasks.move(d.data, status),
      builder: (context, candidates, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: c.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: candidates.isNotEmpty ? c.accent : c.border, width: candidates.isNotEmpty ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(c, status), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(status.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                    const SizedBox(width: 6),
                    Text('${tasks.length}', style: TextStyle(fontSize: 13, color: c.text2)),
                  ],
                ),
              ),
            Expanded(
              child: tasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          status == TaskStatus.done ? 'Hali bajarilgan vazifa yo‘q' : 'Bo‘sh',
                          style: TextStyle(color: c.text2, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                      itemCount: tasks.length,
                      itemBuilder: (_, i) => _DraggableCard(state: state, task: tasks[i], draggable: draggable),
                    ),
            ),
            if (status != TaskStatus.done) _QuickAdd(state: state, status: status),
          ],
        ),
      ),
    );
  }
}

/// A card that can be dragged to another column, or dropped onto to insert
/// a dragged card before it.
class _DraggableCard extends StatelessWidget {
  const _DraggableCard({required this.state, required this.task, required this.draggable});

  final AppState state;
  final Task task;
  final bool draggable;

  @override
  Widget build(BuildContext context) {
    final card = _TaskCard(state: state, task: task);
    if (!draggable) return card;
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != task.id,
      onAcceptWithDetails: (d) => state.tasks.move(d.data, task.status, beforeId: task.id),
      builder: (context, candidates, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (candidates.isNotEmpty)
            Container(height: 3, margin: const EdgeInsets.symmetric(vertical: 2), color: context.fc.accent),
          LayoutBuilder(
            builder: (context, box) => Draggable<int>(
              data: task.id,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(width: box.maxWidth, child: Opacity(opacity: 0.9, child: card)),
              ),
              childWhenDragging: Opacity(opacity: 0.35, child: card),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.state, required this.task});

  final AppState state;
  final Task task;

  Future<void> _menu(BuildContext context, Offset pos) async {
    final c = context.fc;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final choice = await showMenu<String>(
      context: context,
      color: c.panel,
      position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        for (final st in TaskStatus.values)
          if (st != task.status)
            PopupMenuItem(value: st.name, height: 38, child: Text('→ ${st.label}', style: TextStyle(color: c.text))),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'star',
          height: 38,
          child: Text(task.important ? 'Muhim emas' : 'Muhim', style: TextStyle(color: c.text)),
        ),
        if (task.chatId != null)
          PopupMenuItem(value: 'chat', height: 38, child: Text('Chatni ochish', style: TextStyle(color: c.text))),
        PopupMenuItem(value: 'delete', height: 38, child: Text('O‘chirish', style: TextStyle(color: c.danger))),
      ],
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case 'star':
        await state.tasks.edit(task.id, important: !task.important);
      case 'chat':
        state.openTaskChat(task);
      case 'delete':
        await deleteTaskWithUndo(context, state, task);
      default:
        await state.tasks.move(task.id, TaskStatus.values.byName(choice));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    final done = task.status == TaskStatus.done;
    final overdue = state.tasks.isOverdue(task);
    final today = state.tasks.isDueToday(task);
    final chat = task.chatId == null ? null : state.source.chatById(task.chatId!);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onSecondaryTapDown: (d) => _menu(context, d.globalPosition),
        child: Tap(
          onTap: () => showTaskEditor(context, state, task: task),
          radius: 10,
          color: c.bg,
          border: Border.all(color: task.important && !done ? c.waiting : c.border),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: done ? 'Qayta ochish' : 'Bajarildi',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => state.tasks.move(task.id, done ? TaskStatus.planned : TaskStatus.done),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 20, color: done ? c.online : c.text2),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          task.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: done ? c.text2 : c.text,
                            decoration: done ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (task.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(task.note,
                              maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: c.text2)),
                        ),
                      if (task.due != null || task.chatId != null || task.important)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (task.important && !done) Icon(Icons.star_rounded, size: 16, color: c.waiting),
                              if (task.due != null)
                                _Meta(
                                  icon: Icons.event_outlined,
                                  text: Fmt.dueLabel(task.due!),
                                  color: overdue ? c.danger : (today ? c.waitingStrong : c.text2),
                                ),
                              if (task.chatId != null)
                                InkWell(
                                  onTap: chat == null ? null : () => state.openTaskChat(task),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (chat != null)
                                        ChatAvatar(chat, size: 18, showOnline: false)
                                      else
                                        Icon(Icons.chat_bubble_outline, size: 14, color: c.text2),
                                      const SizedBox(width: 5),
                                      ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 150),
                                        child: Text(chat?.name ?? task.chatTitle ?? 'Chat',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: c.text2)),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

/// "+ Vazifa qo‘shish" at the bottom of a column: type a title, press Enter.
class _QuickAdd extends StatefulWidget {
  const _QuickAdd({required this.state, required this.status});

  final AppState state;
  final TaskStatus status;

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  bool _editing = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = _ctrl.text.trim();
    if (t.isNotEmpty) await widget.state.tasks.add(title: t, status: widget.status);
    _ctrl.clear();
    if (t.isEmpty && mounted) setState(() => _editing = false);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.fc;
    if (!_editing) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: TextButton.icon(
          onPressed: () {
            setState(() => _editing = true);
            WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
          },
          icon: Icon(Icons.add, size: 18, color: c.accentText),
          label: Text('Vazifa qo‘shish', style: TextStyle(color: c.accentText)),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: TapRegion(
        onTapOutside: (_) => setState(() => _editing = false),
        child: TextField(
          controller: _ctrl,
          focusNode: _focus,
          onSubmitted: (_) => _submit(),
          style: TextStyle(color: c.text, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Vazifa nomi, Enter',
            hintStyle: TextStyle(color: c.text2),
            isDense: true,
            filled: true,
            fillColor: c.bg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.accent)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.accent)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: c.accent, width: 2)),
          ),
        ),
      ),
    );
  }
}
