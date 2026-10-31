// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StepIntervalsTable extends StepIntervals
    with TableInfo<$StepIntervalsTable, StepInterval> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepIntervalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, startMs, endMs, steps];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'step_intervals';
  @override
  VerificationContext validateIntegrity(
    Insertable<StepInterval> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StepInterval map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepInterval(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
    );
  }

  @override
  $StepIntervalsTable createAlias(String alias) {
    return $StepIntervalsTable(attachedDatabase, alias);
  }
}

class StepInterval extends DataClass implements Insertable<StepInterval> {
  final int id;

  /// Epoch milliseconds, local wall-clock independent.
  final int startMs;
  final int endMs;
  final int steps;
  const StepInterval({
    required this.id,
    required this.startMs,
    required this.endMs,
    required this.steps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['steps'] = Variable<int>(steps);
    return map;
  }

  StepIntervalsCompanion toCompanion(bool nullToAbsent) {
    return StepIntervalsCompanion(
      id: Value(id),
      startMs: Value(startMs),
      endMs: Value(endMs),
      steps: Value(steps),
    );
  }

  factory StepInterval.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepInterval(
      id: serializer.fromJson<int>(json['id']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
      steps: serializer.fromJson<int>(json['steps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
      'steps': serializer.toJson<int>(steps),
    };
  }

  StepInterval copyWith({int? id, int? startMs, int? endMs, int? steps}) =>
      StepInterval(
        id: id ?? this.id,
        startMs: startMs ?? this.startMs,
        endMs: endMs ?? this.endMs,
        steps: steps ?? this.steps,
      );
  StepInterval copyWithCompanion(StepIntervalsCompanion data) {
    return StepInterval(
      id: data.id.present ? data.id.value : this.id,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      steps: data.steps.present ? data.steps.value : this.steps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepInterval(')
          ..write('id: $id, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('steps: $steps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startMs, endMs, steps);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepInterval &&
          other.id == this.id &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.steps == this.steps);
}

class StepIntervalsCompanion extends UpdateCompanion<StepInterval> {
  final Value<int> id;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<int> steps;
  const StepIntervalsCompanion({
    this.id = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.steps = const Value.absent(),
  });
  StepIntervalsCompanion.insert({
    this.id = const Value.absent(),
    required int startMs,
    required int endMs,
    required int steps,
  }) : startMs = Value(startMs),
       endMs = Value(endMs),
       steps = Value(steps);
  static Insertable<StepInterval> custom({
    Expression<int>? id,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<int>? steps,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (steps != null) 'steps': steps,
    });
  }

  StepIntervalsCompanion copyWith({
    Value<int>? id,
    Value<int>? startMs,
    Value<int>? endMs,
    Value<int>? steps,
  }) {
    return StepIntervalsCompanion(
      id: id ?? this.id,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      steps: steps ?? this.steps,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepIntervalsCompanion(')
          ..write('id: $id, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('steps: $steps')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
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
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String value;
  const KeyValue({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(key: Value(key), value: Value(value));
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
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

  KeyValue copyWith({String? key, String? value}) =>
      KeyValue(key: key ?? this.key, value: value ?? this.value);
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
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
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
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
  }) : key = Value(key),
       value = Value(value);
  static Insertable<KeyValue> custom({
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

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
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

class $WorkoutsTable extends Workouts with TableInfo<$WorkoutsTable, Workout> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMsMeta = const VerificationMeta(
    'activeMs',
  );
  @override
  late final GeneratedColumn<int> activeMs = GeneratedColumn<int>(
    'active_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceKmMeta = const VerificationMeta(
    'distanceKm',
  );
  @override
  late final GeneratedColumn<double> distanceKm = GeneratedColumn<double>(
    'distance_km',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeKcalMeta = const VerificationMeta(
    'activeKcal',
  );
  @override
  late final GeneratedColumn<double> activeKcal = GeneratedColumn<double>(
    'active_kcal',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stepsMeta = const VerificationMeta('steps');
  @override
  late final GeneratedColumn<int> steps = GeneratedColumn<int>(
    'steps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effortMeta = const VerificationMeta('effort');
  @override
  late final GeneratedColumn<int> effort = GeneratedColumn<int>(
    'effort',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elevationGainMMeta = const VerificationMeta(
    'elevationGainM',
  );
  @override
  late final GeneratedColumn<double> elevationGainM = GeneratedColumn<double>(
    'elevation_gain_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    startMs,
    endMs,
    activeMs,
    distanceKm,
    activeKcal,
    steps,
    effort,
    elevationGainM,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workouts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Workout> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    } else if (isInserting) {
      context.missing(_endMsMeta);
    }
    if (data.containsKey('active_ms')) {
      context.handle(
        _activeMsMeta,
        activeMs.isAcceptableOrUnknown(data['active_ms']!, _activeMsMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMsMeta);
    }
    if (data.containsKey('distance_km')) {
      context.handle(
        _distanceKmMeta,
        distanceKm.isAcceptableOrUnknown(data['distance_km']!, _distanceKmMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceKmMeta);
    }
    if (data.containsKey('active_kcal')) {
      context.handle(
        _activeKcalMeta,
        activeKcal.isAcceptableOrUnknown(data['active_kcal']!, _activeKcalMeta),
      );
    } else if (isInserting) {
      context.missing(_activeKcalMeta);
    }
    if (data.containsKey('steps')) {
      context.handle(
        _stepsMeta,
        steps.isAcceptableOrUnknown(data['steps']!, _stepsMeta),
      );
    } else if (isInserting) {
      context.missing(_stepsMeta);
    }
    if (data.containsKey('effort')) {
      context.handle(
        _effortMeta,
        effort.isAcceptableOrUnknown(data['effort']!, _effortMeta),
      );
    }
    if (data.containsKey('elevation_gain_m')) {
      context.handle(
        _elevationGainMMeta,
        elevationGainM.isAcceptableOrUnknown(
          data['elevation_gain_m']!,
          _elevationGainMMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Workout map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Workout(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      )!,
      activeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_ms'],
      )!,
      distanceKm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_km'],
      )!,
      activeKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}active_kcal'],
      )!,
      steps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steps'],
      )!,
      effort: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effort'],
      ),
      elevationGainM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}elevation_gain_m'],
      )!,
    );
  }

  @override
  $WorkoutsTable createAlias(String alias) {
    return $WorkoutsTable(attachedDatabase, alias);
  }
}

class Workout extends DataClass implements Insertable<Workout> {
  final int id;

  /// `WorkoutType.name`.
  final String type;
  final int startMs;
  final int endMs;

  /// Moving time, start to end less the pauses.
  final int activeMs;
  final double distanceKm;
  final double activeKcal;
  final int steps;
  final int? effort;

  /// Metres climbed, for a GPS workout. Added in schema 3.
  final double elevationGainM;
  const Workout({
    required this.id,
    required this.type,
    required this.startMs,
    required this.endMs,
    required this.activeMs,
    required this.distanceKm,
    required this.activeKcal,
    required this.steps,
    this.effort,
    required this.elevationGainM,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['start_ms'] = Variable<int>(startMs);
    map['end_ms'] = Variable<int>(endMs);
    map['active_ms'] = Variable<int>(activeMs);
    map['distance_km'] = Variable<double>(distanceKm);
    map['active_kcal'] = Variable<double>(activeKcal);
    map['steps'] = Variable<int>(steps);
    if (!nullToAbsent || effort != null) {
      map['effort'] = Variable<int>(effort);
    }
    map['elevation_gain_m'] = Variable<double>(elevationGainM);
    return map;
  }

  WorkoutsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutsCompanion(
      id: Value(id),
      type: Value(type),
      startMs: Value(startMs),
      endMs: Value(endMs),
      activeMs: Value(activeMs),
      distanceKm: Value(distanceKm),
      activeKcal: Value(activeKcal),
      steps: Value(steps),
      effort: effort == null && nullToAbsent
          ? const Value.absent()
          : Value(effort),
      elevationGainM: Value(elevationGainM),
    );
  }

  factory Workout.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Workout(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int>(json['endMs']),
      activeMs: serializer.fromJson<int>(json['activeMs']),
      distanceKm: serializer.fromJson<double>(json['distanceKm']),
      activeKcal: serializer.fromJson<double>(json['activeKcal']),
      steps: serializer.fromJson<int>(json['steps']),
      effort: serializer.fromJson<int?>(json['effort']),
      elevationGainM: serializer.fromJson<double>(json['elevationGainM']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int>(endMs),
      'activeMs': serializer.toJson<int>(activeMs),
      'distanceKm': serializer.toJson<double>(distanceKm),
      'activeKcal': serializer.toJson<double>(activeKcal),
      'steps': serializer.toJson<int>(steps),
      'effort': serializer.toJson<int?>(effort),
      'elevationGainM': serializer.toJson<double>(elevationGainM),
    };
  }

  Workout copyWith({
    int? id,
    String? type,
    int? startMs,
    int? endMs,
    int? activeMs,
    double? distanceKm,
    double? activeKcal,
    int? steps,
    Value<int?> effort = const Value.absent(),
    double? elevationGainM,
  }) => Workout(
    id: id ?? this.id,
    type: type ?? this.type,
    startMs: startMs ?? this.startMs,
    endMs: endMs ?? this.endMs,
    activeMs: activeMs ?? this.activeMs,
    distanceKm: distanceKm ?? this.distanceKm,
    activeKcal: activeKcal ?? this.activeKcal,
    steps: steps ?? this.steps,
    effort: effort.present ? effort.value : this.effort,
    elevationGainM: elevationGainM ?? this.elevationGainM,
  );
  Workout copyWithCompanion(WorkoutsCompanion data) {
    return Workout(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      activeMs: data.activeMs.present ? data.activeMs.value : this.activeMs,
      distanceKm: data.distanceKm.present
          ? data.distanceKm.value
          : this.distanceKm,
      activeKcal: data.activeKcal.present
          ? data.activeKcal.value
          : this.activeKcal,
      steps: data.steps.present ? data.steps.value : this.steps,
      effort: data.effort.present ? data.effort.value : this.effort,
      elevationGainM: data.elevationGainM.present
          ? data.elevationGainM.value
          : this.elevationGainM,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Workout(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('activeMs: $activeMs, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('steps: $steps, ')
          ..write('effort: $effort, ')
          ..write('elevationGainM: $elevationGainM')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    startMs,
    endMs,
    activeMs,
    distanceKm,
    activeKcal,
    steps,
    effort,
    elevationGainM,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Workout &&
          other.id == this.id &&
          other.type == this.type &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.activeMs == this.activeMs &&
          other.distanceKm == this.distanceKm &&
          other.activeKcal == this.activeKcal &&
          other.steps == this.steps &&
          other.effort == this.effort &&
          other.elevationGainM == this.elevationGainM);
}

class WorkoutsCompanion extends UpdateCompanion<Workout> {
  final Value<int> id;
  final Value<String> type;
  final Value<int> startMs;
  final Value<int> endMs;
  final Value<int> activeMs;
  final Value<double> distanceKm;
  final Value<double> activeKcal;
  final Value<int> steps;
  final Value<int?> effort;
  final Value<double> elevationGainM;
  const WorkoutsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.activeMs = const Value.absent(),
    this.distanceKm = const Value.absent(),
    this.activeKcal = const Value.absent(),
    this.steps = const Value.absent(),
    this.effort = const Value.absent(),
    this.elevationGainM = const Value.absent(),
  });
  WorkoutsCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    required int startMs,
    required int endMs,
    required int activeMs,
    required double distanceKm,
    required double activeKcal,
    required int steps,
    this.effort = const Value.absent(),
    this.elevationGainM = const Value.absent(),
  }) : type = Value(type),
       startMs = Value(startMs),
       endMs = Value(endMs),
       activeMs = Value(activeMs),
       distanceKm = Value(distanceKm),
       activeKcal = Value(activeKcal),
       steps = Value(steps);
  static Insertable<Workout> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<int>? activeMs,
    Expression<double>? distanceKm,
    Expression<double>? activeKcal,
    Expression<int>? steps,
    Expression<int>? effort,
    Expression<double>? elevationGainM,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (activeMs != null) 'active_ms': activeMs,
      if (distanceKm != null) 'distance_km': distanceKm,
      if (activeKcal != null) 'active_kcal': activeKcal,
      if (steps != null) 'steps': steps,
      if (effort != null) 'effort': effort,
      if (elevationGainM != null) 'elevation_gain_m': elevationGainM,
    });
  }

  WorkoutsCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<int>? startMs,
    Value<int>? endMs,
    Value<int>? activeMs,
    Value<double>? distanceKm,
    Value<double>? activeKcal,
    Value<int>? steps,
    Value<int?>? effort,
    Value<double>? elevationGainM,
  }) {
    return WorkoutsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      activeMs: activeMs ?? this.activeMs,
      distanceKm: distanceKm ?? this.distanceKm,
      activeKcal: activeKcal ?? this.activeKcal,
      steps: steps ?? this.steps,
      effort: effort ?? this.effort,
      elevationGainM: elevationGainM ?? this.elevationGainM,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (activeMs.present) {
      map['active_ms'] = Variable<int>(activeMs.value);
    }
    if (distanceKm.present) {
      map['distance_km'] = Variable<double>(distanceKm.value);
    }
    if (activeKcal.present) {
      map['active_kcal'] = Variable<double>(activeKcal.value);
    }
    if (steps.present) {
      map['steps'] = Variable<int>(steps.value);
    }
    if (effort.present) {
      map['effort'] = Variable<int>(effort.value);
    }
    if (elevationGainM.present) {
      map['elevation_gain_m'] = Variable<double>(elevationGainM.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('activeMs: $activeMs, ')
          ..write('distanceKm: $distanceKm, ')
          ..write('activeKcal: $activeKcal, ')
          ..write('steps: $steps, ')
          ..write('effort: $effort, ')
          ..write('elevationGainM: $elevationGainM')
          ..write(')'))
        .toString();
  }
}

class $WorkoutPointsTable extends WorkoutPoints
    with TableInfo<$WorkoutPointsTable, WorkoutPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _workoutIdMeta = const VerificationMeta(
    'workoutId',
  );
  @override
  late final GeneratedColumn<int> workoutId = GeneratedColumn<int>(
    'workout_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workouts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _segmentMeta = const VerificationMeta(
    'segment',
  );
  @override
  late final GeneratedColumn<int> segment = GeneratedColumn<int>(
    'segment',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workoutId,
    latitude,
    longitude,
    altitude,
    elapsedMs,
    segment,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('workout_id')) {
      context.handle(
        _workoutIdMeta,
        workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('segment')) {
      context.handle(
        _segmentMeta,
        segment.isAcceptableOrUnknown(data['segment']!, _segmentMeta),
      );
    } else if (isInserting) {
      context.missing(_segmentMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      workoutId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}workout_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      segment: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}segment'],
      )!,
    );
  }

  @override
  $WorkoutPointsTable createAlias(String alias) {
    return $WorkoutPointsTable(attachedDatabase, alias);
  }
}

class WorkoutPoint extends DataClass implements Insertable<WorkoutPoint> {
  final int id;
  final int workoutId;
  final double latitude;
  final double longitude;
  final double? altitude;

  /// Moving time at the fix.
  final int elapsedMs;

  /// The stretch of moving it belongs to; a new one after every pause.
  final int segment;
  const WorkoutPoint({
    required this.id,
    required this.workoutId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.elapsedMs,
    required this.segment,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['workout_id'] = Variable<int>(workoutId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['segment'] = Variable<int>(segment);
    return map;
  }

  WorkoutPointsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutPointsCompanion(
      id: Value(id),
      workoutId: Value(workoutId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      elapsedMs: Value(elapsedMs),
      segment: Value(segment),
    );
  }

  factory WorkoutPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutPoint(
      id: serializer.fromJson<int>(json['id']),
      workoutId: serializer.fromJson<int>(json['workoutId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      segment: serializer.fromJson<int>(json['segment']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'workoutId': serializer.toJson<int>(workoutId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'altitude': serializer.toJson<double?>(altitude),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'segment': serializer.toJson<int>(segment),
    };
  }

  WorkoutPoint copyWith({
    int? id,
    int? workoutId,
    double? latitude,
    double? longitude,
    Value<double?> altitude = const Value.absent(),
    int? elapsedMs,
    int? segment,
  }) => WorkoutPoint(
    id: id ?? this.id,
    workoutId: workoutId ?? this.workoutId,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitude: altitude.present ? altitude.value : this.altitude,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    segment: segment ?? this.segment,
  );
  WorkoutPoint copyWithCompanion(WorkoutPointsCompanion data) {
    return WorkoutPoint(
      id: data.id.present ? data.id.value : this.id,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      segment: data.segment.present ? data.segment.value : this.segment,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPoint(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('segment: $segment')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workoutId,
    latitude,
    longitude,
    altitude,
    elapsedMs,
    segment,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutPoint &&
          other.id == this.id &&
          other.workoutId == this.workoutId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitude == this.altitude &&
          other.elapsedMs == this.elapsedMs &&
          other.segment == this.segment);
}

class WorkoutPointsCompanion extends UpdateCompanion<WorkoutPoint> {
  final Value<int> id;
  final Value<int> workoutId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> altitude;
  final Value<int> elapsedMs;
  final Value<int> segment;
  const WorkoutPointsCompanion({
    this.id = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.segment = const Value.absent(),
  });
  WorkoutPointsCompanion.insert({
    this.id = const Value.absent(),
    required int workoutId,
    required double latitude,
    required double longitude,
    this.altitude = const Value.absent(),
    required int elapsedMs,
    required int segment,
  }) : workoutId = Value(workoutId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       elapsedMs = Value(elapsedMs),
       segment = Value(segment);
  static Insertable<WorkoutPoint> custom({
    Expression<int>? id,
    Expression<int>? workoutId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitude,
    Expression<int>? elapsedMs,
    Expression<int>? segment,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workoutId != null) 'workout_id': workoutId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (segment != null) 'segment': segment,
    });
  }

  WorkoutPointsCompanion copyWith({
    Value<int>? id,
    Value<int>? workoutId,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? altitude,
    Value<int>? elapsedMs,
    Value<int>? segment,
  }) {
    return WorkoutPointsCompanion(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      segment: segment ?? this.segment,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<int>(workoutId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (segment.present) {
      map['segment'] = Variable<int>(segment.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPointsCompanion(')
          ..write('id: $id, ')
          ..write('workoutId: $workoutId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('segment: $segment')
          ..write(')'))
        .toString();
  }
}

class $SleepSessionsTable extends SleepSessions
    with TableInfo<$SleepSessionsTable, SleepSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _startMsMeta = const VerificationMeta(
    'startMs',
  );
  @override
  late final GeneratedColumn<int> startMs = GeneratedColumn<int>(
    'start_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endMsMeta = const VerificationMeta('endMs');
  @override
  late final GeneratedColumn<int> endMs = GeneratedColumn<int>(
    'end_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hypnogramMeta = const VerificationMeta(
    'hypnogram',
  );
  @override
  late final GeneratedColumn<String> hypnogram = GeneratedColumn<String>(
    'hypnogram',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [id, startMs, endMs, source, hypnogram];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SleepSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('start_ms')) {
      context.handle(
        _startMsMeta,
        startMs.isAcceptableOrUnknown(data['start_ms']!, _startMsMeta),
      );
    } else if (isInserting) {
      context.missing(_startMsMeta);
    }
    if (data.containsKey('end_ms')) {
      context.handle(
        _endMsMeta,
        endMs.isAcceptableOrUnknown(data['end_ms']!, _endMsMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('hypnogram')) {
      context.handle(
        _hypnogramMeta,
        hypnogram.isAcceptableOrUnknown(data['hypnogram']!, _hypnogramMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SleepSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      startMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_ms'],
      )!,
      endMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_ms'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      hypnogram: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hypnogram'],
      )!,
    );
  }

  @override
  $SleepSessionsTable createAlias(String alias) {
    return $SleepSessionsTable(attachedDatabase, alias);
  }
}

class SleepSession extends DataClass implements Insertable<SleepSession> {
  final int id;
  final int startMs;
  final int? endMs;

  /// `SleepSource.name`.
  final String source;

  /// A letter per minute from the start: the estimated stages. Written when
  /// tracking ends; empty for a night entered by hand.
  final String hypnogram;
  const SleepSession({
    required this.id,
    required this.startMs,
    this.endMs,
    required this.source,
    required this.hypnogram,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['start_ms'] = Variable<int>(startMs);
    if (!nullToAbsent || endMs != null) {
      map['end_ms'] = Variable<int>(endMs);
    }
    map['source'] = Variable<String>(source);
    map['hypnogram'] = Variable<String>(hypnogram);
    return map;
  }

  SleepSessionsCompanion toCompanion(bool nullToAbsent) {
    return SleepSessionsCompanion(
      id: Value(id),
      startMs: Value(startMs),
      endMs: endMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endMs),
      source: Value(source),
      hypnogram: Value(hypnogram),
    );
  }

  factory SleepSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepSession(
      id: serializer.fromJson<int>(json['id']),
      startMs: serializer.fromJson<int>(json['startMs']),
      endMs: serializer.fromJson<int?>(json['endMs']),
      source: serializer.fromJson<String>(json['source']),
      hypnogram: serializer.fromJson<String>(json['hypnogram']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'startMs': serializer.toJson<int>(startMs),
      'endMs': serializer.toJson<int?>(endMs),
      'source': serializer.toJson<String>(source),
      'hypnogram': serializer.toJson<String>(hypnogram),
    };
  }

  SleepSession copyWith({
    int? id,
    int? startMs,
    Value<int?> endMs = const Value.absent(),
    String? source,
    String? hypnogram,
  }) => SleepSession(
    id: id ?? this.id,
    startMs: startMs ?? this.startMs,
    endMs: endMs.present ? endMs.value : this.endMs,
    source: source ?? this.source,
    hypnogram: hypnogram ?? this.hypnogram,
  );
  SleepSession copyWithCompanion(SleepSessionsCompanion data) {
    return SleepSession(
      id: data.id.present ? data.id.value : this.id,
      startMs: data.startMs.present ? data.startMs.value : this.startMs,
      endMs: data.endMs.present ? data.endMs.value : this.endMs,
      source: data.source.present ? data.source.value : this.source,
      hypnogram: data.hypnogram.present ? data.hypnogram.value : this.hypnogram,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepSession(')
          ..write('id: $id, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('source: $source, ')
          ..write('hypnogram: $hypnogram')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, startMs, endMs, source, hypnogram);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepSession &&
          other.id == this.id &&
          other.startMs == this.startMs &&
          other.endMs == this.endMs &&
          other.source == this.source &&
          other.hypnogram == this.hypnogram);
}

class SleepSessionsCompanion extends UpdateCompanion<SleepSession> {
  final Value<int> id;
  final Value<int> startMs;
  final Value<int?> endMs;
  final Value<String> source;
  final Value<String> hypnogram;
  const SleepSessionsCompanion({
    this.id = const Value.absent(),
    this.startMs = const Value.absent(),
    this.endMs = const Value.absent(),
    this.source = const Value.absent(),
    this.hypnogram = const Value.absent(),
  });
  SleepSessionsCompanion.insert({
    this.id = const Value.absent(),
    required int startMs,
    this.endMs = const Value.absent(),
    required String source,
    this.hypnogram = const Value.absent(),
  }) : startMs = Value(startMs),
       source = Value(source);
  static Insertable<SleepSession> custom({
    Expression<int>? id,
    Expression<int>? startMs,
    Expression<int>? endMs,
    Expression<String>? source,
    Expression<String>? hypnogram,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (startMs != null) 'start_ms': startMs,
      if (endMs != null) 'end_ms': endMs,
      if (source != null) 'source': source,
      if (hypnogram != null) 'hypnogram': hypnogram,
    });
  }

  SleepSessionsCompanion copyWith({
    Value<int>? id,
    Value<int>? startMs,
    Value<int?>? endMs,
    Value<String>? source,
    Value<String>? hypnogram,
  }) {
    return SleepSessionsCompanion(
      id: id ?? this.id,
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
      source: source ?? this.source,
      hypnogram: hypnogram ?? this.hypnogram,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (startMs.present) {
      map['start_ms'] = Variable<int>(startMs.value);
    }
    if (endMs.present) {
      map['end_ms'] = Variable<int>(endMs.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (hypnogram.present) {
      map['hypnogram'] = Variable<String>(hypnogram.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SleepSessionsCompanion(')
          ..write('id: $id, ')
          ..write('startMs: $startMs, ')
          ..write('endMs: $endMs, ')
          ..write('source: $source, ')
          ..write('hypnogram: $hypnogram')
          ..write(')'))
        .toString();
  }
}

class $SleepMinutesTable extends SleepMinutes
    with TableInfo<$SleepMinutesTable, SleepMinute> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SleepMinutesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sleep_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [sessionId, minute, count];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sleep_minutes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SleepMinute> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, minute};
  @override
  SleepMinute map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SleepMinute(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
    );
  }

  @override
  $SleepMinutesTable createAlias(String alias) {
    return $SleepMinutesTable(attachedDatabase, alias);
  }
}

class SleepMinute extends DataClass implements Insertable<SleepMinute> {
  final int sessionId;

  /// Minutes since the session started.
  final int minute;

  /// Moments of movement felt in that minute.
  final int count;
  const SleepMinute({
    required this.sessionId,
    required this.minute,
    required this.count,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<int>(sessionId);
    map['minute'] = Variable<int>(minute);
    map['count'] = Variable<int>(count);
    return map;
  }

  SleepMinutesCompanion toCompanion(bool nullToAbsent) {
    return SleepMinutesCompanion(
      sessionId: Value(sessionId),
      minute: Value(minute),
      count: Value(count),
    );
  }

  factory SleepMinute.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SleepMinute(
      sessionId: serializer.fromJson<int>(json['sessionId']),
      minute: serializer.fromJson<int>(json['minute']),
      count: serializer.fromJson<int>(json['count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<int>(sessionId),
      'minute': serializer.toJson<int>(minute),
      'count': serializer.toJson<int>(count),
    };
  }

  SleepMinute copyWith({int? sessionId, int? minute, int? count}) =>
      SleepMinute(
        sessionId: sessionId ?? this.sessionId,
        minute: minute ?? this.minute,
        count: count ?? this.count,
      );
  SleepMinute copyWithCompanion(SleepMinutesCompanion data) {
    return SleepMinute(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      minute: data.minute.present ? data.minute.value : this.minute,
      count: data.count.present ? data.count.value : this.count,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SleepMinute(')
          ..write('sessionId: $sessionId, ')
          ..write('minute: $minute, ')
          ..write('count: $count')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, minute, count);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SleepMinute &&
          other.sessionId == this.sessionId &&
          other.minute == this.minute &&
          other.count == this.count);
}

class SleepMinutesCompanion extends UpdateCompanion<SleepMinute> {
  final Value<int> sessionId;
  final Value<int> minute;
  final Value<int> count;
  final Value<int> rowid;
  const SleepMinutesCompanion({
    this.sessionId = const Value.absent(),
    this.minute = const Value.absent(),
    this.count = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SleepMinutesCompanion.insert({
    required int sessionId,
    required int minute,
    required int count,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       minute = Value(minute),
       count = Value(count);
  static Insertable<SleepMinute> custom({
    Expression<int>? sessionId,
    Expression<int>? minute,
    Expression<int>? count,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (minute != null) 'minute': minute,
      if (count != null) 'count': count,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SleepMinutesCompanion copyWith({
    Value<int>? sessionId,
    Value<int>? minute,
    Value<int>? count,
    Value<int>? rowid,
  }) {
    return SleepMinutesCompanion(
      sessionId: sessionId ?? this.sessionId,
      minute: minute ?? this.minute,
      count: count ?? this.count,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
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
    return (StringBuffer('SleepMinutesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('minute: $minute, ')
          ..write('count: $count, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodEntriesTable extends FoodEntries
    with TableInfo<$FoodEntriesTable, FoodRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mealMeta = const VerificationMeta('meal');
  @override
  late final GeneratedColumn<String> meal = GeneratedColumn<String>(
    'meal',
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
  static const VerificationMeta _kcalMeta = const VerificationMeta('kcal');
  @override
  late final GeneratedColumn<double> kcal = GeneratedColumn<double>(
    'kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinMeta = const VerificationMeta(
    'protein',
  );
  @override
  late final GeneratedColumn<double> protein = GeneratedColumn<double>(
    'protein',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsMeta = const VerificationMeta('carbs');
  @override
  late final GeneratedColumn<double> carbs = GeneratedColumn<double>(
    'carbs',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatMeta = const VerificationMeta('fat');
  @override
  late final GeneratedColumn<double> fat = GeneratedColumn<double>(
    'fat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portionsMeta = const VerificationMeta(
    'portions',
  );
  @override
  late final GeneratedColumn<double> portions = GeneratedColumn<double>(
    'portions',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timeMs,
    meal,
    name,
    kcal,
    protein,
    carbs,
    fat,
    portions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'food_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FoodRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMsMeta);
    }
    if (data.containsKey('meal')) {
      context.handle(
        _mealMeta,
        meal.isAcceptableOrUnknown(data['meal']!, _mealMeta),
      );
    } else if (isInserting) {
      context.missing(_mealMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kcal')) {
      context.handle(
        _kcalMeta,
        kcal.isAcceptableOrUnknown(data['kcal']!, _kcalMeta),
      );
    }
    if (data.containsKey('protein')) {
      context.handle(
        _proteinMeta,
        protein.isAcceptableOrUnknown(data['protein']!, _proteinMeta),
      );
    }
    if (data.containsKey('carbs')) {
      context.handle(
        _carbsMeta,
        carbs.isAcceptableOrUnknown(data['carbs']!, _carbsMeta),
      );
    }
    if (data.containsKey('fat')) {
      context.handle(
        _fatMeta,
        fat.isAcceptableOrUnknown(data['fat']!, _fatMeta),
      );
    }
    if (data.containsKey('portions')) {
      context.handle(
        _portionsMeta,
        portions.isAcceptableOrUnknown(data['portions']!, _portionsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FoodRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FoodRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      )!,
      meal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meal'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kcal'],
      ),
      protein: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein'],
      ),
      carbs: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs'],
      ),
      fat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat'],
      ),
      portions: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}portions'],
      )!,
    );
  }

  @override
  $FoodEntriesTable createAlias(String alias) {
    return $FoodEntriesTable(attachedDatabase, alias);
  }
}

class FoodRow extends DataClass implements Insertable<FoodRow> {
  final int id;
  final int timeMs;

  /// `Meal.name`.
  final String meal;
  final String name;
  final double? kcal;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double portions;
  const FoodRow({
    required this.id,
    required this.timeMs,
    required this.meal,
    required this.name,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
    required this.portions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['time_ms'] = Variable<int>(timeMs);
    map['meal'] = Variable<String>(meal);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || kcal != null) {
      map['kcal'] = Variable<double>(kcal);
    }
    if (!nullToAbsent || protein != null) {
      map['protein'] = Variable<double>(protein);
    }
    if (!nullToAbsent || carbs != null) {
      map['carbs'] = Variable<double>(carbs);
    }
    if (!nullToAbsent || fat != null) {
      map['fat'] = Variable<double>(fat);
    }
    map['portions'] = Variable<double>(portions);
    return map;
  }

  FoodEntriesCompanion toCompanion(bool nullToAbsent) {
    return FoodEntriesCompanion(
      id: Value(id),
      timeMs: Value(timeMs),
      meal: Value(meal),
      name: Value(name),
      kcal: kcal == null && nullToAbsent ? const Value.absent() : Value(kcal),
      protein: protein == null && nullToAbsent
          ? const Value.absent()
          : Value(protein),
      carbs: carbs == null && nullToAbsent
          ? const Value.absent()
          : Value(carbs),
      fat: fat == null && nullToAbsent ? const Value.absent() : Value(fat),
      portions: Value(portions),
    );
  }

  factory FoodRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FoodRow(
      id: serializer.fromJson<int>(json['id']),
      timeMs: serializer.fromJson<int>(json['timeMs']),
      meal: serializer.fromJson<String>(json['meal']),
      name: serializer.fromJson<String>(json['name']),
      kcal: serializer.fromJson<double?>(json['kcal']),
      protein: serializer.fromJson<double?>(json['protein']),
      carbs: serializer.fromJson<double?>(json['carbs']),
      fat: serializer.fromJson<double?>(json['fat']),
      portions: serializer.fromJson<double>(json['portions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timeMs': serializer.toJson<int>(timeMs),
      'meal': serializer.toJson<String>(meal),
      'name': serializer.toJson<String>(name),
      'kcal': serializer.toJson<double?>(kcal),
      'protein': serializer.toJson<double?>(protein),
      'carbs': serializer.toJson<double?>(carbs),
      'fat': serializer.toJson<double?>(fat),
      'portions': serializer.toJson<double>(portions),
    };
  }

  FoodRow copyWith({
    int? id,
    int? timeMs,
    String? meal,
    String? name,
    Value<double?> kcal = const Value.absent(),
    Value<double?> protein = const Value.absent(),
    Value<double?> carbs = const Value.absent(),
    Value<double?> fat = const Value.absent(),
    double? portions,
  }) => FoodRow(
    id: id ?? this.id,
    timeMs: timeMs ?? this.timeMs,
    meal: meal ?? this.meal,
    name: name ?? this.name,
    kcal: kcal.present ? kcal.value : this.kcal,
    protein: protein.present ? protein.value : this.protein,
    carbs: carbs.present ? carbs.value : this.carbs,
    fat: fat.present ? fat.value : this.fat,
    portions: portions ?? this.portions,
  );
  FoodRow copyWithCompanion(FoodEntriesCompanion data) {
    return FoodRow(
      id: data.id.present ? data.id.value : this.id,
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      meal: data.meal.present ? data.meal.value : this.meal,
      name: data.name.present ? data.name.value : this.name,
      kcal: data.kcal.present ? data.kcal.value : this.kcal,
      protein: data.protein.present ? data.protein.value : this.protein,
      carbs: data.carbs.present ? data.carbs.value : this.carbs,
      fat: data.fat.present ? data.fat.value : this.fat,
      portions: data.portions.present ? data.portions.value : this.portions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FoodRow(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('meal: $meal, ')
          ..write('name: $name, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('portions: $portions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, timeMs, meal, name, kcal, protein, carbs, fat, portions);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodRow &&
          other.id == this.id &&
          other.timeMs == this.timeMs &&
          other.meal == this.meal &&
          other.name == this.name &&
          other.kcal == this.kcal &&
          other.protein == this.protein &&
          other.carbs == this.carbs &&
          other.fat == this.fat &&
          other.portions == this.portions);
}

class FoodEntriesCompanion extends UpdateCompanion<FoodRow> {
  final Value<int> id;
  final Value<int> timeMs;
  final Value<String> meal;
  final Value<String> name;
  final Value<double?> kcal;
  final Value<double?> protein;
  final Value<double?> carbs;
  final Value<double?> fat;
  final Value<double> portions;
  const FoodEntriesCompanion({
    this.id = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.meal = const Value.absent(),
    this.name = const Value.absent(),
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.portions = const Value.absent(),
  });
  FoodEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int timeMs,
    required String meal,
    required String name,
    this.kcal = const Value.absent(),
    this.protein = const Value.absent(),
    this.carbs = const Value.absent(),
    this.fat = const Value.absent(),
    this.portions = const Value.absent(),
  }) : timeMs = Value(timeMs),
       meal = Value(meal),
       name = Value(name);
  static Insertable<FoodRow> custom({
    Expression<int>? id,
    Expression<int>? timeMs,
    Expression<String>? meal,
    Expression<String>? name,
    Expression<double>? kcal,
    Expression<double>? protein,
    Expression<double>? carbs,
    Expression<double>? fat,
    Expression<double>? portions,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timeMs != null) 'time_ms': timeMs,
      if (meal != null) 'meal': meal,
      if (name != null) 'name': name,
      if (kcal != null) 'kcal': kcal,
      if (protein != null) 'protein': protein,
      if (carbs != null) 'carbs': carbs,
      if (fat != null) 'fat': fat,
      if (portions != null) 'portions': portions,
    });
  }

  FoodEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? timeMs,
    Value<String>? meal,
    Value<String>? name,
    Value<double?>? kcal,
    Value<double?>? protein,
    Value<double?>? carbs,
    Value<double?>? fat,
    Value<double>? portions,
  }) {
    return FoodEntriesCompanion(
      id: id ?? this.id,
      timeMs: timeMs ?? this.timeMs,
      meal: meal ?? this.meal,
      name: name ?? this.name,
      kcal: kcal ?? this.kcal,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      portions: portions ?? this.portions,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (meal.present) {
      map['meal'] = Variable<String>(meal.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kcal.present) {
      map['kcal'] = Variable<double>(kcal.value);
    }
    if (protein.present) {
      map['protein'] = Variable<double>(protein.value);
    }
    if (carbs.present) {
      map['carbs'] = Variable<double>(carbs.value);
    }
    if (fat.present) {
      map['fat'] = Variable<double>(fat.value);
    }
    if (portions.present) {
      map['portions'] = Variable<double>(portions.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodEntriesCompanion(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('meal: $meal, ')
          ..write('name: $name, ')
          ..write('kcal: $kcal, ')
          ..write('protein: $protein, ')
          ..write('carbs: $carbs, ')
          ..write('fat: $fat, ')
          ..write('portions: $portions')
          ..write(')'))
        .toString();
  }
}

class $WaterEntriesTable extends WaterEntries
    with TableInfo<$WaterEntriesTable, WaterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WaterEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mlMeta = const VerificationMeta('ml');
  @override
  late final GeneratedColumn<int> ml = GeneratedColumn<int>(
    'ml',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timeMs, ml];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'water_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WaterEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMsMeta);
    }
    if (data.containsKey('ml')) {
      context.handle(_mlMeta, ml.isAcceptableOrUnknown(data['ml']!, _mlMeta));
    } else if (isInserting) {
      context.missing(_mlMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WaterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WaterEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      )!,
      ml: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ml'],
      )!,
    );
  }

  @override
  $WaterEntriesTable createAlias(String alias) {
    return $WaterEntriesTable(attachedDatabase, alias);
  }
}

class WaterEntry extends DataClass implements Insertable<WaterEntry> {
  final int id;
  final int timeMs;
  final int ml;
  const WaterEntry({required this.id, required this.timeMs, required this.ml});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['time_ms'] = Variable<int>(timeMs);
    map['ml'] = Variable<int>(ml);
    return map;
  }

  WaterEntriesCompanion toCompanion(bool nullToAbsent) {
    return WaterEntriesCompanion(
      id: Value(id),
      timeMs: Value(timeMs),
      ml: Value(ml),
    );
  }

  factory WaterEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WaterEntry(
      id: serializer.fromJson<int>(json['id']),
      timeMs: serializer.fromJson<int>(json['timeMs']),
      ml: serializer.fromJson<int>(json['ml']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timeMs': serializer.toJson<int>(timeMs),
      'ml': serializer.toJson<int>(ml),
    };
  }

  WaterEntry copyWith({int? id, int? timeMs, int? ml}) => WaterEntry(
    id: id ?? this.id,
    timeMs: timeMs ?? this.timeMs,
    ml: ml ?? this.ml,
  );
  WaterEntry copyWithCompanion(WaterEntriesCompanion data) {
    return WaterEntry(
      id: data.id.present ? data.id.value : this.id,
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      ml: data.ml.present ? data.ml.value : this.ml,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WaterEntry(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timeMs, ml);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WaterEntry &&
          other.id == this.id &&
          other.timeMs == this.timeMs &&
          other.ml == this.ml);
}

class WaterEntriesCompanion extends UpdateCompanion<WaterEntry> {
  final Value<int> id;
  final Value<int> timeMs;
  final Value<int> ml;
  const WaterEntriesCompanion({
    this.id = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.ml = const Value.absent(),
  });
  WaterEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int timeMs,
    required int ml,
  }) : timeMs = Value(timeMs),
       ml = Value(ml);
  static Insertable<WaterEntry> custom({
    Expression<int>? id,
    Expression<int>? timeMs,
    Expression<int>? ml,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timeMs != null) 'time_ms': timeMs,
      if (ml != null) 'ml': ml,
    });
  }

  WaterEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? timeMs,
    Value<int>? ml,
  }) {
    return WaterEntriesCompanion(
      id: id ?? this.id,
      timeMs: timeMs ?? this.timeMs,
      ml: ml ?? this.ml,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (ml.present) {
      map['ml'] = Variable<int>(ml.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WaterEntriesCompanion(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('ml: $ml')
          ..write(')'))
        .toString();
  }
}

class $WeightEntriesTable extends WeightEntries
    with TableInfo<$WeightEntriesTable, WeightEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timeMs, kg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMsMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    } else if (isInserting) {
      context.missing(_kgMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeightEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      )!,
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      )!,
    );
  }

  @override
  $WeightEntriesTable createAlias(String alias) {
    return $WeightEntriesTable(attachedDatabase, alias);
  }
}

class WeightEntry extends DataClass implements Insertable<WeightEntry> {
  final int id;
  final int timeMs;
  final double kg;
  const WeightEntry({required this.id, required this.timeMs, required this.kg});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['time_ms'] = Variable<int>(timeMs);
    map['kg'] = Variable<double>(kg);
    return map;
  }

  WeightEntriesCompanion toCompanion(bool nullToAbsent) {
    return WeightEntriesCompanion(
      id: Value(id),
      timeMs: Value(timeMs),
      kg: Value(kg),
    );
  }

  factory WeightEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightEntry(
      id: serializer.fromJson<int>(json['id']),
      timeMs: serializer.fromJson<int>(json['timeMs']),
      kg: serializer.fromJson<double>(json['kg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timeMs': serializer.toJson<int>(timeMs),
      'kg': serializer.toJson<double>(kg),
    };
  }

  WeightEntry copyWith({int? id, int? timeMs, double? kg}) => WeightEntry(
    id: id ?? this.id,
    timeMs: timeMs ?? this.timeMs,
    kg: kg ?? this.kg,
  );
  WeightEntry copyWithCompanion(WeightEntriesCompanion data) {
    return WeightEntry(
      id: data.id.present ? data.id.value : this.id,
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      kg: data.kg.present ? data.kg.value : this.kg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntry(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timeMs, kg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightEntry &&
          other.id == this.id &&
          other.timeMs == this.timeMs &&
          other.kg == this.kg);
}

class WeightEntriesCompanion extends UpdateCompanion<WeightEntry> {
  final Value<int> id;
  final Value<int> timeMs;
  final Value<double> kg;
  const WeightEntriesCompanion({
    this.id = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.kg = const Value.absent(),
  });
  WeightEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int timeMs,
    required double kg,
  }) : timeMs = Value(timeMs),
       kg = Value(kg);
  static Insertable<WeightEntry> custom({
    Expression<int>? id,
    Expression<int>? timeMs,
    Expression<double>? kg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timeMs != null) 'time_ms': timeMs,
      if (kg != null) 'kg': kg,
    });
  }

  WeightEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? timeMs,
    Value<double>? kg,
  }) {
    return WeightEntriesCompanion(
      id: id ?? this.id,
      timeMs: timeMs ?? this.timeMs,
      kg: kg ?? this.kg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightEntriesCompanion(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }
}

class $ExerciseSetsTable extends ExerciseSets
    with TableInfo<$ExerciseSetsTable, ExerciseSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseSetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kgMeta = const VerificationMeta('kg');
  @override
  late final GeneratedColumn<double> kg = GeneratedColumn<double>(
    'kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timeMs, exerciseId, reps, kg];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    } else if (isInserting) {
      context.missing(_timeMsMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    } else if (isInserting) {
      context.missing(_repsMeta);
    }
    if (data.containsKey('kg')) {
      context.handle(_kgMeta, kg.isAcceptableOrUnknown(data['kg']!, _kgMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      kg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}kg'],
      ),
    );
  }

  @override
  $ExerciseSetsTable createAlias(String alias) {
    return $ExerciseSetsTable(attachedDatabase, alias);
  }
}

class ExerciseSet extends DataClass implements Insertable<ExerciseSet> {
  final int id;

  /// When the session started: a session's sets share it.
  final int timeMs;
  final String exerciseId;
  final int reps;
  final double? kg;
  const ExerciseSet({
    required this.id,
    required this.timeMs,
    required this.exerciseId,
    required this.reps,
    this.kg,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['time_ms'] = Variable<int>(timeMs);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['reps'] = Variable<int>(reps);
    if (!nullToAbsent || kg != null) {
      map['kg'] = Variable<double>(kg);
    }
    return map;
  }

  ExerciseSetsCompanion toCompanion(bool nullToAbsent) {
    return ExerciseSetsCompanion(
      id: Value(id),
      timeMs: Value(timeMs),
      exerciseId: Value(exerciseId),
      reps: Value(reps),
      kg: kg == null && nullToAbsent ? const Value.absent() : Value(kg),
    );
  }

  factory ExerciseSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseSet(
      id: serializer.fromJson<int>(json['id']),
      timeMs: serializer.fromJson<int>(json['timeMs']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      reps: serializer.fromJson<int>(json['reps']),
      kg: serializer.fromJson<double?>(json['kg']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timeMs': serializer.toJson<int>(timeMs),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'reps': serializer.toJson<int>(reps),
      'kg': serializer.toJson<double?>(kg),
    };
  }

  ExerciseSet copyWith({
    int? id,
    int? timeMs,
    String? exerciseId,
    int? reps,
    Value<double?> kg = const Value.absent(),
  }) => ExerciseSet(
    id: id ?? this.id,
    timeMs: timeMs ?? this.timeMs,
    exerciseId: exerciseId ?? this.exerciseId,
    reps: reps ?? this.reps,
    kg: kg.present ? kg.value : this.kg,
  );
  ExerciseSet copyWithCompanion(ExerciseSetsCompanion data) {
    return ExerciseSet(
      id: data.id.present ? data.id.value : this.id,
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      reps: data.reps.present ? data.reps.value : this.reps,
      kg: data.kg.present ? data.kg.value : this.kg,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSet(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('reps: $reps, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timeMs, exerciseId, reps, kg);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseSet &&
          other.id == this.id &&
          other.timeMs == this.timeMs &&
          other.exerciseId == this.exerciseId &&
          other.reps == this.reps &&
          other.kg == this.kg);
}

class ExerciseSetsCompanion extends UpdateCompanion<ExerciseSet> {
  final Value<int> id;
  final Value<int> timeMs;
  final Value<String> exerciseId;
  final Value<int> reps;
  final Value<double?> kg;
  const ExerciseSetsCompanion({
    this.id = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.reps = const Value.absent(),
    this.kg = const Value.absent(),
  });
  ExerciseSetsCompanion.insert({
    this.id = const Value.absent(),
    required int timeMs,
    required String exerciseId,
    required int reps,
    this.kg = const Value.absent(),
  }) : timeMs = Value(timeMs),
       exerciseId = Value(exerciseId),
       reps = Value(reps);
  static Insertable<ExerciseSet> custom({
    Expression<int>? id,
    Expression<int>? timeMs,
    Expression<String>? exerciseId,
    Expression<int>? reps,
    Expression<double>? kg,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timeMs != null) 'time_ms': timeMs,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (reps != null) 'reps': reps,
      if (kg != null) 'kg': kg,
    });
  }

  ExerciseSetsCompanion copyWith({
    Value<int>? id,
    Value<int>? timeMs,
    Value<String>? exerciseId,
    Value<int>? reps,
    Value<double?>? kg,
  }) {
    return ExerciseSetsCompanion(
      id: id ?? this.id,
      timeMs: timeMs ?? this.timeMs,
      exerciseId: exerciseId ?? this.exerciseId,
      reps: reps ?? this.reps,
      kg: kg ?? this.kg,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (kg.present) {
      map['kg'] = Variable<double>(kg.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseSetsCompanion(')
          ..write('id: $id, ')
          ..write('timeMs: $timeMs, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('reps: $reps, ')
          ..write('kg: $kg')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StepIntervalsTable stepIntervals = $StepIntervalsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WorkoutPointsTable workoutPoints = $WorkoutPointsTable(this);
  late final $SleepSessionsTable sleepSessions = $SleepSessionsTable(this);
  late final $SleepMinutesTable sleepMinutes = $SleepMinutesTable(this);
  late final $FoodEntriesTable foodEntries = $FoodEntriesTable(this);
  late final $WaterEntriesTable waterEntries = $WaterEntriesTable(this);
  late final $WeightEntriesTable weightEntries = $WeightEntriesTable(this);
  late final $ExerciseSetsTable exerciseSets = $ExerciseSetsTable(this);
  late final Index stepIntervalsEnd = Index(
    'step_intervals_end',
    'CREATE INDEX step_intervals_end ON step_intervals (end_ms)',
  );
  late final Index workoutsStart = Index(
    'workouts_start',
    'CREATE INDEX workouts_start ON workouts (start_ms)',
  );
  late final Index workoutPointsWorkout = Index(
    'workout_points_workout',
    'CREATE INDEX workout_points_workout ON workout_points (workout_id)',
  );
  late final Index sleepSessionsStart = Index(
    'sleep_sessions_start',
    'CREATE INDEX sleep_sessions_start ON sleep_sessions (start_ms)',
  );
  late final Index foodEntriesTime = Index(
    'food_entries_time',
    'CREATE INDEX food_entries_time ON food_entries (time_ms)',
  );
  late final Index waterEntriesTime = Index(
    'water_entries_time',
    'CREATE INDEX water_entries_time ON water_entries (time_ms)',
  );
  late final Index weightEntriesTime = Index(
    'weight_entries_time',
    'CREATE INDEX weight_entries_time ON weight_entries (time_ms)',
  );
  late final Index exerciseSetsExercise = Index(
    'exercise_sets_exercise',
    'CREATE INDEX exercise_sets_exercise ON exercise_sets (exercise_id, time_ms)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stepIntervals,
    keyValues,
    workouts,
    workoutPoints,
    sleepSessions,
    sleepMinutes,
    foodEntries,
    waterEntries,
    weightEntries,
    exerciseSets,
    stepIntervalsEnd,
    workoutsStart,
    workoutPointsWorkout,
    sleepSessionsStart,
    foodEntriesTime,
    waterEntriesTime,
    weightEntriesTime,
    exerciseSetsExercise,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workouts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('workout_points', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sleep_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sleep_minutes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$StepIntervalsTableCreateCompanionBuilder =
    StepIntervalsCompanion Function({
      Value<int> id,
      required int startMs,
      required int endMs,
      required int steps,
    });
typedef $$StepIntervalsTableUpdateCompanionBuilder =
    StepIntervalsCompanion Function({
      Value<int> id,
      Value<int> startMs,
      Value<int> endMs,
      Value<int> steps,
    });

class $$StepIntervalsTableFilterComposer
    extends Composer<_$AppDatabase, $StepIntervalsTable> {
  $$StepIntervalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StepIntervalsTableOrderingComposer
    extends Composer<_$AppDatabase, $StepIntervalsTable> {
  $$StepIntervalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StepIntervalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StepIntervalsTable> {
  $$StepIntervalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);
}

class $$StepIntervalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StepIntervalsTable,
          StepInterval,
          $$StepIntervalsTableFilterComposer,
          $$StepIntervalsTableOrderingComposer,
          $$StepIntervalsTableAnnotationComposer,
          $$StepIntervalsTableCreateCompanionBuilder,
          $$StepIntervalsTableUpdateCompanionBuilder,
          (
            StepInterval,
            BaseReferences<_$AppDatabase, $StepIntervalsTable, StepInterval>,
          ),
          StepInterval,
          PrefetchHooks Function()
        > {
  $$StepIntervalsTableTableManager(_$AppDatabase db, $StepIntervalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StepIntervalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StepIntervalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StepIntervalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
                Value<int> steps = const Value.absent(),
              }) => StepIntervalsCompanion(
                id: id,
                startMs: startMs,
                endMs: endMs,
                steps: steps,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int startMs,
                required int endMs,
                required int steps,
              }) => StepIntervalsCompanion.insert(
                id: id,
                startMs: startMs,
                endMs: endMs,
                steps: steps,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StepIntervalsTable, StepInterval>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $StepIntervalsTable,
                    StepInterval
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StepIntervalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StepIntervalsTable,
      StepInterval,
      $$StepIntervalsTableFilterComposer,
      $$StepIntervalsTableOrderingComposer,
      $$StepIntervalsTableAnnotationComposer,
      $$StepIntervalsTableCreateCompanionBuilder,
      $$StepIntervalsTableUpdateCompanionBuilder,
      (
        StepInterval,
        BaseReferences<_$AppDatabase, $StepIntervalsTable, StepInterval>,
      ),
      StepInterval,
      PrefetchHooks Function()
    >;
typedef $$KeyValuesTableCreateCompanionBuilder =
    KeyValuesCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$KeyValuesTableUpdateCompanionBuilder =
    KeyValuesCompanion Function({
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
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
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
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
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

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => KeyValuesCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;
typedef $$WorkoutsTableCreateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<int> id,
      required String type,
      required int startMs,
      required int endMs,
      required int activeMs,
      required double distanceKm,
      required double activeKcal,
      required int steps,
      Value<int?> effort,
      Value<double> elevationGainM,
    });
typedef $$WorkoutsTableUpdateCompanionBuilder =
    WorkoutsCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<int> startMs,
      Value<int> endMs,
      Value<int> activeMs,
      Value<double> distanceKm,
      Value<double> activeKcal,
      Value<int> steps,
      Value<int?> effort,
      Value<double> elevationGainM,
    });

final class $$WorkoutsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutsTable, Workout> {
  $$WorkoutsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkoutPointsTable, List<WorkoutPoint>>
  _workoutPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workoutPoints,
    aliasName: 'workouts__id__workout_points__workout_id',
  );

  $$WorkoutPointsTableProcessedTableManager get workoutPointsRefs {
    final manager = $$WorkoutPointsTableTableManager(
      $_db,
      $_db.workoutPoints,
    ).filter((f) => f.workoutId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workoutPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get activeKcal => $composableBuilder(
    column: $table.activeKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effort => $composableBuilder(
    column: $table.effort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workoutPointsRefs(
    Expression<bool> Function($$WorkoutPointsTableFilterComposer f) f,
  ) {
    final $$WorkoutPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutPoints,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutPointsTableFilterComposer(
            $db: $db,
            $table: $db.workoutPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeMs => $composableBuilder(
    column: $table.activeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get activeKcal => $composableBuilder(
    column: $table.activeKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steps => $composableBuilder(
    column: $table.steps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effort => $composableBuilder(
    column: $table.effort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutsTable> {
  $$WorkoutsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<int> get activeMs =>
      $composableBuilder(column: $table.activeMs, builder: (column) => column);

  GeneratedColumn<double> get distanceKm => $composableBuilder(
    column: $table.distanceKm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get activeKcal => $composableBuilder(
    column: $table.activeKcal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get steps =>
      $composableBuilder(column: $table.steps, builder: (column) => column);

  GeneratedColumn<int> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => column);

  GeneratedColumn<double> get elevationGainM => $composableBuilder(
    column: $table.elevationGainM,
    builder: (column) => column,
  );

  Expression<T> workoutPointsRefs<T extends Object>(
    Expression<T> Function($$WorkoutPointsTableAnnotationComposer a) f,
  ) {
    final $$WorkoutPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workoutPoints,
      getReferencedColumn: (t) => t.workoutId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutsTable,
          Workout,
          $$WorkoutsTableFilterComposer,
          $$WorkoutsTableOrderingComposer,
          $$WorkoutsTableAnnotationComposer,
          $$WorkoutsTableCreateCompanionBuilder,
          $$WorkoutsTableUpdateCompanionBuilder,
          (Workout, $$WorkoutsTableReferences),
          Workout,
          PrefetchHooks Function({bool workoutPointsRefs})
        > {
  $$WorkoutsTableTableManager(_$AppDatabase db, $WorkoutsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int> endMs = const Value.absent(),
                Value<int> activeMs = const Value.absent(),
                Value<double> distanceKm = const Value.absent(),
                Value<double> activeKcal = const Value.absent(),
                Value<int> steps = const Value.absent(),
                Value<int?> effort = const Value.absent(),
                Value<double> elevationGainM = const Value.absent(),
              }) => WorkoutsCompanion(
                id: id,
                type: type,
                startMs: startMs,
                endMs: endMs,
                activeMs: activeMs,
                distanceKm: distanceKm,
                activeKcal: activeKcal,
                steps: steps,
                effort: effort,
                elevationGainM: elevationGainM,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                required int startMs,
                required int endMs,
                required int activeMs,
                required double distanceKm,
                required double activeKcal,
                required int steps,
                Value<int?> effort = const Value.absent(),
                Value<double> elevationGainM = const Value.absent(),
              }) => WorkoutsCompanion.insert(
                id: id,
                type: type,
                startMs: startMs,
                endMs: endMs,
                activeMs: activeMs,
                distanceKm: distanceKm,
                activeKcal: activeKcal,
                steps: steps,
                effort: effort,
                elevationGainM: elevationGainM,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutsTable, Workout>(table),
                  $$WorkoutsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutPointsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (workoutPointsRefs) db.workoutPoints,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (workoutPointsRefs)
                    await $_getPrefetchedDataByColumns<
                      Workout,
                      $WorkoutsTable,
                      WorkoutPoint,
                      $WorkoutPointsTable
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutsTableReferences
                          ._workoutPointsRefsTable(db),
                      managerFromTypedResult: (p0) => $$WorkoutsTableReferences(
                        db,
                        table,
                        p0,
                      ).workoutPointsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'workout_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutsTable,
      Workout,
      $$WorkoutsTableFilterComposer,
      $$WorkoutsTableOrderingComposer,
      $$WorkoutsTableAnnotationComposer,
      $$WorkoutsTableCreateCompanionBuilder,
      $$WorkoutsTableUpdateCompanionBuilder,
      (Workout, $$WorkoutsTableReferences),
      Workout,
      PrefetchHooks Function({bool workoutPointsRefs})
    >;
typedef $$WorkoutPointsTableCreateCompanionBuilder =
    WorkoutPointsCompanion Function({
      Value<int> id,
      required int workoutId,
      required double latitude,
      required double longitude,
      Value<double?> altitude,
      required int elapsedMs,
      required int segment,
    });
typedef $$WorkoutPointsTableUpdateCompanionBuilder =
    WorkoutPointsCompanion Function({
      Value<int> id,
      Value<int> workoutId,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> altitude,
      Value<int> elapsedMs,
      Value<int> segment,
    });

final class $$WorkoutPointsTableReferences
    extends BaseReferences<_$AppDatabase, $WorkoutPointsTable, WorkoutPoint> {
  $$WorkoutPointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutsTable _workoutIdTable(_$AppDatabase db) =>
      db.workouts.createAlias('workout_points__workout_id__workouts__id');

  $$WorkoutsTableProcessedTableManager get workoutId {
    final $_column = $_itemColumn<int>('workout_id')!;

    final manager = $$WorkoutsTableTableManager(
      $_db,
      $_db.workouts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workoutIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkoutPointsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutPointsTable> {
  $$WorkoutPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutsTableFilterComposer get workoutId {
    final $$WorkoutsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableFilterComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutPointsTable> {
  $$WorkoutPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get segment => $composableBuilder(
    column: $table.segment,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutsTableOrderingComposer get workoutId {
    final $$WorkoutsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableOrderingComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutPointsTable> {
  $$WorkoutPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<int> get segment =>
      $composableBuilder(column: $table.segment, builder: (column) => column);

  $$WorkoutsTableAnnotationComposer get workoutId {
    final $$WorkoutsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workoutId,
      referencedTable: $db.workouts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutsTableAnnotationComposer(
            $db: $db,
            $table: $db.workouts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkoutPointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutPointsTable,
          WorkoutPoint,
          $$WorkoutPointsTableFilterComposer,
          $$WorkoutPointsTableOrderingComposer,
          $$WorkoutPointsTableAnnotationComposer,
          $$WorkoutPointsTableCreateCompanionBuilder,
          $$WorkoutPointsTableUpdateCompanionBuilder,
          (WorkoutPoint, $$WorkoutPointsTableReferences),
          WorkoutPoint,
          PrefetchHooks Function({bool workoutId})
        > {
  $$WorkoutPointsTableTableManager(_$AppDatabase db, $WorkoutPointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> workoutId = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<int> segment = const Value.absent(),
              }) => WorkoutPointsCompanion(
                id: id,
                workoutId: workoutId,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                elapsedMs: elapsedMs,
                segment: segment,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int workoutId,
                required double latitude,
                required double longitude,
                Value<double?> altitude = const Value.absent(),
                required int elapsedMs,
                required int segment,
              }) => WorkoutPointsCompanion.insert(
                id: id,
                workoutId: workoutId,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                elapsedMs: elapsedMs,
                segment: segment,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutPointsTable, WorkoutPoint>(table),
                  $$WorkoutPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workoutId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workoutId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workoutId,
                                referencedTable: $$WorkoutPointsTableReferences
                                    ._workoutIdTable(db),
                                referencedColumn: $$WorkoutPointsTableReferences
                                    ._workoutIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutPointsTable,
      WorkoutPoint,
      $$WorkoutPointsTableFilterComposer,
      $$WorkoutPointsTableOrderingComposer,
      $$WorkoutPointsTableAnnotationComposer,
      $$WorkoutPointsTableCreateCompanionBuilder,
      $$WorkoutPointsTableUpdateCompanionBuilder,
      (WorkoutPoint, $$WorkoutPointsTableReferences),
      WorkoutPoint,
      PrefetchHooks Function({bool workoutId})
    >;
typedef $$SleepSessionsTableCreateCompanionBuilder =
    SleepSessionsCompanion Function({
      Value<int> id,
      required int startMs,
      Value<int?> endMs,
      required String source,
      Value<String> hypnogram,
    });
typedef $$SleepSessionsTableUpdateCompanionBuilder =
    SleepSessionsCompanion Function({
      Value<int> id,
      Value<int> startMs,
      Value<int?> endMs,
      Value<String> source,
      Value<String> hypnogram,
    });

final class $$SleepSessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SleepSessionsTable, SleepSession> {
  $$SleepSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SleepMinutesTable, List<SleepMinute>>
  _sleepMinutesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sleepMinutes,
    aliasName: 'sleep_sessions__id__sleep_minutes__session_id',
  );

  $$SleepMinutesTableProcessedTableManager get sleepMinutesRefs {
    final manager = $$SleepMinutesTableTableManager(
      $_db,
      $_db.sleepMinutes,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_sleepMinutesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SleepSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SleepSessionsTable> {
  $$SleepSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hypnogram => $composableBuilder(
    column: $table.hypnogram,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sleepMinutesRefs(
    Expression<bool> Function($$SleepMinutesTableFilterComposer f) f,
  ) {
    final $$SleepMinutesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sleepMinutes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SleepMinutesTableFilterComposer(
            $db: $db,
            $table: $db.sleepMinutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SleepSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SleepSessionsTable> {
  $$SleepSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startMs => $composableBuilder(
    column: $table.startMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endMs => $composableBuilder(
    column: $table.endMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hypnogram => $composableBuilder(
    column: $table.hypnogram,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SleepSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SleepSessionsTable> {
  $$SleepSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startMs =>
      $composableBuilder(column: $table.startMs, builder: (column) => column);

  GeneratedColumn<int> get endMs =>
      $composableBuilder(column: $table.endMs, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get hypnogram =>
      $composableBuilder(column: $table.hypnogram, builder: (column) => column);

  Expression<T> sleepMinutesRefs<T extends Object>(
    Expression<T> Function($$SleepMinutesTableAnnotationComposer a) f,
  ) {
    final $$SleepMinutesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sleepMinutes,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SleepMinutesTableAnnotationComposer(
            $db: $db,
            $table: $db.sleepMinutes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SleepSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SleepSessionsTable,
          SleepSession,
          $$SleepSessionsTableFilterComposer,
          $$SleepSessionsTableOrderingComposer,
          $$SleepSessionsTableAnnotationComposer,
          $$SleepSessionsTableCreateCompanionBuilder,
          $$SleepSessionsTableUpdateCompanionBuilder,
          (SleepSession, $$SleepSessionsTableReferences),
          SleepSession,
          PrefetchHooks Function({bool sleepMinutesRefs})
        > {
  $$SleepSessionsTableTableManager(_$AppDatabase db, $SleepSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SleepSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SleepSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SleepSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> startMs = const Value.absent(),
                Value<int?> endMs = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> hypnogram = const Value.absent(),
              }) => SleepSessionsCompanion(
                id: id,
                startMs: startMs,
                endMs: endMs,
                source: source,
                hypnogram: hypnogram,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int startMs,
                Value<int?> endMs = const Value.absent(),
                required String source,
                Value<String> hypnogram = const Value.absent(),
              }) => SleepSessionsCompanion.insert(
                id: id,
                startMs: startMs,
                endMs: endMs,
                source: source,
                hypnogram: hypnogram,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SleepSessionsTable, SleepSession>(table),
                  $$SleepSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sleepMinutesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (sleepMinutesRefs) db.sleepMinutes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sleepMinutesRefs)
                    await $_getPrefetchedDataByColumns<
                      SleepSession,
                      $SleepSessionsTable,
                      SleepMinute,
                      $SleepMinutesTable
                    >(
                      currentTable: table,
                      referencedTable: $$SleepSessionsTableReferences
                          ._sleepMinutesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SleepSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).sleepMinutesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'session_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SleepSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SleepSessionsTable,
      SleepSession,
      $$SleepSessionsTableFilterComposer,
      $$SleepSessionsTableOrderingComposer,
      $$SleepSessionsTableAnnotationComposer,
      $$SleepSessionsTableCreateCompanionBuilder,
      $$SleepSessionsTableUpdateCompanionBuilder,
      (SleepSession, $$SleepSessionsTableReferences),
      SleepSession,
      PrefetchHooks Function({bool sleepMinutesRefs})
    >;
typedef $$SleepMinutesTableCreateCompanionBuilder =
    SleepMinutesCompanion Function({
      required int sessionId,
      required int minute,
      required int count,
      Value<int> rowid,
    });
typedef $$SleepMinutesTableUpdateCompanionBuilder =
    SleepMinutesCompanion Function({
      Value<int> sessionId,
      Value<int> minute,
      Value<int> count,
      Value<int> rowid,
    });

final class $$SleepMinutesTableReferences
    extends BaseReferences<_$AppDatabase, $SleepMinutesTable, SleepMinute> {
  $$SleepMinutesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SleepSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .sleepSessions
      .createAlias('sleep_minutes__session_id__sleep_sessions__id');

  $$SleepSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$SleepSessionsTableTableManager(
      $_db,
      $_db.sleepSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SleepMinutesTableFilterComposer
    extends Composer<_$AppDatabase, $SleepMinutesTable> {
  $$SleepMinutesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  $$SleepSessionsTableFilterComposer get sessionId {
    final $$SleepSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sleepSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SleepSessionsTableFilterComposer(
            $db: $db,
            $table: $db.sleepSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SleepMinutesTableOrderingComposer
    extends Composer<_$AppDatabase, $SleepMinutesTable> {
  $$SleepMinutesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  $$SleepSessionsTableOrderingComposer get sessionId {
    final $$SleepSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sleepSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SleepSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sleepSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SleepMinutesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SleepMinutesTable> {
  $$SleepMinutesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  $$SleepSessionsTableAnnotationComposer get sessionId {
    final $$SleepSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sleepSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SleepSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sleepSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SleepMinutesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SleepMinutesTable,
          SleepMinute,
          $$SleepMinutesTableFilterComposer,
          $$SleepMinutesTableOrderingComposer,
          $$SleepMinutesTableAnnotationComposer,
          $$SleepMinutesTableCreateCompanionBuilder,
          $$SleepMinutesTableUpdateCompanionBuilder,
          (SleepMinute, $$SleepMinutesTableReferences),
          SleepMinute,
          PrefetchHooks Function({bool sessionId})
        > {
  $$SleepMinutesTableTableManager(_$AppDatabase db, $SleepMinutesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SleepMinutesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SleepMinutesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SleepMinutesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> sessionId = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SleepMinutesCompanion(
                sessionId: sessionId,
                minute: minute,
                count: count,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int sessionId,
                required int minute,
                required int count,
                Value<int> rowid = const Value.absent(),
              }) => SleepMinutesCompanion.insert(
                sessionId: sessionId,
                minute: minute,
                count: count,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SleepMinutesTable, SleepMinute>(table),
                  $$SleepMinutesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$SleepMinutesTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$SleepMinutesTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SleepMinutesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SleepMinutesTable,
      SleepMinute,
      $$SleepMinutesTableFilterComposer,
      $$SleepMinutesTableOrderingComposer,
      $$SleepMinutesTableAnnotationComposer,
      $$SleepMinutesTableCreateCompanionBuilder,
      $$SleepMinutesTableUpdateCompanionBuilder,
      (SleepMinute, $$SleepMinutesTableReferences),
      SleepMinute,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$FoodEntriesTableCreateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      required int timeMs,
      required String meal,
      required String name,
      Value<double?> kcal,
      Value<double?> protein,
      Value<double?> carbs,
      Value<double?> fat,
      Value<double> portions,
    });
typedef $$FoodEntriesTableUpdateCompanionBuilder =
    FoodEntriesCompanion Function({
      Value<int> id,
      Value<int> timeMs,
      Value<String> meal,
      Value<String> name,
      Value<double?> kcal,
      Value<double?> protein,
      Value<double?> carbs,
      Value<double?> fat,
      Value<double> portions,
    });

class $$FoodEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get portions => $composableBuilder(
    column: $table.portions,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meal => $composableBuilder(
    column: $table.meal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kcal => $composableBuilder(
    column: $table.kcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get protein => $composableBuilder(
    column: $table.protein,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbs => $composableBuilder(
    column: $table.carbs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fat => $composableBuilder(
    column: $table.fat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get portions => $composableBuilder(
    column: $table.portions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodEntriesTable> {
  $$FoodEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<String> get meal =>
      $composableBuilder(column: $table.meal, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get kcal =>
      $composableBuilder(column: $table.kcal, builder: (column) => column);

  GeneratedColumn<double> get protein =>
      $composableBuilder(column: $table.protein, builder: (column) => column);

  GeneratedColumn<double> get carbs =>
      $composableBuilder(column: $table.carbs, builder: (column) => column);

  GeneratedColumn<double> get fat =>
      $composableBuilder(column: $table.fat, builder: (column) => column);

  GeneratedColumn<double> get portions =>
      $composableBuilder(column: $table.portions, builder: (column) => column);
}

class $$FoodEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodEntriesTable,
          FoodRow,
          $$FoodEntriesTableFilterComposer,
          $$FoodEntriesTableOrderingComposer,
          $$FoodEntriesTableAnnotationComposer,
          $$FoodEntriesTableCreateCompanionBuilder,
          $$FoodEntriesTableUpdateCompanionBuilder,
          (FoodRow, BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodRow>),
          FoodRow,
          PrefetchHooks Function()
        > {
  $$FoodEntriesTableTableManager(_$AppDatabase db, $FoodEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timeMs = const Value.absent(),
                Value<String> meal = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> kcal = const Value.absent(),
                Value<double?> protein = const Value.absent(),
                Value<double?> carbs = const Value.absent(),
                Value<double?> fat = const Value.absent(),
                Value<double> portions = const Value.absent(),
              }) => FoodEntriesCompanion(
                id: id,
                timeMs: timeMs,
                meal: meal,
                name: name,
                kcal: kcal,
                protein: protein,
                carbs: carbs,
                fat: fat,
                portions: portions,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timeMs,
                required String meal,
                required String name,
                Value<double?> kcal = const Value.absent(),
                Value<double?> protein = const Value.absent(),
                Value<double?> carbs = const Value.absent(),
                Value<double?> fat = const Value.absent(),
                Value<double> portions = const Value.absent(),
              }) => FoodEntriesCompanion.insert(
                id: id,
                timeMs: timeMs,
                meal: meal,
                name: name,
                kcal: kcal,
                protein: protein,
                carbs: carbs,
                fat: fat,
                portions: portions,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodEntriesTable, FoodRow>(table),
                  BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodEntriesTable,
      FoodRow,
      $$FoodEntriesTableFilterComposer,
      $$FoodEntriesTableOrderingComposer,
      $$FoodEntriesTableAnnotationComposer,
      $$FoodEntriesTableCreateCompanionBuilder,
      $$FoodEntriesTableUpdateCompanionBuilder,
      (FoodRow, BaseReferences<_$AppDatabase, $FoodEntriesTable, FoodRow>),
      FoodRow,
      PrefetchHooks Function()
    >;
typedef $$WaterEntriesTableCreateCompanionBuilder =
    WaterEntriesCompanion Function({
      Value<int> id,
      required int timeMs,
      required int ml,
    });
typedef $$WaterEntriesTableUpdateCompanionBuilder =
    WaterEntriesCompanion Function({
      Value<int> id,
      Value<int> timeMs,
      Value<int> ml,
    });

class $$WaterEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WaterEntriesTable> {
  $$WaterEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WaterEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WaterEntriesTable> {
  $$WaterEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ml => $composableBuilder(
    column: $table.ml,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WaterEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WaterEntriesTable> {
  $$WaterEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<int> get ml =>
      $composableBuilder(column: $table.ml, builder: (column) => column);
}

class $$WaterEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WaterEntriesTable,
          WaterEntry,
          $$WaterEntriesTableFilterComposer,
          $$WaterEntriesTableOrderingComposer,
          $$WaterEntriesTableAnnotationComposer,
          $$WaterEntriesTableCreateCompanionBuilder,
          $$WaterEntriesTableUpdateCompanionBuilder,
          (
            WaterEntry,
            BaseReferences<_$AppDatabase, $WaterEntriesTable, WaterEntry>,
          ),
          WaterEntry,
          PrefetchHooks Function()
        > {
  $$WaterEntriesTableTableManager(_$AppDatabase db, $WaterEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WaterEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WaterEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WaterEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timeMs = const Value.absent(),
                Value<int> ml = const Value.absent(),
              }) => WaterEntriesCompanion(id: id, timeMs: timeMs, ml: ml),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timeMs,
                required int ml,
              }) =>
                  WaterEntriesCompanion.insert(id: id, timeMs: timeMs, ml: ml),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WaterEntriesTable, WaterEntry>(table),
                  BaseReferences<_$AppDatabase, $WaterEntriesTable, WaterEntry>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WaterEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WaterEntriesTable,
      WaterEntry,
      $$WaterEntriesTableFilterComposer,
      $$WaterEntriesTableOrderingComposer,
      $$WaterEntriesTableAnnotationComposer,
      $$WaterEntriesTableCreateCompanionBuilder,
      $$WaterEntriesTableUpdateCompanionBuilder,
      (
        WaterEntry,
        BaseReferences<_$AppDatabase, $WaterEntriesTable, WaterEntry>,
      ),
      WaterEntry,
      PrefetchHooks Function()
    >;
typedef $$WeightEntriesTableCreateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      required int timeMs,
      required double kg,
    });
typedef $$WeightEntriesTableUpdateCompanionBuilder =
    WeightEntriesCompanion Function({
      Value<int> id,
      Value<int> timeMs,
      Value<double> kg,
    });

class $$WeightEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeightEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeightEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightEntriesTable> {
  $$WeightEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<double> get kg =>
      $composableBuilder(column: $table.kg, builder: (column) => column);
}

class $$WeightEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightEntriesTable,
          WeightEntry,
          $$WeightEntriesTableFilterComposer,
          $$WeightEntriesTableOrderingComposer,
          $$WeightEntriesTableAnnotationComposer,
          $$WeightEntriesTableCreateCompanionBuilder,
          $$WeightEntriesTableUpdateCompanionBuilder,
          (
            WeightEntry,
            BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
          ),
          WeightEntry,
          PrefetchHooks Function()
        > {
  $$WeightEntriesTableTableManager(_$AppDatabase db, $WeightEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timeMs = const Value.absent(),
                Value<double> kg = const Value.absent(),
              }) => WeightEntriesCompanion(id: id, timeMs: timeMs, kg: kg),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timeMs,
                required double kg,
              }) =>
                  WeightEntriesCompanion.insert(id: id, timeMs: timeMs, kg: kg),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WeightEntriesTable, WeightEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $WeightEntriesTable,
                    WeightEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeightEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightEntriesTable,
      WeightEntry,
      $$WeightEntriesTableFilterComposer,
      $$WeightEntriesTableOrderingComposer,
      $$WeightEntriesTableAnnotationComposer,
      $$WeightEntriesTableCreateCompanionBuilder,
      $$WeightEntriesTableUpdateCompanionBuilder,
      (
        WeightEntry,
        BaseReferences<_$AppDatabase, $WeightEntriesTable, WeightEntry>,
      ),
      WeightEntry,
      PrefetchHooks Function()
    >;
typedef $$ExerciseSetsTableCreateCompanionBuilder =
    ExerciseSetsCompanion Function({
      Value<int> id,
      required int timeMs,
      required String exerciseId,
      required int reps,
      Value<double?> kg,
    });
typedef $$ExerciseSetsTableUpdateCompanionBuilder =
    ExerciseSetsCompanion Function({
      Value<int> id,
      Value<int> timeMs,
      Value<String> exerciseId,
      Value<int> reps,
      Value<double?> kg,
    });

class $$ExerciseSetsTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseSetsTable> {
  $$ExerciseSetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseSetsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseSetsTable> {
  $$ExerciseSetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get kg => $composableBuilder(
    column: $table.kg,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseSetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseSetsTable> {
  $$ExerciseSetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get kg =>
      $composableBuilder(column: $table.kg, builder: (column) => column);
}

class $$ExerciseSetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseSetsTable,
          ExerciseSet,
          $$ExerciseSetsTableFilterComposer,
          $$ExerciseSetsTableOrderingComposer,
          $$ExerciseSetsTableAnnotationComposer,
          $$ExerciseSetsTableCreateCompanionBuilder,
          $$ExerciseSetsTableUpdateCompanionBuilder,
          (
            ExerciseSet,
            BaseReferences<_$AppDatabase, $ExerciseSetsTable, ExerciseSet>,
          ),
          ExerciseSet,
          PrefetchHooks Function()
        > {
  $$ExerciseSetsTableTableManager(_$AppDatabase db, $ExerciseSetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseSetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseSetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseSetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> timeMs = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<double?> kg = const Value.absent(),
              }) => ExerciseSetsCompanion(
                id: id,
                timeMs: timeMs,
                exerciseId: exerciseId,
                reps: reps,
                kg: kg,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int timeMs,
                required String exerciseId,
                required int reps,
                Value<double?> kg = const Value.absent(),
              }) => ExerciseSetsCompanion.insert(
                id: id,
                timeMs: timeMs,
                exerciseId: exerciseId,
                reps: reps,
                kg: kg,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExerciseSetsTable, ExerciseSet>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ExerciseSetsTable,
                    ExerciseSet
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseSetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseSetsTable,
      ExerciseSet,
      $$ExerciseSetsTableFilterComposer,
      $$ExerciseSetsTableOrderingComposer,
      $$ExerciseSetsTableAnnotationComposer,
      $$ExerciseSetsTableCreateCompanionBuilder,
      $$ExerciseSetsTableUpdateCompanionBuilder,
      (
        ExerciseSet,
        BaseReferences<_$AppDatabase, $ExerciseSetsTable, ExerciseSet>,
      ),
      ExerciseSet,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StepIntervalsTableTableManager get stepIntervals =>
      $$StepIntervalsTableTableManager(_db, _db.stepIntervals);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db, _db.workouts);
  $$WorkoutPointsTableTableManager get workoutPoints =>
      $$WorkoutPointsTableTableManager(_db, _db.workoutPoints);
  $$SleepSessionsTableTableManager get sleepSessions =>
      $$SleepSessionsTableTableManager(_db, _db.sleepSessions);
  $$SleepMinutesTableTableManager get sleepMinutes =>
      $$SleepMinutesTableTableManager(_db, _db.sleepMinutes);
  $$FoodEntriesTableTableManager get foodEntries =>
      $$FoodEntriesTableTableManager(_db, _db.foodEntries);
  $$WaterEntriesTableTableManager get waterEntries =>
      $$WaterEntriesTableTableManager(_db, _db.waterEntries);
  $$WeightEntriesTableTableManager get weightEntries =>
      $$WeightEntriesTableTableManager(_db, _db.weightEntries);
  $$ExerciseSetsTableTableManager get exerciseSets =>
      $$ExerciseSetsTableTableManager(_db, _db.exerciseSets);
}
