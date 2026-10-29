// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ListingsTableTable extends ListingsTable
    with TableInfo<$ListingsTableTable, ListingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlsMeta = const VerificationMeta(
    'imageUrls',
  );
  @override
  late final GeneratedColumn<String> imageUrls = GeneratedColumn<String>(
    'image_urls',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<String> duration = GeneratedColumn<String>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteOnlyMeta = const VerificationMeta(
    'remoteOnly',
  );
  @override
  late final GeneratedColumn<bool> remoteOnly = GeneratedColumn<bool>(
    'remote_only',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remote_only" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local-user'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    price,
    description,
    imageUrls,
    category,
    location,
    duration,
    remoteOnly,
    status,
    ownerId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('image_urls')) {
      context.handle(
        _imageUrlsMeta,
        imageUrls.isAcceptableOrUnknown(data['image_urls']!, _imageUrlsMeta),
      );
    } else if (isInserting) {
      context.missing(_imageUrlsMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    } else if (isInserting) {
      context.missing(_locationMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('remote_only')) {
      context.handle(
        _remoteOnlyMeta,
        remoteOnly.isAcceptableOrUnknown(data['remote_only']!, _remoteOnlyMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      imageUrls: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_urls'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}duration'],
      ),
      remoteOnly: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remote_only'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
    );
  }

  @override
  $ListingsTableTable createAlias(String alias) {
    return $ListingsTableTable(attachedDatabase, alias);
  }
}

class ListingsTableData extends DataClass
    implements Insertable<ListingsTableData> {
  final String id;
  final int type;
  final String title;
  final double price;
  final String description;
  final String imageUrls;
  final String category;
  final String location;
  final String? duration;
  final bool remoteOnly;
  final int status;
  final String ownerId;
  const ListingsTableData({
    required this.id,
    required this.type,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrls,
    required this.category,
    required this.location,
    this.duration,
    required this.remoteOnly,
    required this.status,
    required this.ownerId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<int>(type);
    map['title'] = Variable<String>(title);
    map['price'] = Variable<double>(price);
    map['description'] = Variable<String>(description);
    map['image_urls'] = Variable<String>(imageUrls);
    map['category'] = Variable<String>(category);
    map['location'] = Variable<String>(location);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<String>(duration);
    }
    map['remote_only'] = Variable<bool>(remoteOnly);
    map['status'] = Variable<int>(status);
    map['owner_id'] = Variable<String>(ownerId);
    return map;
  }

  ListingsTableCompanion toCompanion(bool nullToAbsent) {
    return ListingsTableCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      price: Value(price),
      description: Value(description),
      imageUrls: Value(imageUrls),
      category: Value(category),
      location: Value(location),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      remoteOnly: Value(remoteOnly),
      status: Value(status),
      ownerId: Value(ownerId),
    );
  }

  factory ListingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListingsTableData(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<int>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      price: serializer.fromJson<double>(json['price']),
      description: serializer.fromJson<String>(json['description']),
      imageUrls: serializer.fromJson<String>(json['imageUrls']),
      category: serializer.fromJson<String>(json['category']),
      location: serializer.fromJson<String>(json['location']),
      duration: serializer.fromJson<String?>(json['duration']),
      remoteOnly: serializer.fromJson<bool>(json['remoteOnly']),
      status: serializer.fromJson<int>(json['status']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<int>(type),
      'title': serializer.toJson<String>(title),
      'price': serializer.toJson<double>(price),
      'description': serializer.toJson<String>(description),
      'imageUrls': serializer.toJson<String>(imageUrls),
      'category': serializer.toJson<String>(category),
      'location': serializer.toJson<String>(location),
      'duration': serializer.toJson<String?>(duration),
      'remoteOnly': serializer.toJson<bool>(remoteOnly),
      'status': serializer.toJson<int>(status),
      'ownerId': serializer.toJson<String>(ownerId),
    };
  }

  ListingsTableData copyWith({
    String? id,
    int? type,
    String? title,
    double? price,
    String? description,
    String? imageUrls,
    String? category,
    String? location,
    Value<String?> duration = const Value.absent(),
    bool? remoteOnly,
    int? status,
    String? ownerId,
  }) => ListingsTableData(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    price: price ?? this.price,
    description: description ?? this.description,
    imageUrls: imageUrls ?? this.imageUrls,
    category: category ?? this.category,
    location: location ?? this.location,
    duration: duration.present ? duration.value : this.duration,
    remoteOnly: remoteOnly ?? this.remoteOnly,
    status: status ?? this.status,
    ownerId: ownerId ?? this.ownerId,
  );
  ListingsTableData copyWithCompanion(ListingsTableCompanion data) {
    return ListingsTableData(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      price: data.price.present ? data.price.value : this.price,
      description: data.description.present
          ? data.description.value
          : this.description,
      imageUrls: data.imageUrls.present ? data.imageUrls.value : this.imageUrls,
      category: data.category.present ? data.category.value : this.category,
      location: data.location.present ? data.location.value : this.location,
      duration: data.duration.present ? data.duration.value : this.duration,
      remoteOnly: data.remoteOnly.present
          ? data.remoteOnly.value
          : this.remoteOnly,
      status: data.status.present ? data.status.value : this.status,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListingsTableData(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('price: $price, ')
          ..write('description: $description, ')
          ..write('imageUrls: $imageUrls, ')
          ..write('category: $category, ')
          ..write('location: $location, ')
          ..write('duration: $duration, ')
          ..write('remoteOnly: $remoteOnly, ')
          ..write('status: $status, ')
          ..write('ownerId: $ownerId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    price,
    description,
    imageUrls,
    category,
    location,
    duration,
    remoteOnly,
    status,
    ownerId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListingsTableData &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.price == this.price &&
          other.description == this.description &&
          other.imageUrls == this.imageUrls &&
          other.category == this.category &&
          other.location == this.location &&
          other.duration == this.duration &&
          other.remoteOnly == this.remoteOnly &&
          other.status == this.status &&
          other.ownerId == this.ownerId);
}

class ListingsTableCompanion extends UpdateCompanion<ListingsTableData> {
  final Value<String> id;
  final Value<int> type;
  final Value<String> title;
  final Value<double> price;
  final Value<String> description;
  final Value<String> imageUrls;
  final Value<String> category;
  final Value<String> location;
  final Value<String?> duration;
  final Value<bool> remoteOnly;
  final Value<int> status;
  final Value<String> ownerId;
  final Value<int> rowid;
  const ListingsTableCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.price = const Value.absent(),
    this.description = const Value.absent(),
    this.imageUrls = const Value.absent(),
    this.category = const Value.absent(),
    this.location = const Value.absent(),
    this.duration = const Value.absent(),
    this.remoteOnly = const Value.absent(),
    this.status = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListingsTableCompanion.insert({
    required String id,
    required int type,
    required String title,
    required double price,
    required String description,
    required String imageUrls,
    required String category,
    required String location,
    this.duration = const Value.absent(),
    this.remoteOnly = const Value.absent(),
    this.status = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       price = Value(price),
       description = Value(description),
       imageUrls = Value(imageUrls),
       category = Value(category),
       location = Value(location);
  static Insertable<ListingsTableData> custom({
    Expression<String>? id,
    Expression<int>? type,
    Expression<String>? title,
    Expression<double>? price,
    Expression<String>? description,
    Expression<String>? imageUrls,
    Expression<String>? category,
    Expression<String>? location,
    Expression<String>? duration,
    Expression<bool>? remoteOnly,
    Expression<int>? status,
    Expression<String>? ownerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (price != null) 'price': price,
      if (description != null) 'description': description,
      if (imageUrls != null) 'image_urls': imageUrls,
      if (category != null) 'category': category,
      if (location != null) 'location': location,
      if (duration != null) 'duration': duration,
      if (remoteOnly != null) 'remote_only': remoteOnly,
      if (status != null) 'status': status,
      if (ownerId != null) 'owner_id': ownerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListingsTableCompanion copyWith({
    Value<String>? id,
    Value<int>? type,
    Value<String>? title,
    Value<double>? price,
    Value<String>? description,
    Value<String>? imageUrls,
    Value<String>? category,
    Value<String>? location,
    Value<String?>? duration,
    Value<bool>? remoteOnly,
    Value<int>? status,
    Value<String>? ownerId,
    Value<int>? rowid,
  }) {
    return ListingsTableCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      location: location ?? this.location,
      duration: duration ?? this.duration,
      remoteOnly: remoteOnly ?? this.remoteOnly,
      status: status ?? this.status,
      ownerId: ownerId ?? this.ownerId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imageUrls.present) {
      map['image_urls'] = Variable<String>(imageUrls.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (duration.present) {
      map['duration'] = Variable<String>(duration.value);
    }
    if (remoteOnly.present) {
      map['remote_only'] = Variable<bool>(remoteOnly.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ListingsTableCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('price: $price, ')
          ..write('description: $description, ')
          ..write('imageUrls: $imageUrls, ')
          ..write('category: $category, ')
          ..write('location: $location, ')
          ..write('duration: $duration, ')
          ..write('remoteOnly: $remoteOnly, ')
          ..write('status: $status, ')
          ..write('ownerId: $ownerId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SwipeStatesTableTable extends SwipeStatesTable
    with TableInfo<$SwipeStatesTableTable, SwipeStatesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SwipeStatesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _listingIdMeta = const VerificationMeta(
    'listingId',
  );
  @override
  late final GeneratedColumn<String> listingId = GeneratedColumn<String>(
    'listing_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<int> action = GeneratedColumn<int>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actedAtMeta = const VerificationMeta(
    'actedAt',
  );
  @override
  late final GeneratedColumn<DateTime> actedAt = GeneratedColumn<DateTime>(
    'acted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [listingId, action, actedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'swipe_states_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SwipeStatesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('listing_id')) {
      context.handle(
        _listingIdMeta,
        listingId.isAcceptableOrUnknown(data['listing_id']!, _listingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listingIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('acted_at')) {
      context.handle(
        _actedAtMeta,
        actedAt.isAcceptableOrUnknown(data['acted_at']!, _actedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_actedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {listingId};
  @override
  SwipeStatesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SwipeStatesTableData(
      listingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}listing_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}action'],
      )!,
      actedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}acted_at'],
      )!,
    );
  }

  @override
  $SwipeStatesTableTable createAlias(String alias) {
    return $SwipeStatesTableTable(attachedDatabase, alias);
  }
}

class SwipeStatesTableData extends DataClass
    implements Insertable<SwipeStatesTableData> {
  final String listingId;
  final int action;
  final DateTime actedAt;
  const SwipeStatesTableData({
    required this.listingId,
    required this.action,
    required this.actedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['listing_id'] = Variable<String>(listingId);
    map['action'] = Variable<int>(action);
    map['acted_at'] = Variable<DateTime>(actedAt);
    return map;
  }

  SwipeStatesTableCompanion toCompanion(bool nullToAbsent) {
    return SwipeStatesTableCompanion(
      listingId: Value(listingId),
      action: Value(action),
      actedAt: Value(actedAt),
    );
  }

  factory SwipeStatesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SwipeStatesTableData(
      listingId: serializer.fromJson<String>(json['listingId']),
      action: serializer.fromJson<int>(json['action']),
      actedAt: serializer.fromJson<DateTime>(json['actedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'listingId': serializer.toJson<String>(listingId),
      'action': serializer.toJson<int>(action),
      'actedAt': serializer.toJson<DateTime>(actedAt),
    };
  }

  SwipeStatesTableData copyWith({
    String? listingId,
    int? action,
    DateTime? actedAt,
  }) => SwipeStatesTableData(
    listingId: listingId ?? this.listingId,
    action: action ?? this.action,
    actedAt: actedAt ?? this.actedAt,
  );
  SwipeStatesTableData copyWithCompanion(SwipeStatesTableCompanion data) {
    return SwipeStatesTableData(
      listingId: data.listingId.present ? data.listingId.value : this.listingId,
      action: data.action.present ? data.action.value : this.action,
      actedAt: data.actedAt.present ? data.actedAt.value : this.actedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SwipeStatesTableData(')
          ..write('listingId: $listingId, ')
          ..write('action: $action, ')
          ..write('actedAt: $actedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(listingId, action, actedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SwipeStatesTableData &&
          other.listingId == this.listingId &&
          other.action == this.action &&
          other.actedAt == this.actedAt);
}

class SwipeStatesTableCompanion extends UpdateCompanion<SwipeStatesTableData> {
  final Value<String> listingId;
  final Value<int> action;
  final Value<DateTime> actedAt;
  final Value<int> rowid;
  const SwipeStatesTableCompanion({
    this.listingId = const Value.absent(),
    this.action = const Value.absent(),
    this.actedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SwipeStatesTableCompanion.insert({
    required String listingId,
    required int action,
    required DateTime actedAt,
    this.rowid = const Value.absent(),
  }) : listingId = Value(listingId),
       action = Value(action),
       actedAt = Value(actedAt);
  static Insertable<SwipeStatesTableData> custom({
    Expression<String>? listingId,
    Expression<int>? action,
    Expression<DateTime>? actedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (listingId != null) 'listing_id': listingId,
      if (action != null) 'action': action,
      if (actedAt != null) 'acted_at': actedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SwipeStatesTableCompanion copyWith({
    Value<String>? listingId,
    Value<int>? action,
    Value<DateTime>? actedAt,
    Value<int>? rowid,
  }) {
    return SwipeStatesTableCompanion(
      listingId: listingId ?? this.listingId,
      action: action ?? this.action,
      actedAt: actedAt ?? this.actedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (listingId.present) {
      map['listing_id'] = Variable<String>(listingId.value);
    }
    if (action.present) {
      map['action'] = Variable<int>(action.value);
    }
    if (actedAt.present) {
      map['acted_at'] = Variable<DateTime>(actedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SwipeStatesTableCompanion(')
          ..write('listingId: $listingId, ')
          ..write('action: $action, ')
          ..write('actedAt: $actedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConversationsTableTable extends ConversationsTable
    with TableInfo<$ConversationsTableTable, ConversationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConversationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantNameMeta = const VerificationMeta(
    'participantName',
  );
  @override
  late final GeneratedColumn<String> participantName = GeneratedColumn<String>(
    'participant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantAvatarMeta = const VerificationMeta(
    'participantAvatar',
  );
  @override
  late final GeneratedColumn<String> participantAvatar =
      GeneratedColumn<String>(
        'participant_avatar',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastMessageMeta = const VerificationMeta(
    'lastMessage',
  );
  @override
  late final GeneratedColumn<String> lastMessage = GeneratedColumn<String>(
    'last_message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<int> role = GeneratedColumn<int>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listingTitleMeta = const VerificationMeta(
    'listingTitle',
  );
  @override
  late final GeneratedColumn<String> listingTitle = GeneratedColumn<String>(
    'listing_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listingIdMeta = const VerificationMeta(
    'listingId',
  );
  @override
  late final GeneratedColumn<String> listingId = GeneratedColumn<String>(
    'listing_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _otherUserIdMeta = const VerificationMeta(
    'otherUserId',
  );
  @override
  late final GeneratedColumn<String> otherUserId = GeneratedColumn<String>(
    'other_user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _otherLastReadAtMeta = const VerificationMeta(
    'otherLastReadAt',
  );
  @override
  late final GeneratedColumn<DateTime> otherLastReadAt =
      GeneratedColumn<DateTime>(
        'other_last_read_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    participantName,
    participantAvatar,
    lastMessage,
    timestamp,
    unreadCount,
    role,
    listingTitle,
    listingId,
    otherUserId,
    archived,
    otherLastReadAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conversations_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConversationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('participant_name')) {
      context.handle(
        _participantNameMeta,
        participantName.isAcceptableOrUnknown(
          data['participant_name']!,
          _participantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantNameMeta);
    }
    if (data.containsKey('participant_avatar')) {
      context.handle(
        _participantAvatarMeta,
        participantAvatar.isAcceptableOrUnknown(
          data['participant_avatar']!,
          _participantAvatarMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantAvatarMeta);
    }
    if (data.containsKey('last_message')) {
      context.handle(
        _lastMessageMeta,
        lastMessage.isAcceptableOrUnknown(
          data['last_message']!,
          _lastMessageMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastMessageMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('listing_title')) {
      context.handle(
        _listingTitleMeta,
        listingTitle.isAcceptableOrUnknown(
          data['listing_title']!,
          _listingTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_listingTitleMeta);
    }
    if (data.containsKey('listing_id')) {
      context.handle(
        _listingIdMeta,
        listingId.isAcceptableOrUnknown(data['listing_id']!, _listingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_listingIdMeta);
    }
    if (data.containsKey('other_user_id')) {
      context.handle(
        _otherUserIdMeta,
        otherUserId.isAcceptableOrUnknown(
          data['other_user_id']!,
          _otherUserIdMeta,
        ),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('other_last_read_at')) {
      context.handle(
        _otherLastReadAtMeta,
        otherLastReadAt.isAcceptableOrUnknown(
          data['other_last_read_at']!,
          _otherLastReadAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConversationsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConversationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      participantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_name'],
      )!,
      participantAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_avatar'],
      )!,
      lastMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}role'],
      )!,
      listingTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}listing_title'],
      )!,
      listingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}listing_id'],
      )!,
      otherUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}other_user_id'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      otherLastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}other_last_read_at'],
      ),
    );
  }

  @override
  $ConversationsTableTable createAlias(String alias) {
    return $ConversationsTableTable(attachedDatabase, alias);
  }
}

class ConversationsTableData extends DataClass
    implements Insertable<ConversationsTableData> {
  final String id;
  final String participantName;
  final String participantAvatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final int role;
  final String listingTitle;
  final String listingId;
  final String otherUserId;
  final bool archived;
  final DateTime? otherLastReadAt;
  const ConversationsTableData({
    required this.id,
    required this.participantName,
    required this.participantAvatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.role,
    required this.listingTitle,
    required this.listingId,
    required this.otherUserId,
    required this.archived,
    this.otherLastReadAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['participant_name'] = Variable<String>(participantName);
    map['participant_avatar'] = Variable<String>(participantAvatar);
    map['last_message'] = Variable<String>(lastMessage);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['unread_count'] = Variable<int>(unreadCount);
    map['role'] = Variable<int>(role);
    map['listing_title'] = Variable<String>(listingTitle);
    map['listing_id'] = Variable<String>(listingId);
    map['other_user_id'] = Variable<String>(otherUserId);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || otherLastReadAt != null) {
      map['other_last_read_at'] = Variable<DateTime>(otherLastReadAt);
    }
    return map;
  }

  ConversationsTableCompanion toCompanion(bool nullToAbsent) {
    return ConversationsTableCompanion(
      id: Value(id),
      participantName: Value(participantName),
      participantAvatar: Value(participantAvatar),
      lastMessage: Value(lastMessage),
      timestamp: Value(timestamp),
      unreadCount: Value(unreadCount),
      role: Value(role),
      listingTitle: Value(listingTitle),
      listingId: Value(listingId),
      otherUserId: Value(otherUserId),
      archived: Value(archived),
      otherLastReadAt: otherLastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(otherLastReadAt),
    );
  }

  factory ConversationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConversationsTableData(
      id: serializer.fromJson<String>(json['id']),
      participantName: serializer.fromJson<String>(json['participantName']),
      participantAvatar: serializer.fromJson<String>(json['participantAvatar']),
      lastMessage: serializer.fromJson<String>(json['lastMessage']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
      role: serializer.fromJson<int>(json['role']),
      listingTitle: serializer.fromJson<String>(json['listingTitle']),
      listingId: serializer.fromJson<String>(json['listingId']),
      otherUserId: serializer.fromJson<String>(json['otherUserId']),
      archived: serializer.fromJson<bool>(json['archived']),
      otherLastReadAt: serializer.fromJson<DateTime?>(json['otherLastReadAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'participantName': serializer.toJson<String>(participantName),
      'participantAvatar': serializer.toJson<String>(participantAvatar),
      'lastMessage': serializer.toJson<String>(lastMessage),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'unreadCount': serializer.toJson<int>(unreadCount),
      'role': serializer.toJson<int>(role),
      'listingTitle': serializer.toJson<String>(listingTitle),
      'listingId': serializer.toJson<String>(listingId),
      'otherUserId': serializer.toJson<String>(otherUserId),
      'archived': serializer.toJson<bool>(archived),
      'otherLastReadAt': serializer.toJson<DateTime?>(otherLastReadAt),
    };
  }

  ConversationsTableData copyWith({
    String? id,
    String? participantName,
    String? participantAvatar,
    String? lastMessage,
    DateTime? timestamp,
    int? unreadCount,
    int? role,
    String? listingTitle,
    String? listingId,
    String? otherUserId,
    bool? archived,
    Value<DateTime?> otherLastReadAt = const Value.absent(),
  }) => ConversationsTableData(
    id: id ?? this.id,
    participantName: participantName ?? this.participantName,
    participantAvatar: participantAvatar ?? this.participantAvatar,
    lastMessage: lastMessage ?? this.lastMessage,
    timestamp: timestamp ?? this.timestamp,
    unreadCount: unreadCount ?? this.unreadCount,
    role: role ?? this.role,
    listingTitle: listingTitle ?? this.listingTitle,
    listingId: listingId ?? this.listingId,
    otherUserId: otherUserId ?? this.otherUserId,
    archived: archived ?? this.archived,
    otherLastReadAt: otherLastReadAt.present
        ? otherLastReadAt.value
        : this.otherLastReadAt,
  );
  ConversationsTableData copyWithCompanion(ConversationsTableCompanion data) {
    return ConversationsTableData(
      id: data.id.present ? data.id.value : this.id,
      participantName: data.participantName.present
          ? data.participantName.value
          : this.participantName,
      participantAvatar: data.participantAvatar.present
          ? data.participantAvatar.value
          : this.participantAvatar,
      lastMessage: data.lastMessage.present
          ? data.lastMessage.value
          : this.lastMessage,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
      role: data.role.present ? data.role.value : this.role,
      listingTitle: data.listingTitle.present
          ? data.listingTitle.value
          : this.listingTitle,
      listingId: data.listingId.present ? data.listingId.value : this.listingId,
      otherUserId: data.otherUserId.present
          ? data.otherUserId.value
          : this.otherUserId,
      archived: data.archived.present ? data.archived.value : this.archived,
      otherLastReadAt: data.otherLastReadAt.present
          ? data.otherLastReadAt.value
          : this.otherLastReadAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsTableData(')
          ..write('id: $id, ')
          ..write('participantName: $participantName, ')
          ..write('participantAvatar: $participantAvatar, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('timestamp: $timestamp, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('role: $role, ')
          ..write('listingTitle: $listingTitle, ')
          ..write('listingId: $listingId, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('archived: $archived, ')
          ..write('otherLastReadAt: $otherLastReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    participantName,
    participantAvatar,
    lastMessage,
    timestamp,
    unreadCount,
    role,
    listingTitle,
    listingId,
    otherUserId,
    archived,
    otherLastReadAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConversationsTableData &&
          other.id == this.id &&
          other.participantName == this.participantName &&
          other.participantAvatar == this.participantAvatar &&
          other.lastMessage == this.lastMessage &&
          other.timestamp == this.timestamp &&
          other.unreadCount == this.unreadCount &&
          other.role == this.role &&
          other.listingTitle == this.listingTitle &&
          other.listingId == this.listingId &&
          other.otherUserId == this.otherUserId &&
          other.archived == this.archived &&
          other.otherLastReadAt == this.otherLastReadAt);
}

class ConversationsTableCompanion
    extends UpdateCompanion<ConversationsTableData> {
  final Value<String> id;
  final Value<String> participantName;
  final Value<String> participantAvatar;
  final Value<String> lastMessage;
  final Value<DateTime> timestamp;
  final Value<int> unreadCount;
  final Value<int> role;
  final Value<String> listingTitle;
  final Value<String> listingId;
  final Value<String> otherUserId;
  final Value<bool> archived;
  final Value<DateTime?> otherLastReadAt;
  final Value<int> rowid;
  const ConversationsTableCompanion({
    this.id = const Value.absent(),
    this.participantName = const Value.absent(),
    this.participantAvatar = const Value.absent(),
    this.lastMessage = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.role = const Value.absent(),
    this.listingTitle = const Value.absent(),
    this.listingId = const Value.absent(),
    this.otherUserId = const Value.absent(),
    this.archived = const Value.absent(),
    this.otherLastReadAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConversationsTableCompanion.insert({
    required String id,
    required String participantName,
    required String participantAvatar,
    required String lastMessage,
    required DateTime timestamp,
    this.unreadCount = const Value.absent(),
    required int role,
    required String listingTitle,
    required String listingId,
    this.otherUserId = const Value.absent(),
    this.archived = const Value.absent(),
    this.otherLastReadAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       participantName = Value(participantName),
       participantAvatar = Value(participantAvatar),
       lastMessage = Value(lastMessage),
       timestamp = Value(timestamp),
       role = Value(role),
       listingTitle = Value(listingTitle),
       listingId = Value(listingId);
  static Insertable<ConversationsTableData> custom({
    Expression<String>? id,
    Expression<String>? participantName,
    Expression<String>? participantAvatar,
    Expression<String>? lastMessage,
    Expression<DateTime>? timestamp,
    Expression<int>? unreadCount,
    Expression<int>? role,
    Expression<String>? listingTitle,
    Expression<String>? listingId,
    Expression<String>? otherUserId,
    Expression<bool>? archived,
    Expression<DateTime>? otherLastReadAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (participantName != null) 'participant_name': participantName,
      if (participantAvatar != null) 'participant_avatar': participantAvatar,
      if (lastMessage != null) 'last_message': lastMessage,
      if (timestamp != null) 'timestamp': timestamp,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (role != null) 'role': role,
      if (listingTitle != null) 'listing_title': listingTitle,
      if (listingId != null) 'listing_id': listingId,
      if (otherUserId != null) 'other_user_id': otherUserId,
      if (archived != null) 'archived': archived,
      if (otherLastReadAt != null) 'other_last_read_at': otherLastReadAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConversationsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? participantName,
    Value<String>? participantAvatar,
    Value<String>? lastMessage,
    Value<DateTime>? timestamp,
    Value<int>? unreadCount,
    Value<int>? role,
    Value<String>? listingTitle,
    Value<String>? listingId,
    Value<String>? otherUserId,
    Value<bool>? archived,
    Value<DateTime?>? otherLastReadAt,
    Value<int>? rowid,
  }) {
    return ConversationsTableCompanion(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      timestamp: timestamp ?? this.timestamp,
      unreadCount: unreadCount ?? this.unreadCount,
      role: role ?? this.role,
      listingTitle: listingTitle ?? this.listingTitle,
      listingId: listingId ?? this.listingId,
      otherUserId: otherUserId ?? this.otherUserId,
      archived: archived ?? this.archived,
      otherLastReadAt: otherLastReadAt ?? this.otherLastReadAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (participantName.present) {
      map['participant_name'] = Variable<String>(participantName.value);
    }
    if (participantAvatar.present) {
      map['participant_avatar'] = Variable<String>(participantAvatar.value);
    }
    if (lastMessage.present) {
      map['last_message'] = Variable<String>(lastMessage.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (role.present) {
      map['role'] = Variable<int>(role.value);
    }
    if (listingTitle.present) {
      map['listing_title'] = Variable<String>(listingTitle.value);
    }
    if (listingId.present) {
      map['listing_id'] = Variable<String>(listingId.value);
    }
    if (otherUserId.present) {
      map['other_user_id'] = Variable<String>(otherUserId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (otherLastReadAt.present) {
      map['other_last_read_at'] = Variable<DateTime>(otherLastReadAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConversationsTableCompanion(')
          ..write('id: $id, ')
          ..write('participantName: $participantName, ')
          ..write('participantAvatar: $participantAvatar, ')
          ..write('lastMessage: $lastMessage, ')
          ..write('timestamp: $timestamp, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('role: $role, ')
          ..write('listingTitle: $listingTitle, ')
          ..write('listingId: $listingId, ')
          ..write('otherUserId: $otherUserId, ')
          ..write('archived: $archived, ')
          ..write('otherLastReadAt: $otherLastReadAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MessagesTableTable extends MessagesTable
    with TableInfo<$MessagesTableTable, MessagesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isOutgoingMeta = const VerificationMeta(
    'isOutgoing',
  );
  @override
  late final GeneratedColumn<bool> isOutgoing = GeneratedColumn<bool>(
    'is_outgoing',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_outgoing" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sentAtMeta = const VerificationMeta('sentAt');
  @override
  late final GeneratedColumn<DateTime> sentAt = GeneratedColumn<DateTime>(
    'sent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    body,
    isOutgoing,
    sentAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<MessagesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('is_outgoing')) {
      context.handle(
        _isOutgoingMeta,
        isOutgoing.isAcceptableOrUnknown(data['is_outgoing']!, _isOutgoingMeta),
      );
    } else if (isInserting) {
      context.missing(_isOutgoingMeta);
    }
    if (data.containsKey('sent_at')) {
      context.handle(
        _sentAtMeta,
        sentAt.isAcceptableOrUnknown(data['sent_at']!, _sentAtMeta),
      );
    } else if (isInserting) {
      context.missing(_sentAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MessagesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MessagesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      isOutgoing: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_outgoing'],
      )!,
      sentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sent_at'],
      )!,
    );
  }

  @override
  $MessagesTableTable createAlias(String alias) {
    return $MessagesTableTable(attachedDatabase, alias);
  }
}

class MessagesTableData extends DataClass
    implements Insertable<MessagesTableData> {
  final String id;
  final String conversationId;
  final String body;
  final bool isOutgoing;
  final DateTime sentAt;
  const MessagesTableData({
    required this.id,
    required this.conversationId,
    required this.body,
    required this.isOutgoing,
    required this.sentAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['body'] = Variable<String>(body);
    map['is_outgoing'] = Variable<bool>(isOutgoing);
    map['sent_at'] = Variable<DateTime>(sentAt);
    return map;
  }

  MessagesTableCompanion toCompanion(bool nullToAbsent) {
    return MessagesTableCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      body: Value(body),
      isOutgoing: Value(isOutgoing),
      sentAt: Value(sentAt),
    );
  }

  factory MessagesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MessagesTableData(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      body: serializer.fromJson<String>(json['body']),
      isOutgoing: serializer.fromJson<bool>(json['isOutgoing']),
      sentAt: serializer.fromJson<DateTime>(json['sentAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'body': serializer.toJson<String>(body),
      'isOutgoing': serializer.toJson<bool>(isOutgoing),
      'sentAt': serializer.toJson<DateTime>(sentAt),
    };
  }

  MessagesTableData copyWith({
    String? id,
    String? conversationId,
    String? body,
    bool? isOutgoing,
    DateTime? sentAt,
  }) => MessagesTableData(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    body: body ?? this.body,
    isOutgoing: isOutgoing ?? this.isOutgoing,
    sentAt: sentAt ?? this.sentAt,
  );
  MessagesTableData copyWithCompanion(MessagesTableCompanion data) {
    return MessagesTableData(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      body: data.body.present ? data.body.value : this.body,
      isOutgoing: data.isOutgoing.present
          ? data.isOutgoing.value
          : this.isOutgoing,
      sentAt: data.sentAt.present ? data.sentAt.value : this.sentAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableData(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('body: $body, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('sentAt: $sentAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, conversationId, body, isOutgoing, sentAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MessagesTableData &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.body == this.body &&
          other.isOutgoing == this.isOutgoing &&
          other.sentAt == this.sentAt);
}

class MessagesTableCompanion extends UpdateCompanion<MessagesTableData> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> body;
  final Value<bool> isOutgoing;
  final Value<DateTime> sentAt;
  final Value<int> rowid;
  const MessagesTableCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.body = const Value.absent(),
    this.isOutgoing = const Value.absent(),
    this.sentAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MessagesTableCompanion.insert({
    required String id,
    required String conversationId,
    required String body,
    required bool isOutgoing,
    required DateTime sentAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       body = Value(body),
       isOutgoing = Value(isOutgoing),
       sentAt = Value(sentAt);
  static Insertable<MessagesTableData> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? body,
    Expression<bool>? isOutgoing,
    Expression<DateTime>? sentAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (body != null) 'body': body,
      if (isOutgoing != null) 'is_outgoing': isOutgoing,
      if (sentAt != null) 'sent_at': sentAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MessagesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? body,
    Value<bool>? isOutgoing,
    Value<DateTime>? sentAt,
    Value<int>? rowid,
  }) {
    return MessagesTableCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      body: body ?? this.body,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      sentAt: sentAt ?? this.sentAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (isOutgoing.present) {
      map['is_outgoing'] = Variable<bool>(isOutgoing.value);
    }
    if (sentAt.present) {
      map['sent_at'] = Variable<DateTime>(sentAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesTableCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('body: $body, ')
          ..write('isOutgoing: $isOutgoing, ')
          ..write('sentAt: $sentAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserProfilesTableTable extends UserProfilesTable
    with TableInfo<$UserProfilesTableTable, UserProfilesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listingsCountMeta = const VerificationMeta(
    'listingsCount',
  );
  @override
  late final GeneratedColumn<int> listingsCount = GeneratedColumn<int>(
    'listings_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _soldCountMeta = const VerificationMeta(
    'soldCount',
  );
  @override
  late final GeneratedColumn<int> soldCount = GeneratedColumn<int>(
    'sold_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberSinceMeta = const VerificationMeta(
    'memberSince',
  );
  @override
  late final GeneratedColumn<DateTime> memberSince = GeneratedColumn<DateTime>(
    'member_since',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewsJsonMeta = const VerificationMeta(
    'reviewsJson',
  );
  @override
  late final GeneratedColumn<String> reviewsJson = GeneratedColumn<String>(
    'reviews_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    avatarUrl,
    rating,
    reviewCount,
    listingsCount,
    soldCount,
    memberSince,
    reviewsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfilesTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarUrlMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reviewCountMeta);
    }
    if (data.containsKey('listings_count')) {
      context.handle(
        _listingsCountMeta,
        listingsCount.isAcceptableOrUnknown(
          data['listings_count']!,
          _listingsCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_listingsCountMeta);
    }
    if (data.containsKey('sold_count')) {
      context.handle(
        _soldCountMeta,
        soldCount.isAcceptableOrUnknown(data['sold_count']!, _soldCountMeta),
      );
    } else if (isInserting) {
      context.missing(_soldCountMeta);
    }
    if (data.containsKey('member_since')) {
      context.handle(
        _memberSinceMeta,
        memberSince.isAcceptableOrUnknown(
          data['member_since']!,
          _memberSinceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_memberSinceMeta);
    }
    if (data.containsKey('reviews_json')) {
      context.handle(
        _reviewsJsonMeta,
        reviewsJson.isAcceptableOrUnknown(
          data['reviews_json']!,
          _reviewsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfilesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfilesTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      listingsCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}listings_count'],
      )!,
      soldCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sold_count'],
      )!,
      memberSince: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}member_since'],
      )!,
      reviewsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviews_json'],
      )!,
    );
  }

  @override
  $UserProfilesTableTable createAlias(String alias) {
    return $UserProfilesTableTable(attachedDatabase, alias);
  }
}

class UserProfilesTableData extends DataClass
    implements Insertable<UserProfilesTableData> {
  final String id;
  final String name;
  final String avatarUrl;
  final double rating;
  final int reviewCount;
  final int listingsCount;
  final int soldCount;
  final DateTime memberSince;
  final String reviewsJson;
  const UserProfilesTableData({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.listingsCount,
    required this.soldCount,
    required this.memberSince,
    required this.reviewsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['avatar_url'] = Variable<String>(avatarUrl);
    map['rating'] = Variable<double>(rating);
    map['review_count'] = Variable<int>(reviewCount);
    map['listings_count'] = Variable<int>(listingsCount);
    map['sold_count'] = Variable<int>(soldCount);
    map['member_since'] = Variable<DateTime>(memberSince);
    map['reviews_json'] = Variable<String>(reviewsJson);
    return map;
  }

  UserProfilesTableCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesTableCompanion(
      id: Value(id),
      name: Value(name),
      avatarUrl: Value(avatarUrl),
      rating: Value(rating),
      reviewCount: Value(reviewCount),
      listingsCount: Value(listingsCount),
      soldCount: Value(soldCount),
      memberSince: Value(memberSince),
      reviewsJson: Value(reviewsJson),
    );
  }

  factory UserProfilesTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfilesTableData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      avatarUrl: serializer.fromJson<String>(json['avatarUrl']),
      rating: serializer.fromJson<double>(json['rating']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      listingsCount: serializer.fromJson<int>(json['listingsCount']),
      soldCount: serializer.fromJson<int>(json['soldCount']),
      memberSince: serializer.fromJson<DateTime>(json['memberSince']),
      reviewsJson: serializer.fromJson<String>(json['reviewsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'avatarUrl': serializer.toJson<String>(avatarUrl),
      'rating': serializer.toJson<double>(rating),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'listingsCount': serializer.toJson<int>(listingsCount),
      'soldCount': serializer.toJson<int>(soldCount),
      'memberSince': serializer.toJson<DateTime>(memberSince),
      'reviewsJson': serializer.toJson<String>(reviewsJson),
    };
  }

  UserProfilesTableData copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    double? rating,
    int? reviewCount,
    int? listingsCount,
    int? soldCount,
    DateTime? memberSince,
    String? reviewsJson,
  }) => UserProfilesTableData(
    id: id ?? this.id,
    name: name ?? this.name,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    rating: rating ?? this.rating,
    reviewCount: reviewCount ?? this.reviewCount,
    listingsCount: listingsCount ?? this.listingsCount,
    soldCount: soldCount ?? this.soldCount,
    memberSince: memberSince ?? this.memberSince,
    reviewsJson: reviewsJson ?? this.reviewsJson,
  );
  UserProfilesTableData copyWithCompanion(UserProfilesTableCompanion data) {
    return UserProfilesTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      listingsCount: data.listingsCount.present
          ? data.listingsCount.value
          : this.listingsCount,
      soldCount: data.soldCount.present ? data.soldCount.value : this.soldCount,
      memberSince: data.memberSince.present
          ? data.memberSince.value
          : this.memberSince,
      reviewsJson: data.reviewsJson.present
          ? data.reviewsJson.value
          : this.reviewsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('rating: $rating, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('listingsCount: $listingsCount, ')
          ..write('soldCount: $soldCount, ')
          ..write('memberSince: $memberSince, ')
          ..write('reviewsJson: $reviewsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    avatarUrl,
    rating,
    reviewCount,
    listingsCount,
    soldCount,
    memberSince,
    reviewsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfilesTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.rating == this.rating &&
          other.reviewCount == this.reviewCount &&
          other.listingsCount == this.listingsCount &&
          other.soldCount == this.soldCount &&
          other.memberSince == this.memberSince &&
          other.reviewsJson == this.reviewsJson);
}

class UserProfilesTableCompanion
    extends UpdateCompanion<UserProfilesTableData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> avatarUrl;
  final Value<double> rating;
  final Value<int> reviewCount;
  final Value<int> listingsCount;
  final Value<int> soldCount;
  final Value<DateTime> memberSince;
  final Value<String> reviewsJson;
  final Value<int> rowid;
  const UserProfilesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.listingsCount = const Value.absent(),
    this.soldCount = const Value.absent(),
    this.memberSince = const Value.absent(),
    this.reviewsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserProfilesTableCompanion.insert({
    required String id,
    required String name,
    required String avatarUrl,
    required double rating,
    required int reviewCount,
    required int listingsCount,
    required int soldCount,
    required DateTime memberSince,
    this.reviewsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       avatarUrl = Value(avatarUrl),
       rating = Value(rating),
       reviewCount = Value(reviewCount),
       listingsCount = Value(listingsCount),
       soldCount = Value(soldCount),
       memberSince = Value(memberSince);
  static Insertable<UserProfilesTableData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<double>? rating,
    Expression<int>? reviewCount,
    Expression<int>? listingsCount,
    Expression<int>? soldCount,
    Expression<DateTime>? memberSince,
    Expression<String>? reviewsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'review_count': reviewCount,
      if (listingsCount != null) 'listings_count': listingsCount,
      if (soldCount != null) 'sold_count': soldCount,
      if (memberSince != null) 'member_since': memberSince,
      if (reviewsJson != null) 'reviews_json': reviewsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserProfilesTableCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? avatarUrl,
    Value<double>? rating,
    Value<int>? reviewCount,
    Value<int>? listingsCount,
    Value<int>? soldCount,
    Value<DateTime>? memberSince,
    Value<String>? reviewsJson,
    Value<int>? rowid,
  }) {
    return UserProfilesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      listingsCount: listingsCount ?? this.listingsCount,
      soldCount: soldCount ?? this.soldCount,
      memberSince: memberSince ?? this.memberSince,
      reviewsJson: reviewsJson ?? this.reviewsJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (listingsCount.present) {
      map['listings_count'] = Variable<int>(listingsCount.value);
    }
    if (soldCount.present) {
      map['sold_count'] = Variable<int>(soldCount.value);
    }
    if (memberSince.present) {
      map['member_since'] = Variable<DateTime>(memberSince.value);
    }
    if (reviewsJson.present) {
      map['reviews_json'] = Variable<String>(reviewsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('rating: $rating, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('listingsCount: $listingsCount, ')
          ..write('soldCount: $soldCount, ')
          ..write('memberSince: $memberSince, ')
          ..write('reviewsJson: $reviewsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTableTable extends AppMetaTable
    with TableInfo<$AppMetaTableTable, AppMetaTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seededMeta = const VerificationMeta('seeded');
  @override
  late final GeneratedColumn<bool> seeded = GeneratedColumn<bool>(
    'seeded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("seeded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [key, seeded];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('seeded')) {
      context.handle(
        _seededMeta,
        seeded.isAcceptableOrUnknown(data['seeded']!, _seededMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppMetaTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      seeded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}seeded'],
      )!,
    );
  }

  @override
  $AppMetaTableTable createAlias(String alias) {
    return $AppMetaTableTable(attachedDatabase, alias);
  }
}

class AppMetaTableData extends DataClass
    implements Insertable<AppMetaTableData> {
  final String key;
  final bool seeded;
  const AppMetaTableData({required this.key, required this.seeded});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['seeded'] = Variable<bool>(seeded);
    return map;
  }

  AppMetaTableCompanion toCompanion(bool nullToAbsent) {
    return AppMetaTableCompanion(key: Value(key), seeded: Value(seeded));
  }

  factory AppMetaTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaTableData(
      key: serializer.fromJson<String>(json['key']),
      seeded: serializer.fromJson<bool>(json['seeded']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'seeded': serializer.toJson<bool>(seeded),
    };
  }

  AppMetaTableData copyWith({String? key, bool? seeded}) =>
      AppMetaTableData(key: key ?? this.key, seeded: seeded ?? this.seeded);
  AppMetaTableData copyWithCompanion(AppMetaTableCompanion data) {
    return AppMetaTableData(
      key: data.key.present ? data.key.value : this.key,
      seeded: data.seeded.present ? data.seeded.value : this.seeded,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaTableData(')
          ..write('key: $key, ')
          ..write('seeded: $seeded')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, seeded);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaTableData &&
          other.key == this.key &&
          other.seeded == this.seeded);
}

class AppMetaTableCompanion extends UpdateCompanion<AppMetaTableData> {
  final Value<String> key;
  final Value<bool> seeded;
  final Value<int> rowid;
  const AppMetaTableCompanion({
    this.key = const Value.absent(),
    this.seeded = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaTableCompanion.insert({
    required String key,
    this.seeded = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppMetaTableData> custom({
    Expression<String>? key,
    Expression<bool>? seeded,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (seeded != null) 'seeded': seeded,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaTableCompanion copyWith({
    Value<String>? key,
    Value<bool>? seeded,
    Value<int>? rowid,
  }) {
    return AppMetaTableCompanion(
      key: key ?? this.key,
      seeded: seeded ?? this.seeded,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (seeded.present) {
      map['seeded'] = Variable<bool>(seeded.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaTableCompanion(')
          ..write('key: $key, ')
          ..write('seeded: $seeded, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ListingsTableTable listingsTable = $ListingsTableTable(this);
  late final $SwipeStatesTableTable swipeStatesTable = $SwipeStatesTableTable(
    this,
  );
  late final $ConversationsTableTable conversationsTable =
      $ConversationsTableTable(this);
  late final $MessagesTableTable messagesTable = $MessagesTableTable(this);
  late final $UserProfilesTableTable userProfilesTable =
      $UserProfilesTableTable(this);
  late final $AppMetaTableTable appMetaTable = $AppMetaTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    listingsTable,
    swipeStatesTable,
    conversationsTable,
    messagesTable,
    userProfilesTable,
    appMetaTable,
  ];
}

typedef $$ListingsTableTableCreateCompanionBuilder =
    ListingsTableCompanion Function({
      required String id,
      required int type,
      required String title,
      required double price,
      required String description,
      required String imageUrls,
      required String category,
      required String location,
      Value<String?> duration,
      Value<bool> remoteOnly,
      Value<int> status,
      Value<String> ownerId,
      Value<int> rowid,
    });
typedef $$ListingsTableTableUpdateCompanionBuilder =
    ListingsTableCompanion Function({
      Value<String> id,
      Value<int> type,
      Value<String> title,
      Value<double> price,
      Value<String> description,
      Value<String> imageUrls,
      Value<String> category,
      Value<String> location,
      Value<String?> duration,
      Value<bool> remoteOnly,
      Value<int> status,
      Value<String> ownerId,
      Value<int> rowid,
    });

class $$ListingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ListingsTableTable> {
  $$ListingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrls => $composableBuilder(
    column: $table.imageUrls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remoteOnly => $composableBuilder(
    column: $table.remoteOnly,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ListingsTableTable> {
  $$ListingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrls => $composableBuilder(
    column: $table.imageUrls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remoteOnly => $composableBuilder(
    column: $table.remoteOnly,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListingsTableTable> {
  $$ListingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrls =>
      $composableBuilder(column: $table.imageUrls, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<String> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<bool> get remoteOnly => $composableBuilder(
    column: $table.remoteOnly,
    builder: (column) => column,
  );

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);
}

class $$ListingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListingsTableTable,
          ListingsTableData,
          $$ListingsTableTableFilterComposer,
          $$ListingsTableTableOrderingComposer,
          $$ListingsTableTableAnnotationComposer,
          $$ListingsTableTableCreateCompanionBuilder,
          $$ListingsTableTableUpdateCompanionBuilder,
          (
            ListingsTableData,
            BaseReferences<
              _$AppDatabase,
              $ListingsTableTable,
              ListingsTableData
            >,
          ),
          ListingsTableData,
          PrefetchHooks Function()
        > {
  $$ListingsTableTableTableManager(_$AppDatabase db, $ListingsTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> imageUrls = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<String?> duration = const Value.absent(),
                Value<bool> remoteOnly = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListingsTableCompanion(
                id: id,
                type: type,
                title: title,
                price: price,
                description: description,
                imageUrls: imageUrls,
                category: category,
                location: location,
                duration: duration,
                remoteOnly: remoteOnly,
                status: status,
                ownerId: ownerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int type,
                required String title,
                required double price,
                required String description,
                required String imageUrls,
                required String category,
                required String location,
                Value<String?> duration = const Value.absent(),
                Value<bool> remoteOnly = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListingsTableCompanion.insert(
                id: id,
                type: type,
                title: title,
                price: price,
                description: description,
                imageUrls: imageUrls,
                category: category,
                location: location,
                duration: duration,
                remoteOnly: remoteOnly,
                status: status,
                ownerId: ownerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ListingsTableTable, ListingsTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ListingsTableTable,
                    ListingsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListingsTableTable,
      ListingsTableData,
      $$ListingsTableTableFilterComposer,
      $$ListingsTableTableOrderingComposer,
      $$ListingsTableTableAnnotationComposer,
      $$ListingsTableTableCreateCompanionBuilder,
      $$ListingsTableTableUpdateCompanionBuilder,
      (
        ListingsTableData,
        BaseReferences<_$AppDatabase, $ListingsTableTable, ListingsTableData>,
      ),
      ListingsTableData,
      PrefetchHooks Function()
    >;
typedef $$SwipeStatesTableTableCreateCompanionBuilder =
    SwipeStatesTableCompanion Function({
      required String listingId,
      required int action,
      required DateTime actedAt,
      Value<int> rowid,
    });
typedef $$SwipeStatesTableTableUpdateCompanionBuilder =
    SwipeStatesTableCompanion Function({
      Value<String> listingId,
      Value<int> action,
      Value<DateTime> actedAt,
      Value<int> rowid,
    });

class $$SwipeStatesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SwipeStatesTableTable> {
  $$SwipeStatesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get listingId => $composableBuilder(
    column: $table.listingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get actedAt => $composableBuilder(
    column: $table.actedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SwipeStatesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SwipeStatesTableTable> {
  $$SwipeStatesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get listingId => $composableBuilder(
    column: $table.listingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get actedAt => $composableBuilder(
    column: $table.actedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SwipeStatesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SwipeStatesTableTable> {
  $$SwipeStatesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get listingId =>
      $composableBuilder(column: $table.listingId, builder: (column) => column);

  GeneratedColumn<int> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<DateTime> get actedAt =>
      $composableBuilder(column: $table.actedAt, builder: (column) => column);
}

class $$SwipeStatesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SwipeStatesTableTable,
          SwipeStatesTableData,
          $$SwipeStatesTableTableFilterComposer,
          $$SwipeStatesTableTableOrderingComposer,
          $$SwipeStatesTableTableAnnotationComposer,
          $$SwipeStatesTableTableCreateCompanionBuilder,
          $$SwipeStatesTableTableUpdateCompanionBuilder,
          (
            SwipeStatesTableData,
            BaseReferences<
              _$AppDatabase,
              $SwipeStatesTableTable,
              SwipeStatesTableData
            >,
          ),
          SwipeStatesTableData,
          PrefetchHooks Function()
        > {
  $$SwipeStatesTableTableTableManager(
    _$AppDatabase db,
    $SwipeStatesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SwipeStatesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SwipeStatesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SwipeStatesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> listingId = const Value.absent(),
                Value<int> action = const Value.absent(),
                Value<DateTime> actedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SwipeStatesTableCompanion(
                listingId: listingId,
                action: action,
                actedAt: actedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String listingId,
                required int action,
                required DateTime actedAt,
                Value<int> rowid = const Value.absent(),
              }) => SwipeStatesTableCompanion.insert(
                listingId: listingId,
                action: action,
                actedAt: actedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SwipeStatesTableTable, SwipeStatesTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SwipeStatesTableTable,
                    SwipeStatesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SwipeStatesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SwipeStatesTableTable,
      SwipeStatesTableData,
      $$SwipeStatesTableTableFilterComposer,
      $$SwipeStatesTableTableOrderingComposer,
      $$SwipeStatesTableTableAnnotationComposer,
      $$SwipeStatesTableTableCreateCompanionBuilder,
      $$SwipeStatesTableTableUpdateCompanionBuilder,
      (
        SwipeStatesTableData,
        BaseReferences<
          _$AppDatabase,
          $SwipeStatesTableTable,
          SwipeStatesTableData
        >,
      ),
      SwipeStatesTableData,
      PrefetchHooks Function()
    >;
typedef $$ConversationsTableTableCreateCompanionBuilder =
    ConversationsTableCompanion Function({
      required String id,
      required String participantName,
      required String participantAvatar,
      required String lastMessage,
      required DateTime timestamp,
      Value<int> unreadCount,
      required int role,
      required String listingTitle,
      required String listingId,
      Value<String> otherUserId,
      Value<bool> archived,
      Value<DateTime?> otherLastReadAt,
      Value<int> rowid,
    });
typedef $$ConversationsTableTableUpdateCompanionBuilder =
    ConversationsTableCompanion Function({
      Value<String> id,
      Value<String> participantName,
      Value<String> participantAvatar,
      Value<String> lastMessage,
      Value<DateTime> timestamp,
      Value<int> unreadCount,
      Value<int> role,
      Value<String> listingTitle,
      Value<String> listingId,
      Value<String> otherUserId,
      Value<bool> archived,
      Value<DateTime?> otherLastReadAt,
      Value<int> rowid,
    });

class $$ConversationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ConversationsTableTable> {
  $$ConversationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantName => $composableBuilder(
    column: $table.participantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantAvatar => $composableBuilder(
    column: $table.participantAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listingTitle => $composableBuilder(
    column: $table.listingTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get listingId => $composableBuilder(
    column: $table.listingId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get otherLastReadAt => $composableBuilder(
    column: $table.otherLastReadAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConversationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ConversationsTableTable> {
  $$ConversationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantName => $composableBuilder(
    column: $table.participantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantAvatar => $composableBuilder(
    column: $table.participantAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listingTitle => $composableBuilder(
    column: $table.listingTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get listingId => $composableBuilder(
    column: $table.listingId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get otherLastReadAt => $composableBuilder(
    column: $table.otherLastReadAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConversationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConversationsTableTable> {
  $$ConversationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get participantName => $composableBuilder(
    column: $table.participantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get participantAvatar => $composableBuilder(
    column: $table.participantAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessage => $composableBuilder(
    column: $table.lastMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get listingTitle => $composableBuilder(
    column: $table.listingTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get listingId =>
      $composableBuilder(column: $table.listingId, builder: (column) => column);

  GeneratedColumn<String> get otherUserId => $composableBuilder(
    column: $table.otherUserId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<DateTime> get otherLastReadAt => $composableBuilder(
    column: $table.otherLastReadAt,
    builder: (column) => column,
  );
}

class $$ConversationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConversationsTableTable,
          ConversationsTableData,
          $$ConversationsTableTableFilterComposer,
          $$ConversationsTableTableOrderingComposer,
          $$ConversationsTableTableAnnotationComposer,
          $$ConversationsTableTableCreateCompanionBuilder,
          $$ConversationsTableTableUpdateCompanionBuilder,
          (
            ConversationsTableData,
            BaseReferences<
              _$AppDatabase,
              $ConversationsTableTable,
              ConversationsTableData
            >,
          ),
          ConversationsTableData,
          PrefetchHooks Function()
        > {
  $$ConversationsTableTableTableManager(
    _$AppDatabase db,
    $ConversationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConversationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConversationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConversationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> participantName = const Value.absent(),
                Value<String> participantAvatar = const Value.absent(),
                Value<String> lastMessage = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> role = const Value.absent(),
                Value<String> listingTitle = const Value.absent(),
                Value<String> listingId = const Value.absent(),
                Value<String> otherUserId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime?> otherLastReadAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsTableCompanion(
                id: id,
                participantName: participantName,
                participantAvatar: participantAvatar,
                lastMessage: lastMessage,
                timestamp: timestamp,
                unreadCount: unreadCount,
                role: role,
                listingTitle: listingTitle,
                listingId: listingId,
                otherUserId: otherUserId,
                archived: archived,
                otherLastReadAt: otherLastReadAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String participantName,
                required String participantAvatar,
                required String lastMessage,
                required DateTime timestamp,
                Value<int> unreadCount = const Value.absent(),
                required int role,
                required String listingTitle,
                required String listingId,
                Value<String> otherUserId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<DateTime?> otherLastReadAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConversationsTableCompanion.insert(
                id: id,
                participantName: participantName,
                participantAvatar: participantAvatar,
                lastMessage: lastMessage,
                timestamp: timestamp,
                unreadCount: unreadCount,
                role: role,
                listingTitle: listingTitle,
                listingId: listingId,
                otherUserId: otherUserId,
                archived: archived,
                otherLastReadAt: otherLastReadAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConversationsTableTable, ConversationsTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ConversationsTableTable,
                    ConversationsTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConversationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConversationsTableTable,
      ConversationsTableData,
      $$ConversationsTableTableFilterComposer,
      $$ConversationsTableTableOrderingComposer,
      $$ConversationsTableTableAnnotationComposer,
      $$ConversationsTableTableCreateCompanionBuilder,
      $$ConversationsTableTableUpdateCompanionBuilder,
      (
        ConversationsTableData,
        BaseReferences<
          _$AppDatabase,
          $ConversationsTableTable,
          ConversationsTableData
        >,
      ),
      ConversationsTableData,
      PrefetchHooks Function()
    >;
typedef $$MessagesTableTableCreateCompanionBuilder =
    MessagesTableCompanion Function({
      required String id,
      required String conversationId,
      required String body,
      required bool isOutgoing,
      required DateTime sentAt,
      Value<int> rowid,
    });
typedef $$MessagesTableTableUpdateCompanionBuilder =
    MessagesTableCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> body,
      Value<bool> isOutgoing,
      Value<DateTime> sentAt,
      Value<int> rowid,
    });

class $$MessagesTableTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sentAt => $composableBuilder(
    column: $table.sentAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTableTable> {
  $$MessagesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get isOutgoing => $composableBuilder(
    column: $table.isOutgoing,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sentAt =>
      $composableBuilder(column: $table.sentAt, builder: (column) => column);
}

class $$MessagesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTableTable,
          MessagesTableData,
          $$MessagesTableTableFilterComposer,
          $$MessagesTableTableOrderingComposer,
          $$MessagesTableTableAnnotationComposer,
          $$MessagesTableTableCreateCompanionBuilder,
          $$MessagesTableTableUpdateCompanionBuilder,
          (
            MessagesTableData,
            BaseReferences<
              _$AppDatabase,
              $MessagesTableTable,
              MessagesTableData
            >,
          ),
          MessagesTableData,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableTableManager(_$AppDatabase db, $MessagesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<bool> isOutgoing = const Value.absent(),
                Value<DateTime> sentAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MessagesTableCompanion(
                id: id,
                conversationId: conversationId,
                body: body,
                isOutgoing: isOutgoing,
                sentAt: sentAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String body,
                required bool isOutgoing,
                required DateTime sentAt,
                Value<int> rowid = const Value.absent(),
              }) => MessagesTableCompanion.insert(
                id: id,
                conversationId: conversationId,
                body: body,
                isOutgoing: isOutgoing,
                sentAt: sentAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MessagesTableTable, MessagesTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MessagesTableTable,
                    MessagesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTableTable,
      MessagesTableData,
      $$MessagesTableTableFilterComposer,
      $$MessagesTableTableOrderingComposer,
      $$MessagesTableTableAnnotationComposer,
      $$MessagesTableTableCreateCompanionBuilder,
      $$MessagesTableTableUpdateCompanionBuilder,
      (
        MessagesTableData,
        BaseReferences<_$AppDatabase, $MessagesTableTable, MessagesTableData>,
      ),
      MessagesTableData,
      PrefetchHooks Function()
    >;
typedef $$UserProfilesTableTableCreateCompanionBuilder =
    UserProfilesTableCompanion Function({
      required String id,
      required String name,
      required String avatarUrl,
      required double rating,
      required int reviewCount,
      required int listingsCount,
      required int soldCount,
      required DateTime memberSince,
      Value<String> reviewsJson,
      Value<int> rowid,
    });
typedef $$UserProfilesTableTableUpdateCompanionBuilder =
    UserProfilesTableCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> avatarUrl,
      Value<double> rating,
      Value<int> reviewCount,
      Value<int> listingsCount,
      Value<int> soldCount,
      Value<DateTime> memberSince,
      Value<String> reviewsJson,
      Value<int> rowid,
    });

class $$UserProfilesTableTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTableTable> {
  $$UserProfilesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get listingsCount => $composableBuilder(
    column: $table.listingsCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get soldCount => $composableBuilder(
    column: $table.soldCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get memberSince => $composableBuilder(
    column: $table.memberSince,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewsJson => $composableBuilder(
    column: $table.reviewsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTableTable> {
  $$UserProfilesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get listingsCount => $composableBuilder(
    column: $table.listingsCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get soldCount => $composableBuilder(
    column: $table.soldCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get memberSince => $composableBuilder(
    column: $table.memberSince,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewsJson => $composableBuilder(
    column: $table.reviewsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTableTable> {
  $$UserProfilesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get listingsCount => $composableBuilder(
    column: $table.listingsCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get soldCount =>
      $composableBuilder(column: $table.soldCount, builder: (column) => column);

  GeneratedColumn<DateTime> get memberSince => $composableBuilder(
    column: $table.memberSince,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewsJson => $composableBuilder(
    column: $table.reviewsJson,
    builder: (column) => column,
  );
}

class $$UserProfilesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTableTable,
          UserProfilesTableData,
          $$UserProfilesTableTableFilterComposer,
          $$UserProfilesTableTableOrderingComposer,
          $$UserProfilesTableTableAnnotationComposer,
          $$UserProfilesTableTableCreateCompanionBuilder,
          $$UserProfilesTableTableUpdateCompanionBuilder,
          (
            UserProfilesTableData,
            BaseReferences<
              _$AppDatabase,
              $UserProfilesTableTable,
              UserProfilesTableData
            >,
          ),
          UserProfilesTableData,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableTableManager(
    _$AppDatabase db,
    $UserProfilesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> avatarUrl = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> listingsCount = const Value.absent(),
                Value<int> soldCount = const Value.absent(),
                Value<DateTime> memberSince = const Value.absent(),
                Value<String> reviewsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesTableCompanion(
                id: id,
                name: name,
                avatarUrl: avatarUrl,
                rating: rating,
                reviewCount: reviewCount,
                listingsCount: listingsCount,
                soldCount: soldCount,
                memberSince: memberSince,
                reviewsJson: reviewsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String avatarUrl,
                required double rating,
                required int reviewCount,
                required int listingsCount,
                required int soldCount,
                required DateTime memberSince,
                Value<String> reviewsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserProfilesTableCompanion.insert(
                id: id,
                name: name,
                avatarUrl: avatarUrl,
                rating: rating,
                reviewCount: reviewCount,
                listingsCount: listingsCount,
                soldCount: soldCount,
                memberSince: memberSince,
                reviewsJson: reviewsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserProfilesTableTable, UserProfilesTableData>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $UserProfilesTableTable,
                    UserProfilesTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTableTable,
      UserProfilesTableData,
      $$UserProfilesTableTableFilterComposer,
      $$UserProfilesTableTableOrderingComposer,
      $$UserProfilesTableTableAnnotationComposer,
      $$UserProfilesTableTableCreateCompanionBuilder,
      $$UserProfilesTableTableUpdateCompanionBuilder,
      (
        UserProfilesTableData,
        BaseReferences<
          _$AppDatabase,
          $UserProfilesTableTable,
          UserProfilesTableData
        >,
      ),
      UserProfilesTableData,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableTableCreateCompanionBuilder =
    AppMetaTableCompanion Function({
      required String key,
      Value<bool> seeded,
      Value<int> rowid,
    });
typedef $$AppMetaTableTableUpdateCompanionBuilder =
    AppMetaTableCompanion Function({
      Value<String> key,
      Value<bool> seeded,
      Value<int> rowid,
    });

class $$AppMetaTableTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetaTableTable> {
  $$AppMetaTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get seeded => $composableBuilder(
    column: $table.seeded,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetaTableTable> {
  $$AppMetaTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get seeded => $composableBuilder(
    column: $table.seeded,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetaTableTable> {
  $$AppMetaTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<bool> get seeded =>
      $composableBuilder(column: $table.seeded, builder: (column) => column);
}

class $$AppMetaTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetaTableTable,
          AppMetaTableData,
          $$AppMetaTableTableFilterComposer,
          $$AppMetaTableTableOrderingComposer,
          $$AppMetaTableTableAnnotationComposer,
          $$AppMetaTableTableCreateCompanionBuilder,
          $$AppMetaTableTableUpdateCompanionBuilder,
          (
            AppMetaTableData,
            BaseReferences<_$AppDatabase, $AppMetaTableTable, AppMetaTableData>,
          ),
          AppMetaTableData,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableTableManager(_$AppDatabase db, $AppMetaTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<bool> seeded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  AppMetaTableCompanion(key: key, seeded: seeded, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<bool> seeded = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaTableCompanion.insert(
                key: key,
                seeded: seeded,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppMetaTableTable, AppMetaTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppMetaTableTable,
                    AppMetaTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetaTableTable,
      AppMetaTableData,
      $$AppMetaTableTableFilterComposer,
      $$AppMetaTableTableOrderingComposer,
      $$AppMetaTableTableAnnotationComposer,
      $$AppMetaTableTableCreateCompanionBuilder,
      $$AppMetaTableTableUpdateCompanionBuilder,
      (
        AppMetaTableData,
        BaseReferences<_$AppDatabase, $AppMetaTableTable, AppMetaTableData>,
      ),
      AppMetaTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ListingsTableTableTableManager get listingsTable =>
      $$ListingsTableTableTableManager(_db, _db.listingsTable);
  $$SwipeStatesTableTableTableManager get swipeStatesTable =>
      $$SwipeStatesTableTableTableManager(_db, _db.swipeStatesTable);
  $$ConversationsTableTableTableManager get conversationsTable =>
      $$ConversationsTableTableTableManager(_db, _db.conversationsTable);
  $$MessagesTableTableTableManager get messagesTable =>
      $$MessagesTableTableTableManager(_db, _db.messagesTable);
  $$UserProfilesTableTableTableManager get userProfilesTable =>
      $$UserProfilesTableTableTableManager(_db, _db.userProfilesTable);
  $$AppMetaTableTableTableManager get appMetaTable =>
      $$AppMetaTableTableTableManager(_db, _db.appMetaTable);
}
