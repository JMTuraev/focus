// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<TaskStatus, String> status =
      GeneratedColumn<String>('status', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<TaskStatus>($TasksTable.$converterstatus);
  static const VerificationMeta _importantMeta =
      const VerificationMeta('important');
  @override
  late final GeneratedColumn<bool> important = GeneratedColumn<bool>(
      'important', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("important" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
      'due', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<double> position = GeneratedColumn<double>(
      'position', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chatTitleMeta =
      const VerificationMeta('chatTitle');
  @override
  late final GeneratedColumn<String> chatTitle = GeneratedColumn<String>(
      'chat_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageTextMeta =
      const VerificationMeta('messageText');
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
      'message_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        note,
        status,
        important,
        due,
        position,
        chatId,
        chatTitle,
        messageId,
        messageText,
        createdAt,
        updatedAt,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<Task> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('important')) {
      context.handle(_importantMeta,
          important.isAcceptableOrUnknown(data['important']!, _importantMeta));
    }
    if (data.containsKey('due')) {
      context.handle(
          _dueMeta, due.isAcceptableOrUnknown(data['due']!, _dueMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    }
    if (data.containsKey('chat_title')) {
      context.handle(_chatTitleMeta,
          chatTitle.isAcceptableOrUnknown(data['chat_title']!, _chatTitleMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    }
    if (data.containsKey('message_text')) {
      context.handle(
          _messageTextMeta,
          messageText.isAcceptableOrUnknown(
              data['message_text']!, _messageTextMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      status: $TasksTable.$converterstatus.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!),
      important: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}important'])!,
      due: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due']),
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}position'])!,
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id']),
      chatTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_title']),
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id']),
      messageText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_text']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskStatus, String, String> $converterstatus =
      const EnumNameConverter<TaskStatus>(TaskStatus.values);
}

class Task extends DataClass implements Insertable<Task> {
  final int id;
  final String title;
  final String note;
  final TaskStatus status;
  final bool important;

  /// Due day (local midnight); null = no deadline.
  final DateTime? due;

  /// Order inside a column (smaller first).
  final double position;

  /// Where the task came from (Telegram chat id, title and message).
  final String? chatId;
  final String? chatTitle;
  final String? messageId;
  final String? messageText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  const Task(
      {required this.id,
      required this.title,
      required this.note,
      required this.status,
      required this.important,
      this.due,
      required this.position,
      this.chatId,
      this.chatTitle,
      this.messageId,
      this.messageText,
      required this.createdAt,
      required this.updatedAt,
      this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['note'] = Variable<String>(note);
    {
      map['status'] =
          Variable<String>($TasksTable.$converterstatus.toSql(status));
    }
    map['important'] = Variable<bool>(important);
    if (!nullToAbsent || due != null) {
      map['due'] = Variable<DateTime>(due);
    }
    map['position'] = Variable<double>(position);
    if (!nullToAbsent || chatId != null) {
      map['chat_id'] = Variable<String>(chatId);
    }
    if (!nullToAbsent || chatTitle != null) {
      map['chat_title'] = Variable<String>(chatTitle);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || messageText != null) {
      map['message_text'] = Variable<String>(messageText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      note: Value(note),
      status: Value(status),
      important: Value(important),
      due: due == null && nullToAbsent ? const Value.absent() : Value(due),
      position: Value(position),
      chatId:
          chatId == null && nullToAbsent ? const Value.absent() : Value(chatId),
      chatTitle: chatTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(chatTitle),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      messageText: messageText == null && nullToAbsent
          ? const Value.absent()
          : Value(messageText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory Task.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String>(json['note']),
      status: $TasksTable.$converterstatus
          .fromJson(serializer.fromJson<String>(json['status'])),
      important: serializer.fromJson<bool>(json['important']),
      due: serializer.fromJson<DateTime?>(json['due']),
      position: serializer.fromJson<double>(json['position']),
      chatId: serializer.fromJson<String?>(json['chatId']),
      chatTitle: serializer.fromJson<String?>(json['chatTitle']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      messageText: serializer.fromJson<String?>(json['messageText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String>(note),
      'status': serializer
          .toJson<String>($TasksTable.$converterstatus.toJson(status)),
      'important': serializer.toJson<bool>(important),
      'due': serializer.toJson<DateTime?>(due),
      'position': serializer.toJson<double>(position),
      'chatId': serializer.toJson<String?>(chatId),
      'chatTitle': serializer.toJson<String?>(chatTitle),
      'messageId': serializer.toJson<String?>(messageId),
      'messageText': serializer.toJson<String?>(messageText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  Task copyWith(
          {int? id,
          String? title,
          String? note,
          TaskStatus? status,
          bool? important,
          Value<DateTime?> due = const Value.absent(),
          double? position,
          Value<String?> chatId = const Value.absent(),
          Value<String?> chatTitle = const Value.absent(),
          Value<String?> messageId = const Value.absent(),
          Value<String?> messageText = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt,
          Value<DateTime?> completedAt = const Value.absent()}) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        note: note ?? this.note,
        status: status ?? this.status,
        important: important ?? this.important,
        due: due.present ? due.value : this.due,
        position: position ?? this.position,
        chatId: chatId.present ? chatId.value : this.chatId,
        chatTitle: chatTitle.present ? chatTitle.value : this.chatTitle,
        messageId: messageId.present ? messageId.value : this.messageId,
        messageText: messageText.present ? messageText.value : this.messageText,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
      );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      status: data.status.present ? data.status.value : this.status,
      important: data.important.present ? data.important.value : this.important,
      due: data.due.present ? data.due.value : this.due,
      position: data.position.present ? data.position.value : this.position,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      chatTitle: data.chatTitle.present ? data.chatTitle.value : this.chatTitle,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      messageText:
          data.messageText.present ? data.messageText.value : this.messageText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('important: $important, ')
          ..write('due: $due, ')
          ..write('position: $position, ')
          ..write('chatId: $chatId, ')
          ..write('chatTitle: $chatTitle, ')
          ..write('messageId: $messageId, ')
          ..write('messageText: $messageText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      note,
      status,
      important,
      due,
      position,
      chatId,
      chatTitle,
      messageId,
      messageText,
      createdAt,
      updatedAt,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.status == this.status &&
          other.important == this.important &&
          other.due == this.due &&
          other.position == this.position &&
          other.chatId == this.chatId &&
          other.chatTitle == this.chatTitle &&
          other.messageId == this.messageId &&
          other.messageText == this.messageText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.completedAt == this.completedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> note;
  final Value<TaskStatus> status;
  final Value<bool> important;
  final Value<DateTime?> due;
  final Value<double> position;
  final Value<String?> chatId;
  final Value<String?> chatTitle;
  final Value<String?> messageId;
  final Value<String?> messageText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> completedAt;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.status = const Value.absent(),
    this.important = const Value.absent(),
    this.due = const Value.absent(),
    this.position = const Value.absent(),
    this.chatId = const Value.absent(),
    this.chatTitle = const Value.absent(),
    this.messageId = const Value.absent(),
    this.messageText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
  });
  TasksCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    required TaskStatus status,
    this.important = const Value.absent(),
    this.due = const Value.absent(),
    this.position = const Value.absent(),
    this.chatId = const Value.absent(),
    this.chatTitle = const Value.absent(),
    this.messageId = const Value.absent(),
    this.messageText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.completedAt = const Value.absent(),
  })  : title = Value(title),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? status,
    Expression<bool>? important,
    Expression<DateTime>? due,
    Expression<double>? position,
    Expression<String>? chatId,
    Expression<String>? chatTitle,
    Expression<String>? messageId,
    Expression<String>? messageText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? completedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (status != null) 'status': status,
      if (important != null) 'important': important,
      if (due != null) 'due': due,
      if (position != null) 'position': position,
      if (chatId != null) 'chat_id': chatId,
      if (chatTitle != null) 'chat_title': chatTitle,
      if (messageId != null) 'message_id': messageId,
      if (messageText != null) 'message_text': messageText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (completedAt != null) 'completed_at': completedAt,
    });
  }

  TasksCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? note,
      Value<TaskStatus>? status,
      Value<bool>? important,
      Value<DateTime?>? due,
      Value<double>? position,
      Value<String?>? chatId,
      Value<String?>? chatTitle,
      Value<String?>? messageId,
      Value<String?>? messageText,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<DateTime?>? completedAt}) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      status: status ?? this.status,
      important: important ?? this.important,
      due: due ?? this.due,
      position: position ?? this.position,
      chatId: chatId ?? this.chatId,
      chatTitle: chatTitle ?? this.chatTitle,
      messageId: messageId ?? this.messageId,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (status.present) {
      map['status'] =
          Variable<String>($TasksTable.$converterstatus.toSql(status.value));
    }
    if (important.present) {
      map['important'] = Variable<bool>(important.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (position.present) {
      map['position'] = Variable<double>(position.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (chatTitle.present) {
      map['chat_title'] = Variable<String>(chatTitle.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (messageText.present) {
      map['message_text'] = Variable<String>(messageText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('status: $status, ')
          ..write('important: $important, ')
          ..write('due: $due, ')
          ..write('position: $position, ')
          ..write('chatId: $chatId, ')
          ..write('chatTitle: $chatTitle, ')
          ..write('messageId: $messageId, ')
          ..write('messageText: $messageText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
      'start', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endMeta = const VerificationMeta('end');
  @override
  late final GeneratedColumn<DateTime> end = GeneratedColumn<DateTime>(
      'end', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
      'all_day', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("all_day" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _remindBeforeMeta =
      const VerificationMeta('remindBefore');
  @override
  late final GeneratedColumn<int> remindBefore = GeneratedColumn<int>(
      'remind_before', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chatTitleMeta =
      const VerificationMeta('chatTitle');
  @override
  late final GeneratedColumn<String> chatTitle = GeneratedColumn<String>(
      'chat_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageTextMeta =
      const VerificationMeta('messageText');
  @override
  late final GeneratedColumn<String> messageText = GeneratedColumn<String>(
      'message_text', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        note,
        start,
        end,
        allDay,
        remindBefore,
        chatId,
        chatTitle,
        messageId,
        messageText,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('start')) {
      context.handle(
          _startMeta, start.isAcceptableOrUnknown(data['start']!, _startMeta));
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('end')) {
      context.handle(
          _endMeta, end.isAcceptableOrUnknown(data['end']!, _endMeta));
    } else if (isInserting) {
      context.missing(_endMeta);
    }
    if (data.containsKey('all_day')) {
      context.handle(_allDayMeta,
          allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta));
    }
    if (data.containsKey('remind_before')) {
      context.handle(
          _remindBeforeMeta,
          remindBefore.isAcceptableOrUnknown(
              data['remind_before']!, _remindBeforeMeta));
    }
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    }
    if (data.containsKey('chat_title')) {
      context.handle(_chatTitleMeta,
          chatTitle.isAcceptableOrUnknown(data['chat_title']!, _chatTitleMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    }
    if (data.containsKey('message_text')) {
      context.handle(
          _messageTextMeta,
          messageText.isAcceptableOrUnknown(
              data['message_text']!, _messageTextMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      start: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start'])!,
      end: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end'])!,
      allDay: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}all_day'])!,
      remindBefore: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remind_before']),
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id']),
      chatTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_title']),
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id']),
      messageText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_text']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final int id;
  final String title;
  final String note;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  /// Minutes before [start] to remind; null = no reminder.
  final int? remindBefore;
  final String? chatId;
  final String? chatTitle;
  final String? messageId;
  final String? messageText;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Event(
      {required this.id,
      required this.title,
      required this.note,
      required this.start,
      required this.end,
      required this.allDay,
      this.remindBefore,
      this.chatId,
      this.chatTitle,
      this.messageId,
      this.messageText,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['note'] = Variable<String>(note);
    map['start'] = Variable<DateTime>(start);
    map['end'] = Variable<DateTime>(end);
    map['all_day'] = Variable<bool>(allDay);
    if (!nullToAbsent || remindBefore != null) {
      map['remind_before'] = Variable<int>(remindBefore);
    }
    if (!nullToAbsent || chatId != null) {
      map['chat_id'] = Variable<String>(chatId);
    }
    if (!nullToAbsent || chatTitle != null) {
      map['chat_title'] = Variable<String>(chatTitle);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    if (!nullToAbsent || messageText != null) {
      map['message_text'] = Variable<String>(messageText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      title: Value(title),
      note: Value(note),
      start: Value(start),
      end: Value(end),
      allDay: Value(allDay),
      remindBefore: remindBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(remindBefore),
      chatId:
          chatId == null && nullToAbsent ? const Value.absent() : Value(chatId),
      chatTitle: chatTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(chatTitle),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      messageText: messageText == null && nullToAbsent
          ? const Value.absent()
          : Value(messageText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String>(json['note']),
      start: serializer.fromJson<DateTime>(json['start']),
      end: serializer.fromJson<DateTime>(json['end']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      remindBefore: serializer.fromJson<int?>(json['remindBefore']),
      chatId: serializer.fromJson<String?>(json['chatId']),
      chatTitle: serializer.fromJson<String?>(json['chatTitle']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      messageText: serializer.fromJson<String?>(json['messageText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String>(note),
      'start': serializer.toJson<DateTime>(start),
      'end': serializer.toJson<DateTime>(end),
      'allDay': serializer.toJson<bool>(allDay),
      'remindBefore': serializer.toJson<int?>(remindBefore),
      'chatId': serializer.toJson<String?>(chatId),
      'chatTitle': serializer.toJson<String?>(chatTitle),
      'messageId': serializer.toJson<String?>(messageId),
      'messageText': serializer.toJson<String?>(messageText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Event copyWith(
          {int? id,
          String? title,
          String? note,
          DateTime? start,
          DateTime? end,
          bool? allDay,
          Value<int?> remindBefore = const Value.absent(),
          Value<String?> chatId = const Value.absent(),
          Value<String?> chatTitle = const Value.absent(),
          Value<String?> messageId = const Value.absent(),
          Value<String?> messageText = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Event(
        id: id ?? this.id,
        title: title ?? this.title,
        note: note ?? this.note,
        start: start ?? this.start,
        end: end ?? this.end,
        allDay: allDay ?? this.allDay,
        remindBefore:
            remindBefore.present ? remindBefore.value : this.remindBefore,
        chatId: chatId.present ? chatId.value : this.chatId,
        chatTitle: chatTitle.present ? chatTitle.value : this.chatTitle,
        messageId: messageId.present ? messageId.value : this.messageId,
        messageText: messageText.present ? messageText.value : this.messageText,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      start: data.start.present ? data.start.value : this.start,
      end: data.end.present ? data.end.value : this.end,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      remindBefore: data.remindBefore.present
          ? data.remindBefore.value
          : this.remindBefore,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      chatTitle: data.chatTitle.present ? data.chatTitle.value : this.chatTitle,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      messageText:
          data.messageText.present ? data.messageText.value : this.messageText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('allDay: $allDay, ')
          ..write('remindBefore: $remindBefore, ')
          ..write('chatId: $chatId, ')
          ..write('chatTitle: $chatTitle, ')
          ..write('messageId: $messageId, ')
          ..write('messageText: $messageText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      note,
      start,
      end,
      allDay,
      remindBefore,
      chatId,
      chatTitle,
      messageId,
      messageText,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.start == this.start &&
          other.end == this.end &&
          other.allDay == this.allDay &&
          other.remindBefore == this.remindBefore &&
          other.chatId == this.chatId &&
          other.chatTitle == this.chatTitle &&
          other.messageId == this.messageId &&
          other.messageText == this.messageText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> note;
  final Value<DateTime> start;
  final Value<DateTime> end;
  final Value<bool> allDay;
  final Value<int?> remindBefore;
  final Value<String?> chatId;
  final Value<String?> chatTitle;
  final Value<String?> messageId;
  final Value<String?> messageText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.start = const Value.absent(),
    this.end = const Value.absent(),
    this.allDay = const Value.absent(),
    this.remindBefore = const Value.absent(),
    this.chatId = const Value.absent(),
    this.chatTitle = const Value.absent(),
    this.messageId = const Value.absent(),
    this.messageText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EventsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.note = const Value.absent(),
    required DateTime start,
    required DateTime end,
    this.allDay = const Value.absent(),
    this.remindBefore = const Value.absent(),
    this.chatId = const Value.absent(),
    this.chatTitle = const Value.absent(),
    this.messageId = const Value.absent(),
    this.messageText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : title = Value(title),
        start = Value(start),
        end = Value(end),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Event> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<DateTime>? start,
    Expression<DateTime>? end,
    Expression<bool>? allDay,
    Expression<int>? remindBefore,
    Expression<String>? chatId,
    Expression<String>? chatTitle,
    Expression<String>? messageId,
    Expression<String>? messageText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (start != null) 'start': start,
      if (end != null) 'end': end,
      if (allDay != null) 'all_day': allDay,
      if (remindBefore != null) 'remind_before': remindBefore,
      if (chatId != null) 'chat_id': chatId,
      if (chatTitle != null) 'chat_title': chatTitle,
      if (messageId != null) 'message_id': messageId,
      if (messageText != null) 'message_text': messageText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EventsCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? note,
      Value<DateTime>? start,
      Value<DateTime>? end,
      Value<bool>? allDay,
      Value<int?>? remindBefore,
      Value<String?>? chatId,
      Value<String?>? chatTitle,
      Value<String?>? messageId,
      Value<String?>? messageText,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return EventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      start: start ?? this.start,
      end: end ?? this.end,
      allDay: allDay ?? this.allDay,
      remindBefore: remindBefore ?? this.remindBefore,
      chatId: chatId ?? this.chatId,
      chatTitle: chatTitle ?? this.chatTitle,
      messageId: messageId ?? this.messageId,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (end.present) {
      map['end'] = Variable<DateTime>(end.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (remindBefore.present) {
      map['remind_before'] = Variable<int>(remindBefore.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (chatTitle.present) {
      map['chat_title'] = Variable<String>(chatTitle.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (messageText.present) {
      map['message_text'] = Variable<String>(messageText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('start: $start, ')
          ..write('end: $end, ')
          ..write('allDay: $allDay, ')
          ..write('remindBefore: $remindBefore, ')
          ..write('chatId: $chatId, ')
          ..write('chatTitle: $chatTitle, ')
          ..write('messageId: $messageId, ')
          ..write('messageText: $messageText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NotesTable extends Notes with TableInfo<$NotesTable, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  late final GeneratedColumnWithTypeConverter<List<NoteItem>, String> items =
      GeneratedColumn<String>('items', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<NoteItem>>($NotesTable.$converteritems);
  static const VerificationMeta _checklistMeta =
      const VerificationMeta('checklist');
  @override
  late final GeneratedColumn<bool> checklist = GeneratedColumn<bool>(
      'checklist', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("checklist" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  late final GeneratedColumnWithTypeConverter<NoteColor, String> color =
      GeneratedColumn<String>('color', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: Constant(NoteColor.none.name))
          .withConverter<NoteColor>($NotesTable.$convertercolor);
  static const VerificationMeta _pinnedMeta = const VerificationMeta('pinned');
  @override
  late final GeneratedColumn<bool> pinned = GeneratedColumn<bool>(
      'pinned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("pinned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _chatTitleMeta =
      const VerificationMeta('chatTitle');
  @override
  late final GeneratedColumn<String> chatTitle = GeneratedColumn<String>(
      'chat_title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        body,
        items,
        checklist,
        color,
        pinned,
        chatId,
        chatTitle,
        messageId,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(Insertable<Note> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('checklist')) {
      context.handle(_checklistMeta,
          checklist.isAcceptableOrUnknown(data['checklist']!, _checklistMeta));
    }
    if (data.containsKey('pinned')) {
      context.handle(_pinnedMeta,
          pinned.isAcceptableOrUnknown(data['pinned']!, _pinnedMeta));
    }
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    }
    if (data.containsKey('chat_title')) {
      context.handle(_chatTitleMeta,
          chatTitle.isAcceptableOrUnknown(data['chat_title']!, _chatTitleMeta));
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      items: $NotesTable.$converteritems.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}items'])!),
      checklist: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}checklist'])!,
      color: $NotesTable.$convertercolor.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!),
      pinned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}pinned'])!,
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id']),
      chatTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_title']),
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $NotesTable createAlias(String alias) {
    return $NotesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<NoteItem>, String> $converteritems =
      const NoteItemsConverter();
  static JsonTypeConverter2<NoteColor, String, String> $convertercolor =
      const EnumNameConverter<NoteColor>(NoteColor.values);
}

class Note extends DataClass implements Insertable<Note> {
  final int id;
  final String title;
  final String body;
  final List<NoteItem> items;
  final bool checklist;
  final NoteColor color;
  final bool pinned;
  final String? chatId;
  final String? chatTitle;
  final String? messageId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Note(
      {required this.id,
      required this.title,
      required this.body,
      required this.items,
      required this.checklist,
      required this.color,
      required this.pinned,
      this.chatId,
      this.chatTitle,
      this.messageId,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    {
      map['items'] = Variable<String>($NotesTable.$converteritems.toSql(items));
    }
    map['checklist'] = Variable<bool>(checklist);
    {
      map['color'] = Variable<String>($NotesTable.$convertercolor.toSql(color));
    }
    map['pinned'] = Variable<bool>(pinned);
    if (!nullToAbsent || chatId != null) {
      map['chat_id'] = Variable<String>(chatId);
    }
    if (!nullToAbsent || chatTitle != null) {
      map['chat_title'] = Variable<String>(chatTitle);
    }
    if (!nullToAbsent || messageId != null) {
      map['message_id'] = Variable<String>(messageId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      items: Value(items),
      checklist: Value(checklist),
      color: Value(color),
      pinned: Value(pinned),
      chatId:
          chatId == null && nullToAbsent ? const Value.absent() : Value(chatId),
      chatTitle: chatTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(chatTitle),
      messageId: messageId == null && nullToAbsent
          ? const Value.absent()
          : Value(messageId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Note.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      items: serializer.fromJson<List<NoteItem>>(json['items']),
      checklist: serializer.fromJson<bool>(json['checklist']),
      color: $NotesTable.$convertercolor
          .fromJson(serializer.fromJson<String>(json['color'])),
      pinned: serializer.fromJson<bool>(json['pinned']),
      chatId: serializer.fromJson<String?>(json['chatId']),
      chatTitle: serializer.fromJson<String?>(json['chatTitle']),
      messageId: serializer.fromJson<String?>(json['messageId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'items': serializer.toJson<List<NoteItem>>(items),
      'checklist': serializer.toJson<bool>(checklist),
      'color':
          serializer.toJson<String>($NotesTable.$convertercolor.toJson(color)),
      'pinned': serializer.toJson<bool>(pinned),
      'chatId': serializer.toJson<String?>(chatId),
      'chatTitle': serializer.toJson<String?>(chatTitle),
      'messageId': serializer.toJson<String?>(messageId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Note copyWith(
          {int? id,
          String? title,
          String? body,
          List<NoteItem>? items,
          bool? checklist,
          NoteColor? color,
          bool? pinned,
          Value<String?> chatId = const Value.absent(),
          Value<String?> chatTitle = const Value.absent(),
          Value<String?> messageId = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        items: items ?? this.items,
        checklist: checklist ?? this.checklist,
        color: color ?? this.color,
        pinned: pinned ?? this.pinned,
        chatId: chatId.present ? chatId.value : this.chatId,
        chatTitle: chatTitle.present ? chatTitle.value : this.chatTitle,
        messageId: messageId.present ? messageId.value : this.messageId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      items: data.items.present ? data.items.value : this.items,
      checklist: data.checklist.present ? data.checklist.value : this.checklist,
      color: data.color.present ? data.color.value : this.color,
      pinned: data.pinned.present ? data.pinned.value : this.pinned,
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      chatTitle: data.chatTitle.present ? data.chatTitle.value : this.chatTitle,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('items: $items, ')
          ..write('checklist: $checklist, ')
          ..write('color: $color, ')
          ..write('pinned: $pinned, ')
          ..write('chatId: $chatId, ')
          ..write('chatTitle: $chatTitle, ')
          ..write('messageId: $messageId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, body, items, checklist, color,
      pinned, chatId, chatTitle, messageId, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.items == this.items &&
          other.checklist == this.checklist &&
          other.color == this.color &&
          other.pinned == this.pinned &&
          other.chatId == this.chatId &&
          other.chatTitle == this.chatTitle &&
          other.messageId == this.messageId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> body;
  final Value<List<NoteItem>> items;
  final Value<bool> checklist;
  final Value<NoteColor> color;
  final Value<bool> pinned;
  final Value<String?> chatId;
  final Value<String?> chatTitle;
  final Value<String?> messageId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const NotesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.items = const Value.absent(),
    this.checklist = const Value.absent(),
    this.color = const Value.absent(),
    this.pinned = const Value.absent(),
    this.chatId = const Value.absent(),
    this.chatTitle = const Value.absent(),
    this.messageId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotesCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.items = const Value.absent(),
    this.checklist = const Value.absent(),
    this.color = const Value.absent(),
    this.pinned = const Value.absent(),
    this.chatId = const Value.absent(),
    this.chatTitle = const Value.absent(),
    this.messageId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Note> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? items,
    Expression<bool>? checklist,
    Expression<String>? color,
    Expression<bool>? pinned,
    Expression<String>? chatId,
    Expression<String>? chatTitle,
    Expression<String>? messageId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (items != null) 'items': items,
      if (checklist != null) 'checklist': checklist,
      if (color != null) 'color': color,
      if (pinned != null) 'pinned': pinned,
      if (chatId != null) 'chat_id': chatId,
      if (chatTitle != null) 'chat_title': chatTitle,
      if (messageId != null) 'message_id': messageId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String>? body,
      Value<List<NoteItem>>? items,
      Value<bool>? checklist,
      Value<NoteColor>? color,
      Value<bool>? pinned,
      Value<String?>? chatId,
      Value<String?>? chatTitle,
      Value<String?>? messageId,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return NotesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      items: items ?? this.items,
      checklist: checklist ?? this.checklist,
      color: color ?? this.color,
      pinned: pinned ?? this.pinned,
      chatId: chatId ?? this.chatId,
      chatTitle: chatTitle ?? this.chatTitle,
      messageId: messageId ?? this.messageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (items.present) {
      map['items'] =
          Variable<String>($NotesTable.$converteritems.toSql(items.value));
    }
    if (checklist.present) {
      map['checklist'] = Variable<bool>(checklist.value);
    }
    if (color.present) {
      map['color'] =
          Variable<String>($NotesTable.$convertercolor.toSql(color.value));
    }
    if (pinned.present) {
      map['pinned'] = Variable<bool>(pinned.value);
    }
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (chatTitle.present) {
      map['chat_title'] = Variable<String>(chatTitle.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('items: $items, ')
          ..write('checklist: $checklist, ')
          ..write('color: $color, ')
          ..write('pinned: $pinned, ')
          ..write('chatId: $chatId, ')
          ..write('chatTitle: $chatTitle, ')
          ..write('messageId: $messageId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CollectionsTable extends Collections
    with TableInfo<$CollectionsTable, CollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
      'label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('folder'));
  static const VerificationMeta _positionMeta =
      const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
      'position', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [id, label, icon, position, color];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collections';
  @override
  VerificationContext validateIntegrity(Insertable<CollectionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
          _labelMeta, label.isAcceptableOrUnknown(data['label']!, _labelMeta));
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('position')) {
      context.handle(_positionMeta,
          position.isAcceptableOrUnknown(data['position']!, _positionMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      label: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}label'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      position: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color'])!,
    );
  }

  @override
  $CollectionsTable createAlias(String alias) {
    return $CollectionsTable(attachedDatabase, alias);
  }
}

class CollectionRow extends DataClass implements Insertable<CollectionRow> {
  final String id;
  final String label;
  final String icon;
  final int position;

  /// One of `kCollectionColorKeys`; '' = accent.
  final String color;
  const CollectionRow(
      {required this.id,
      required this.label,
      required this.icon,
      required this.position,
      required this.color});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['label'] = Variable<String>(label);
    map['icon'] = Variable<String>(icon);
    map['position'] = Variable<int>(position);
    map['color'] = Variable<String>(color);
    return map;
  }

  CollectionsCompanion toCompanion(bool nullToAbsent) {
    return CollectionsCompanion(
      id: Value(id),
      label: Value(label),
      icon: Value(icon),
      position: Value(position),
      color: Value(color),
    );
  }

  factory CollectionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionRow(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String>(json['label']),
      icon: serializer.fromJson<String>(json['icon']),
      position: serializer.fromJson<int>(json['position']),
      color: serializer.fromJson<String>(json['color']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String>(label),
      'icon': serializer.toJson<String>(icon),
      'position': serializer.toJson<int>(position),
      'color': serializer.toJson<String>(color),
    };
  }

  CollectionRow copyWith(
          {String? id,
          String? label,
          String? icon,
          int? position,
          String? color}) =>
      CollectionRow(
        id: id ?? this.id,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        position: position ?? this.position,
        color: color ?? this.color,
      );
  CollectionRow copyWithCompanion(CollectionsCompanion data) {
    return CollectionRow(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      icon: data.icon.present ? data.icon.value : this.icon,
      position: data.position.present ? data.position.value : this.position,
      color: data.color.present ? data.color.value : this.color,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionRow(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('icon: $icon, ')
          ..write('position: $position, ')
          ..write('color: $color')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, label, icon, position, color);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionRow &&
          other.id == this.id &&
          other.label == this.label &&
          other.icon == this.icon &&
          other.position == this.position &&
          other.color == this.color);
}

class CollectionsCompanion extends UpdateCompanion<CollectionRow> {
  final Value<String> id;
  final Value<String> label;
  final Value<String> icon;
  final Value<int> position;
  final Value<String> color;
  final Value<int> rowid;
  const CollectionsCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.icon = const Value.absent(),
    this.position = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionsCompanion.insert({
    required String id,
    required String label,
    this.icon = const Value.absent(),
    this.position = const Value.absent(),
    this.color = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        label = Value(label);
  static Insertable<CollectionRow> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? icon,
    Expression<int>? position,
    Expression<String>? color,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (icon != null) 'icon': icon,
      if (position != null) 'position': position,
      if (color != null) 'color': color,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? label,
      Value<String>? icon,
      Value<int>? position,
      Value<String>? color,
      Value<int>? rowid}) {
    return CollectionsCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      position: position ?? this.position,
      color: color ?? this.color,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionsCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('icon: $icon, ')
          ..write('position: $position, ')
          ..write('color: $color, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChatCollectionsTable extends ChatCollections
    with TableInfo<$ChatCollectionsTable, ChatCollectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatCollectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _collectionIdMeta =
      const VerificationMeta('collectionId');
  @override
  late final GeneratedColumn<String> collectionId = GeneratedColumn<String>(
      'collection_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [chatId, collectionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_collections';
  @override
  VerificationContext validateIntegrity(Insertable<ChatCollectionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('collection_id')) {
      context.handle(
          _collectionIdMeta,
          collectionId.isAcceptableOrUnknown(
              data['collection_id']!, _collectionIdMeta));
    } else if (isInserting) {
      context.missing(_collectionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId};
  @override
  ChatCollectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatCollectionRow(
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id'])!,
      collectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}collection_id'])!,
    );
  }

  @override
  $ChatCollectionsTable createAlias(String alias) {
    return $ChatCollectionsTable(attachedDatabase, alias);
  }
}

class ChatCollectionRow extends DataClass
    implements Insertable<ChatCollectionRow> {
  final String chatId;
  final String collectionId;
  const ChatCollectionRow({required this.chatId, required this.collectionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['collection_id'] = Variable<String>(collectionId);
    return map;
  }

  ChatCollectionsCompanion toCompanion(bool nullToAbsent) {
    return ChatCollectionsCompanion(
      chatId: Value(chatId),
      collectionId: Value(collectionId),
    );
  }

  factory ChatCollectionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatCollectionRow(
      chatId: serializer.fromJson<String>(json['chatId']),
      collectionId: serializer.fromJson<String>(json['collectionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'collectionId': serializer.toJson<String>(collectionId),
    };
  }

  ChatCollectionRow copyWith({String? chatId, String? collectionId}) =>
      ChatCollectionRow(
        chatId: chatId ?? this.chatId,
        collectionId: collectionId ?? this.collectionId,
      );
  ChatCollectionRow copyWithCompanion(ChatCollectionsCompanion data) {
    return ChatCollectionRow(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      collectionId: data.collectionId.present
          ? data.collectionId.value
          : this.collectionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatCollectionRow(')
          ..write('chatId: $chatId, ')
          ..write('collectionId: $collectionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chatId, collectionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatCollectionRow &&
          other.chatId == this.chatId &&
          other.collectionId == this.collectionId);
}

class ChatCollectionsCompanion extends UpdateCompanion<ChatCollectionRow> {
  final Value<String> chatId;
  final Value<String> collectionId;
  final Value<int> rowid;
  const ChatCollectionsCompanion({
    this.chatId = const Value.absent(),
    this.collectionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatCollectionsCompanion.insert({
    required String chatId,
    required String collectionId,
    this.rowid = const Value.absent(),
  })  : chatId = Value(chatId),
        collectionId = Value(collectionId);
  static Insertable<ChatCollectionRow> custom({
    Expression<String>? chatId,
    Expression<String>? collectionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (collectionId != null) 'collection_id': collectionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatCollectionsCompanion copyWith(
      {Value<String>? chatId, Value<String>? collectionId, Value<int>? rowid}) {
    return ChatCollectionsCompanion(
      chatId: chatId ?? this.chatId,
      collectionId: collectionId ?? this.collectionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (collectionId.present) {
      map['collection_id'] = Variable<String>(collectionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatCollectionsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('collectionId: $collectionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeenCountsTable extends SeenCounts
    with TableInfo<$SeenCountsTable, SeenCountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeenCountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
      'count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [chatId, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'seen_counts';
  @override
  VerificationContext validateIntegrity(Insertable<SeenCountRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
          _countMeta, count.isAcceptableOrUnknown(data['count']!, _countMeta));
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId};
  @override
  SeenCountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeenCountRow(
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id'])!,
      count: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}count'])!,
    );
  }

  @override
  $SeenCountsTable createAlias(String alias) {
    return $SeenCountsTable(attachedDatabase, alias);
  }
}

class SeenCountRow extends DataClass implements Insertable<SeenCountRow> {
  final String chatId;
  final int count;
  const SeenCountRow({required this.chatId, required this.count});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['count'] = Variable<int>(count);
    return map;
  }

  SeenCountsCompanion toCompanion(bool nullToAbsent) {
    return SeenCountsCompanion(
      chatId: Value(chatId),
      count: Value(count),
    );
  }

  factory SeenCountRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeenCountRow(
      chatId: serializer.fromJson<String>(json['chatId']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'count': serializer.toJson<int>(count),
    };
  }

  SeenCountRow copyWith({String? chatId, int? count}) => SeenCountRow(
        chatId: chatId ?? this.chatId,
        count: count ?? this.count,
      );
  SeenCountRow copyWithCompanion(SeenCountsCompanion data) {
    return SeenCountRow(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeenCountRow(')
          ..write('chatId: $chatId, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chatId, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeenCountRow &&
          other.chatId == this.chatId &&
          other.count == this.count);
}

class SeenCountsCompanion extends UpdateCompanion<SeenCountRow> {
  final Value<String> chatId;
  final Value<int> count;
  final Value<int> rowid;
  const SeenCountsCompanion({
    this.chatId = const Value.absent(),
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeenCountsCompanion.insert({
    required String chatId,
    required int count,
    this.rowid = const Value.absent(),
  })  : chatId = Value(chatId),
        count = Value(count);
  static Insertable<SeenCountRow> custom({
    Expression<String>? chatId,
    Expression<int>? count,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (count != null) 'count': count,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeenCountsCompanion copyWith(
      {Value<String>? chatId, Value<int>? count, Value<int>? rowid}) {
    return SeenCountsCompanion(
      chatId: chatId ?? this.chatId,
      count: count ?? this.count,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeenCountsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('count: $count, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(Insertable<KeyValueRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueRow(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValueRow extends DataClass implements Insertable<KeyValueRow> {
  final String key;
  final String value;
  const KeyValueRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory KeyValueRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KeyValueRow copyWith({String? key, String? value}) => KeyValueRow(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  KeyValueRow copyWithCompanion(KeyValuesCompanion data) {
    return KeyValueRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueRow &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValueRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<KeyValueRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FileNamesTable extends FileNames
    with TableInfo<$FileNamesTable, FileName> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileNamesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [chatId, messageId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_names';
  @override
  VerificationContext validateIntegrity(Insertable<FileName> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId, messageId};
  @override
  FileName map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileName(
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
    );
  }

  @override
  $FileNamesTable createAlias(String alias) {
    return $FileNamesTable(attachedDatabase, alias);
  }
}

class FileName extends DataClass implements Insertable<FileName> {
  final String chatId;
  final String messageId;
  final String name;
  const FileName(
      {required this.chatId, required this.messageId, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['message_id'] = Variable<String>(messageId);
    map['name'] = Variable<String>(name);
    return map;
  }

  FileNamesCompanion toCompanion(bool nullToAbsent) {
    return FileNamesCompanion(
      chatId: Value(chatId),
      messageId: Value(messageId),
      name: Value(name),
    );
  }

  factory FileName.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileName(
      chatId: serializer.fromJson<String>(json['chatId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'messageId': serializer.toJson<String>(messageId),
      'name': serializer.toJson<String>(name),
    };
  }

  FileName copyWith({String? chatId, String? messageId, String? name}) =>
      FileName(
        chatId: chatId ?? this.chatId,
        messageId: messageId ?? this.messageId,
        name: name ?? this.name,
      );
  FileName copyWithCompanion(FileNamesCompanion data) {
    return FileName(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileName(')
          ..write('chatId: $chatId, ')
          ..write('messageId: $messageId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chatId, messageId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileName &&
          other.chatId == this.chatId &&
          other.messageId == this.messageId &&
          other.name == this.name);
}

class FileNamesCompanion extends UpdateCompanion<FileName> {
  final Value<String> chatId;
  final Value<String> messageId;
  final Value<String> name;
  final Value<int> rowid;
  const FileNamesCompanion({
    this.chatId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileNamesCompanion.insert({
    required String chatId,
    required String messageId,
    required String name,
    this.rowid = const Value.absent(),
  })  : chatId = Value(chatId),
        messageId = Value(messageId),
        name = Value(name);
  static Insertable<FileName> custom({
    Expression<String>? chatId,
    Expression<String>? messageId,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (messageId != null) 'message_id': messageId,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileNamesCompanion copyWith(
      {Value<String>? chatId,
      Value<String>? messageId,
      Value<String>? name,
      Value<int>? rowid}) {
    return FileNamesCompanion(
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileNamesCompanion(')
          ..write('chatId: $chatId, ')
          ..write('messageId: $messageId, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FileMarksTable extends FileMarks
    with TableInfo<$FileMarksTable, FileMarkRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FileMarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _favoriteMeta =
      const VerificationMeta('favorite');
  @override
  late final GeneratedColumn<bool> favorite = GeneratedColumn<bool>(
      'favorite', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("favorite" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [chatId, messageId, kind, favorite, tags, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'file_marks';
  @override
  VerificationContext validateIntegrity(Insertable<FileMarkRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('favorite')) {
      context.handle(_favoriteMeta,
          favorite.isAcceptableOrUnknown(data['favorite']!, _favoriteMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId, messageId};
  @override
  FileMarkRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FileMarkRow(
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      favorite: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}favorite'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $FileMarksTable createAlias(String alias) {
    return $FileMarksTable(attachedDatabase, alias);
  }
}

class FileMarkRow extends DataClass implements Insertable<FileMarkRow> {
  final String chatId;
  final String messageId;
  final String kind;
  final bool favorite;
  final String tags;
  final DateTime updatedAt;
  const FileMarkRow(
      {required this.chatId,
      required this.messageId,
      required this.kind,
      required this.favorite,
      required this.tags,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['message_id'] = Variable<String>(messageId);
    map['kind'] = Variable<String>(kind);
    map['favorite'] = Variable<bool>(favorite);
    map['tags'] = Variable<String>(tags);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FileMarksCompanion toCompanion(bool nullToAbsent) {
    return FileMarksCompanion(
      chatId: Value(chatId),
      messageId: Value(messageId),
      kind: Value(kind),
      favorite: Value(favorite),
      tags: Value(tags),
      updatedAt: Value(updatedAt),
    );
  }

  factory FileMarkRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FileMarkRow(
      chatId: serializer.fromJson<String>(json['chatId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      kind: serializer.fromJson<String>(json['kind']),
      favorite: serializer.fromJson<bool>(json['favorite']),
      tags: serializer.fromJson<String>(json['tags']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'messageId': serializer.toJson<String>(messageId),
      'kind': serializer.toJson<String>(kind),
      'favorite': serializer.toJson<bool>(favorite),
      'tags': serializer.toJson<String>(tags),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  FileMarkRow copyWith(
          {String? chatId,
          String? messageId,
          String? kind,
          bool? favorite,
          String? tags,
          DateTime? updatedAt}) =>
      FileMarkRow(
        chatId: chatId ?? this.chatId,
        messageId: messageId ?? this.messageId,
        kind: kind ?? this.kind,
        favorite: favorite ?? this.favorite,
        tags: tags ?? this.tags,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  FileMarkRow copyWithCompanion(FileMarksCompanion data) {
    return FileMarkRow(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      kind: data.kind.present ? data.kind.value : this.kind,
      favorite: data.favorite.present ? data.favorite.value : this.favorite,
      tags: data.tags.present ? data.tags.value : this.tags,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FileMarkRow(')
          ..write('chatId: $chatId, ')
          ..write('messageId: $messageId, ')
          ..write('kind: $kind, ')
          ..write('favorite: $favorite, ')
          ..write('tags: $tags, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(chatId, messageId, kind, favorite, tags, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FileMarkRow &&
          other.chatId == this.chatId &&
          other.messageId == this.messageId &&
          other.kind == this.kind &&
          other.favorite == this.favorite &&
          other.tags == this.tags &&
          other.updatedAt == this.updatedAt);
}

class FileMarksCompanion extends UpdateCompanion<FileMarkRow> {
  final Value<String> chatId;
  final Value<String> messageId;
  final Value<String> kind;
  final Value<bool> favorite;
  final Value<String> tags;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FileMarksCompanion({
    this.chatId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.kind = const Value.absent(),
    this.favorite = const Value.absent(),
    this.tags = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FileMarksCompanion.insert({
    required String chatId,
    required String messageId,
    required String kind,
    this.favorite = const Value.absent(),
    this.tags = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : chatId = Value(chatId),
        messageId = Value(messageId),
        kind = Value(kind),
        updatedAt = Value(updatedAt);
  static Insertable<FileMarkRow> custom({
    Expression<String>? chatId,
    Expression<String>? messageId,
    Expression<String>? kind,
    Expression<bool>? favorite,
    Expression<String>? tags,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (messageId != null) 'message_id': messageId,
      if (kind != null) 'kind': kind,
      if (favorite != null) 'favorite': favorite,
      if (tags != null) 'tags': tags,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FileMarksCompanion copyWith(
      {Value<String>? chatId,
      Value<String>? messageId,
      Value<String>? kind,
      Value<bool>? favorite,
      Value<String>? tags,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return FileMarksCompanion(
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      kind: kind ?? this.kind,
      favorite: favorite ?? this.favorite,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (favorite.present) {
      map['favorite'] = Variable<bool>(favorite.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FileMarksCompanion(')
          ..write('chatId: $chatId, ')
          ..write('messageId: $messageId, ')
          ..write('kind: $kind, ')
          ..write('favorite: $favorite, ')
          ..write('tags: $tags, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedItemsTable extends SavedItems
    with TableInfo<$SavedItemsTable, SavedItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chatTitleMeta =
      const VerificationMeta('chatTitle');
  @override
  late final GeneratedColumn<String> chatTitle = GeneratedColumn<String>(
      'chat_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
      'size', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _savedAtMeta =
      const VerificationMeta('savedAt');
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
      'saved_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [chatId, messageId, kind, chatTitle, body, fileName, size, date, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_items';
  @override
  VerificationContext validateIntegrity(Insertable<SavedItemRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('chat_title')) {
      context.handle(_chatTitleMeta,
          chatTitle.isAcceptableOrUnknown(data['chat_title']!, _chatTitleMeta));
    } else if (isInserting) {
      context.missing(_chatTitleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    }
    if (data.containsKey('size')) {
      context.handle(
          _sizeMeta, size.isAcceptableOrUnknown(data['size']!, _sizeMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    }
    if (data.containsKey('saved_at')) {
      context.handle(_savedAtMeta,
          savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta));
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {chatId, messageId};
  @override
  SavedItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedItemRow(
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      chatTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_title'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name']),
      size: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date']),
      savedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}saved_at'])!,
    );
  }

  @override
  $SavedItemsTable createAlias(String alias) {
    return $SavedItemsTable(attachedDatabase, alias);
  }
}

class SavedItemRow extends DataClass implements Insertable<SavedItemRow> {
  final String chatId;
  final String messageId;
  final String kind;
  final String chatTitle;
  final String body;
  final String? fileName;
  final int size;
  final DateTime? date;
  final DateTime savedAt;
  const SavedItemRow(
      {required this.chatId,
      required this.messageId,
      required this.kind,
      required this.chatTitle,
      required this.body,
      this.fileName,
      required this.size,
      this.date,
      required this.savedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['message_id'] = Variable<String>(messageId);
    map['kind'] = Variable<String>(kind);
    map['chat_title'] = Variable<String>(chatTitle);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    map['size'] = Variable<int>(size);
    if (!nullToAbsent || date != null) {
      map['date'] = Variable<DateTime>(date);
    }
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  SavedItemsCompanion toCompanion(bool nullToAbsent) {
    return SavedItemsCompanion(
      chatId: Value(chatId),
      messageId: Value(messageId),
      kind: Value(kind),
      chatTitle: Value(chatTitle),
      body: Value(body),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      size: Value(size),
      date: date == null && nullToAbsent ? const Value.absent() : Value(date),
      savedAt: Value(savedAt),
    );
  }

  factory SavedItemRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedItemRow(
      chatId: serializer.fromJson<String>(json['chatId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      kind: serializer.fromJson<String>(json['kind']),
      chatTitle: serializer.fromJson<String>(json['chatTitle']),
      body: serializer.fromJson<String>(json['body']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      size: serializer.fromJson<int>(json['size']),
      date: serializer.fromJson<DateTime?>(json['date']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'messageId': serializer.toJson<String>(messageId),
      'kind': serializer.toJson<String>(kind),
      'chatTitle': serializer.toJson<String>(chatTitle),
      'body': serializer.toJson<String>(body),
      'fileName': serializer.toJson<String?>(fileName),
      'size': serializer.toJson<int>(size),
      'date': serializer.toJson<DateTime?>(date),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  SavedItemRow copyWith(
          {String? chatId,
          String? messageId,
          String? kind,
          String? chatTitle,
          String? body,
          Value<String?> fileName = const Value.absent(),
          int? size,
          Value<DateTime?> date = const Value.absent(),
          DateTime? savedAt}) =>
      SavedItemRow(
        chatId: chatId ?? this.chatId,
        messageId: messageId ?? this.messageId,
        kind: kind ?? this.kind,
        chatTitle: chatTitle ?? this.chatTitle,
        body: body ?? this.body,
        fileName: fileName.present ? fileName.value : this.fileName,
        size: size ?? this.size,
        date: date.present ? date.value : this.date,
        savedAt: savedAt ?? this.savedAt,
      );
  SavedItemRow copyWithCompanion(SavedItemsCompanion data) {
    return SavedItemRow(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      kind: data.kind.present ? data.kind.value : this.kind,
      chatTitle: data.chatTitle.present ? data.chatTitle.value : this.chatTitle,
      body: data.body.present ? data.body.value : this.body,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      size: data.size.present ? data.size.value : this.size,
      date: data.date.present ? data.date.value : this.date,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedItemRow(')
          ..write('chatId: $chatId, ')
          ..write('messageId: $messageId, ')
          ..write('kind: $kind, ')
          ..write('chatTitle: $chatTitle, ')
          ..write('body: $body, ')
          ..write('fileName: $fileName, ')
          ..write('size: $size, ')
          ..write('date: $date, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      chatId, messageId, kind, chatTitle, body, fileName, size, date, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedItemRow &&
          other.chatId == this.chatId &&
          other.messageId == this.messageId &&
          other.kind == this.kind &&
          other.chatTitle == this.chatTitle &&
          other.body == this.body &&
          other.fileName == this.fileName &&
          other.size == this.size &&
          other.date == this.date &&
          other.savedAt == this.savedAt);
}

class SavedItemsCompanion extends UpdateCompanion<SavedItemRow> {
  final Value<String> chatId;
  final Value<String> messageId;
  final Value<String> kind;
  final Value<String> chatTitle;
  final Value<String> body;
  final Value<String?> fileName;
  final Value<int> size;
  final Value<DateTime?> date;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const SavedItemsCompanion({
    this.chatId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.kind = const Value.absent(),
    this.chatTitle = const Value.absent(),
    this.body = const Value.absent(),
    this.fileName = const Value.absent(),
    this.size = const Value.absent(),
    this.date = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavedItemsCompanion.insert({
    required String chatId,
    required String messageId,
    required String kind,
    required String chatTitle,
    this.body = const Value.absent(),
    this.fileName = const Value.absent(),
    this.size = const Value.absent(),
    this.date = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  })  : chatId = Value(chatId),
        messageId = Value(messageId),
        kind = Value(kind),
        chatTitle = Value(chatTitle),
        savedAt = Value(savedAt);
  static Insertable<SavedItemRow> custom({
    Expression<String>? chatId,
    Expression<String>? messageId,
    Expression<String>? kind,
    Expression<String>? chatTitle,
    Expression<String>? body,
    Expression<String>? fileName,
    Expression<int>? size,
    Expression<DateTime>? date,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (messageId != null) 'message_id': messageId,
      if (kind != null) 'kind': kind,
      if (chatTitle != null) 'chat_title': chatTitle,
      if (body != null) 'body': body,
      if (fileName != null) 'file_name': fileName,
      if (size != null) 'size': size,
      if (date != null) 'date': date,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavedItemsCompanion copyWith(
      {Value<String>? chatId,
      Value<String>? messageId,
      Value<String>? kind,
      Value<String>? chatTitle,
      Value<String>? body,
      Value<String?>? fileName,
      Value<int>? size,
      Value<DateTime?>? date,
      Value<DateTime>? savedAt,
      Value<int>? rowid}) {
    return SavedItemsCompanion(
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      kind: kind ?? this.kind,
      chatTitle: chatTitle ?? this.chatTitle,
      body: body ?? this.body,
      fileName: fileName ?? this.fileName,
      size: size ?? this.size,
      date: date ?? this.date,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (chatTitle.present) {
      map['chat_title'] = Variable<String>(chatTitle.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedItemsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('messageId: $messageId, ')
          ..write('kind: $kind, ')
          ..write('chatTitle: $chatTitle, ')
          ..write('body: $body, ')
          ..write('fileName: $fileName, ')
          ..write('size: $size, ')
          ..write('date: $date, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $NotesTable notes = $NotesTable(this);
  late final $CollectionsTable collections = $CollectionsTable(this);
  late final $ChatCollectionsTable chatCollections =
      $ChatCollectionsTable(this);
  late final $SeenCountsTable seenCounts = $SeenCountsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $FileNamesTable fileNames = $FileNamesTable(this);
  late final $FileMarksTable fileMarks = $FileMarksTable(this);
  late final $SavedItemsTable savedItems = $SavedItemsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        tasks,
        events,
        notes,
        collections,
        chatCollections,
        seenCounts,
        keyValues,
        fileNames,
        fileMarks,
        savedItems
      ];
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  required String title,
  Value<String> note,
  required TaskStatus status,
  Value<bool> important,
  Value<DateTime?> due,
  Value<double> position,
  Value<String?> chatId,
  Value<String?> chatTitle,
  Value<String?> messageId,
  Value<String?> messageText,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> completedAt,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> note,
  Value<TaskStatus> status,
  Value<bool> important,
  Value<DateTime?> due,
  Value<double> position,
  Value<String?> chatId,
  Value<String?> chatTitle,
  Value<String?> messageId,
  Value<String?> messageText,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> completedAt,
});

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<TaskStatus, TaskStatus, String> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get important => $composableBuilder(
      column: $table.important, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get due => $composableBuilder(
      column: $table.due, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatTitle => $composableBuilder(
      column: $table.chatTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get important => $composableBuilder(
      column: $table.important, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get due => $composableBuilder(
      column: $table.due, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatTitle => $composableBuilder(
      column: $table.chatTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get important =>
      $composableBuilder(column: $table.important, builder: (column) => column);

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<double> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get chatTitle =>
      $composableBuilder(column: $table.chatTitle, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<TaskStatus> status = const Value.absent(),
            Value<bool> important = const Value.absent(),
            Value<DateTime?> due = const Value.absent(),
            Value<double> position = const Value.absent(),
            Value<String?> chatId = const Value.absent(),
            Value<String?> chatTitle = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            Value<String?> messageText = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            title: title,
            note: note,
            status: status,
            important: important,
            due: due,
            position: position,
            chatId: chatId,
            chatTitle: chatTitle,
            messageId: messageId,
            messageText: messageText,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String> note = const Value.absent(),
            required TaskStatus status,
            Value<bool> important = const Value.absent(),
            Value<DateTime?> due = const Value.absent(),
            Value<double> position = const Value.absent(),
            Value<String?> chatId = const Value.absent(),
            Value<String?> chatTitle = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            Value<String?> messageText = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<DateTime?> completedAt = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            title: title,
            note: note,
            status: status,
            important: important,
            due: due,
            position: position,
            chatId: chatId,
            chatTitle: chatTitle,
            messageId: messageId,
            messageText: messageText,
            createdAt: createdAt,
            updatedAt: updatedAt,
            completedAt: completedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    Task,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableAnnotationComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
    Task,
    PrefetchHooks Function()>;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  required String title,
  Value<String> note,
  required DateTime start,
  required DateTime end,
  Value<bool> allDay,
  Value<int?> remindBefore,
  Value<String?> chatId,
  Value<String?> chatTitle,
  Value<String?> messageId,
  Value<String?> messageText,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> note,
  Value<DateTime> start,
  Value<DateTime> end,
  Value<bool> allDay,
  Value<int?> remindBefore,
  Value<String?> chatId,
  Value<String?> chatTitle,
  Value<String?> messageId,
  Value<String?> messageText,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get start => $composableBuilder(
      column: $table.start, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get end => $composableBuilder(
      column: $table.end, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get remindBefore => $composableBuilder(
      column: $table.remindBefore, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatTitle => $composableBuilder(
      column: $table.chatTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get start => $composableBuilder(
      column: $table.start, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get end => $composableBuilder(
      column: $table.end, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get allDay => $composableBuilder(
      column: $table.allDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get remindBefore => $composableBuilder(
      column: $table.remindBefore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatTitle => $composableBuilder(
      column: $table.chatTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<DateTime> get end =>
      $composableBuilder(column: $table.end, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<int> get remindBefore => $composableBuilder(
      column: $table.remindBefore, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get chatTitle =>
      $composableBuilder(column: $table.chatTitle, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get messageText => $composableBuilder(
      column: $table.messageText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
    Event,
    PrefetchHooks Function()> {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<DateTime> start = const Value.absent(),
            Value<DateTime> end = const Value.absent(),
            Value<bool> allDay = const Value.absent(),
            Value<int?> remindBefore = const Value.absent(),
            Value<String?> chatId = const Value.absent(),
            Value<String?> chatTitle = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            Value<String?> messageText = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EventsCompanion(
            id: id,
            title: title,
            note: note,
            start: start,
            end: end,
            allDay: allDay,
            remindBefore: remindBefore,
            chatId: chatId,
            chatTitle: chatTitle,
            messageId: messageId,
            messageText: messageText,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String> note = const Value.absent(),
            required DateTime start,
            required DateTime end,
            Value<bool> allDay = const Value.absent(),
            Value<int?> remindBefore = const Value.absent(),
            Value<String?> chatId = const Value.absent(),
            Value<String?> chatTitle = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            Value<String?> messageText = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              EventsCompanion.insert(
            id: id,
            title: title,
            note: note,
            start: start,
            end: end,
            allDay: allDay,
            remindBefore: remindBefore,
            chatId: chatId,
            chatTitle: chatTitle,
            messageId: messageId,
            messageText: messageText,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
    Event,
    PrefetchHooks Function()>;
typedef $$NotesTableCreateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> body,
  Value<List<NoteItem>> items,
  Value<bool> checklist,
  Value<NoteColor> color,
  Value<bool> pinned,
  Value<String?> chatId,
  Value<String?> chatTitle,
  Value<String?> messageId,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$NotesTableUpdateCompanionBuilder = NotesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> body,
  Value<List<NoteItem>> items,
  Value<bool> checklist,
  Value<NoteColor> color,
  Value<bool> pinned,
  Value<String?> chatId,
  Value<String?> chatTitle,
  Value<String?> messageId,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$NotesTableFilterComposer extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<NoteItem>, List<NoteItem>, String>
      get items => $composableBuilder(
          column: $table.items,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get checklist => $composableBuilder(
      column: $table.checklist, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<NoteColor, NoteColor, String> get color =>
      $composableBuilder(
          column: $table.color,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatTitle => $composableBuilder(
      column: $table.chatTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$NotesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get items => $composableBuilder(
      column: $table.items, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get checklist => $composableBuilder(
      column: $table.checklist, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get pinned => $composableBuilder(
      column: $table.pinned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatTitle => $composableBuilder(
      column: $table.chatTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$NotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotesTable> {
  $$NotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<NoteItem>, String> get items =>
      $composableBuilder(column: $table.items, builder: (column) => column);

  GeneratedColumn<bool> get checklist =>
      $composableBuilder(column: $table.checklist, builder: (column) => column);

  GeneratedColumnWithTypeConverter<NoteColor, String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get pinned =>
      $composableBuilder(column: $table.pinned, builder: (column) => column);

  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get chatTitle =>
      $composableBuilder(column: $table.chatTitle, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
    Note,
    PrefetchHooks Function()> {
  $$NotesTableTableManager(_$AppDatabase db, $NotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<List<NoteItem>> items = const Value.absent(),
            Value<bool> checklist = const Value.absent(),
            Value<NoteColor> color = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<String?> chatId = const Value.absent(),
            Value<String?> chatTitle = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              NotesCompanion(
            id: id,
            title: title,
            body: body,
            items: items,
            checklist: checklist,
            color: color,
            pinned: pinned,
            chatId: chatId,
            chatTitle: chatTitle,
            messageId: messageId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<List<NoteItem>> items = const Value.absent(),
            Value<bool> checklist = const Value.absent(),
            Value<NoteColor> color = const Value.absent(),
            Value<bool> pinned = const Value.absent(),
            Value<String?> chatId = const Value.absent(),
            Value<String?> chatTitle = const Value.absent(),
            Value<String?> messageId = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              NotesCompanion.insert(
            id: id,
            title: title,
            body: body,
            items: items,
            checklist: checklist,
            color: color,
            pinned: pinned,
            chatId: chatId,
            chatTitle: chatTitle,
            messageId: messageId,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$NotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NotesTable,
    Note,
    $$NotesTableFilterComposer,
    $$NotesTableOrderingComposer,
    $$NotesTableAnnotationComposer,
    $$NotesTableCreateCompanionBuilder,
    $$NotesTableUpdateCompanionBuilder,
    (Note, BaseReferences<_$AppDatabase, $NotesTable, Note>),
    Note,
    PrefetchHooks Function()>;
typedef $$CollectionsTableCreateCompanionBuilder = CollectionsCompanion
    Function({
  required String id,
  required String label,
  Value<String> icon,
  Value<int> position,
  Value<String> color,
  Value<int> rowid,
});
typedef $$CollectionsTableUpdateCompanionBuilder = CollectionsCompanion
    Function({
  Value<String> id,
  Value<String> label,
  Value<String> icon,
  Value<int> position,
  Value<String> color,
  Value<int> rowid,
});

class $$CollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));
}

class $$CollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get label => $composableBuilder(
      column: $table.label, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position => $composableBuilder(
      column: $table.position, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));
}

class $$CollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionsTable> {
  $$CollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);
}

class $$CollectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CollectionsTable,
    CollectionRow,
    $$CollectionsTableFilterComposer,
    $$CollectionsTableOrderingComposer,
    $$CollectionsTableAnnotationComposer,
    $$CollectionsTableCreateCompanionBuilder,
    $$CollectionsTableUpdateCompanionBuilder,
    (
      CollectionRow,
      BaseReferences<_$AppDatabase, $CollectionsTable, CollectionRow>
    ),
    CollectionRow,
    PrefetchHooks Function()> {
  $$CollectionsTableTableManager(_$AppDatabase db, $CollectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> label = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CollectionsCompanion(
            id: id,
            label: label,
            icon: icon,
            position: position,
            color: color,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String label,
            Value<String> icon = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<String> color = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CollectionsCompanion.insert(
            id: id,
            label: label,
            icon: icon,
            position: position,
            color: color,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CollectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CollectionsTable,
    CollectionRow,
    $$CollectionsTableFilterComposer,
    $$CollectionsTableOrderingComposer,
    $$CollectionsTableAnnotationComposer,
    $$CollectionsTableCreateCompanionBuilder,
    $$CollectionsTableUpdateCompanionBuilder,
    (
      CollectionRow,
      BaseReferences<_$AppDatabase, $CollectionsTable, CollectionRow>
    ),
    CollectionRow,
    PrefetchHooks Function()>;
typedef $$ChatCollectionsTableCreateCompanionBuilder = ChatCollectionsCompanion
    Function({
  required String chatId,
  required String collectionId,
  Value<int> rowid,
});
typedef $$ChatCollectionsTableUpdateCompanionBuilder = ChatCollectionsCompanion
    Function({
  Value<String> chatId,
  Value<String> collectionId,
  Value<int> rowid,
});

class $$ChatCollectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ChatCollectionsTable> {
  $$ChatCollectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get collectionId => $composableBuilder(
      column: $table.collectionId, builder: (column) => ColumnFilters(column));
}

class $$ChatCollectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChatCollectionsTable> {
  $$ChatCollectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get collectionId => $composableBuilder(
      column: $table.collectionId,
      builder: (column) => ColumnOrderings(column));
}

class $$ChatCollectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChatCollectionsTable> {
  $$ChatCollectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get collectionId => $composableBuilder(
      column: $table.collectionId, builder: (column) => column);
}

class $$ChatCollectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ChatCollectionsTable,
    ChatCollectionRow,
    $$ChatCollectionsTableFilterComposer,
    $$ChatCollectionsTableOrderingComposer,
    $$ChatCollectionsTableAnnotationComposer,
    $$ChatCollectionsTableCreateCompanionBuilder,
    $$ChatCollectionsTableUpdateCompanionBuilder,
    (
      ChatCollectionRow,
      BaseReferences<_$AppDatabase, $ChatCollectionsTable, ChatCollectionRow>
    ),
    ChatCollectionRow,
    PrefetchHooks Function()> {
  $$ChatCollectionsTableTableManager(
      _$AppDatabase db, $ChatCollectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatCollectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatCollectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatCollectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> chatId = const Value.absent(),
            Value<String> collectionId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatCollectionsCompanion(
            chatId: chatId,
            collectionId: collectionId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chatId,
            required String collectionId,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatCollectionsCompanion.insert(
            chatId: chatId,
            collectionId: collectionId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ChatCollectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ChatCollectionsTable,
    ChatCollectionRow,
    $$ChatCollectionsTableFilterComposer,
    $$ChatCollectionsTableOrderingComposer,
    $$ChatCollectionsTableAnnotationComposer,
    $$ChatCollectionsTableCreateCompanionBuilder,
    $$ChatCollectionsTableUpdateCompanionBuilder,
    (
      ChatCollectionRow,
      BaseReferences<_$AppDatabase, $ChatCollectionsTable, ChatCollectionRow>
    ),
    ChatCollectionRow,
    PrefetchHooks Function()>;
typedef $$SeenCountsTableCreateCompanionBuilder = SeenCountsCompanion Function({
  required String chatId,
  required int count,
  Value<int> rowid,
});
typedef $$SeenCountsTableUpdateCompanionBuilder = SeenCountsCompanion Function({
  Value<String> chatId,
  Value<int> count,
  Value<int> rowid,
});

class $$SeenCountsTableFilterComposer
    extends Composer<_$AppDatabase, $SeenCountsTable> {
  $$SeenCountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get count => $composableBuilder(
      column: $table.count, builder: (column) => ColumnFilters(column));
}

class $$SeenCountsTableOrderingComposer
    extends Composer<_$AppDatabase, $SeenCountsTable> {
  $$SeenCountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get count => $composableBuilder(
      column: $table.count, builder: (column) => ColumnOrderings(column));
}

class $$SeenCountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeenCountsTable> {
  $$SeenCountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);
}

class $$SeenCountsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SeenCountsTable,
    SeenCountRow,
    $$SeenCountsTableFilterComposer,
    $$SeenCountsTableOrderingComposer,
    $$SeenCountsTableAnnotationComposer,
    $$SeenCountsTableCreateCompanionBuilder,
    $$SeenCountsTableUpdateCompanionBuilder,
    (
      SeenCountRow,
      BaseReferences<_$AppDatabase, $SeenCountsTable, SeenCountRow>
    ),
    SeenCountRow,
    PrefetchHooks Function()> {
  $$SeenCountsTableTableManager(_$AppDatabase db, $SeenCountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeenCountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeenCountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeenCountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> chatId = const Value.absent(),
            Value<int> count = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SeenCountsCompanion(
            chatId: chatId,
            count: count,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chatId,
            required int count,
            Value<int> rowid = const Value.absent(),
          }) =>
              SeenCountsCompanion.insert(
            chatId: chatId,
            count: count,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SeenCountsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SeenCountsTable,
    SeenCountRow,
    $$SeenCountsTableFilterComposer,
    $$SeenCountsTableOrderingComposer,
    $$SeenCountsTableAnnotationComposer,
    $$SeenCountsTableCreateCompanionBuilder,
    $$SeenCountsTableUpdateCompanionBuilder,
    (
      SeenCountRow,
      BaseReferences<_$AppDatabase, $SeenCountsTable, SeenCountRow>
    ),
    SeenCountRow,
    PrefetchHooks Function()>;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $KeyValuesTable,
    KeyValueRow,
    $$KeyValuesTableFilterComposer,
    $$KeyValuesTableOrderingComposer,
    $$KeyValuesTableAnnotationComposer,
    $$KeyValuesTableCreateCompanionBuilder,
    $$KeyValuesTableUpdateCompanionBuilder,
    (KeyValueRow, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>),
    KeyValueRow,
    PrefetchHooks Function()> {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KeyValuesCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              KeyValuesCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KeyValuesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $KeyValuesTable,
    KeyValueRow,
    $$KeyValuesTableFilterComposer,
    $$KeyValuesTableOrderingComposer,
    $$KeyValuesTableAnnotationComposer,
    $$KeyValuesTableCreateCompanionBuilder,
    $$KeyValuesTableUpdateCompanionBuilder,
    (KeyValueRow, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValueRow>),
    KeyValueRow,
    PrefetchHooks Function()>;
typedef $$FileNamesTableCreateCompanionBuilder = FileNamesCompanion Function({
  required String chatId,
  required String messageId,
  required String name,
  Value<int> rowid,
});
typedef $$FileNamesTableUpdateCompanionBuilder = FileNamesCompanion Function({
  Value<String> chatId,
  Value<String> messageId,
  Value<String> name,
  Value<int> rowid,
});

class $$FileNamesTableFilterComposer
    extends Composer<_$AppDatabase, $FileNamesTable> {
  $$FileNamesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));
}

class $$FileNamesTableOrderingComposer
    extends Composer<_$AppDatabase, $FileNamesTable> {
  $$FileNamesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));
}

class $$FileNamesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileNamesTable> {
  $$FileNamesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);
}

class $$FileNamesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FileNamesTable,
    FileName,
    $$FileNamesTableFilterComposer,
    $$FileNamesTableOrderingComposer,
    $$FileNamesTableAnnotationComposer,
    $$FileNamesTableCreateCompanionBuilder,
    $$FileNamesTableUpdateCompanionBuilder,
    (FileName, BaseReferences<_$AppDatabase, $FileNamesTable, FileName>),
    FileName,
    PrefetchHooks Function()> {
  $$FileNamesTableTableManager(_$AppDatabase db, $FileNamesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileNamesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileNamesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileNamesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> chatId = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FileNamesCompanion(
            chatId: chatId,
            messageId: messageId,
            name: name,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chatId,
            required String messageId,
            required String name,
            Value<int> rowid = const Value.absent(),
          }) =>
              FileNamesCompanion.insert(
            chatId: chatId,
            messageId: messageId,
            name: name,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FileNamesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FileNamesTable,
    FileName,
    $$FileNamesTableFilterComposer,
    $$FileNamesTableOrderingComposer,
    $$FileNamesTableAnnotationComposer,
    $$FileNamesTableCreateCompanionBuilder,
    $$FileNamesTableUpdateCompanionBuilder,
    (FileName, BaseReferences<_$AppDatabase, $FileNamesTable, FileName>),
    FileName,
    PrefetchHooks Function()>;
typedef $$FileMarksTableCreateCompanionBuilder = FileMarksCompanion Function({
  required String chatId,
  required String messageId,
  required String kind,
  Value<bool> favorite,
  Value<String> tags,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$FileMarksTableUpdateCompanionBuilder = FileMarksCompanion Function({
  Value<String> chatId,
  Value<String> messageId,
  Value<String> kind,
  Value<bool> favorite,
  Value<String> tags,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$FileMarksTableFilterComposer
    extends Composer<_$AppDatabase, $FileMarksTable> {
  $$FileMarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get favorite => $composableBuilder(
      column: $table.favorite, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$FileMarksTableOrderingComposer
    extends Composer<_$AppDatabase, $FileMarksTable> {
  $$FileMarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get favorite => $composableBuilder(
      column: $table.favorite, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$FileMarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $FileMarksTable> {
  $$FileMarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get favorite =>
      $composableBuilder(column: $table.favorite, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FileMarksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FileMarksTable,
    FileMarkRow,
    $$FileMarksTableFilterComposer,
    $$FileMarksTableOrderingComposer,
    $$FileMarksTableAnnotationComposer,
    $$FileMarksTableCreateCompanionBuilder,
    $$FileMarksTableUpdateCompanionBuilder,
    (FileMarkRow, BaseReferences<_$AppDatabase, $FileMarksTable, FileMarkRow>),
    FileMarkRow,
    PrefetchHooks Function()> {
  $$FileMarksTableTableManager(_$AppDatabase db, $FileMarksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FileMarksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FileMarksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FileMarksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> chatId = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<bool> favorite = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FileMarksCompanion(
            chatId: chatId,
            messageId: messageId,
            kind: kind,
            favorite: favorite,
            tags: tags,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chatId,
            required String messageId,
            required String kind,
            Value<bool> favorite = const Value.absent(),
            Value<String> tags = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              FileMarksCompanion.insert(
            chatId: chatId,
            messageId: messageId,
            kind: kind,
            favorite: favorite,
            tags: tags,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FileMarksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FileMarksTable,
    FileMarkRow,
    $$FileMarksTableFilterComposer,
    $$FileMarksTableOrderingComposer,
    $$FileMarksTableAnnotationComposer,
    $$FileMarksTableCreateCompanionBuilder,
    $$FileMarksTableUpdateCompanionBuilder,
    (FileMarkRow, BaseReferences<_$AppDatabase, $FileMarksTable, FileMarkRow>),
    FileMarkRow,
    PrefetchHooks Function()>;
typedef $$SavedItemsTableCreateCompanionBuilder = SavedItemsCompanion Function({
  required String chatId,
  required String messageId,
  required String kind,
  required String chatTitle,
  Value<String> body,
  Value<String?> fileName,
  Value<int> size,
  Value<DateTime?> date,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$SavedItemsTableUpdateCompanionBuilder = SavedItemsCompanion Function({
  Value<String> chatId,
  Value<String> messageId,
  Value<String> kind,
  Value<String> chatTitle,
  Value<String> body,
  Value<String?> fileName,
  Value<int> size,
  Value<DateTime?> date,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$SavedItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chatTitle => $composableBuilder(
      column: $table.chatTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnFilters(column));
}

class $$SavedItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chatTitle => $composableBuilder(
      column: $table.chatTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get size => $composableBuilder(
      column: $table.size, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
      column: $table.savedAt, builder: (column) => ColumnOrderings(column));
}

class $$SavedItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SavedItemsTable> {
  $$SavedItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get chatTitle =>
      $composableBuilder(column: $table.chatTitle, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$SavedItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SavedItemsTable,
    SavedItemRow,
    $$SavedItemsTableFilterComposer,
    $$SavedItemsTableOrderingComposer,
    $$SavedItemsTableAnnotationComposer,
    $$SavedItemsTableCreateCompanionBuilder,
    $$SavedItemsTableUpdateCompanionBuilder,
    (
      SavedItemRow,
      BaseReferences<_$AppDatabase, $SavedItemsTable, SavedItemRow>
    ),
    SavedItemRow,
    PrefetchHooks Function()> {
  $$SavedItemsTableTableManager(_$AppDatabase db, $SavedItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> chatId = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> chatTitle = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
            Value<DateTime> savedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SavedItemsCompanion(
            chatId: chatId,
            messageId: messageId,
            kind: kind,
            chatTitle: chatTitle,
            body: body,
            fileName: fileName,
            size: size,
            date: date,
            savedAt: savedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chatId,
            required String messageId,
            required String kind,
            required String chatTitle,
            Value<String> body = const Value.absent(),
            Value<String?> fileName = const Value.absent(),
            Value<int> size = const Value.absent(),
            Value<DateTime?> date = const Value.absent(),
            required DateTime savedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SavedItemsCompanion.insert(
            chatId: chatId,
            messageId: messageId,
            kind: kind,
            chatTitle: chatTitle,
            body: body,
            fileName: fileName,
            size: size,
            date: date,
            savedAt: savedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SavedItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SavedItemsTable,
    SavedItemRow,
    $$SavedItemsTableFilterComposer,
    $$SavedItemsTableOrderingComposer,
    $$SavedItemsTableAnnotationComposer,
    $$SavedItemsTableCreateCompanionBuilder,
    $$SavedItemsTableUpdateCompanionBuilder,
    (
      SavedItemRow,
      BaseReferences<_$AppDatabase, $SavedItemsTable, SavedItemRow>
    ),
    SavedItemRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$NotesTableTableManager get notes =>
      $$NotesTableTableManager(_db, _db.notes);
  $$CollectionsTableTableManager get collections =>
      $$CollectionsTableTableManager(_db, _db.collections);
  $$ChatCollectionsTableTableManager get chatCollections =>
      $$ChatCollectionsTableTableManager(_db, _db.chatCollections);
  $$SeenCountsTableTableManager get seenCounts =>
      $$SeenCountsTableTableManager(_db, _db.seenCounts);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$FileNamesTableTableManager get fileNames =>
      $$FileNamesTableTableManager(_db, _db.fileNames);
  $$FileMarksTableTableManager get fileMarks =>
      $$FileMarksTableTableManager(_db, _db.fileMarks);
  $$SavedItemsTableTableManager get savedItems =>
      $$SavedItemsTableTableManager(_db, _db.savedItems);
}
