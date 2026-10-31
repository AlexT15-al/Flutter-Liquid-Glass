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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StepIntervalsTable stepIntervals = $StepIntervalsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final $WorkoutsTable workouts = $WorkoutsTable(this);
  late final $WorkoutPointsTable workoutPoints = $WorkoutPointsTable(this);
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stepIntervals,
    keyValues,
    workouts,
    workoutPoints,
    stepIntervalsEnd,
    workoutsStart,
    workoutPointsWorkout,
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
}
