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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $EventsTable events = $EventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [tasks, events];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
}
