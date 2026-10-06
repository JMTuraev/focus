import '../l10n.dart' show enPlural;

/// "Fayllar" module: files and messages the user saved from chats.
class FilesStrings {
  FilesStrings({
    required this.title,
    required this.intro,
    required this.introForChat,
    required this.searchHint,
    required this.allFiles,
    required this.tabDocuments,
    required this.tabPhotos,
    required this.tabVideos,
    required this.tabAudio,
    required this.tabTexts,
    required this.emptySaved,
    required this.emptyKind,
    required this.emptySearch,
    required this.emptyMarked,
    required this.goToChat,
    required this.rename,
    required this.renameHint,
    required this.originalName,
    required this.copyText,
    required this.copied,
    required this.removeFromFiles,
    required this.photo,
    required this.video,
    required this.foundCount,
    required this.allChats,
    required this.marks,
    required this.favorites,
    required this.addFavorite,
    required this.removeFavorite,
    required this.tags,
    required this.newTagHint,
    required this.tagsHint,
    required this.groupBy,
    required this.groupNone,
    required this.groupDay,
    required this.groupChat,
    required this.noDate,
  });

  final String title;
  final String intro;

  /// Header line when the list is limited to one chat.
  final String Function(String chat) introForChat;
  final String searchHint;

  /// Kind tabs; [allFiles] is every kind.
  final String allFiles;
  final String tabDocuments;
  final String tabPhotos;
  final String tabVideos;
  final String tabAudio;
  final String tabTexts;

  /// Nothing saved yet (explains how to save).
  final String emptySaved;
  final String emptyKind;
  final String emptySearch;
  final String emptyMarked;

  /// Context menu: open the chat the item came from.
  final String goToChat;

  /// Rename in Focus (the file in Telegram keeps its name).
  final String rename;
  final String renameHint;
  final String Function(String name) originalName;
  final String copyText;
  final String copied;
  final String removeFromFiles;

  /// Card title for a photo / video without a caption.
  final String photo;
  final String video;

  /// Number of shown items next to the title.
  final String Function(int n) foundCount;

  /// Chip that drops the "only this chat" filter.
  final String allChats;

  /// Card button and popover: favorite and the user's tags.
  final String marks;
  final String favorites;
  final String addFavorite;
  final String removeFavorite;
  final String tags;
  final String newTagHint;
  final String tagsHint;

  /// Grouping of the cards.
  final String groupBy;
  final String groupNone;
  final String groupDay;
  final String groupChat;

  /// Day group for items without a date.
  final String noDate;
}

final filesUz = FilesStrings(
  title: 'Fayllar',
  intro: 'Chatlardan saqlagan fayl va xabarlaringiz.',
  introForChat: (chat) => '$chat chatidan saqlanganlar',
  searchHint: 'Nom, matn yoki teg bo‘yicha qidirish',
  allFiles: 'Hammasi',
  tabDocuments: 'Hujjatlar',
  tabPhotos: 'Rasmlar',
  tabVideos: 'Videolar',
  tabAudio: 'Audio',
  tabTexts: 'Matnlar',
  emptySaved:
      'Hali hech narsa saqlanmagan.\nChatda xabarni tanlab «Fayllarga» tugmasini bosing yoki faylga o‘ng tugma → «Fayllarga saqlash».',
  emptyKind: 'Bu turda saqlangan narsa yo‘q.',
  emptySearch: 'Qidiruvga mos narsa yo‘q.',
  emptyMarked: 'Bu belgili narsa hali yo‘q.',
  goToChat: 'Chatga o‘tish',
  rename: 'Nomini o‘zgartirish',
  renameHint: 'Faqat Focusda ko‘rinadi, Telegramdagi nom o‘zgarmaydi. Bo‘sh qoldirilsa asl nom qaytadi.',
  originalName: (n) => 'Asl nomi: $n',
  copyText: 'Matnni nusxalash',
  copied: 'Nusxalandi',
  removeFromFiles: 'Fayllardan olib tashlash',
  photo: 'Rasm',
  video: 'Video',
  foundCount: (n) => '$n ta',
  allChats: 'Barcha chatlar',
  marks: 'Belgilash',
  favorites: 'Sevimlilar',
  addFavorite: 'Sevimlilarga qo‘shish',
  removeFavorite: 'Sevimlilardan olish',
  tags: 'Teglar',
  newTagHint: 'Yangi teg…',
  tagsHint: 'Teg yozib Enter bosing. Belgilar faqat Focusda saqlanadi.',
  groupBy: 'Guruhlash',
  groupNone: 'Yo‘q',
  groupDay: 'Kunlar',
  groupChat: 'Chatlar',
  noDate: 'Sanasiz',
);

final filesRu = FilesStrings(
  title: 'Файлы',
  intro: 'Файлы и сообщения, которые вы сохранили из чатов.',
  introForChat: (chat) => 'Сохранено из чата $chat',
  searchHint: 'Поиск по имени, тексту или метке',
  allFiles: 'Все',
  tabDocuments: 'Документы',
  tabPhotos: 'Фото',
  tabVideos: 'Видео',
  tabAudio: 'Аудио',
  tabTexts: 'Тексты',
  emptySaved:
      'Пока ничего не сохранено.\nВыберите сообщение в чате и нажмите «В файлы» или правый клик по файлу → «Сохранить в Файлы».',
  emptyKind: 'Сохранённого такого типа нет.',
  emptySearch: 'По запросу ничего не найдено.',
  emptyMarked: 'С такой пометкой пока ничего нет.',
  goToChat: 'Перейти в чат',
  rename: 'Переименовать',
  renameHint: 'Видно только в Focus, имя в Telegram не меняется. Пустое поле вернёт исходное имя.',
  originalName: (n) => 'Исходное имя: $n',
  copyText: 'Копировать текст',
  copied: 'Скопировано',
  removeFromFiles: 'Убрать из Файлов',
  photo: 'Фото',
  video: 'Видео',
  foundCount: (n) => '$n',
  allChats: 'Все чаты',
  marks: 'Пометить',
  favorites: 'Избранное',
  addFavorite: 'В избранное',
  removeFavorite: 'Убрать из избранного',
  tags: 'Метки',
  newTagHint: 'Новая метка…',
  tagsHint: 'Введите метку и нажмите Enter. Пометки хранятся только в Focus.',
  groupBy: 'Группировка',
  groupNone: 'Нет',
  groupDay: 'По дням',
  groupChat: 'По чатам',
  noDate: 'Без даты',
);

final filesEn = FilesStrings(
  title: 'Files',
  intro: 'Files and messages you saved from chats.',
  introForChat: (chat) => 'Saved from $chat',
  searchHint: 'Search by name, text or tag',
  allFiles: 'All',
  tabDocuments: 'Documents',
  tabPhotos: 'Photos',
  tabVideos: 'Videos',
  tabAudio: 'Audio',
  tabTexts: 'Texts',
  emptySaved: 'Nothing saved yet.\nPick a message in a chat and press “To Files”, or right-click a file → “Save to Files”.',
  emptyKind: 'Nothing of this kind is saved.',
  emptySearch: 'Nothing matches the search.',
  emptyMarked: 'Nothing with this mark yet.',
  goToChat: 'Go to chat',
  rename: 'Rename',
  renameHint: 'Shown only in Focus; the name in Telegram stays. Leave empty to restore the original.',
  originalName: (n) => 'Original name: $n',
  copyText: 'Copy text',
  copied: 'Copied',
  removeFromFiles: 'Remove from Files',
  photo: 'Photo',
  video: 'Video',
  foundCount: (n) => '$n ${enPlural(n, 'item', 'items')}',
  allChats: 'All chats',
  marks: 'Mark',
  favorites: 'Favorites',
  addFavorite: 'Add to favorites',
  removeFavorite: 'Remove from favorites',
  tags: 'Tags',
  newTagHint: 'New tag…',
  tagsHint: 'Type a tag and press Enter. Marks are stored only in Focus.',
  groupBy: 'Group',
  groupNone: 'None',
  groupDay: 'By day',
  groupChat: 'By chat',
  noDate: 'No date',
);
