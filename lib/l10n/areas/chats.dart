import '../l10n.dart' show enPlural, ruPlural;

/// Chat list, chat view, info panel, media, files, message previews.
class ChatStrings {
  ChatStrings({
    required this.allChats,
    required this.loadingChats,
    required this.noChatsInFilter,
    required this.pinned,
    required this.hideMuted,
    required this.clearFilter,
    required this.typeFilter,
    required this.typePrivate,
    required this.typeGroups,
    required this.typeChannels,
    required this.typeBots,
    required this.fileSendFailed,
    required this.messageSendFailed,
    required this.actionTyping,
    required this.actionVoice,
    required this.actionVideo,
    required this.actionFile,
    required this.actionSticker,
    required this.copyMessage,
    required this.copied,
    required this.editMessage,
    required this.deleteMessage,
    required this.editing,
    required this.cancelEdit,
    required this.edited,
    required this.deleteTitle,
    required this.deleteForBoth,
    required this.deleteForAll,
    required this.editFailed,
    required this.deleteFailed,
    required this.pinChat,
    required this.unpinChat,
    required this.pinLimit,
    required this.pinFailed,
    required this.addedToCalendar,
    required this.openCalendar,
    required this.callsOnPhone,
    required this.selectedMessage,
    required this.lastMessageHint,
    required this.messageLower,
    required this.taskCreated,
    required this.goToTasks,
    required this.savedToNotes,
    required this.openNotes,
    required this.noMessages,
    required this.dropFiles,
    required this.dropFilesHint,
    required this.noRecentEmoji,
    required this.emojiSearch,
    required this.call,
    required this.infoPanel,
    required this.toTask,
    required this.toCalendar,
    required this.toNote,
    required this.toFiles,
    required this.savedToFiles,
    required this.alreadyInFiles,
    required this.openFiles,
    required this.saveToFiles,
    required this.meetingFound,
    required this.messageHint,
    required this.attachFile,
    required this.closeEmoji,
    required this.emoji,
    required this.tickFailed,
    required this.tickSending,
    required this.tickRead,
    required this.tickSent,
    required this.selectChat,
    required this.channelReadOnly,
    required this.groupNoRights,
    required this.openFileTitle,
    required this.riskyFile,
    required this.openAnyway,
    required this.cantOpenFile,
    required this.savedAs,
    required this.cantSaveFile,
    required this.showInFolder,
    required this.saveAs,
    required this.openLinkTitle,
    required this.pause,
    required this.play,
    required this.closeEsc,
    required this.sendPhoto,
    required this.sendFile,
    required this.sendFiles,
    required this.noFileSelected,
    required this.addMore,
    required this.compressImages,
    required this.compressOn,
    required this.compressOff,
    required this.captionHint,
    required this.removeFile,
    required this.info,
    required this.closePanel,
    required this.phone,
    required this.about,
    required this.collection,
    required this.newCollection,
    required this.fromThisChat,
    required this.tasks,
    required this.meetings,
    required this.notes,
    required this.files,
    required this.chat,
    required this.openChat,
    required this.meetingTitle,
    required this.savedMessages,
    required this.statusCloud,
    required this.statusBot,
    required this.statusChannel,
    required this.statusGroup,
    required this.subscribers,
    required this.members,
    required this.deletedAccount,
    required this.online,
    required this.lastSeenRecently,
    required this.lastSeenWeek,
    required this.lastSeenMonth,
    required this.lastSeenLongAgo,
    required this.youPrefix,
    required this.photo,
    required this.video,
    required this.sticker,
    required this.voiceMessage,
    required this.videoMessage,
    required this.audio,
    required this.location,
    required this.venue,
    required this.contact,
    required this.poll,
    required this.callMessage,
    required this.story,
    required this.message,
    required this.unsupportedMessage,
    required this.paidMedia,
    required this.invoice,
    required this.giveaway,
    required this.videoChatStarted,
    required this.videoChatEnded,
    required this.boostedChat,
    required this.topicChanged,
    required this.joinedGroup,
    required this.leftGroup,
    required this.changedGroupTitle,
    required this.changedGroupPhoto,
    required this.deletedGroupPhoto,
    required this.pinnedMessage,
    required this.createdGroup,
    required this.upgradedGroup,
    required this.joinedTelegram,
    required this.setAutoDelete,
    required this.tookScreenshot,
  });

  // ---- chat list

  /// Header above the list when no collection is picked.
  final String allChats;
  final String loadingChats;
  final String noChatsInFilter;

  /// Tooltip of the pin icon of a pinned chat.
  final String pinned;
  final String hideMuted;
  final String clearFilter;

  /// Tooltip of the chat type filter button.
  final String typeFilter;

  /// Chat type filter and "unsorted" tabs.
  final String typePrivate;
  final String typeGroups;
  final String typeChannels;
  final String typeBots;

  // ---- chat view
  final String fileSendFailed;
  final String messageSendFailed;

  /// What the other side is doing (TDLib chat actions), shown as the status.
  final String actionTyping;
  final String actionVoice;
  final String actionVideo;
  final String actionFile;
  final String actionSticker;

  /// Message context menu, editing and deleting.
  final String copyMessage;
  final String copied;
  final String editMessage;
  final String deleteMessage;

  /// Bar above the composer while a message is edited.
  final String editing;
  final String cancelEdit;

  /// Next to the time of an edited message.
  final String edited;
  final String deleteTitle;

  /// Checkbox in a private chat: also delete for [name].
  final String Function(String name) deleteForBoth;

  /// Checkbox in groups: delete for everyone.
  final String deleteForAll;
  final String editFailed;
  final String deleteFailed;

  /// Chat context menu: pin / unpin in Telegram; errors of that call.
  final String pinChat;
  final String unpinChat;
  final String pinLimit;
  final String pinFailed;

  /// Toast after a detected meeting was added; the value is the meeting label.
  final String Function(String meeting) addedToCalendar;
  final String openCalendar;
  final String callsOnPhone;

  /// Quick actions bar: which message the actions use.
  final String selectedMessage;
  final String lastMessageHint;

  /// "xabar": a message without text or file name, inside a sentence.
  final String messageLower;
  final String Function(String what) taskCreated;
  final String goToTasks;
  final String Function(String what) savedToNotes;
  final String openNotes;
  final String noMessages;
  final String dropFiles;
  final String dropFilesHint;
  final String noRecentEmoji;
  final String emojiSearch;

  /// Tooltip of the call button in the chat header.
  final String call;
  final String infoPanel;

  /// Quick actions: "Vazifa qilish", "Kalendarga", "Eslatmaga".
  final String toTask;
  final String toCalendar;
  final String toNote;

  /// "Fayllarga": saves the message into the "Fayllar" module.
  final String toFiles;
  final String Function(String what) savedToFiles;
  final String alreadyInFiles;
  final String openFiles;

  /// File context menu entry.
  final String saveToFiles;

  /// Prefix before a detected meeting under a message.
  final String meetingFound;
  final String messageHint;
  final String attachFile;
  final String closeEmoji;
  final String emoji;

  /// Delivery mark tooltips.
  final String tickFailed;
  final String tickSending;
  final String tickRead;
  final String tickSent;

  /// Placeholder before a chat is picked.
  final String selectChat;
  final String channelReadOnly;
  final String groupNoRights;

  // ---- files and links
  final String openFileTitle;

  /// Warning before opening a program or script.
  final String Function(String name) riskyFile;
  final String openAnyway;
  final String cantOpenFile;
  final String Function(String name) savedAs;
  final String cantSaveFile;
  final String showInFolder;
  final String saveAs;
  final String openLinkTitle;

  // ---- media
  final String pause;
  final String play;
  final String closeEsc;

  // ---- send files dialog
  final String sendPhoto;
  final String sendFile;

  /// Dialog title for several files (n > 1).
  final String Function(int n) sendFiles;
  final String noFileSelected;
  final String addMore;
  final String compressImages;
  final String compressOn;
  final String compressOff;
  final String captionHint;
  final String removeFile;

  // ---- info panel
  final String info;
  final String closePanel;
  final String phone;

  /// Bio of a user or description of a group.
  final String about;

  /// Section title: the chat's collection.
  final String collection;

  /// Chip that creates a collection.
  final String newCollection;
  final String fromThisChat;
  final String tasks;
  final String meetings;
  final String notes;
  final String files;

  // ---- source box (tasks, events)
  /// Fallback title of an unknown chat.
  final String chat;
  final String openChat;

  /// Title of a calendar event made from a detected meeting.
  final String Function(String chat) meetingTitle;

  // ---- chats from Telegram: names, statuses, previews
  final String savedMessages;

  /// Status of Saved Messages.
  final String statusCloud;
  final String statusBot;

  /// Status of a channel or group with an unknown member count.
  final String statusChannel;
  final String statusGroup;

  /// [count] is [n] already formatted ("3 412").
  final String Function(int n, String count) subscribers;
  final String Function(int n, String count) members;
  final String deletedAccount;
  final String online;
  final String lastSeenRecently;
  final String lastSeenWeek;
  final String lastSeenMonth;
  final String lastSeenLongAgo;

  /// Before the text of our own last message in the chat list.
  final String youPrefix;

  /// Media labels (previews and message rows).
  final String photo;
  final String video;
  final String sticker;
  final String voiceMessage;
  final String videoMessage;
  final String audio;
  final String location;
  final String Function(String title) venue;
  final String contact;
  final String Function(String question) poll;

  /// A call in the message history.
  final String callMessage;
  final String story;

  /// Any message of an unknown type.
  final String message;

  /// A message type this TDLib build cannot show (messageUnsupported).
  final String unsupportedMessage;
  final String paidMedia;
  final String invoice;
  final String giveaway;

  /// Service messages of video chats, boosts and forum topics.
  final String videoChatStarted;
  final String videoChatEnded;
  final String boostedChat;
  final String topicChanged;

  /// Service messages; the sender's name comes before them.
  final String joinedGroup;
  final String leftGroup;
  final String Function(String title) changedGroupTitle;
  final String changedGroupPhoto;
  final String deletedGroupPhoto;
  final String pinnedMessage;
  final String createdGroup;
  final String upgradedGroup;
  final String joinedTelegram;
  final String setAutoDelete;
  final String tookScreenshot;
}

final chatsUz = ChatStrings(
  allChats: 'Barcha chatlar',
  loadingChats: 'Chatlar yuklanmoqda…',
  noChatsInFilter: 'Bu filtrda chat yo‘q',
  pinned: 'Qadalgan',
  hideMuted: 'Ovozsizlarni yashirish',
  clearFilter: 'Filtrni tozalash',
  typeFilter: 'Chat turi bo‘yicha filtr',
  typePrivate: 'Shaxsiy',
  typeGroups: 'Guruhlar',
  typeChannels: 'Kanallar',
  typeBots: 'Botlar',
  fileSendFailed: 'Fayl yuborilmadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.',
  messageSendFailed: 'Xabar yuborilmadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.',
  actionTyping: 'yozmoqda…',
  actionVoice: 'ovozli xabar yozmoqda…',
  actionVideo: 'video yozmoqda…',
  actionFile: 'fayl yubormoqda…',
  actionSticker: 'stiker tanlamoqda…',
  copyMessage: 'Nusxalash',
  copied: 'Nusxalandi',
  editMessage: 'Tahrirlash',
  deleteMessage: 'O‘chirish',
  editing: 'Tahrirlash',
  cancelEdit: 'Tahrirlashni bekor qilish (Esc)',
  edited: 'tahrirlangan',
  deleteTitle: 'Xabar o‘chirilsinmi?',
  deleteForBoth: (name) => '$name uchun ham o‘chirish',
  deleteForAll: 'Hamma uchun o‘chirish',
  editFailed: 'Xabarni tahrirlab bo‘lmadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.',
  deleteFailed: 'Xabarni o‘chirib bo‘lmadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.',
  pinChat: 'Qadash',
  unpinChat: 'Qadalganini yechish',
  pinLimit: 'Telegramda qadash chegarasiga yetildi. Avval boshqa chatni yeching.',
  pinFailed: 'Qadab bo‘lmadi. Internet aloqasini tekshirib, qayta urinib ko‘ring.',
  addedToCalendar: (m) => 'Kalendarga qo‘shildi: $m',
  openCalendar: 'Kalendarni ochish',
  callsOnPhone: 'Qo‘ng‘iroqlar telefon ilovasida qoladi',
  selectedMessage: 'Tanlangan xabar',
  lastMessageHint: 'Oxirgi xabar · boshqasini tanlash uchun xabarni bosing',
  messageLower: 'xabar',
  taskCreated: (w) => 'Vazifa yaratildi: “$w”',
  goToTasks: 'Vazifalarga o‘tish',
  savedToNotes: (w) => 'Eslatmaga saqlandi: “$w”',
  openNotes: 'Eslatmalarni ochish',
  noMessages: 'Hali xabar yo‘q',
  dropFiles: 'Fayllarni shu yerga tashlang',
  dropFilesHint: 'Yuborishdan oldin ko‘rib chiqasiz',
  noRecentEmoji: 'Hali emoji tanlanmagan',
  emojiSearch: 'Qidirish',
  call: 'Qo‘ng‘iroq',
  infoPanel: 'Ma’lumot paneli',
  toTask: 'Vazifa qilish',
  toCalendar: 'Kalendarga',
  toNote: 'Eslatmaga',
  toFiles: 'Fayllarga',
  savedToFiles: (w) => '«$w» Fayllarga saqlandi',
  alreadyInFiles: 'Bu xabar Fayllarda bor',
  openFiles: 'Fayllar',
  saveToFiles: 'Fayllarga saqlash',
  meetingFound: 'Uchrashuv aniqlandi: ',
  messageHint: 'Xabar yozing…',
  attachFile: 'Fayl biriktirish',
  closeEmoji: 'Emojilarni yopish',
  emoji: 'Emoji',
  tickFailed: 'Yuborilmadi',
  tickSending: 'Yuborilmoqda',
  tickRead: 'O‘qildi',
  tickSent: 'Yuborildi',
  selectChat: 'Suhbatni tanlang',
  channelReadOnly: 'Kanal · faqat o‘qish mumkin',
  groupNoRights: 'Bu guruhga yozish huquqingiz yo‘q',
  openFileTitle: 'Faylni ochasizmi?',
  riskyFile: (name) => '“$name” dastur yoki skript bo‘lishi mumkin. Unga ishonchingiz komil bo‘lmasa, ochmang: '
      'u kompyuteringizga zarar yetkazishi mumkin.',
  openAnyway: 'Baribir ochish',
  cantOpenFile: 'Faylni ochib bo‘lmadi',
  savedAs: (name) => 'Saqlandi: $name',
  cantSaveFile: 'Faylni saqlab bo‘lmadi',
  showInFolder: 'Papkada ko‘rsatish',
  saveAs: 'Boshqa joyga saqlash…',
  openLinkTitle: 'Havolani ochasizmi?',
  pause: 'To‘xtatish',
  play: 'Tinglash',
  closeEsc: 'Yopish (Esc)',
  sendPhoto: 'Rasm yuborish',
  sendFile: 'Fayl yuborish',
  sendFiles: (n) => '$n ta fayl yuborish',
  noFileSelected: 'Fayl tanlanmagan',
  addMore: 'Yana qo‘shish',
  compressImages: 'Rasmlarni siqib yuborish',
  compressOn: 'Rasm sifatida, albom bo‘lib boradi',
  compressOff: 'Asl sifatda, fayl sifatida boradi',
  captionHint: 'Izoh qo‘shish…',
  removeFile: 'Olib tashlash',
  info: 'Ma’lumot',
  closePanel: 'Panelni yopish',
  phone: 'Telefon',
  about: 'Izoh',
  collection: 'To‘plam',
  newCollection: '+ Yangi',
  fromThisChat: 'Shu chatdan',
  tasks: 'Vazifalar',
  meetings: 'Uchrashuvlar',
  notes: 'Eslatmalar',
  files: 'Fayllar',
  chat: 'Chat',
  openChat: 'Chatni ochish',
  meetingTitle: (chat) => 'Uchrashuv: $chat',
  savedMessages: 'Saqlangan xabarlar',
  statusCloud: 'shaxsiy bulut',
  statusBot: 'bot',
  statusChannel: 'kanal',
  statusGroup: 'guruh',
  subscribers: (n, count) => '$count obunachi',
  members: (n, count) => '$count a’zo',
  deletedAccount: 'o‘chirilgan akkaunt',
  online: 'online',
  lastSeenRecently: 'yaqinda onlayn edi',
  lastSeenWeek: 'shu hafta onlayn edi',
  lastSeenMonth: 'shu oy onlayn edi',
  lastSeenLongAgo: 'uzoq vaqt oldin onlayn edi',
  youPrefix: 'Siz: ',
  photo: 'Rasm',
  video: 'Video',
  sticker: 'Stiker',
  voiceMessage: 'Ovozli xabar',
  videoMessage: 'Video xabar',
  audio: 'Audio',
  location: 'Joylashuv',
  venue: (t) => 'Joy: $t',
  contact: 'Kontakt',
  poll: (q) => 'So‘rovnoma: $q',
  callMessage: 'Qo‘ng‘iroq',
  story: 'Hikoya',
  message: 'Xabar',
  unsupportedMessage: 'Bu xabar turi Focusda ko‘rsatilmaydi. Uni Telegramda oching.',
  paidMedia: 'Pullik media',
  invoice: 'To‘lov',
  giveaway: 'Sovg‘a o‘yini',
  videoChatStarted: 'video chatni boshladi',
  videoChatEnded: 'video chat tugadi',
  boostedChat: 'chatni kuchaytirdi',
  topicChanged: 'mavzuni o‘zgartirdi',
  joinedGroup: 'guruhga qo‘shildi',
  leftGroup: 'guruhdan chiqdi',
  changedGroupTitle: (t) => 'guruh nomini «$t» ga o‘zgartirdi',
  changedGroupPhoto: 'guruh rasmini o‘zgartirdi',
  deletedGroupPhoto: 'guruh rasmini o‘chirdi',
  pinnedMessage: 'xabarni qadadi',
  createdGroup: 'guruh yaratdi',
  upgradedGroup: 'guruh superguruhga aylantirildi',
  joinedTelegram: 'Telegram’ga qo‘shildi',
  setAutoDelete: 'xabarlarni avtomatik o‘chirishni sozladi',
  tookScreenshot: 'skrinshot oldi',
);

final chatsRu = ChatStrings(
  allChats: 'Все чаты',
  loadingChats: 'Загрузка чатов…',
  noChatsInFilter: 'Нет чатов в этом фильтре',
  pinned: 'Закреплён',
  hideMuted: 'Скрыть чаты без звука',
  clearFilter: 'Сбросить фильтр',
  typeFilter: 'Фильтр по типу чата',
  typePrivate: 'Личные',
  typeGroups: 'Группы',
  typeChannels: 'Каналы',
  typeBots: 'Боты',
  fileSendFailed: 'Не удалось отправить файл. Проверьте подключение к интернету и попробуйте снова.',
  messageSendFailed: 'Не удалось отправить сообщение. Проверьте подключение к интернету и попробуйте снова.',
  actionTyping: 'печатает…',
  actionVoice: 'записывает голосовое…',
  actionVideo: 'записывает видео…',
  actionFile: 'отправляет файл…',
  actionSticker: 'выбирает стикер…',
  copyMessage: 'Копировать',
  copied: 'Скопировано',
  editMessage: 'Изменить',
  deleteMessage: 'Удалить',
  editing: 'Редактирование',
  cancelEdit: 'Отменить редактирование (Esc)',
  edited: 'изменено',
  deleteTitle: 'Удалить сообщение?',
  deleteForBoth: (name) => 'Также удалить для $name',
  deleteForAll: 'Удалить для всех',
  editFailed: 'Не удалось изменить сообщение. Проверьте подключение к интернету и попробуйте снова.',
  deleteFailed: 'Не удалось удалить сообщение. Проверьте подключение к интернету и попробуйте снова.',
  pinChat: 'Закрепить',
  unpinChat: 'Открепить',
  pinLimit: 'Достигнут лимит закреплённых чатов в Telegram. Сначала открепите другой чат.',
  pinFailed: 'Не удалось закрепить. Проверьте подключение к интернету и попробуйте снова.',
  addedToCalendar: (m) => 'Добавлено в календарь: $m',
  openCalendar: 'Открыть календарь',
  callsOnPhone: 'Звонки остаются в приложении на телефоне',
  selectedMessage: 'Выбранное сообщение',
  lastMessageHint: 'Последнее сообщение · нажмите на сообщение, чтобы выбрать другое',
  messageLower: 'сообщение',
  taskCreated: (w) => 'Задача создана: «$w»',
  goToTasks: 'К задачам',
  savedToNotes: (w) => 'Сохранено в заметки: «$w»',
  openNotes: 'Открыть заметки',
  noMessages: 'Здесь пока нет сообщений',
  dropFiles: 'Перетащите файлы сюда',
  dropFilesHint: 'Перед отправкой вы сможете их просмотреть',
  noRecentEmoji: 'Нет недавних эмодзи',
  emojiSearch: 'Поиск',
  call: 'Позвонить',
  infoPanel: 'Информация',
  toTask: 'В задачи',
  toCalendar: 'В календарь',
  toNote: 'В заметки',
  toFiles: 'В файлы',
  savedToFiles: (w) => '«$w» сохранено в Файлы',
  alreadyInFiles: 'Это сообщение уже в Файлах',
  openFiles: 'Файлы',
  saveToFiles: 'Сохранить в Файлы',
  meetingFound: 'Найдена встреча: ',
  messageHint: 'Написать сообщение…',
  attachFile: 'Прикрепить файл',
  closeEmoji: 'Скрыть эмодзи',
  emoji: 'Эмодзи',
  tickFailed: 'Не отправлено',
  tickSending: 'Отправляется',
  tickRead: 'Прочитано',
  tickSent: 'Отправлено',
  selectChat: 'Выберите чат',
  channelReadOnly: 'Канал · только чтение',
  groupNoRights: 'У вас нет прав писать в эту группу',
  openFileTitle: 'Открыть файл?',
  riskyFile: (name) => '«$name» может быть программой или скриптом. Не открывайте его, если не уверены в нём: '
      'он может навредить компьютеру.',
  openAnyway: 'Всё равно открыть',
  cantOpenFile: 'Не удалось открыть файл',
  savedAs: (name) => 'Сохранено: $name',
  cantSaveFile: 'Не удалось сохранить файл',
  showInFolder: 'Показать в папке',
  saveAs: 'Сохранить как…',
  openLinkTitle: 'Открыть ссылку?',
  pause: 'Пауза',
  play: 'Прослушать',
  closeEsc: 'Закрыть (Esc)',
  sendPhoto: 'Отправить фото',
  sendFile: 'Отправить файл',
  sendFiles: (n) => 'Отправить $n ${ruPlural(n, 'файл', 'файла', 'файлов')}',
  noFileSelected: 'Файлы не выбраны',
  addMore: 'Добавить ещё',
  compressImages: 'Сжать изображения',
  compressOn: 'Как фото, альбомом',
  compressOff: 'Как файлы, в исходном качестве',
  captionHint: 'Добавить подпись…',
  removeFile: 'Убрать',
  info: 'Информация',
  closePanel: 'Закрыть панель',
  phone: 'Телефон',
  about: 'Описание',
  collection: 'Коллекция',
  newCollection: '+ Новая',
  fromThisChat: 'Из этого чата',
  tasks: 'Задачи',
  meetings: 'Встречи',
  notes: 'Заметки',
  files: 'Файлы',
  chat: 'Чат',
  openChat: 'Открыть чат',
  meetingTitle: (chat) => 'Встреча: $chat',
  savedMessages: 'Избранное',
  statusCloud: 'личное облако',
  statusBot: 'бот',
  statusChannel: 'канал',
  statusGroup: 'группа',
  subscribers: (n, count) => '$count ${ruPlural(n, 'подписчик', 'подписчика', 'подписчиков')}',
  members: (n, count) => '$count ${ruPlural(n, 'участник', 'участника', 'участников')}',
  deletedAccount: 'удалённый аккаунт',
  online: 'в сети',
  lastSeenRecently: 'был(а) недавно',
  lastSeenWeek: 'был(а) на этой неделе',
  lastSeenMonth: 'был(а) в этом месяце',
  lastSeenLongAgo: 'был(а) давно',
  youPrefix: 'Вы: ',
  photo: 'Фотография',
  video: 'Видео',
  sticker: 'Стикер',
  voiceMessage: 'Голосовое сообщение',
  videoMessage: 'Видеосообщение',
  audio: 'Аудио',
  location: 'Геопозиция',
  venue: (t) => 'Место: $t',
  contact: 'Контакт',
  poll: (q) => 'Опрос: $q',
  callMessage: 'Звонок',
  story: 'История',
  message: 'Сообщение',
  unsupportedMessage: 'Этот тип сообщения не отображается в Focus. Откройте его в Telegram.',
  paidMedia: 'Платные медиа',
  invoice: 'Счёт',
  giveaway: 'Розыгрыш',
  videoChatStarted: 'начал(а) видеочат',
  videoChatEnded: 'видеочат завершён',
  boostedChat: 'усилил(а) чат',
  topicChanged: 'изменил(а) тему',
  joinedGroup: 'вступил(а) в группу',
  leftGroup: 'покинул(а) группу',
  changedGroupTitle: (t) => 'изменил(а) название группы на «$t»',
  changedGroupPhoto: 'изменил(а) фото группы',
  deletedGroupPhoto: 'удалил(а) фото группы',
  pinnedMessage: 'закрепил(а) сообщение',
  createdGroup: 'создал(а) группу',
  upgradedGroup: 'преобразовал(а) группу в супергруппу',
  joinedTelegram: 'теперь в Telegram',
  setAutoDelete: 'настроил(а) автоудаление сообщений',
  tookScreenshot: 'сделал(а) скриншот',
);

final chatsEn = ChatStrings(
  allChats: 'All chats',
  loadingChats: 'Loading chats…',
  noChatsInFilter: 'No chats in this filter',
  pinned: 'Pinned',
  hideMuted: 'Hide muted chats',
  clearFilter: 'Clear filter',
  typeFilter: 'Filter by chat type',
  typePrivate: 'Personal',
  typeGroups: 'Groups',
  typeChannels: 'Channels',
  typeBots: 'Bots',
  fileSendFailed: 'Couldn’t send the file. Check your internet connection and try again.',
  messageSendFailed: 'Couldn’t send the message. Check your internet connection and try again.',
  actionTyping: 'typing…',
  actionVoice: 'recording a voice message…',
  actionVideo: 'recording a video…',
  actionFile: 'sending a file…',
  actionSticker: 'choosing a sticker…',
  copyMessage: 'Copy',
  copied: 'Copied',
  editMessage: 'Edit',
  deleteMessage: 'Delete',
  editing: 'Editing',
  cancelEdit: 'Cancel editing (Esc)',
  edited: 'edited',
  deleteTitle: 'Delete the message?',
  deleteForBoth: (name) => 'Also delete for $name',
  deleteForAll: 'Delete for everyone',
  editFailed: 'Couldn’t edit the message. Check your internet connection and try again.',
  deleteFailed: 'Couldn’t delete the message. Check your internet connection and try again.',
  pinChat: 'Pin',
  unpinChat: 'Unpin',
  pinLimit: 'Telegram’s pinned chat limit is reached. Unpin another chat first.',
  pinFailed: 'Couldn’t pin the chat. Check your internet connection and try again.',
  addedToCalendar: (m) => 'Added to calendar: $m',
  openCalendar: 'Open calendar',
  callsOnPhone: 'Calls stay in the phone app',
  selectedMessage: 'Selected message',
  lastMessageHint: 'Last message · click a message to pick another',
  messageLower: 'message',
  taskCreated: (w) => 'Task created: “$w”',
  goToTasks: 'Go to tasks',
  savedToNotes: (w) => 'Saved to notes: “$w”',
  openNotes: 'Open notes',
  noMessages: 'No messages here yet',
  dropFiles: 'Drop files here',
  dropFilesHint: 'You can review them before sending',
  noRecentEmoji: 'No recent emoji',
  emojiSearch: 'Search',
  call: 'Call',
  infoPanel: 'Info panel',
  toTask: 'Make task',
  toCalendar: 'To calendar',
  toNote: 'To notes',
  toFiles: 'To Files',
  savedToFiles: (w) => '“$w” saved to Files',
  alreadyInFiles: 'This message is already in Files',
  openFiles: 'Files',
  saveToFiles: 'Save to Files',
  meetingFound: 'Meeting found: ',
  messageHint: 'Write a message…',
  attachFile: 'Attach file',
  closeEmoji: 'Close emoji',
  emoji: 'Emoji',
  tickFailed: 'Not sent',
  tickSending: 'Sending',
  tickRead: 'Read',
  tickSent: 'Sent',
  selectChat: 'Select a chat to start messaging',
  channelReadOnly: 'Channel · read only',
  groupNoRights: 'You can’t send messages in this group',
  openFileTitle: 'Open this file?',
  riskyFile: (name) => '“$name” may be a program or a script. Don’t open it unless you trust it: '
      'it could harm your computer.',
  openAnyway: 'Open anyway',
  cantOpenFile: 'Couldn’t open the file',
  savedAs: (name) => 'Saved: $name',
  cantSaveFile: 'Couldn’t save the file',
  showInFolder: 'Show in folder',
  saveAs: 'Save as…',
  openLinkTitle: 'Open this link?',
  pause: 'Pause',
  play: 'Play',
  closeEsc: 'Close (Esc)',
  sendPhoto: 'Send photo',
  sendFile: 'Send file',
  sendFiles: (n) => 'Send $n ${enPlural(n, 'file', 'files')}',
  noFileSelected: 'No files selected',
  addMore: 'Add more',
  compressImages: 'Compress images',
  compressOn: 'As photos, grouped in an album',
  compressOff: 'As files, in original quality',
  captionHint: 'Add a caption…',
  removeFile: 'Remove',
  info: 'Info',
  closePanel: 'Close panel',
  phone: 'Phone',
  about: 'About',
  collection: 'Collection',
  newCollection: '+ New',
  fromThisChat: 'From this chat',
  tasks: 'Tasks',
  meetings: 'Meetings',
  notes: 'Notes',
  files: 'Files',
  chat: 'Chat',
  openChat: 'Open chat',
  meetingTitle: (chat) => 'Meeting: $chat',
  savedMessages: 'Saved Messages',
  statusCloud: 'personal cloud',
  statusBot: 'bot',
  statusChannel: 'channel',
  statusGroup: 'group',
  subscribers: (n, count) => '$count ${enPlural(n, 'subscriber', 'subscribers')}',
  members: (n, count) => '$count ${enPlural(n, 'member', 'members')}',
  deletedAccount: 'deleted account',
  online: 'online',
  lastSeenRecently: 'last seen recently',
  lastSeenWeek: 'last seen within a week',
  lastSeenMonth: 'last seen within a month',
  lastSeenLongAgo: 'last seen a long time ago',
  youPrefix: 'You: ',
  photo: 'Photo',
  video: 'Video',
  sticker: 'Sticker',
  voiceMessage: 'Voice message',
  videoMessage: 'Video message',
  audio: 'Audio',
  location: 'Location',
  venue: (t) => 'Venue: $t',
  contact: 'Contact',
  poll: (q) => 'Poll: $q',
  callMessage: 'Call',
  story: 'Story',
  message: 'Message',
  unsupportedMessage: 'Focus cannot show this kind of message. Open it in Telegram.',
  paidMedia: 'Paid media',
  invoice: 'Invoice',
  giveaway: 'Giveaway',
  videoChatStarted: 'started a video chat',
  videoChatEnded: 'video chat ended',
  boostedChat: 'boosted the chat',
  topicChanged: 'changed the topic',
  joinedGroup: 'joined the group',
  leftGroup: 'left the group',
  changedGroupTitle: (t) => 'changed the group name to “$t”',
  changedGroupPhoto: 'changed the group photo',
  deletedGroupPhoto: 'removed the group photo',
  pinnedMessage: 'pinned a message',
  createdGroup: 'created the group',
  upgradedGroup: 'upgraded the group to a supergroup',
  joinedTelegram: 'joined Telegram',
  setAutoDelete: 'set messages to auto-delete',
  tookScreenshot: 'took a screenshot',
);
