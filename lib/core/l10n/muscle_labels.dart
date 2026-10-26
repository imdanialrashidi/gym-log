import 'package:lift_core/lift_core.dart';

import 'l10n.dart';

/// Localized label for the fixed muscle-group list (`EXR-006`).
String muscleGroupLabel(AppLocalizations l10n, MuscleGroup group) {
  return switch (group) {
    MuscleGroup.chest => l10n.muscleChest,
    MuscleGroup.back => l10n.muscleBack,
    MuscleGroup.shoulders => l10n.muscleShoulders,
    MuscleGroup.biceps => l10n.muscleBiceps,
    MuscleGroup.triceps => l10n.muscleTriceps,
    MuscleGroup.forearms => l10n.muscleForearms,
    MuscleGroup.quadriceps => l10n.muscleQuadriceps,
    MuscleGroup.hamstrings => l10n.muscleHamstrings,
    MuscleGroup.glutes => l10n.muscleGlutes,
    MuscleGroup.calves => l10n.muscleCalves,
    MuscleGroup.abdominals => l10n.muscleAbdominals,
    MuscleGroup.fullBody => l10n.muscleFullBody,
  };
}
