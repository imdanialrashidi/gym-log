/// Generous UI and import bounds, not database limits.
///
/// They are enforced at the untrusted import boundary and by editors. Existing
/// on-device documents may exceed them: the models stay permissive so an older
/// install still loads instead of landing on the recovery screen.
library;

/// Maximum stored exercise name length.
const int maximumExerciseNameLength = 120;

/// Maximum stored exercise search-term length.
const int maximumSearchTermLength = 200;

/// Maximum stored program name length.
const int maximumProgramNameLength = 120;

/// Maximum stored program-day name length.
const int maximumDayNameLength = 120;

/// Maximum `sortOrder` for days, plan items, and session exercises.
///
/// Far beyond any realistic list, and small enough that `last + 1` stays well
/// inside 64-bit arithmetic.
const int maximumSortOrder = 1000000;
