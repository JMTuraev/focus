import '../l10n.dart' show ruPlural;

/// Tasks board and editor.
class TaskStrings {
  TaskStrings({
    required this.statusLabels,
    required this.title,
    required this.openCount,
    required this.overdueCount,
    required this.searchHint,
    required this.newTaskShort,
    required this.newTask,
    required this.onlyChat,
    required this.removeFilter,
    required this.emptyColumn,
    required this.emptyDone,
    required this.important,
    required this.notImportant,
    required this.openChat,
    required this.reopen,
    required this.markDone,
    required this.chatFallback,
    required this.quickAdd,
    required this.quickAddHint,
    required this.deleted,
    required this.undo,
    required this.editTitle,
    required this.markImportant,
    required this.titleHint,
    required this.titleRequired,
    required this.noteHint,
    required this.statusField,
    required this.dueField,
    required this.noDue,
    required this.inAWeek,
    required this.pickDate,
    required this.fromChat,
  });

  /// Kanban columns in `TaskStatus` order: planned, in progress, waiting, done.
  final List<String> statusLabels;

  // Board (tasks_screen.dart)
  final String title;

  /// Header stats: "5 ta ochiq".
  final String Function(int n) openCount;

  /// Header stats: "2 tasi muddati o‘tgan".
  final String Function(int n) overdueCount;
  final String searchHint;

  /// "New task" button on narrow windows.
  final String newTaskShort;

  /// "New task" button and the editor title for a new task.
  final String newTask;

  /// Chat filter chip: "Faqat: Dilshod"; [name] is null for an unknown chat.
  final String Function(String? name) onlyChat;
  final String removeFilter;
  final String emptyColumn;
  final String emptyDone;

  /// Card menu: mark as important.
  final String important;

  /// Card menu and editor star tooltip: unmark as important.
  final String notImportant;
  final String openChat;

  /// Tooltip of the check circle on a done card.
  final String reopen;

  /// Tooltip of the check circle on an open card.
  final String markDone;

  /// Card chip for a linked chat without a title.
  final String chatFallback;

  /// "+ Vazifa qo‘shish" at the bottom of a column.
  final String quickAdd;
  final String quickAddHint;

  // Editor (task_editor.dart)
  /// Toast after a delete: "Vazifa o‘chirildi: “title”".
  final String Function(String title) deleted;

  /// Toast action that restores a deleted task.
  final String undo;

  /// Editor title for an existing task.
  final String editTitle;

  /// Editor star tooltip when the task is not important.
  final String markImportant;
  final String titleHint;
  final String titleRequired;
  final String noteHint;
  final String statusField;
  final String dueField;
  final String noDue;
  final String inAWeek;
  final String pickDate;

  /// Label above the source chat box.
  final String fromChat;
}

final tasksUz = TaskStrings(
  statusLabels: const ['Rejada', 'Jarayonda', 'Kutilmoqda', 'Bajarildi'],
  title: 'Vazifalar',
  openCount: (n) => '$n ta ochiq',
  overdueCount: (n) => '$n tasi muddati o‘tgan',
  searchHint: 'Vazifa qidirish',
  newTaskShort: 'Yangi',
  newTask: 'Yangi vazifa',
  onlyChat: (name) => 'Faqat: ${name ?? 'chat'}',
  removeFilter: 'Filtrni olib tashlash',
  emptyColumn: 'Bo‘sh',
  emptyDone: 'Hali bajarilgan vazifa yo‘q',
  important: 'Muhim',
  notImportant: 'Muhim emas',
  openChat: 'Chatni ochish',
  reopen: 'Qayta ochish',
  markDone: 'Bajarildi',
  chatFallback: 'Chat',
  quickAdd: 'Vazifa qo‘shish',
  quickAddHint: 'Vazifa nomi, Enter',
  deleted: (t) => 'Vazifa o‘chirildi: “$t”',
  undo: 'Qaytarish',
  editTitle: 'Vazifa',
  markImportant: 'Muhim deb belgilash',
  titleHint: 'Nima qilish kerak?',
  titleRequired: 'Vazifa nomini kiriting.',
  noteHint: 'Izoh (ixtiyoriy)',
  statusField: 'Holat',
  dueField: 'Muddat',
  noDue: 'Muddatsiz',
  inAWeek: 'Bir haftadan keyin',
  pickDate: 'Sana tanlash…',
  fromChat: 'Chatdan',
);

final tasksRu = TaskStrings(
  statusLabels: const ['Запланировано', 'В работе', 'Ожидание', 'Готово'],
  title: 'Задачи',
  openCount: (n) => '$n ${ruPlural(n, 'открытая', 'открытые', 'открытых')}',
  overdueCount: (n) => '$n ${ruPlural(n, 'просрочена', 'просрочены', 'просрочено')}',
  searchHint: 'Поиск задач',
  newTaskShort: 'Новая',
  newTask: 'Новая задача',
  onlyChat: (name) => 'Только: ${name ?? 'чат'}',
  removeFilter: 'Сбросить фильтр',
  emptyColumn: 'Пусто',
  emptyDone: 'Выполненных задач пока нет',
  important: 'Важная',
  notImportant: 'Не важная',
  openChat: 'Открыть чат',
  reopen: 'Открыть снова',
  markDone: 'Выполнено',
  chatFallback: 'Чат',
  quickAdd: 'Добавить задачу',
  quickAddHint: 'Название задачи, Enter',
  deleted: (t) => 'Задача удалена: «$t»',
  undo: 'Вернуть',
  editTitle: 'Задача',
  markImportant: 'Отметить как важную',
  titleHint: 'Что нужно сделать?',
  titleRequired: 'Введите название задачи.',
  noteHint: 'Заметка (необязательно)',
  statusField: 'Статус',
  dueField: 'Срок',
  noDue: 'Без срока',
  inAWeek: 'Через неделю',
  pickDate: 'Выбрать дату…',
  fromChat: 'Из чата',
);

final tasksEn = TaskStrings(
  statusLabels: const ['Planned', 'In progress', 'Waiting', 'Done'],
  title: 'Tasks',
  openCount: (n) => '$n open',
  overdueCount: (n) => '$n overdue',
  searchHint: 'Search tasks',
  newTaskShort: 'New',
  newTask: 'New task',
  onlyChat: (name) => 'Only: ${name ?? 'chat'}',
  removeFilter: 'Clear filter',
  emptyColumn: 'Empty',
  emptyDone: 'No completed tasks yet',
  important: 'Important',
  notImportant: 'Not important',
  openChat: 'Open chat',
  reopen: 'Reopen',
  markDone: 'Mark as done',
  chatFallback: 'Chat',
  quickAdd: 'Add task',
  quickAddHint: 'Task title, Enter',
  deleted: (t) => 'Task deleted: “$t”',
  undo: 'Undo',
  editTitle: 'Task',
  markImportant: 'Mark as important',
  titleHint: 'What needs to be done?',
  titleRequired: 'Enter a task title.',
  noteHint: 'Note (optional)',
  statusField: 'Status',
  dueField: 'Due date',
  noDue: 'No due date',
  inAWeek: 'In a week',
  pickDate: 'Pick a date…',
  fromChat: 'From chat',
);
