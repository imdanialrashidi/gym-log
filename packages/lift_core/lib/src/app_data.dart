import 'body_weight.dart';
import 'exercise.dart';
import 'json_reader.dart';
import 'persian_search.dart';
import 'program.dart';
import 'session.dart';
import 'settings.dart';

/// Current on-device document schema. A future Drift migration must carry this
/// document forward, never discard it.
///
/// Version 2 added sessions and app settings. Version 3 added body-weight
/// check-ins. Version 4 adds optional weekly goals inside settings. Older
/// documents are read with empty/default newer fields and written back as the
/// current version; no version ever discards an existing collection.
const int appDataSchemaVersion = 4;

/// Aggregate persisted by the exercise/program/logging milestones.
///
/// Higher layers never mutate these lists in place; every change produces a
/// new [AppData] that is validated before it can be saved.
class AppData {
  factory AppData({
    List<Exercise> exercises = const <Exercise>[],
    List<Program> programs = const <Program>[],
    List<Session> sessions = const <Session>[],
    List<BodyWeightEntry> bodyWeights = const <BodyWeightEntry>[],
    AppSettings settings = const AppSettings(),
  }) {
    final Set<String> ids = <String>{};
    for (final Exercise exercise in exercises) {
      if (!ids.add(exercise.id)) {
        throw ArgumentError('Duplicate exercise id ${exercise.id}');
      }
    }
    for (final BodyWeightEntry entry in bodyWeights) {
      if (!ids.add(entry.id)) {
        throw ArgumentError('Duplicate body-weight id ${entry.id}');
      }
    }
    for (final Program program in programs) {
      if (!ids.add(program.id)) {
        throw ArgumentError('Duplicate program id ${program.id}');
      }
      for (final ProgramDay day in program.days) {
        if (!ids.add(day.id)) {
          throw ArgumentError('Duplicate day id ${day.id}');
        }
        for (final PlanItem item in day.items) {
          if (!ids.add(item.id)) {
            throw ArgumentError('Duplicate plan item id ${item.id}');
          }
        }
      }
    }

    final Set<String> exerciseIds = <String>{
      for (final Exercise exercise in exercises) exercise.id,
    };
    for (final Program program in programs) {
      for (final ProgramDay day in program.days) {
        for (final PlanItem item in day.items) {
          if (!exerciseIds.contains(item.exerciseId)) {
            throw FormatException(
              'Plan item ${item.id} references missing exercise '
              '${item.exerciseId}',
            );
          }
        }
      }
    }

    int activeSessions = 0;
    for (final Session session in sessions) {
      if (!ids.add(session.id)) {
        throw ArgumentError('Duplicate session id ${session.id}');
      }
      if (session.isActive) {
        activeSessions += 1;
      }
      for (final SessionExercise exercise in session.exercises) {
        if (!ids.add(exercise.id)) {
          throw ArgumentError('Duplicate session exercise id ${exercise.id}');
        }
        if (!exerciseIds.contains(exercise.exerciseId)) {
          throw FormatException(
            'Session exercise ${exercise.id} references missing exercise '
            '${exercise.exerciseId}',
          );
        }
        for (final SetLog set in exercise.sets) {
          if (!ids.add(set.id)) {
            throw ArgumentError('Duplicate set id ${set.id}');
          }
        }
      }
    }
    if (activeSessions > 1) {
      throw ArgumentError('Only one session may be active');
    }

    return AppData._(
      exercises: List<Exercise>.unmodifiable(exercises),
      programs: List<Program>.unmodifiable(programs),
      sessions: List<Session>.unmodifiable(sessions),
      bodyWeights: List<BodyWeightEntry>.unmodifiable(bodyWeights),
      settings: settings,
    );
  }

  const AppData._({
    required this.exercises,
    required this.programs,
    required this.sessions,
    required this.bodyWeights,
    required this.settings,
  });

  final List<Exercise> exercises;
  final List<Program> programs;
  final List<Session> sessions;

  /// Body-weight check-ins, in insertion order. Weekly series pick the latest
  /// entry inside each week.
  final List<BodyWeightEntry> bodyWeights;
  final AppSettings settings;

  /// Exercises offered by the picker and the default library view.
  List<Exercise> get activeExercises => List<Exercise>.unmodifiable(
    exercises.where((Exercise exercise) => !exercise.isArchived),
  );

  /// Active exercises filtered by the Persian/Latin search rules.
  List<Exercise> searchExercises(String query) => List<Exercise>.unmodifiable(
    activeExercises.where(
      (Exercise exercise) => matchesSearchQuery(exercise.name, query),
    ),
  );

  Exercise? exerciseById(String id) {
    for (final Exercise exercise in exercises) {
      if (exercise.id == id) {
        return exercise;
      }
    }
    return null;
  }

  Program? programById(String id) {
    for (final Program program in programs) {
      if (program.id == id) {
        return program;
      }
    }
    return null;
  }

  ProgramDay? dayById(String id) {
    for (final Program program in programs) {
      for (final ProgramDay day in program.days) {
        if (day.id == id) {
          return day;
        }
      }
    }
    return null;
  }

  PlanItem? planItemById(String id) {
    for (final Program program in programs) {
      for (final ProgramDay day in program.days) {
        for (final PlanItem item in day.items) {
          if (item.id == id) {
            return item;
          }
        }
      }
    }
    return null;
  }

  Program? programForDay(String dayId) {
    for (final Program program in programs) {
      for (final ProgramDay day in program.days) {
        if (day.id == dayId) {
          return program;
        }
      }
    }
    return null;
  }

  Session? sessionById(String id) {
    for (final Session session in sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  /// The single unfinished session, if one exists (`LOG-009`).
  Session? get activeSession {
    for (final Session session in sessions) {
      if (session.isActive) {
        return session;
      }
    }
    return null;
  }

  AppData copyWith({
    List<Exercise>? exercises,
    List<Program>? programs,
    List<Session>? sessions,
    List<BodyWeightEntry>? bodyWeights,
    AppSettings? settings,
  }) {
    return AppData(
      exercises: exercises ?? this.exercises,
      programs: programs ?? this.programs,
      sessions: sessions ?? this.sessions,
      bodyWeights: bodyWeights ?? this.bodyWeights,
      settings: settings ?? this.settings,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': appDataSchemaVersion,
    'exercises': <Object?>[
      for (final Exercise exercise in exercises) exercise.toJson(),
    ],
    'programs': <Object?>[
      for (final Program program in programs) program.toJson(),
    ],
    'sessions': <Object?>[
      for (final Session session in sessions) session.toJson(),
    ],
    'bodyWeights': <Object?>[
      for (final BodyWeightEntry entry in bodyWeights) entry.toJson(),
    ],
    'settings': settings.toJson(),
  };

  factory AppData.fromJson(Map<String, Object?> json) {
    final int version = readInt(json, 'schemaVersion');
    if (version < 1 || version > appDataSchemaVersion) {
      throw FormatException(
        'Unsupported data schema version $version '
        '(expected 1 through $appDataSchemaVersion)',
      );
    }
    final List<Program> programs = <Program>[
      for (final Object? program in readList(json, 'programs'))
        Program.fromJson(readMap(program, 'programs')),
    ];
    final List<Session> sessions;
    final List<BodyWeightEntry> bodyWeights;
    final AppSettings settings;
    if (version == 1) {
      sessions = const <Session>[];
      bodyWeights = const <BodyWeightEntry>[];
      settings = const AppSettings();
    } else if (version == 2) {
      sessions = <Session>[
        for (final Object? session in readList(json, 'sessions'))
          Session.fromJson(readMap(session, 'sessions')),
      ];
      bodyWeights = const <BodyWeightEntry>[];
      settings = AppSettings.fromJson(readMap(json['settings'], 'settings'));
    } else {
      // Versions 3 and 4 share the same collections; version 4 adds optional
      // goal values that the settings reader accepts when present.
      sessions = <Session>[
        for (final Object? session in readList(json, 'sessions'))
          Session.fromJson(readMap(session, 'sessions')),
      ];
      bodyWeights = <BodyWeightEntry>[
        for (final Object? entry in readList(json, 'bodyWeights'))
          BodyWeightEntry.fromJson(readMap(entry, 'bodyWeights')),
      ];
      settings = AppSettings.fromJson(readMap(json['settings'], 'settings'));
    }
    return AppData(
      exercises: <Exercise>[
        for (final Object? exercise in readList(json, 'exercises'))
          Exercise.fromJson(readMap(exercise, 'exercises')),
      ],
      programs: programs,
      sessions: sessions,
      bodyWeights: bodyWeights,
      settings: settings,
    );
  }
}
