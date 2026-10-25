import 'digits.dart';
import 'json_reader.dart';
import 'weight.dart';

/// Default in-app rest duration (`LOG-008`).
const int defaultRestTimerSeconds = 90;

/// Bounds accepted for a configured rest duration.
const int minimumRestTimerSeconds = 5;
const int maximumRestTimerSeconds = 3600;

/// Whether [seconds] is a valid configured rest duration.
bool isValidRestTimerDuration(int seconds) {
  return seconds >= minimumRestTimerSeconds &&
      seconds <= maximumRestTimerSeconds;
}

/// Settings that affect stored or displayed training data (`SET-003`,
/// `LOG-008`).
///
/// The weight unit is display-only; weights stay canonical grams.
class AppSettings {
  const AppSettings({
    this.weightUnit = WeightUnit.kilograms,
    this.digitStyle,
    this.defaultIncrementGrams,
    this.restTimerEnabled = false,
    this.restTimerDurationSeconds = defaultRestTimerSeconds,
  });

  final WeightUnit weightUnit;

  /// Explicit digit style (`SET-002`, `L10N-004`). `null` follows the UI
  /// language (Persian digits for `fa`, Latin digits otherwise).
  final DigitStyle? digitStyle;

  /// Default increment for a new exercise. `null` means the unit default.
  ///
  /// Per-exercise increments remain authoritative once an exercise exists.
  final int? defaultIncrementGrams;

  /// Whether logging a set starts the in-app rest timer.
  final bool restTimerEnabled;

  /// Configured rest length. The timer stores an end timestamp when it starts,
  /// so this value is only read at start time.
  final int restTimerDurationSeconds;

  /// The increment to offer for a new exercise in [weightUnit].
  int incrementFor(WeightUnit displayUnit) {
    return defaultIncrementGrams ?? unitDefaultIncrementGrams(displayUnit);
  }

  AppSettings copyWith({
    WeightUnit? weightUnit,
    DigitStyle? digitStyle,
    int? defaultIncrementGrams,
    bool? restTimerEnabled,
    int? restTimerDurationSeconds,
  }) {
    return AppSettings(
      weightUnit: weightUnit ?? this.weightUnit,
      digitStyle: digitStyle ?? this.digitStyle,
      defaultIncrementGrams:
          defaultIncrementGrams ?? this.defaultIncrementGrams,
      restTimerEnabled: restTimerEnabled ?? this.restTimerEnabled,
      restTimerDurationSeconds:
          restTimerDurationSeconds ?? this.restTimerDurationSeconds,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'weightUnit': switch (weightUnit) {
      WeightUnit.kilograms => 'kilograms',
      WeightUnit.pounds => 'pounds',
    },
    if (digitStyle != null)
      'digitStyle': switch (digitStyle!) {
        DigitStyle.persian => 'persian',
        DigitStyle.latin => 'latin',
      },
    if (defaultIncrementGrams != null)
      'defaultIncrementGrams': defaultIncrementGrams,
    'restTimerEnabled': restTimerEnabled,
    'restTimerDurationSeconds': restTimerDurationSeconds,
  };

  factory AppSettings.fromJson(Map<String, Object?> json) {
    final String unit = readString(json, 'weightUnit');
    final bool enabled = _readOptionalBool(json, 'restTimerEnabled') ?? false;
    final int duration =
        readOptionalInt(json, 'restTimerDurationSeconds') ??
        defaultRestTimerSeconds;
    if (!isValidRestTimerDuration(duration)) {
      throw FormatException(
        'Rest timer duration must be between $minimumRestTimerSeconds and '
        '$maximumRestTimerSeconds seconds',
      );
    }
    final String? digitName = readOptionalString(json, 'digitStyle');
    final DigitStyle? digitStyle = switch (digitName) {
      null => null,
      'persian' => DigitStyle.persian,
      'latin' => DigitStyle.latin,
      _ => throw FormatException('Unknown digit style "$digitName"'),
    };
    final int? increment = readOptionalInt(json, 'defaultIncrementGrams');
    if (increment != null &&
        (increment <= 0 || increment > maximumSetWeightGrams)) {
      throw FormatException(
        'Default increment must be between 1 and $maximumSetWeightGrams grams',
      );
    }
    return AppSettings(
      weightUnit: switch (unit) {
        'kilograms' => WeightUnit.kilograms,
        'pounds' => WeightUnit.pounds,
        _ => throw FormatException('Unknown weight unit "$unit"'),
      },
      digitStyle: digitStyle,
      defaultIncrementGrams: increment,
      restTimerEnabled: enabled,
      restTimerDurationSeconds: duration,
    );
  }
}

bool? _readOptionalBool(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  throw FormatException('"$key" must be a boolean or null');
}
