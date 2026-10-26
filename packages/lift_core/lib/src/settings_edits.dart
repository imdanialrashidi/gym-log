import 'app_data.dart';
import 'digits.dart';
import 'settings.dart';
import 'weight.dart';

AppData setWeightUnit(AppData data, WeightUnit unit) {
  return data.copyWith(settings: data.settings.copyWith(weightUnit: unit));
}

/// Sets the explicit digit style; display only (`SET-002`).
AppData setDigitStyle(AppData data, DigitStyle style) {
  return data.copyWith(settings: data.settings.copyWith(digitStyle: style));
}

/// Sets the default increment for new exercises (`EXR-007`).
AppData setDefaultIncrementGrams(AppData data, int grams) {
  if (grams <= 0 || grams > maximumSetWeightGrams) {
    throw ArgumentError.value(grams, 'grams');
  }
  return data.copyWith(
    settings: data.settings.copyWith(defaultIncrementGrams: grams),
  );
}

AppData setRestTimerEnabled(AppData data, bool enabled) {
  return data.copyWith(
    settings: data.settings.copyWith(restTimerEnabled: enabled),
  );
}

/// Applies a relative rest-duration change and clamps it to the supported
/// bounds, so two quick steps each see the previous result.
AppData adjustRestTimerDurationSeconds(AppData data, int delta) {
  return data.copyWith(
    settings: data.settings.copyWith(
      restTimerDurationSeconds: (data.settings.restTimerDurationSeconds + delta)
          .clamp(minimumRestTimerSeconds, maximumRestTimerSeconds),
    ),
  );
}

AppData setRestTimerDurationSeconds(AppData data, int seconds) {
  if (!isValidRestTimerDuration(seconds)) {
    throw ArgumentError.value(seconds, 'seconds');
  }
  return data.copyWith(
    settings: data.settings.copyWith(restTimerDurationSeconds: seconds),
  );
}

/// Enables or updates the optional weekly training goal (`GOAL-001`).
AppData setWeeklyGoals(AppData data, {int? sessionGoal, int? setGoal}) {
  return data.copyWith(
    settings: data.settings.withWeeklyGoals(
      sessionGoal: sessionGoal,
      setGoal: setGoal,
    ),
  );
}

/// Removes both weekly goals without touching anything else.
AppData clearWeeklyGoals(AppData data) {
  return data.copyWith(
    settings: data.settings.withWeeklyGoals(sessionGoal: null, setGoal: null),
  );
}
