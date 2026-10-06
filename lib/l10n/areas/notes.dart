import '../l10n.dart' show enPlural, ruPlural;

/// Notes and collections.
class NoteStrings {
  NoteStrings({
    required this.colorLabels,
    required this.notesTitle,
    required this.notesCount,
    required this.searchHint,
    required this.newChecklistShort,
    required this.newChecklist,
    required this.newNoteShort,
    required this.newNote,
    required this.filterAll,
    required this.filterFromChats,
    required this.filterChecklists,
    required this.onlyChat,
    required this.removeFilter,
    required this.noMatches,
    required this.emptyHint,
    required this.pinnedSection,
    required this.othersSection,
    required this.pin,
    required this.unpin,
    required this.toText,
    required this.toChecklist,
    required this.openChat,
    required this.moreItems,
    required this.unknownChat,
    required this.checklistFallback,
    required this.noteDeleted,
    required this.undo,
    required this.titleHint,
    required this.bodyHint,
    required this.addItem,
    required this.itemHint,
    required this.removeItem,
    required this.done,
    required this.allCollection,
    required this.collectionsTitle,
    required this.collectionsIntro,
    required this.newCollection,
    required this.newCollectionMenu,
    required this.editCollection,
    required this.collectionNameHint,
    required this.collectionNameEmpty,
    required this.collectionExists,
    required this.icon,
    required this.color,
    required this.collectionColorLabels,
    required this.deleteCollectionTitle,
    required this.deleteEmptyCollection,
    required this.deleteCollectionBody,
    required this.addToCollection,
    required this.removeFromCollection,
    required this.allSorted,
    required this.noUnsortedOfType,
    required this.unsorted,
    required this.unsortedCount,
    required this.allTypes,
    required this.movedToCollection,
    required this.moveAll,
    required this.moveAllOfType,
    required this.unreadCount,
    required this.emptyCollection,
    required this.actions,
    required this.otherCollection,
    required this.toCollection,
  });

  /// Note colors in `NoteColor` order: none, yellow, green, blue, purple, pink, orange.
  final List<String> colorLabels;

  // Notes screen.
  final String notesTitle;

  /// "12 ta eslatma".
  final String Function(int n) notesCount;
  final String searchHint;

  /// Header buttons; the short forms are used on narrow windows.
  final String newChecklistShort;
  final String newChecklist;
  final String newNoteShort;
  final String newNote;

  /// `NoteFilter` chips.
  final String filterAll;
  final String filterFromChats;
  final String filterChecklists;

  /// Chip of the chat filter; [name] is null when the chat is unknown.
  final String Function(String? name) onlyChat;
  final String removeFilter;
  final String noMatches;
  final String emptyHint;

  /// Section titles (shown upper-case).
  final String pinnedSection;
  final String othersSection;
  final String pin;
  final String unpin;
  final String toText;
  final String toChecklist;
  final String openChat;

  /// "yana 3 ta": checklist items not shown on a card.
  final String Function(int n) moreItems;

  /// Title of a linked chat that is no longer known.
  final String unknownChat;

  // Note editor.
  /// Used in the "deleted" toast for a checklist without any text.
  final String checklistFallback;
  final String Function(String what) noteDeleted;
  final String undo;
  final String titleHint;
  final String bodyHint;
  final String addItem;
  final String itemHint;
  final String removeItem;
  final String done;

  // Collections.
  /// The virtual "all chats" collection (`kAllCollection`).
  final String allCollection;
  final String collectionsTitle;
  final String collectionsIntro;
  final String newCollection;

  /// Menu entry that opens the new-collection dialog.
  final String newCollectionMenu;
  final String editCollection;
  final String collectionNameHint;
  final String collectionNameEmpty;
  final String collectionExists;
  final String icon;

  /// Color section of the collection editor and its swatch tooltips
  /// ([kCollectionColorKeys] order).
  final String color;
  final List<String> collectionColorLabels;
  final String Function(String name) deleteCollectionTitle;
  final String deleteEmptyCollection;

  /// [n] chats of the deleted collection become unsorted.
  final String Function(int n) deleteCollectionBody;
  final String addToCollection;
  final String removeFromCollection;
  final String allSorted;
  final String noUnsortedOfType;

  /// Chats in no collection ("Saralanmagan").
  final String unsorted;
  final String Function(int n) unsortedCount;

  /// Tab of the unsorted list with every chat type.
  final String allTypes;
  final String Function(int n, String collection) movedToCollection;
  final String Function(int n) moveAll;

  /// [type] is the lower-cased chat type tab, e.g. "guruhlar".
  final String Function(String type, int n) moveAllOfType;

  /// "3 o‘qilmagan" on a collection card.
  final String Function(int n) unreadCount;
  final String emptyCollection;

  /// Tooltip of a collection card menu.
  final String actions;

  /// Unsorted row button next to the quick collection buttons.
  final String otherCollection;
  final String toCollection;
}

final notesUz = NoteStrings(
  colorLabels: const ['Rangsiz', 'Sariq', 'Yashil', 'Ko‘k', 'Binafsha', 'Pushti', 'To‘q sariq'],
  notesTitle: 'Eslatmalar',
  notesCount: (n) => '$n ta eslatma',
  searchHint: 'Eslatma qidirish',
  newChecklistShort: 'Ro‘yxat',
  newChecklist: 'Yangi ro‘yxat',
  newNoteShort: 'Yangi',
  newNote: 'Yangi eslatma',
  filterAll: 'Hammasi',
  filterFromChats: 'Chatdan saqlangan',
  filterChecklists: 'Ro‘yxatlar',
  onlyChat: (name) => 'Faqat: ${name ?? 'chat'}',
  removeFilter: 'Filtrni olib tashlash',
  noMatches: 'Mos eslatma topilmadi.',
  emptyHint: 'Hali eslatma yo‘q. Chatdagi xabarni «Eslatmaga» tugmasi bilan saqlang yoki yangisini yozing.',
  pinnedSection: 'Qadalgan',
  othersSection: 'Boshqalar',
  pin: 'Qadash',
  unpin: 'Qadashni olib tashlash',
  toText: 'Matnga aylantirish',
  toChecklist: 'Ro‘yxatga aylantirish',
  openChat: 'Chatni ochish',
  moreItems: (n) => 'yana $n ta',
  unknownChat: 'Chat',
  checklistFallback: 'ro‘yxat',
  noteDeleted: (what) => 'Eslatma o‘chirildi: “$what”',
  undo: 'Qaytarish',
  titleHint: 'Sarlavha',
  bodyHint: 'Eslatma…',
  addItem: 'Element qo‘shish',
  itemHint: 'Element',
  removeItem: 'Olib tashlash',
  done: 'Tayyor',
  allCollection: 'Hammasi',
  collectionsTitle: 'To‘plamlar',
  collectionsIntro:
      'Chatlarni o‘zingizga qulay guruhlarga ajrating. Bu faqat Focus’da saqlanadi, Telegram’ga ta’sir qilmaydi.',
  newCollection: 'Yangi to‘plam',
  newCollectionMenu: 'Yangi to‘plam…',
  editCollection: 'To‘plamni tahrirlash',
  collectionNameHint: 'Masalan: Yetkazib beruvchilar',
  collectionNameEmpty: 'Nomini kiriting.',
  collectionExists: 'Bu nomdagi to‘plam allaqachon bor.',
  icon: 'Ikonka',
  color: 'Rang',
  collectionColorLabels: const ['Ko‘k', 'Yashil', 'Moviy', 'To‘q sariq', 'Qizil', 'Binafsha', 'Pushti', 'Kulrang'],
  deleteCollectionTitle: (name) => '«$name» o‘chirilsinmi?',
  deleteEmptyCollection: 'To‘plam bo‘sh. Telegram’dagi chatlarga ta’sir qilmaydi.',
  deleteCollectionBody: (n) =>
      'Undagi $n ta chat «Saralanmagan»ga qaytadi. Telegram’dagi chatlarga ta’sir qilmaydi.',
  addToCollection: 'To‘plamga qo‘shish',
  removeFromCollection: 'To‘plamdan chiqarish',
  allSorted: 'Barcha chatlar to‘plamlarga ajratilgan.',
  noUnsortedOfType: 'Bu turdagi saralanmagan chat yo‘q.',
  unsorted: 'Saralanmagan',
  unsortedCount: (n) => '$n ta chat hech qaysi to‘plamda emas',
  allTypes: 'Hammasi',
  movedToCollection: (n, col) => '$n ta chat «$col» to‘plamiga o‘tkazildi',
  moveAll: (n) => 'Barchasini to‘plamga ($n)',
  moveAllOfType: (type, n) => 'Barcha $type ($n) → to‘plamga',
  unreadCount: (n) => '$n o‘qilmagan',
  emptyCollection: 'Bo‘sh',
  actions: 'Amallar',
  otherCollection: 'Boshqa…',
  toCollection: 'To‘plamga',
);

final notesRu = NoteStrings(
  colorLabels: const ['Без цвета', 'Жёлтый', 'Зелёный', 'Синий', 'Фиолетовый', 'Розовый', 'Оранжевый'],
  notesTitle: 'Заметки',
  notesCount: (n) => '$n ${ruPlural(n, 'заметка', 'заметки', 'заметок')}',
  searchHint: 'Поиск заметок',
  newChecklistShort: 'Список',
  newChecklist: 'Новый список',
  newNoteShort: 'Новая',
  newNote: 'Новая заметка',
  filterAll: 'Все',
  filterFromChats: 'Из чатов',
  filterChecklists: 'Списки',
  onlyChat: (name) => 'Только: ${name ?? 'чат'}',
  removeFilter: 'Убрать фильтр',
  noMatches: 'Подходящих заметок нет.',
  emptyHint: 'Заметок пока нет. Сохраните сообщение из чата кнопкой «В заметки» или напишите новую.',
  pinnedSection: 'Закреплённые',
  othersSection: 'Остальные',
  pin: 'Закрепить',
  unpin: 'Открепить',
  toText: 'Превратить в текст',
  toChecklist: 'Превратить в список',
  openChat: 'Открыть чат',
  moreItems: (n) => 'ещё $n',
  unknownChat: 'Чат',
  checklistFallback: 'список',
  noteDeleted: (what) => 'Заметка удалена: «$what»',
  undo: 'Вернуть',
  titleHint: 'Заголовок',
  bodyHint: 'Заметка…',
  addItem: 'Добавить пункт',
  itemHint: 'Пункт',
  removeItem: 'Убрать',
  done: 'Готово',
  allCollection: 'Все',
  collectionsTitle: 'Коллекции',
  collectionsIntro:
      'Разложите чаты по удобным вам группам. Это хранится только в Focus и никак не влияет на Telegram.',
  newCollection: 'Новая коллекция',
  newCollectionMenu: 'Новая коллекция…',
  editCollection: 'Изменить коллекцию',
  collectionNameHint: 'Например: Поставщики',
  collectionNameEmpty: 'Введите название.',
  collectionExists: 'Коллекция с таким названием уже есть.',
  icon: 'Значок',
  color: 'Цвет',
  collectionColorLabels: const ['Синий', 'Зелёный', 'Бирюзовый', 'Оранжевый', 'Красный', 'Фиолетовый', 'Розовый', 'Серый'],
  deleteCollectionTitle: (name) => 'Удалить «$name»?',
  deleteEmptyCollection: 'Коллекция пуста. Чаты в Telegram не изменятся.',
  deleteCollectionBody: (n) =>
      '${ruPlural(n, 'Её $n чат вернётся', 'Её $n чата вернутся', 'Её $n чатов вернутся')} в «Без коллекции». '
      'Чаты в Telegram не изменятся.',
  addToCollection: 'Добавить в коллекцию',
  removeFromCollection: 'Убрать из коллекции',
  allSorted: 'Все чаты разложены по коллекциям.',
  noUnsortedOfType: 'Чатов этого типа без коллекции нет.',
  unsorted: 'Без коллекции',
  unsortedCount: (n) => ruPlural(n, '$n чат не входит ни в одну коллекцию', '$n чата не входят ни в одну коллекцию',
      '$n чатов не входят ни в одну коллекцию'),
  allTypes: 'Все',
  movedToCollection: (n, col) =>
      '$n ${ruPlural(n, 'чат перемещён', 'чата перемещены', 'чатов перемещены')} в коллекцию «$col»',
  moveAll: (n) => 'Все в коллекцию ($n)',
  moveAllOfType: (type, n) => 'Все $type ($n) → в коллекцию',
  unreadCount: (n) => '$n ${ruPlural(n, 'непрочитанный', 'непрочитанных', 'непрочитанных')}',
  emptyCollection: 'Пусто',
  actions: 'Действия',
  otherCollection: 'Другая…',
  toCollection: 'В коллекцию',
);

final notesEn = NoteStrings(
  colorLabels: const ['No color', 'Yellow', 'Green', 'Blue', 'Purple', 'Pink', 'Orange'],
  notesTitle: 'Notes',
  notesCount: (n) => '$n ${enPlural(n, 'note', 'notes')}',
  searchHint: 'Search notes',
  newChecklistShort: 'Checklist',
  newChecklist: 'New checklist',
  newNoteShort: 'New',
  newNote: 'New note',
  filterAll: 'All',
  filterFromChats: 'Saved from chats',
  filterChecklists: 'Checklists',
  onlyChat: (name) => 'Only: ${name ?? 'chat'}',
  removeFilter: 'Remove filter',
  noMatches: 'No matching notes.',
  emptyHint: 'No notes yet. Save a message from a chat with the “To notes” button or write a new one.',
  pinnedSection: 'Pinned',
  othersSection: 'Others',
  pin: 'Pin',
  unpin: 'Unpin',
  toText: 'Convert to text',
  toChecklist: 'Convert to checklist',
  openChat: 'Open chat',
  moreItems: (n) => '$n more',
  unknownChat: 'Chat',
  checklistFallback: 'checklist',
  noteDeleted: (what) => 'Note deleted: “$what”',
  undo: 'Undo',
  titleHint: 'Title',
  bodyHint: 'Note…',
  addItem: 'Add item',
  itemHint: 'Item',
  removeItem: 'Remove',
  done: 'Done',
  allCollection: 'All',
  collectionsTitle: 'Collections',
  collectionsIntro: 'Sort chats into groups that suit you. This is stored only in Focus and does not affect Telegram.',
  newCollection: 'New collection',
  newCollectionMenu: 'New collection…',
  editCollection: 'Edit collection',
  collectionNameHint: 'For example: Suppliers',
  collectionNameEmpty: 'Enter a name.',
  collectionExists: 'A collection with this name already exists.',
  icon: 'Icon',
  color: 'Color',
  collectionColorLabels: const ['Blue', 'Green', 'Teal', 'Orange', 'Red', 'Purple', 'Pink', 'Grey'],
  deleteCollectionTitle: (name) => 'Delete “$name”?',
  deleteEmptyCollection: 'The collection is empty. Chats in Telegram are not affected.',
  deleteCollectionBody: (n) =>
      'Its $n ${enPlural(n, 'chat goes', 'chats go')} back to “Unsorted”. Chats in Telegram are not affected.',
  addToCollection: 'Add to collection',
  removeFromCollection: 'Remove from collection',
  allSorted: 'All chats are sorted into collections.',
  noUnsortedOfType: 'No unsorted chats of this type.',
  unsorted: 'Unsorted',
  unsortedCount: (n) => '$n ${enPlural(n, 'chat is', 'chats are')} not in any collection',
  allTypes: 'All',
  movedToCollection: (n, col) => '$n ${enPlural(n, 'chat', 'chats')} moved to “$col”',
  moveAll: (n) => 'Move all to a collection ($n)',
  moveAllOfType: (type, n) => 'All $type ($n) → to a collection',
  unreadCount: (n) => '$n unread',
  emptyCollection: 'Empty',
  actions: 'Actions',
  otherCollection: 'Other…',
  toCollection: 'To collection',
);
