import 'dart:convert';

import 'app_data.dart';
import 'body_weight.dart';
import 'exercise.dart';
import 'limits.dart';
import 'program.dart';
import 'session.dart';
import 'settings.dart';

/// Version of the user-facing JSON backup format.
///
/// This is independent of the internal on-device document version. Additive
/// fields may stay in the same format version because readers ignore unknown
/// fields; removing or changing a field requires a new version.
const int backupSchemaVersion = 1;

/// Hard cap for an import or export document. A 10,000-set document is far
/// below this; the cap prevents unbounded allocation from a hostile file.
const int maxBackupBytes = 32 * 1024 * 1024;

/// Maximum JSON container nesting accepted before decoding.
const int maxBackupNestingDepth = 64;

/// Maximum number of JSON objects/arrays accepted before decoding. A valid
/// 10,000-set document uses roughly 10,000 containers; this bound prevents a
/// dense file from amplifying into hundreds of thousands of decoded objects.
const int maxBackupContainers = 500000;

/// Value written to the top-level `generator` field.
const String backupGenerator = 'gym-log';

/// Identity and header strings are bounded and restricted to printable
/// characters so hostile files cannot inject control or bidi characters into
/// validation messages or the preview.
const int maximumBackupIdLength = 128;
const int maximumBackupHeaderLength = 64;
final RegExp backupIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final RegExp backupHeaderPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9.+_-]*$');

/// Sanity bounds for stored timestamps. Existing model invariants still apply;
/// this only rejects files that could not be legitimate app data.
const int minimumBackupYear = 1970;
const int maximumBackupYear = 2200;

/// Typed validation failure. The UI maps [code] to localized fa/en copy;
/// [field] and [value] are identifiers, never free-form training data.
enum BackupErrorCode {
  empty,
  tooLarge,
  tooDeep,
  corrupt,
  rootNotObject,
  missingField,
  invalidField,
  unsupportedVersion,
  newerVersion,
  duplicateId,
  orphanReference,
  absurdValue,
}

class BackupError implements Exception {
  const BackupError(
    this.code, {
    this.field,
    this.value,
    this.detail,
    this.supportedVersion,
  });

  final BackupErrorCode code;

  /// JSON path such as `exercises[0].createdAt`.
  final String? field;

  /// Offending identifier or version; never a note or other user text.
  final String? value;

  /// Diagnostic detail for tests and logs. Not shown raw to users.
  final String? detail;

  final int? supportedVersion;

  @override
  String toString() {
    final String location = field == null ? '' : ' ($field)';
    return 'BackupError(${code.name})$location';
  }
}

/// A validated backup file: header metadata plus the decoded data.
class BackupDocument {
  const BackupDocument({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.generator,
    required this.data,
  });

  final int schemaVersion;
  final String appVersion;
  final DateTime exportedAt;
  final String generator;
  final AppData data;
}

/// Serialized representation used by exports, fixtures, and tests.
Map<String, Object?> buildBackupMap(
  AppData data, {
  required String appVersion,
  required DateTime exportedAt,
  String generator = backupGenerator,
}) {
  final String version = appVersion.trim();
  if (version.isEmpty) {
    throw ArgumentError.value(appVersion, 'appVersion');
  }
  final String source = generator.trim();
  if (source.isEmpty) {
    throw ArgumentError.value(generator, 'generator');
  }
  final Map<String, Object?> document = data.toJson();
  final List<Object?> bodyWeights = (document['bodyWeights']! as List)
      .cast<Object?>();
  return <String, Object?>{
    'schemaVersion': backupSchemaVersion,
    'appVersion': version,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'generator': source,
    'exercises': document['exercises'],
    'programs': document['programs'],
    'sessions': document['sessions'],
    // Additive field: omitted while empty so every historical fixture keeps
    // round-tripping byte-for-byte, and older readers stay compatible.
    if (bodyWeights.isNotEmpty) 'bodyWeights': bodyWeights,
    'settings': document['settings'],
  };
}

/// Encodes a backup document. Runs off the UI thread at the call site.
String buildBackupJson(
  AppData data, {
  required String appVersion,
  required DateTime exportedAt,
  String generator = backupGenerator,
}) {
  return jsonEncode(
    buildBackupMap(
      data,
      appVersion: appVersion,
      exportedAt: exportedAt,
      generator: generator,
    ),
  );
}

/// Parses and validates one untrusted backup file.
///
/// Throws [BackupError] before any caller state can change. Unknown fields are
/// ignored by the entity readers for forward compatibility.
BackupDocument parseBackup(String text) {
  if (text.trim().isEmpty) {
    throw const BackupError(BackupErrorCode.empty);
  }
  if (text.length > maxBackupBytes ||
      utf8.encode(text).length > maxBackupBytes) {
    throw const BackupError(BackupErrorCode.tooLarge);
  }
  _checkJsonBudget(text);

  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException catch (error) {
    throw BackupError(BackupErrorCode.corrupt, detail: error.message);
  }
  if (decoded is! Map) {
    throw const BackupError(BackupErrorCode.rootNotObject);
  }
  final Map<String, Object?> root = decoded.cast<String, Object?>();

  final int version = _readRequiredInt(root, 'schemaVersion');
  if (version > backupSchemaVersion) {
    throw BackupError(
      BackupErrorCode.newerVersion,
      field: 'schemaVersion',
      value: '$version',
      supportedVersion: backupSchemaVersion,
    );
  }
  if (version != backupSchemaVersion) {
    throw BackupError(
      BackupErrorCode.unsupportedVersion,
      field: 'schemaVersion',
      value: '$version',
      supportedVersion: backupSchemaVersion,
    );
  }

  final String appVersion = _readRequiredString(root, 'appVersion');
  final String generator = _readRequiredString(root, 'generator');
  _validateHeaderString(appVersion, 'appVersion');
  _validateHeaderString(generator, 'generator');
  final DateTime exportedAt = _readRequiredUtcDateTime(root, 'exportedAt');
  _checkTimestamp(exportedAt, 'exportedAt');

  final List<Exercise> exercises = _decodeList(
    root,
    'exercises',
    Exercise.fromJson,
  );
  final List<Program> programs = _decodeList(
    root,
    'programs',
    Program.fromJson,
  );
  final List<Session> sessions = _decodeList(
    root,
    'sessions',
    Session.fromJson,
  );
  // Additive in backup schema 1: older files have no body-weight check-ins.
  final List<BodyWeightEntry> bodyWeights = root.containsKey('bodyWeights')
      ? _decodeList(root, 'bodyWeights', BodyWeightEntry.fromJson)
      : const <BodyWeightEntry>[];
  final Map<String, Object?> settingsJson = _readRequiredMap(root, 'settings');
  final AppSettings settings;
  try {
    settings = AppSettings.fromJson(settingsJson);
  } on FormatException catch (error) {
    throw BackupError(
      BackupErrorCode.invalidField,
      field: 'settings',
      detail: error.message,
    );
  } on ArgumentError catch (error) {
    throw BackupError(
      BackupErrorCode.absurdValue,
      field: 'settings',
      detail: '${error.message}',
    );
  }

  _validateIdentityAndReferences(exercises, programs, sessions, bodyWeights);
  _validateTextAndOrderBounds(exercises, programs, sessions);
  _validateTimestamps(exercises, programs, sessions, bodyWeights);

  final int activeSessions = sessions.where((Session s) => s.isActive).length;
  if (activeSessions > 1) {
    throw const BackupError(
      BackupErrorCode.invalidField,
      field: 'sessions',
      detail: 'more than one active session',
    );
  }

  final AppData data;
  try {
    data = AppData(
      exercises: exercises,
      programs: programs,
      sessions: sessions,
      bodyWeights: bodyWeights,
      settings: settings,
    );
  } on ArgumentError catch (error) {
    throw BackupError(
      BackupErrorCode.absurdValue,
      field: 'data',
      detail: '${error.message}',
    );
  } on FormatException catch (error) {
    throw BackupError(
      BackupErrorCode.invalidField,
      field: 'data',
      detail: error.message,
    );
  }

  return BackupDocument(
    schemaVersion: version,
    appVersion: appVersion,
    exportedAt: exportedAt,
    generator: generator,
    data: data,
  );
}

void _checkJsonBudget(String text) {
  int depth = 0;
  int containers = 0;
  bool inString = false;
  bool escape = false;
  for (int index = 0; index < text.length; index += 1) {
    final int unit = text.codeUnitAt(index);
    if (inString) {
      if (escape) {
        escape = false;
      } else if (unit == 0x5C) {
        escape = true;
      } else if (unit == 0x22) {
        inString = false;
      }
      continue;
    }
    if (unit == 0x22) {
      inString = true;
    } else if (unit == 0x7B || unit == 0x5B) {
      depth += 1;
      containers += 1;
      if (depth > maxBackupNestingDepth) {
        throw const BackupError(BackupErrorCode.tooDeep);
      }
      if (containers > maxBackupContainers) {
        throw const BackupError(BackupErrorCode.tooLarge);
      }
    } else if (unit == 0x7D || unit == 0x5D) {
      depth -= 1;
      if (depth < 0) {
        return;
      }
    }
  }
}

String _readRequiredString(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) {
    throw BackupError(BackupErrorCode.missingField, field: field);
  }
  final Object? value = json[field];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw BackupError(BackupErrorCode.invalidField, field: field);
}

int _readRequiredInt(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) {
    throw BackupError(BackupErrorCode.missingField, field: field);
  }
  final Object? value = json[field];
  if (value is int) {
    return value;
  }
  throw BackupError(BackupErrorCode.invalidField, field: field);
}

DateTime _readRequiredUtcDateTime(Map<String, Object?> json, String field) {
  final String raw = _readRequiredString(json, field).trim();
  final String normalized = raw.toUpperCase();
  if (!(normalized.endsWith('Z') || normalized.endsWith('+00:00'))) {
    throw BackupError(BackupErrorCode.invalidField, field: field);
  }
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null || !parsed.isUtc) {
    throw BackupError(BackupErrorCode.invalidField, field: field);
  }
  return parsed;
}

Map<String, Object?> _readRequiredMap(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) {
    throw BackupError(BackupErrorCode.missingField, field: field);
  }
  final Object? value = json[field];
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw BackupError(BackupErrorCode.invalidField, field: field);
}

List<Object?> _readRequiredList(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) {
    throw BackupError(BackupErrorCode.missingField, field: field);
  }
  final Object? value = json[field];
  if (value is List) {
    return value.cast<Object?>();
  }
  throw BackupError(BackupErrorCode.invalidField, field: field);
}

List<T> _decodeList<T>(
  Map<String, Object?> root,
  String field,
  T Function(Map<String, Object?>) decode,
) {
  final List<Object?> raw = _readRequiredList(root, field);
  final List<T> result = <T>[];
  for (int index = 0; index < raw.length; index += 1) {
    final String path = '$field[$index]';
    final Object? item = raw[index];
    if (item is! Map) {
      throw BackupError(BackupErrorCode.invalidField, field: path);
    }
    try {
      result.add(decode(item.cast<String, Object?>()));
    } on FormatException catch (error) {
      throw BackupError(
        BackupErrorCode.invalidField,
        field: path,
        detail: error.message,
      );
    } on ArgumentError catch (error) {
      throw BackupError(
        BackupErrorCode.absurdValue,
        field: path,
        detail: '${error.message}',
      );
    }
  }
  return result;
}

void _validateIdentityAndReferences(
  List<Exercise> exercises,
  List<Program> programs,
  List<Session> sessions,
  List<BodyWeightEntry> bodyWeights,
) {
  final Map<String, String> seen = <String, String>{};

  void addId(String id, String path) {
    if (id.length > maximumBackupIdLength || !backupIdPattern.hasMatch(id)) {
      throw BackupError(BackupErrorCode.invalidField, field: path);
    }
    final String? existing = seen[id];
    if (existing != null) {
      throw BackupError(
        BackupErrorCode.duplicateId,
        field: path,
        value: id,
        detail: 'first used at $existing',
      );
    }
    seen[id] = path;
  }

  for (
    int exerciseIndex = 0;
    exerciseIndex < exercises.length;
    exerciseIndex += 1
  ) {
    addId(exercises[exerciseIndex].id, 'exercises[$exerciseIndex].id');
  }

  for (
    int programIndex = 0;
    programIndex < programs.length;
    programIndex += 1
  ) {
    final Program program = programs[programIndex];
    addId(program.id, 'programs[$programIndex].id');
    for (int dayIndex = 0; dayIndex < program.days.length; dayIndex += 1) {
      final ProgramDay day = program.days[dayIndex];
      addId(day.id, 'programs[$programIndex].days[$dayIndex].id');
      for (int itemIndex = 0; itemIndex < day.items.length; itemIndex += 1) {
        addId(
          day.items[itemIndex].id,
          'programs[$programIndex].days[$dayIndex].items[$itemIndex].id',
        );
      }
    }
  }

  for (
    int bodyWeightIndex = 0;
    bodyWeightIndex < bodyWeights.length;
    bodyWeightIndex += 1
  ) {
    addId(bodyWeights[bodyWeightIndex].id, 'bodyWeights[$bodyWeightIndex].id');
  }

  for (
    int sessionIndex = 0;
    sessionIndex < sessions.length;
    sessionIndex += 1
  ) {
    final Session session = sessions[sessionIndex];
    addId(session.id, 'sessions[$sessionIndex].id');
    for (
      int exerciseIndex = 0;
      exerciseIndex < session.exercises.length;
      exerciseIndex += 1
    ) {
      final SessionExercise exercise = session.exercises[exerciseIndex];
      addId(
        exercise.id,
        'sessions[$sessionIndex].exercises[$exerciseIndex].id',
      );
      for (int setIndex = 0; setIndex < exercise.sets.length; setIndex += 1) {
        addId(
          exercise.sets[setIndex].id,
          'sessions[$sessionIndex].exercises[$exerciseIndex].sets[$setIndex].id',
        );
      }
    }
  }

  final Set<String> exerciseIds = <String>{
    for (final Exercise exercise in exercises) exercise.id,
  };

  void checkReference(String id, String path) {
    if (id.length > maximumBackupIdLength || !backupIdPattern.hasMatch(id)) {
      throw BackupError(BackupErrorCode.invalidField, field: path);
    }
  }

  for (
    int programIndex = 0;
    programIndex < programs.length;
    programIndex += 1
  ) {
    final Program program = programs[programIndex];
    for (int dayIndex = 0; dayIndex < program.days.length; dayIndex += 1) {
      final ProgramDay day = program.days[dayIndex];
      for (int itemIndex = 0; itemIndex < day.items.length; itemIndex += 1) {
        final PlanItem item = day.items[itemIndex];
        final String path =
            'programs[$programIndex].days[$dayIndex].items[$itemIndex].exerciseId';
        checkReference(item.exerciseId, path);
        if (!exerciseIds.contains(item.exerciseId)) {
          throw BackupError(
            BackupErrorCode.orphanReference,
            field: path,
            value: item.exerciseId,
          );
        }
      }
    }
  }

  for (
    int sessionIndex = 0;
    sessionIndex < sessions.length;
    sessionIndex += 1
  ) {
    final Session session = sessions[sessionIndex];
    final String? programDayId = session.programDayId;
    if (programDayId != null) {
      checkReference(programDayId, 'sessions[$sessionIndex].programDayId');
    }
    for (
      int exerciseIndex = 0;
      exerciseIndex < session.exercises.length;
      exerciseIndex += 1
    ) {
      final SessionExercise exercise = session.exercises[exerciseIndex];
      final String path =
          'sessions[$sessionIndex].exercises[$exerciseIndex].exerciseId';
      checkReference(exercise.exerciseId, path);
      if (!exerciseIds.contains(exercise.exerciseId)) {
        throw BackupError(
          BackupErrorCode.orphanReference,
          field: path,
          value: exercise.exerciseId,
        );
      }
    }
  }
}

/// Rejects over-limit free text and ordering values at the untrusted boundary.
///
/// Field paths only: never echo a user's name. Older on-device documents are
/// loaded through the permissive models, not this parser, so this cannot lock
/// an existing install out.
void _validateTextAndOrderBounds(
  List<Exercise> exercises,
  List<Program> programs,
  List<Session> sessions,
) {
  void checkText(String value, String field, int maximum) {
    if (value.length > maximum) {
      throw BackupError(BackupErrorCode.absurdValue, field: field);
    }
  }

  void checkOrder(int value, String field) {
    if (value < 0 || value > maximumSortOrder) {
      throw BackupError(
        BackupErrorCode.absurdValue,
        field: field,
        value: '$value',
      );
    }
  }

  for (int index = 0; index < exercises.length; index += 1) {
    final Exercise exercise = exercises[index];
    checkText(
      exercise.name,
      'exercises[$index].name',
      maximumExerciseNameLength,
    );
    final String? searchTerm = exercise.searchTerm;
    if (searchTerm != null) {
      checkText(
        searchTerm,
        'exercises[$index].searchTerm',
        maximumSearchTermLength,
      );
    }
  }
  for (
    int programIndex = 0;
    programIndex < programs.length;
    programIndex += 1
  ) {
    final Program program = programs[programIndex];
    checkText(
      program.name,
      'programs[$programIndex].name',
      maximumProgramNameLength,
    );
    for (int dayIndex = 0; dayIndex < program.days.length; dayIndex += 1) {
      final ProgramDay day = program.days[dayIndex];
      final String dayPath = 'programs[$programIndex].days[$dayIndex]';
      checkText(day.name, '$dayPath.name', maximumDayNameLength);
      checkOrder(day.sortOrder, '$dayPath.sortOrder');
      for (int itemIndex = 0; itemIndex < day.items.length; itemIndex += 1) {
        checkOrder(
          day.items[itemIndex].sortOrder,
          '$dayPath.items[$itemIndex].sortOrder',
        );
      }
    }
  }
  for (
    int sessionIndex = 0;
    sessionIndex < sessions.length;
    sessionIndex += 1
  ) {
    final Session session = sessions[sessionIndex];
    for (
      int exerciseIndex = 0;
      exerciseIndex < session.exercises.length;
      exerciseIndex += 1
    ) {
      checkOrder(
        session.exercises[exerciseIndex].sortOrder,
        'sessions[$sessionIndex].exercises[$exerciseIndex].sortOrder',
      );
    }
  }
}

void _validateTimestamps(
  List<Exercise> exercises,
  List<Program> programs,
  List<Session> sessions,
  List<BodyWeightEntry> bodyWeights,
) {
  for (int index = 0; index < exercises.length; index += 1) {
    _checkTimestamp(exercises[index].createdAt, 'exercises[$index].createdAt');
    final DateTime? archivedAt = exercises[index].archivedAt;
    if (archivedAt != null) {
      _checkTimestamp(archivedAt, 'exercises[$index].archivedAt');
    }
  }
  for (
    int programIndex = 0;
    programIndex < programs.length;
    programIndex += 1
  ) {
    final Program program = programs[programIndex];
    _checkTimestamp(program.createdAt, 'programs[$programIndex].createdAt');
    final DateTime? archivedAt = program.archivedAt;
    if (archivedAt != null) {
      _checkTimestamp(archivedAt, 'programs[$programIndex].archivedAt');
    }
  }
  for (
    int bodyWeightIndex = 0;
    bodyWeightIndex < bodyWeights.length;
    bodyWeightIndex += 1
  ) {
    _checkTimestamp(
      bodyWeights[bodyWeightIndex].recordedAt,
      'bodyWeights[$bodyWeightIndex].recordedAt',
    );
  }
  for (
    int sessionIndex = 0;
    sessionIndex < sessions.length;
    sessionIndex += 1
  ) {
    final Session session = sessions[sessionIndex];
    _checkTimestamp(session.startedAt, 'sessions[$sessionIndex].startedAt');
    final DateTime? endedAt = session.endedAt;
    if (endedAt != null) {
      _checkTimestamp(endedAt, 'sessions[$sessionIndex].endedAt');
    }
    for (
      int exerciseIndex = 0;
      exerciseIndex < session.exercises.length;
      exerciseIndex += 1
    ) {
      final SessionExercise exercise = session.exercises[exerciseIndex];
      for (int setIndex = 0; setIndex < exercise.sets.length; setIndex += 1) {
        _checkTimestamp(
          exercise.sets[setIndex].loggedAt,
          'sessions[$sessionIndex].exercises[$exerciseIndex]'
          '.sets[$setIndex].loggedAt',
        );
      }
    }
  }
}

void _checkTimestamp(DateTime value, String field) {
  if (value.year < minimumBackupYear || value.year > maximumBackupYear) {
    throw BackupError(
      BackupErrorCode.absurdValue,
      field: field,
      value: value.toIso8601String(),
    );
  }
}

void _validateHeaderString(String value, String field) {
  if (value.length > maximumBackupHeaderLength ||
      !backupHeaderPattern.hasMatch(value)) {
    throw BackupError(BackupErrorCode.invalidField, field: field);
  }
}
