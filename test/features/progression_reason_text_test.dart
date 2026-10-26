import 'package:flutter_test/flutter_test.dart';
import 'package:gym_log/core/l10n/generated/app_localizations.dart';
import 'package:gym_log/core/l10n/generated/app_localizations_en.dart';
import 'package:gym_log/core/l10n/generated/app_localizations_fa.dart';
import 'package:gym_log/features/workout/presentation/progression_reason_text.dart';
import 'package:lift_core/lift_core.dart';

ProgressionSuggestion _suggestion(ProgressionReason reason) {
  return ProgressionSuggestion(
    rule: ProgressionRule.addWeight,
    weightGrams: 102500,
    targetReps: 8,
    reason: reason,
  );
}

void main() {
  final AppLocalizations en = AppLocalizationsEn();
  final AppLocalizations fa = AppLocalizationsFa();

  test('rule A reason renders count, top reps, and kg in both locales', () {
    final ProgressionSuggestion suggestion = _suggestion(
      const ProgressionReasonAddWeight(
        setCount: 3,
        maxReps: 12,
        incrementGrams: 2500,
      ),
    );

    expect(
      progressionReasonTextFor(en, suggestion, WeightUnit.kilograms),
      'All working sets reached 12 reps last time (sets: 3), so add 2.5 kg.',
    );
    expect(
      progressionReasonTextFor(fa, suggestion, WeightUnit.kilograms),
      'دفعه قبل هر 3 ست به 12 تکرار رسیدی؛ 2.5 کیلوگرم اضافه کن.',
    );
  });

  test('rule A reason formats a per-exercise pound increment', () {
    final ProgressionSuggestion suggestion = _suggestion(
      const ProgressionReasonAddWeight(
        setCount: 4,
        maxReps: 10,
        incrementGrams: defaultPoundIncrementGrams,
      ),
    );

    expect(
      progressionReasonTextFor(en, suggestion, WeightUnit.pounds),
      'All working sets reached 10 reps last time (sets: 4), so add 5 lb.',
    );
    expect(
      progressionReasonTextFor(fa, suggestion, WeightUnit.pounds),
      'دفعه قبل هر 4 ست به 10 تکرار رسیدی؛ 5 پوند اضافه کن.',
    );
  });

  test('rule B reason renders weakest and target reps in both locales', () {
    final ProgressionSuggestion suggestion = _suggestion(
      const ProgressionReasonAddReps(weakestReps: 9, targetReps: 10),
    );

    expect(
      progressionReasonTextFor(en, suggestion, WeightUnit.kilograms),
      'Your weakest set was 9 reps; aim for 10 reps.',
    );
    expect(
      progressionReasonTextFor(fa, suggestion, WeightUnit.kilograms),
      'ضعیف‌ترین ست دفعه قبل 9 تکرار بود؛ هدف 10 تکرار است.',
    );
  });

  test('rule C reason renders the minimum in both locales', () {
    final ProgressionSuggestion suggestion = _suggestion(
      const ProgressionReasonHold(minReps: 8),
    );

    expect(
      progressionReasonTextFor(en, suggestion, WeightUnit.kilograms),
      'Below 8 reps last time; keep the weight and rebuild.',
    );
    expect(
      progressionReasonTextFor(fa, suggestion, WeightUnit.kilograms),
      'دفعه قبل زیر 8 تکرار بودی؛ وزن را نگه دار و دوباره بساز.',
    );
  });
}
