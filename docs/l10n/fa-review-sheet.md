# Persian copy review sheet

Native-speaker review aid for `L10N-010`. Every Persian string in `lib/core/l10n/app_fa.arb` appears exactly once. The English column is the source message, not a translation; the context column names the screen or shared surface. Review tone, clarity, and natural button wording; do not translate marketing claims.

Regenerate with `dart run tool/fa_review_sheet.dart`.

| Key | Screen / context | Persian (fa) | English reference | Notes |
|---|---|---|---|---|
| `aboutDonate` | General | حمایت مالی | Donate | Review tone and clarity. |
| `aboutLicenseLabel` | General | مجوز برنامه | App license | Review tone and clarity. |
| `aboutLicenseValue` | General | کلیهٔ حقوق محفوظ است. | All rights reserved | Review tone and clarity. |
| `aboutLinkFailed` | General | مرورگر باز نشد. | Could not open a browser. | Review tone and clarity. |
| `aboutNotMedicalAdvice` | General | Gym Log یک دفتر تمرین است، نه توصیهٔ پزشکی. پیش از تغییر برنامهٔ تمرینی با یک متخصص واجد شرایط مشورت کن. | Gym Log is a training log, not medical advice. Consult a qualified professional before changing your training. | Review tone and clarity. |
| `aboutOpenSourceLicenses` | General | مجوزهای متن‌باز | Open-source licenses | Review tone and clarity. |
| `aboutPrivacyBody` | General | داده‌های تمرینت روی همین دستگاه می‌ماند. Gym Log حساب کاربری، آمارگیری و مجوز شبکه در نسخهٔ انتشار ندارد. عکس‌ها به‌صورت خصوصی و بدون فرادادهٔ مکان ذخیره می‌شوند و خروجی JSON هرگز شامل عکس‌ها نیست. پشتیبان‌گیری اندروید خاموش است؛ برای انتقال به گوشی تازه، خروجی JSON بگیر و آن را در گوشی جدید وارد کن. | Your training data stays on this device. Gym Log has no account, no analytics, and no network permission in release builds. Photos are stored privately with location metadata removed, and JSON exports never include photos. Android backup is disabled, so moving to a new phone means exporting a JSON backup and importing it there. | Review tone and clarity. |
| `aboutPrivacyTitle` | General | حریم خصوصی | Privacy | Review tone and clarity. |
| `aboutSourceCode` | General | کد منبع | Source code | Review tone and clarity. |
| `aboutTitle` | General | درباره | About | Review tone and clarity. |
| `aboutVersion` | General | نسخه {version} | Version {version} | Placeholders: {version} |
| `activeWorkoutTitle` | Workout | تمرین فعال | Active workout | Review tone and clarity. |
| `addDay` | Programs | افزودن روز | Add day | Review tone and clarity. |
| `addExercise` | Exercises | افزودن حرکت | Add exercise | Review tone and clarity. |
| `addFirstExercise` | Exercises | اولین حرکتت را اضافه کن | Add your first exercise | Review tone and clarity. |
| `addNote` | History / session | افزودن یادداشت | Add note | Review tone and clarity. |
| `addPhoto` | General | افزودن عکس | Add photo | Review tone and clarity. |
| `addProgram` | Programs | افزودن برنامه | Add program | Review tone and clarity. |
| `addSet` | Workout | افزودن ست | Add set | Review tone and clarity. |
| `androidBackupHint` | Settings / backup | خاموش. پشتیبان‌گیری خودکار اندروید در همهٔ نسخه‌ها غیرفعال است تا داده‌ها از دستگاه خارج نشوند. برای انتقال گوشی، خروجی JSON بگیر. | Off. Android Auto Backup is disabled in every build so your data cannot leave the device. Export a JSON backup to move phones. | Review tone and clarity. |
| `androidBackupTitle` | Settings / backup | اجازه پشتیبان‌گیری اندروید | Allow Android backup | Review tone and clarity. |
| `appTagline` | General | تمرین تو، اندازه‌گیری‌شده. | Your training, measured. | Review tone and clarity. |
| `appTitle` | App shell / navigation | Gym Log | Gym Log | Review tone and clarity. |
| `archive` | Exercises | بایگانی | Archive | Review tone and clarity. |
| `archivedLabel` | Exercises | بایگانی‌شده | Archived | Review tone and clarity. |
| `averageTime` | General | میانگین | Average | Review tone and clarity. |
| `backupSectionTitle` | Settings / backup | پشتیبان‌گیری | Backup | Review tone and clarity. |
| `bodyWeightChartSubtitle` | Workout | آخرین ثبت هر هفته | Latest check-in per week | Review tone and clarity. |
| `bodyWeightChartTitle` | Workout | روند هفتگی | Weekly trend | Review tone and clarity. |
| `bodyWeightDeleted` | Workout | ثبت وزن حذف شد. | Weight check-in deleted. | Review tone and clarity. |
| `bodyWeightEmpty` | Workout | هنوز وزنی ثبت نشده. برای شروع نمودار، وزنت را ثبت کن. | No weight check-ins yet. Log your weight to start the trend. | Review tone and clarity. |
| `bodyWeightErrorRange` | Workout | یک وزن واقعی وارد کن. | Enter a realistic body weight. | Review tone and clarity. |
| `bodyWeightHint` | Workout | هر هفته در ساعت ثابتی وزن کن؛ بهتر است صبح و قبل از غذا باشد. | Weigh in at the same time each week, ideally in the morning before eating. | Review tone and clarity. |
| `bodyWeightHistory` | History / session | ثبت‌ها | Check-ins | Review tone and clarity. |
| `bodyWeightLogTitle` | Workout | ثبت وزن بدن | Log body weight | Review tone and clarity. |
| `bodyWeightMissingWeek` | Workout | ثبت نشده | No check-in | Review tone and clarity. |
| `bodyWeightSaved` | Workout | وزن ثبت شد. | Weight logged. | Review tone and clarity. |
| `bodyWeightSubtitle` | Workout | ثبت هفتگی | Weekly check-in | Review tone and clarity. |
| `bodyWeightThisWeek` | Workout | این هفته | This week | Review tone and clarity. |
| `bodyWeightTitle` | Workout | وزن بدن | Body weight | Review tone and clarity. |
| `cancel` | Shared controls | انصراف | Cancel | Review tone and clarity. |
| `changePhoto` | General | تغییر عکس | Change photo | Review tone and clarity. |
| `checkInCount` | General | {count} ثبت | {count, plural, =1{1 check-in} other{{count} check-ins}} | Placeholders: {count}; Plural |
| `chooseDay` | General | یک روز انتخاب کن | Choose a day | Review tone and clarity. |
| `chooseExercise` | Exercises | انتخاب حرکت | Choose exercise | Review tone and clarity. |
| `chooseFromGallery` | General | انتخاب از گالری | Choose from gallery | Review tone and clarity. |
| `clearSearch` | Exercises | پاک کردن جستجو | Clear search | Review tone and clarity. |
| `close` | Shared controls | بستن | Close | Review tone and clarity. |
| `dashboardGoalKicker` | General | هدف | TARGET | Review tone and clarity. |
| `dashboardReady` | General | آمادهٔ شروع | Ready to train | Review tone and clarity. |
| `dashboardTitle` | General | تمرین امروز | Today’s training | Review tone and clarity. |
| `dashboardToday` | General | امروز | Today | Review tone and clarity. |
| `dashboardWeekKicker` | General | دفتر هفته | WEEKLY LOG | Review tone and clarity. |
| `dashboardWeekVolume` | General | حجم این هفته | Week volume | Review tone and clarity. |
| `dayNameLabel` | Programs | نام روز | Day name | Review tone and clarity. |
| `dayNotFound` | Programs | این روز دیگر وجود ندارد. | This day no longer exists. | Review tone and clarity. |
| `decreaseReps` | Workout | کم کردن تکرار | Decrease reps | Review tone and clarity. |
| `decreaseRestTimer` | Settings / backup | کم کردن مدت استراحت | Decrease rest duration | Review tone and clarity. |
| `decreaseWeight` | Workout | کم کردن وزن | Decrease weight | Review tone and clarity. |
| `defaultIncrementDialogTitle` | Settings / backup | افزایش وزن پیش‌فرض | Default weight increment | Review tone and clarity. |
| `defaultIncrementHint` | Settings / backup | برای حرکت‌های جدید استفاده می‌شود. | Used when you create a new exercise. | Review tone and clarity. |
| `defaultIncrementLabel` | Settings / backup | افزایش وزن پیش‌فرض | Default weight increment | Review tone and clarity. |
| `defaultRepRangeLabel` | Exercises | محدوده تکرار پیش‌فرض | Default rep range | Review tone and clarity. |
| `delete` | Shared controls | حذف | Delete | Review tone and clarity. |
| `deleteDayBody` | Programs | این روز و آیتم‌های برنامه‌اش حذف می‌شوند. | This removes the day and its plan items. | Review tone and clarity. |
| `deleteDayTitle` | Programs | روز حذف شود؟ | Delete day? | Review tone and clarity. |
| `deletePlanItemBody` | Programs | این حرکت از برنامهٔ روز حذف می‌شود. | This removes the item from the plan. | Review tone and clarity. |
| `deletePlanItemTitle` | Programs | این ردیف حذف شود؟ | Delete plan item? | Review tone and clarity. |
| `deleteProgramBody` | Programs | برنامه و روزهایش حذف می‌شوند. تاریخچهٔ ثبت‌شده باقی می‌ماند. | This removes the program and its days. Logged history stays. | Review tone and clarity. |
| `deleteProgramTitle` | Programs | برنامه حذف شود؟ | Delete program? | Review tone and clarity. |
| `deleteSession` | History / session | حذف جلسه | Delete session | Review tone and clarity. |
| `deleteSessionBody` | History / session | این جلسه، ست‌ها و یادداشت‌هایش برای همیشه حذف می‌شوند. | This permanently removes the session, its sets, and its notes. | Review tone and clarity. |
| `deleteSessionTitle` | History / session | جلسه حذف شود؟ | Delete session? | Review tone and clarity. |
| `deleteSet` | History / session | حذف ست | Delete set | Review tone and clarity. |
| `deleteWeightBody` | Workout | نمودار روند بدون این مورد دوباره حساب می‌شود. | The weight trend is recalculated without it. | Review tone and clarity. |
| `deleteWeightTitle` | Workout | این ثبت وزن حذف شود؟ | Delete this check-in? | Review tone and clarity. |
| `digitStyleLabel` | Settings / backup | ارقام | Digits | Review tone and clarity. |
| `digitStyleLatin` | Settings / backup | ارقام لاتین | Latin digits | Review tone and clarity. |
| `digitStylePersian` | Settings / backup | ارقام فارسی | Persian digits | Review tone and clarity. |
| `duplicateExerciseNameBody` | Exercises | حرکتی با نام «{name}» از قبل وجود دارد. باز هم ذخیره شود؟ | An exercise named "{name}" already exists. Save anyway? | Placeholders: {name} |
| `duplicateExerciseNameTitle` | Exercises | نام تکراری | Duplicate name | Review tone and clarity. |
| `durationHours` | General | {hours} ساعت | {hours} h | Placeholders: {hours} |
| `durationHoursMinutes` | General | {hours} ساعت و {minutes} دقیقه | {hours} h {minutes} min | Placeholders: {hours}, {minutes} |
| `durationHoursMinutesShort` | General | {hours}س {minutes}د | {hours}h {minutes}m | Placeholders: {hours}, {minutes} |
| `durationHoursShort` | General | {hours}س | {hours}h | Placeholders: {hours} |
| `durationLessThanMinute` | General | کمتر از یک دقیقه | Under a minute | Review tone and clarity. |
| `durationMinutes` | General | {minutes} دقیقه | {minutes} min | Placeholders: {minutes} |
| `durationMinutesShort` | General | {minutes}د | {minutes}m | Placeholders: {minutes} |
| `durationUnderMinuteShort` | General | کمتر از ۱د | <1m | Review tone and clarity. |
| `durationUnknown` | General | ثبت نشده | Not recorded | Review tone and clarity. |
| `edit` | Shared controls | ویرایش | Edit | Review tone and clarity. |
| `editDayTitle` | Programs | ویرایش روز | Edit day | Review tone and clarity. |
| `editExerciseTitle` | Exercises | ویرایش حرکت | Edit exercise | Review tone and clarity. |
| `editNote` | History / session | ویرایش یادداشت | Edit note | Review tone and clarity. |
| `editPlanItemTitle` | Programs | ویرایش ردیف برنامه | Edit plan item | Review tone and clarity. |
| `editProgramTitle` | Programs | ویرایش برنامه | Edit program | Review tone and clarity. |
| `editSet` | History / session | ویرایش ست | Edit set | Review tone and clarity. |
| `elapsedTime` | General | مدت | Elapsed | Review tone and clarity. |
| `errorEnterBothReps` | Exercises | هر دو مقدار تکرار را وارد کن یا هر دو را خالی بگذار. | Enter both rep values or leave them empty. | Review tone and clarity. |
| `errorExerciseRequired` | Exercises | یک حرکت انتخاب کن. | Choose an exercise. | Review tone and clarity. |
| `errorIncrement` | Exercises | یک مقدار مثبت وارد کن. | Enter a positive increment. | Review tone and clarity. |
| `errorInputTooLong` | Shared controls | این مقدار بیش از حد طولانی است. | This value is too long. | Review tone and clarity. |
| `errorInvalidNumber` | Shared controls | فقط رقم وارد کن. | Use digits only. | Review tone and clarity. |
| `errorMinExceedsMax` | Exercises | حداقل تکرار نباید از حداکثر بیشتر باشد. | Minimum reps must not exceed maximum reps. | Review tone and clarity. |
| `errorNameRequired` | Exercises | نام را وارد کن. | Enter a name. | Review tone and clarity. |
| `errorNumberRequired` | Shared controls | یک عدد وارد کن. | Enter a number. | Review tone and clarity. |
| `errorRepRange` | Exercises / programs | عددی بین ۱ تا ۱۰۰ وارد کن. | Use 1 to 100. | Review tone and clarity. |
| `errorRepsNegative` | Exercises | تعداد تکرار نمی‌تواند منفی باشد. | Reps cannot be negative. | Review tone and clarity. |
| `errorRepsRange` | Exercises | عددی بین ۱ تا ۱۰۰۰ تکرار وارد کن. | Use 1 to 1000 reps. | Review tone and clarity. |
| `errorRepsRequired` | Exercises | تعداد تکرار را وارد کن. | Enter reps. | Review tone and clarity. |
| `errorSetsRange` | Programs | عددی بین ۱ تا ۲۰ وارد کن. | Use 1 to 20 sets. | Review tone and clarity. |
| `errorWeightDecimals` | Workout | حداکثر دو رقم اعشار وارد کن. | Use up to two decimals. | Review tone and clarity. |
| `errorWeightNegative` | Workout | وزن نمی‌تواند منفی باشد. | Weight cannot be negative. | Review tone and clarity. |
| `errorWeightRange` | Workout | وزن خارج از محدودهٔ مجاز است. | Weight is out of range. | Review tone and clarity. |
| `errorWeightRequired` | Workout | وزن را وارد کن. | Enter a weight. | Review tone and clarity. |
| `exerciseCount` | Exercises | {count} حرکت | {count, plural, =1{1 exercise} other{{count} exercises}} | Placeholders: {count}; Plural |
| `exerciseLabel` | Exercises | حرکت | Exercise | Review tone and clarity. |
| `exerciseLibraryCount` | Exercises | {count} حرکت | {count, plural, =1{1 exercise} other{{count} exercises}} | Placeholders: {count}; Plural |
| `exerciseLibrarySubtitle` | Exercises | ساخت و مدیریت حرکت‌ها | Create and manage exercises | Review tone and clarity. |
| `exerciseLibraryTitle` | Exercises | کتابخانهٔ حرکت‌ها | Exercise library | Review tone and clarity. |
| `exerciseListMeta` | Exercises | {sessions} جلسه · {sets} ست | {sessions, plural, =1{1 session} other{{sessions} sessions}} · {sets, plural, =1{1 set} other{{sets} sets}} | Placeholders: {sessions}, {sets}; Plural |
| `exerciseNeverTrained` | History / session | هنوز ثبت نشده | Not logged yet | Review tone and clarity. |
| `exerciseNotFound` | Exercises | این حرکت دیگر وجود ندارد. | This exercise no longer exists. | Review tone and clarity. |
| `exerciseNoteLabel` | History / session | یادداشت حرکت | Exercise note | Review tone and clarity. |
| `exercisePhotoLabel` | Exercises | عکس حرکت | Exercise photo | Review tone and clarity. |
| `exercisePickerTitle` | Exercises | انتخاب حرکت | Choose exercise | Review tone and clarity. |
| `exerciseTimeHint` | Exercises | از اولین تا آخرین ست این حرکت. | From the first to the last set in this exercise. | Review tone and clarity. |
| `exercisesEmpty` | Exercises | هنوز حرکتی نساخته‌ای. | No exercises yet. | Review tone and clarity. |
| `exercisesTitle` | Exercises | حرکت‌ها | Exercises | Review tone and clarity. |
| `exportData` | Settings / backup | خروجی داده‌ها | Export data | Review tone and clarity. |
| `exportDataHint` | Settings / backup | یک فایل JSON از حرکت‌ها، برنامه‌ها و تاریخچه ذخیره کن. عکس‌ها داخلش نیستند. | Save a JSON file with exercises, programs, and history. Photos are not included. | Review tone and clarity. |
| `exportFailed` | Settings / backup | ذخیرهٔ پشتیبان ممکن نشد. دوباره تلاش کن. | Could not save the backup. Try again. | Review tone and clarity. |
| `exportReminderBody` | Settings / backup | ۳۰ روز است که خروجی نگرفته‌ای. یک پشتیبان JSON ذخیره کن تا تاریخچه با گم شدن گوشی از دست نرود. | You have not exported your data in 30 days. Save a JSON backup so your history survives a lost phone. | Review tone and clarity. |
| `exportReminderDismiss` | Settings / backup | بستن یادآوری | Dismiss reminder | Review tone and clarity. |
| `exportReminderExport` | Settings / backup | همین حالا خروجی بگیر | Export now | Review tone and clarity. |
| `exportReminderLater` | Settings / backup | بعداً | Later | Review tone and clarity. |
| `exportReminderTitle` | Settings / backup | از داده‌هایت پشتیبان بگیر | Back up your data | Review tone and clarity. |
| `exportSaved` | Settings / backup | پشتیبان ذخیره شد. | Backup saved. | Review tone and clarity. |
| `finishWorkout` | Workout | پایان تمرین | Finish workout | Review tone and clarity. |
| `finishWorkoutBody` | Workout | ست‌های ثبت‌شده در تاریخچه می‌مانند. | Logged sets stay in your history. | Review tone and clarity. |
| `finishWorkoutConfirm` | Workout | تمام کن | Finish | Review tone and clarity. |
| `finishWorkoutTitle` | Workout | تمرین را تمام کنم؟ | Finish workout? | Review tone and clarity. |
| `goalEdit` | Shared controls | ویرایش هدف | Edit goal | Review tone and clarity. |
| `goalEnabled` | General | فعال | Active | Review tone and clarity. |
| `goalNotSet` | General | هدف تعیین نشده | No goal set | Review tone and clarity. |
| `goalProgressValue` | Progress | {done} از {target} | {done} of {target} | Placeholders: {done}, {target} |
| `goalRemainingSessions` | History / session | {count} جلسه تا هدف | {count} sessions to go | Placeholders: {count} |
| `goalRemainingSets` | General | {count} ست تا هدف | {count} sets to go | Placeholders: {count} |
| `goalRemove` | General | حذف هدف | Remove goal | Review tone and clarity. |
| `goalSaved` | Shared controls | هدف ذخیره شد. | Goal saved. | Review tone and clarity. |
| `goalSessionTargetLabel` | History / session | جلسه در هفته | Sessions per week | Review tone and clarity. |
| `goalSessionsLabel` | History / session | جلسه | Sessions | Review tone and clarity. |
| `goalSetCta` | General | هدف هفتگی تعیین کن | Set a weekly goal | Review tone and clarity. |
| `goalSetTargetLabel` | General | ست کارآمد در هفته | Working sets per week | Review tone and clarity. |
| `goalSetsLabel` | General | ست کارآمد | Working sets | Review tone and clarity. |
| `goalSettingsSubtitle` | General | هدف این هفته را تنظیم کن. | Set this week’s target. | Review tone and clarity. |
| `goalSheetBody` | General | دو عدد ساده که نشان می‌دهند این هفته چقدر جلو رفته‌ای. هدفی انتخاب کن که بتوانی تکرارش کنی، نه هدفی که فقط از سرش بگذری. | Two numbers that tell you where this week stands. Pick a target you can repeat, not one you have to survive. | Review tone and clarity. |
| `goalSheetTitle` | General | هدف هفتگی | Weekly goal | Review tone and clarity. |
| `goalStreak` | General | {count} هفته پیاپی | {count, plural, =1{1 week in a row} other{{count} weeks in a row}} | Placeholders: {count}; Plural |
| `goalWeeklyTitle` | General | هدف هفتگی | Weekly goal | Review tone and clarity. |
| `historyCalendarNext` | History / session | ماه بعد | Next month | Review tone and clarity. |
| `historyCalendarPrevious` | History / session | ماه قبل | Previous month | Review tone and clarity. |
| `historyEmpty` | History / session | هنوز تاریخچه‌ای نداری. | No history yet. | Review tone and clarity. |
| `historySessionSummary` | History / session | {sets} ست · {exercises} حرکت | Sets: {sets} · Exercises: {exercises} | Placeholders: {sets}, {exercises} |
| `historyTab` | App shell / navigation | تاریخچه | History | Review tone and clarity. |
| `historyTrainedDay` | History / session | تمرین در {date} | Trained {date} | Placeholders: {date} |
| `importCompleted` | Settings / backup | ورود کامل شد. | Import complete. | Review tone and clarity. |
| `importConfirm` | Settings / backup | ورود | Import | Review tone and clarity. |
| `importData` | Settings / backup | ورود داده‌ها | Import data | Review tone and clarity. |
| `importDataChanged` | Settings / backup | داده‌ها در میانهٔ ورود عوض شدند. فایل را دوباره بررسی و تلاش کن. | Your data changed during import. Review the file and try again. | Review tone and clarity. |
| `importDataHint` | Settings / backup | بازیابی از فایل پشتیبان JSON. | Restore from a JSON backup file. | Review tone and clarity. |
| `importErrorAbsurdValue` | Settings / backup | پشتیبان مقداری خارج از محدوده دارد: {field}. | The backup contains an out-of-range value: {field}. | Placeholders: {field} |
| `importErrorCorrupt` | Settings / backup | این فایل JSON معتبر نیست. ممکن است ناقص باشد. | This file is not valid JSON. It may be truncated. | Review tone and clarity. |
| `importErrorDuplicateId` | Settings / backup | شناسهٔ {id} بیش از یک بار در پشتیبان آمده است. | The backup contains the same ID more than once: {id}. | Placeholders: {id} |
| `importErrorEmpty` | Settings / backup | این فایل خالی است. | This file is empty. | Review tone and clarity. |
| `importErrorInvalidField` | Settings / backup | مقدار {field} در پشتیبان معتبر نیست. | The backup has an invalid value for {field}. | Placeholders: {field} |
| `importErrorMissingField` | Settings / backup | بخش {field} در پشتیبان نیست. | The backup is missing {field}. | Placeholders: {field} |
| `importErrorNewerVersion` | Settings / backup | این پشتیبان با نسخهٔ جدیدتری از Gym Log ساخته شده. اپ را به‌روز کن و دوباره تلاش کن. | This backup was made by a newer version of Gym Log. Update the app, then try again. | Review tone and clarity. |
| `importErrorOrphanReference` | Settings / backup | پشتیبان به حرکتی اشاره می‌کند که وجود ندارد: {id}. | The backup references an exercise that is missing: {id}. | Placeholders: {id} |
| `importErrorPickerUnavailable` | Settings / backup | باز کردن انتخاب‌گر فایل ممکن نشد. | Could not open the file picker. | Review tone and clarity. |
| `importErrorRoot` | Settings / backup | این فایل پشتیبان Gym Log نیست. | This file is not a Gym Log backup. | Review tone and clarity. |
| `importErrorTitle` | Settings / backup | ورود ممکن نشد | Could not import | Review tone and clarity. |
| `importErrorTooDeep` | Settings / backup | ساختار این فایل برای ورود بیش از حد تودرتو است. | This file is nested too deeply to import. | Review tone and clarity. |
| `importErrorTooLarge` | Settings / backup | این فایل برای ورود بیش از حد بزرگ است. | This file is too large to import. | Review tone and clarity. |
| `importErrorUnreadable` | Settings / backup | خواندن این فایل ممکن نشد. | Could not read this file. | Review tone and clarity. |
| `importErrorUnsupportedVersion` | Settings / backup | این نسخهٔ پشتیبان در این اپ پشتیبانی نمی‌شود. | This backup version is not supported by this app. | Review tone and clarity. |
| `importFailed` | Settings / backup | ورود ممکن نشد. داده‌هایت تغییری نکرد. | Could not import. Your data was not changed. | Review tone and clarity. |
| `importMergeHint` | Settings / backup | رکوردهای تازه اضافه می‌شوند؛ رکوردهای موجود بازنویسی نمی‌شوند. | Adds new records. Existing records are never overwritten. | Review tone and clarity. |
| `importModeLabel` | Settings / backup | حالت ورود | Import mode | Review tone and clarity. |
| `importModeMerge` | Settings / backup | ادغام | Merge | Review tone and clarity. |
| `importModeReplace` | Settings / backup | جایگزینی | Replace | Review tone and clarity. |
| `importNothingToAdd` | Settings / backup | مورد تازه‌ای برای ورود نیست. | Nothing new to import. | Review tone and clarity. |
| `importPhotosExcluded` | Settings / backup | عکس‌ها در پشتیبان JSON نیستند؛ جایگزینی و بازیابی، عکس‌هایی را که در فایل انتخاب‌شده نیستند حذف می‌کنند. | Photos are not included in JSON backups; Replace and restore delete photos that are not in the selected file. | Review tone and clarity. |
| `importPreviewTitle` | Settings / backup | ورود پشتیبان | Import backup | Review tone and clarity. |
| `importReplaceHint` | Settings / backup | همهٔ داده‌های فعلی جایگزین می‌شوند. قبلش یک نسخه از فایل داده ذخیره می‌شود؛ عکس‌ها در آن نیستند و حذف می‌شوند. | Replaces all current data. A snapshot of the data file is saved first; photos are not in it and are deleted. | Review tone and clarity. |
| `importSettingsRestored` | Settings / backup | تنظیمات بازیابی می‌شوند. | Settings will be restored. | Review tone and clarity. |
| `importSource` | Settings / backup | از نسخهٔ {version}، صادرشده در {date}. | From app version {version}, exported {date}. | Placeholders: {version}, {date} |
| `importSummaryAdd` | Settings / backup | افزوده می‌شود: {exercises} حرکت، {programs} برنامه، {sessions} جلسه، {sets} ست و {weights} ثبت وزن. | Will add {exercises, plural, =1{1 exercise} other{{exercises} exercises}}, {programs, plural, =1{1 program} other{{programs} programs}}, {sessions, plural, =1{1 session} other{{sessions} sessions}}, {sets, plural, =1{1 set} other{{sets} sets}}, and {weights, plural, =1{1 weight check-in} other{{weights} weight check-ins}}. | Placeholders: {exercises}, {programs}, {sessions}, {sets}, {weights}; Plural |
| `importSummaryConflicts` | Settings / backup | برای حفظ داده‌های محلی وارد نشد: {count}. | Not imported to keep local data: {count}. | Placeholders: {count} |
| `importSummaryReplace` | Settings / backup | داده‌های فعلی با این موارد جایگزین می‌شوند: {exercises} حرکت، {programs} برنامه، {sessions} جلسه، {sets} ست و {weights} ثبت وزن. | Will replace current data with {exercises, plural, =1{1 exercise} other{{exercises} exercises}}, {programs, plural, =1{1 program} other{{programs} programs}}, {sessions, plural, =1{1 session} other{{sessions} sessions}}, {sets, plural, =1{1 set} other{{sets} sets}}, and {weights, plural, =1{1 weight check-in} other{{weights} weight check-ins}}. | Placeholders: {exercises}, {programs}, {sessions}, {sets}, {weights}; Plural |
| `importSummaryUnchanged` | Settings / backup | رکوردهای بدون تغییر: {count}. | Unchanged records: {count}. | Placeholders: {count} |
| `inProgress` | Progress | در حال انجام | In progress | Review tone and clarity. |
| `increaseReps` | Workout | زیاد کردن تکرار | Increase reps | Review tone and clarity. |
| `increaseRestTimer` | Settings / backup | زیاد کردن مدت استراحت | Increase rest duration | Review tone and clarity. |
| `increaseWeight` | Workout | زیاد کردن وزن | Increase weight | Review tone and clarity. |
| `incrementDefaultHint` | Exercises | پیش‌فرض ۲٫۵ کیلوگرم (۵ پوند) | Default 2.5 kg (5 lb) | Review tone and clarity. |
| `incrementLabel` | Exercises | افزایش وزن | Weight increment | Review tone and clarity. |
| `languageEnglish` | Settings / backup | انگلیسی | English | Review tone and clarity. |
| `languageLabel` | Settings / backup | زبان | Language | Review tone and clarity. |
| `languagePersian` | Settings / backup | فارسی | Persian | Review tone and clarity. |
| `lastWorkout` | Workout | آخرین تمرین | Last workout | Review tone and clarity. |
| `liveAllSetsDone` | General | همهٔ ست‌ها ثبت شد | All sets logged | Review tone and clarity. |
| `liveNextExercise` | Exercises | بعدی: {exercise} | Next: {exercise} | Placeholders: {exercise} |
| `liveNextSet` | General | بعدی: {exercise} · ست {setNumber} | Next: {exercise} · set {setNumber} | Placeholders: {exercise}, {setNumber} |
| `liveOpenWorkout` | Workout | باز کردن تمرین | Open workout | Review tone and clarity. |
| `liveSessionLabel` | History / session | تمرین در جریان | Live workout | Review tone and clarity. |
| `loadFailed` | General | داده‌ها باز نشد. | Could not open your data. | Review tone and clarity. |
| `loadingData` | General | در حال باز کردن داده‌ها | Loading your data | Review tone and clarity. |
| `logSet` | Workout | ثبت ست | Log set | Review tone and clarity. |
| `logWeight` | Workout | ثبت وزن | Log weight | Review tone and clarity. |
| `logWeightThisWeek` | Workout | وزن این هفته را ثبت کن | Log this week's weight | Review tone and clarity. |
| `loggedSets` | General | ست‌های ثبت‌شده | Logged sets | Review tone and clarity. |
| `lookupFailed` | Exercises | مرورگر باز نشد. نام حرکت را دستی جستجو کن. | Could not open a browser. Search for the exercise manually. | Review tone and clarity. |
| `lookupImages` | Exercises | جستجوی تصویر | Look up images | Review tone and clarity. |
| `moreActions` | Shared controls | گزینه‌های بیشتر | More actions | Review tone and clarity. |
| `muscleAbdominals` | Exercises | شکم | Abdominals | Review tone and clarity. |
| `muscleBack` | Exercises | پشت | Back | Review tone and clarity. |
| `muscleBiceps` | Exercises | دوسر بازو | Biceps | Review tone and clarity. |
| `muscleCalves` | Exercises | ساق | Calves | Review tone and clarity. |
| `muscleChest` | Exercises | سینه | Chest | Review tone and clarity. |
| `muscleForearms` | Exercises | ساعد | Forearms | Review tone and clarity. |
| `muscleFullBody` | Exercises | کل بدن | Full body | Review tone and clarity. |
| `muscleGlutes` | Exercises | سرینی | Glutes | Review tone and clarity. |
| `muscleGroupLabel` | Exercises | گروه عضلانی | Muscle group | Review tone and clarity. |
| `muscleGroupNone` | Exercises | هیچ‌کدام | None | Review tone and clarity. |
| `muscleHamstrings` | Exercises | همسترینگ | Hamstrings | Review tone and clarity. |
| `muscleQuadriceps` | Exercises | چهارسر ران | Quadriceps | Review tone and clarity. |
| `muscleSetsEmpty` | Exercises | برای دیدن این تقسیم‌بندی، برای حرکت‌ها گروه عضلانی انتخاب کن. | Tag exercises with a muscle group to see this split. | Review tone and clarity. |
| `muscleSetsHint` | Exercises | ست‌های کارآمد این هفته | Working sets this week | Review tone and clarity. |
| `muscleSetsTitle` | Exercises | ست‌ها به تفکیک عضله | Sets by muscle | Review tone and clarity. |
| `muscleShoulders` | Exercises | شانه | Shoulders | Review tone and clarity. |
| `muscleTriceps` | Exercises | سه‌سر بازو | Triceps | Review tone and clarity. |
| `nameLabel` | General | نام | Name | Review tone and clarity. |
| `newDayTitle` | Programs | روز جدید | New day | Review tone and clarity. |
| `newExerciseTitle` | Exercises | حرکت جدید | New exercise | Review tone and clarity. |
| `newPlanItemTitle` | Programs | ردیف جدید برنامه | New plan item | Review tone and clarity. |
| `newProgramTitle` | Programs | برنامه جدید | New program | Review tone and clarity. |
| `noActiveExercises` | Exercises | حرکت فعالی نداری. برای دیدن بایگانی‌شده‌ها، نمایش بایگانی را روشن کن. | No active exercises. Show archived to see them. | Review tone and clarity. |
| `noActiveExercisesPicker` | Exercises | حرکت فعالی نداری. یک حرکت جدید اضافه کن. | No active exercises. Add a new exercise. | Review tone and clarity. |
| `noDaysYet` | Programs | هنوز روزی نداری. یک روز اضافه کن تا برنامه شکل بگیرد. | No days yet. Add a day to plan this program. | Review tone and clarity. |
| `noExercisesAvailableForSession` | Workout | همهٔ حرکات فعال از قبل در این تمرین هستند. | All active exercises are already in this workout. | Review tone and clarity. |
| `noExercisesInSession` | Workout | هنوز حرکتی در این تمرین نیست. برای شروع، یک حرکت اضافه کن. | No exercises yet. Add one to start logging. | Review tone and clarity. |
| `noPlanItemsYet` | Programs | هنوز حرکتی به این روز اضافه نشده. | No plan items yet. | Review tone and clarity. |
| `noProgramDays` | Programs | هنوز روزی در برنامه نیست. یک تمرین خالی شروع کن و حرکت اضافه کن. | No planned days yet. Start an empty workout and add exercises. | Review tone and clarity. |
| `noSearchResults` | Exercises | حرکتی با این جستجو پیدا نشد. | No exercises match your search. | Review tone and clarity. |
| `noSessionPhotos` | History / session | هنوز عکسی برای این جلسه نیست. | No session photos yet. | Review tone and clarity. |
| `noSetsLogged` | History / session | ست ثبت‌شده‌ای نیست. | No sets logged. | Review tone and clarity. |
| `noTrainingThisWeek` | General | این هفته هنوز تمرینی ثبت نشده. | No training logged this week yet. | Review tone and clarity. |
| `notEnoughData` | History / session | داده کافی نیست | Not enough data | Review tone and clarity. |
| `noteHint` | History / session | متن ساده، حداکثر {limit} نویسه | Plain text, up to {limit} characters | Placeholders: {limit} |
| `noteTooLong` | History / session | این یادداشت بیش از حد طولانی است. | This note is too long. | Review tone and clarity. |
| `openBodyWeight` | Workout | باز کردن وزن بدن | Open body weight | Review tone and clarity. |
| `photoDeleteFailed` | Shared controls | عکس حذف نشد. دوباره تلاش کن. | Could not remove the photo. Try again. | Review tone and clarity. |
| `photoLimitReached` | General | حداکثر {max} عکس برای هر جلسه. | You can add up to {max} photos per session. | Placeholders: {max} |
| `photoLoadFailed` | General | عکس‌ها بارگذاری نشدند. | Could not load photos. | Review tone and clarity. |
| `photoMissing` | General | این عکس دیگر موجود نیست. | This photo is no longer available. | Review tone and clarity. |
| `photoNumber` | General | عکس {number} | Photo {number} | Placeholders: {number} |
| `photoPickFailed` | General | این تصویر خوانده نشد. تصویر دیگری را امتحان کن. | Could not read this image. Try another one. | Review tone and clarity. |
| `photoPrivateHint` | General | به‌صورت خصوصی روی همین دستگاه ذخیره می‌شود. | Stored privately on this device. | Review tone and clarity. |
| `photoSaveFailed` | Shared controls | عکس ذخیره نشد. دوباره تلاش کن. | Could not save the photo. Try again. | Review tone and clarity. |
| `photoStorageFull` | General | فضای کافی برای ذخیره عکس نیست. | Not enough storage to save the photo. | Review tone and clarity. |
| `photoViewerTitle` | General | عکس | Photo | Review tone and clarity. |
| `planItemNotFound` | Programs | این ردیف برنامه دیگر وجود ندارد. | This plan item no longer exists. | Review tone and clarity. |
| `planItemSummary` | Programs / workout / history | ⁦{sets} × {min}–{max}⁩ | {sets} × {min}–{max} | Placeholders: {sets}, {min}, {max} |
| `plateAssumption` | General | هالتر ۲۰ کیلوگرم و صفحه‌های استاندارد. | Standard 20 kg bar and plates. | Review tone and clarity. |
| `plateAssumptionPounds` | General | هالتر ۴۵ پوند و صفحه‌های استاندارد. | Standard 45 lb bar and plates. | Review tone and clarity. |
| `plateBarLabel` | General | هالتر {weight} | Bar {weight} | Placeholders: {weight} |
| `plateBelowBar` | General | از وزن هالتر کمتر است | Lighter than the bar | Review tone and clarity. |
| `plateCalculatorAction` | General | صفحه‌ها و گرم‌کردن | Plates and warm-up | Review tone and clarity. |
| `plateCalculatorTitle` | General | ماشین‌حساب صفحه | Plate calculator | Review tone and clarity. |
| `plateClose` | Shared controls | تمام | Done | Review tone and clarity. |
| `plateEmpty` | General | صفحه‌ای لازم نیست | No plates needed | Review tone and clarity. |
| `plateExact` | General | دقیق | Exact load | Review tone and clarity. |
| `plateInvalidWeight` | Workout | یک وزن معتبر وارد کن. | Enter a valid weight. | Review tone and clarity. |
| `plateKicker` | General | حساب صفحه | PLATE MATH | Review tone and clarity. |
| `platePerSide` | General | هر طرف | Each side | Review tone and clarity. |
| `platePerSideCount` | General | {count} در هر طرف | {count} per side | Placeholders: {count} |
| `plateRemainder` | General | {weight} مانده تا هدف | {weight} short of target | Placeholders: {weight} |
| `plateTargetLabel` | General | وزن هدف | Target weight | Review tone and clarity. |
| `plateWarmupBar` | Workout | هالتر خالی | Empty bar | Review tone and clarity. |
| `plateWarmupNoSteps` | Workout | برای این وزن، گرم‌کردن جدا لازم نیست. | No warm-up steps for this weight. | Review tone and clarity. |
| `plateWarmupTitle` | Workout | پله‌های گرم‌کردن | Warm-up ramp | Review tone and clarity. |
| `prBadge` | Workout / history | رکورد | PR | Review tone and clarity. |
| `prBadgeTooltip` | Workout / history | رکورد شخصی: {types} | Personal record: {types} | Placeholders: {types} |
| `prE1rmLabel` | Workout / history | بیشترین ۱RM برآوردی | highest estimated 1RM | Review tone and clarity. |
| `prRepsLabel` | Workout / history | بیشترین تکرار در همین وزن | most reps at this weight | Review tone and clarity. |
| `prWeightLabel` | Workout / history | سنگین‌ترین وزن | heaviest weight | Review tone and clarity. |
| `previousDataVersions` | General | نسخه‌های قبلی داده‌ها | Previous data versions | Review tone and clarity. |
| `previousWeeks` | General | هفته‌های قبل | Previous weeks | Review tone and clarity. |
| `programCardMeta` | Programs | {days} روز · {exercises} حرکت | {days} days · {exercises} exercises | Placeholders: {days}, {exercises} |
| `programDaysCount` | Programs | {count} روز | {count, plural, =1{1 day} other{{count} days}} | Placeholders: {count}; Plural |
| `programEmptyBody` | Programs | یک برنامه بساز، روزهایش را بچین و از داشبورد شروع کن. همه‌چیز روی همین گوشی می‌ماند. | Build a program, arrange its days, and start from the dashboard. Everything stays on this device. | Review tone and clarity. |
| `programExercisesCount` | Programs | {count} حرکت | {count, plural, =1{1 exercise} other{{count} exercises}} | Placeholders: {count}; Plural |
| `programNameLabel` | Programs | نام برنامه | Program name | Review tone and clarity. |
| `programNeverTrained` | History / session | هنوز اجرا نشده | Not trained yet | Review tone and clarity. |
| `programNotFound` | Programs | این برنامه دیگر وجود ندارد. | This program no longer exists. | Review tone and clarity. |
| `programSetsCount` | Programs | {count} ست | {count, plural, =1{1 set} other{{count} sets}} | Placeholders: {count}; Plural |
| `programsEmpty` | Programs | هنوز برنامه‌ای نساخته‌ای. | No programs yet. | Review tone and clarity. |
| `programsSectionTitle` | Programs | برنامه‌های تمرینی | Training programs | Review tone and clarity. |
| `programsTab` | App shell / navigation | برنامه‌ها | Programs | Review tone and clarity. |
| `progressBestE1rm` | Progress | بهترین ۱RM برآوردی | Best e1RM | Review tone and clarity. |
| `progressBestWeight` | Progress | بیشترین وزن | Best weight | Review tone and clarity. |
| `progressChartE1rmHint` | Progress | برآورد اپلی. ۱۱ تا ۱۲ تکرار کم‌دقت‌تر است. | Epley estimate. 11–12 reps are less reliable. | Review tone and clarity. |
| `progressChartE1rmTitle` | Progress | ۱RM برآوردی | Estimated 1RM | Review tone and clarity. |
| `progressChartEmptyValues` | Progress | در این بازه مقداری ثبت نشده است. | No values in this range. | Review tone and clarity. |
| `progressChartRepsTitle` | Progress | تکرار | Reps | Review tone and clarity. |
| `progressChartRirHint` | Progress | RIR ثبت‌نشده به‌صورت شکاف نمایش داده می‌شود. | Missing RIR appears as a gap. | Review tone and clarity. |
| `progressChartRirTitle` | Progress | RIR | RIR | Review tone and clarity. |
| `progressChartWeightTitle` | Progress | وزن بهترین ست | Best set weight | Review tone and clarity. |
| `progressEmpty` | Progress | برای دیدن پیشرفت، یک تمرین را تمام کن. | Finish a workout to see progress here. | Review tone and clarity. |
| `progressEstimatedLabel` | Progress | برآوردی | Estimated | Review tone and clarity. |
| `progressLastTrained` | Progress | آخرین تمرین {date} | Last trained {date} | Placeholders: {date} |
| `progressLessReliableLabel` | Progress | کم‌دقت‌تر | Less reliable | Review tone and clarity. |
| `progressNoDataForExercise` | Progress | برای دیدن پیشرفت این حرکت، آن را ثبت کن. | Log this exercise to see its progress. | Review tone and clarity. |
| `progressNoDataInRange` | Progress | در این بازه جلسه‌ای ثبت نشده است. | No sessions in this range. | Review tone and clarity. |
| `progressRangeAll` | Progress | همه | All | Review tone and clarity. |
| `progressRangeFourWeeks` | Progress | ۴ هفته | 4 weeks | Review tone and clarity. |
| `progressRangeLabel` | Progress | بازه | Range | Review tone and clarity. |
| `progressRangeOneYear` | Progress | ۱ سال | 1 year | Review tone and clarity. |
| `progressRangeTwelveWeeks` | Progress | ۱۲ هفته | 12 weeks | Review tone and clarity. |
| `progressSessions` | Progress | {count} جلسه | {count, plural, =1{1 session} other{{count} sessions}} | Placeholders: {count}; Plural |
| `progressSummaryHint` | Progress | بهترین ست و زمان کل هر حرکت | Best set and total time by exercise | Review tone and clarity. |
| `progressTab` | App shell / navigation | پیشرفت | Progress | Review tone and clarity. |
| `progressValueMissing` | Progress | داده کافی نیست | Not enough data | Review tone and clarity. |
| `progressionAddRepsReason` | Workout | ضعیف‌ترین ست دفعه قبل {reps} تکرار بود؛ هدف {target} تکرار است. | Your weakest set was {reps} reps; aim for {target} reps. | Placeholders: {reps}, {target} |
| `progressionAddWeightReason` | Workout | دفعه قبل هر {count} ست به {max} تکرار رسیدی؛ {increment} اضافه کن. | All working sets reached {max} reps last time (sets: {count}), so add {increment}. | Placeholders: {max}, {count}, {increment} |
| `progressionHoldReason` | Workout | دفعه قبل زیر {min} تکرار بودی؛ وزن را نگه دار و دوباره بساز. | Below {min} reps last time; keep the weight and rebuild. | Placeholders: {min} |
| `progressionLastSession` | Workout | دفعه قبل: {weight} × {reps} | Last time: {weight} × {reps} | Placeholders: {weight}, {reps} |
| `progressionSuggestionLabel` | Workout | پیشنهاد | Suggestion | Review tone and clarity. |
| `progressionUseLastSession` | Workout | همان دفعه قبل | Use last time | Review tone and clarity. |
| `quickStartTitle` | Workout | شروع سریع | Quick start | Review tone and clarity. |
| `recentWorkout` | Workout | تمرین اخیر | Recent workout | Review tone and clarity. |
| `removePhoto` | General | حذف عکس | Remove photo | Review tone and clarity. |
| `removePhotoBody` | General | نسخهٔ ذخیره‌شده برای همیشه حذف می‌شود. | This permanently deletes the stored copy. | Review tone and clarity. |
| `removePhotoTitle` | General | عکس حذف شود؟ | Remove photo? | Review tone and clarity. |
| `rename` | Shared controls | تغییر نام | Rename | Review tone and clarity. |
| `reorder` | Shared controls | جابه‌جایی | Reorder | Review tone and clarity. |
| `repMaxLabel` | Exercises | حداکثر تکرار | Max reps | Review tone and clarity. |
| `repMinLabel` | Exercises | حداقل تکرار | Min reps | Review tone and clarity. |
| `repRangeSummary` | Workout / history | ⁦{min}–{max}⁩ | {min}–{max} | Placeholders: {min}, {max} |
| `repsLabel` | Workout | تکرار | Reps | Review tone and clarity. |
| `restTimerBannerLabel` | Settings / backup | زمان استراحت در جریان است. | Rest timer running | Review tone and clarity. |
| `restTimerComplete` | Settings / backup | استراحت تمام شد | Rest complete | Review tone and clarity. |
| `restTimerDuration` | Settings / backup | مدت | Duration | Review tone and clarity. |
| `restTimerEnabled` | Settings / backup | بعد از هر ست شروع شود | Start after each set | Review tone and clarity. |
| `restTimerHint` | Settings / backup | داخل اپ اجرا می‌شود و پایانش را با لرزش خبر می‌دهد. | Runs in the app and vibrates when time is up. | Review tone and clarity. |
| `restTimerLabel` | Settings / backup | زمان‌سنج استراحت | Rest timer | Review tone and clarity. |
| `restTimerRunning` | Settings / backup | استراحت {remaining} | Rest {remaining} | Placeholders: {remaining} |
| `restTimerStop` | Settings / backup | توقف زمان‌سنج | Stop timer | Review tone and clarity. |
| `restoreBackupFailed` | Settings / backup | بازیابی پشتیبان ممکن نشد. | Could not restore the backup. | Review tone and clarity. |
| `restoreBackupHint` | Settings / backup | داده‌های ذخیره‌شده خوانده نشد. برای جایگزینی، یک پشتیبان JSON وارد کن؛ قبلش یک نسخه از فایل دادهٔ ناخوانا (نه عکس‌ها) نگه داشته می‌شود. | Your saved data could not be read. Import a JSON backup to replace it; a snapshot of the unreadable data file (not photos) is kept first. | Review tone and clarity. |
| `restoreFromBackup` | Settings / backup | بازیابی از پشتیبان | Restore from backup | Review tone and clarity. |
| `restoreSnapshotBody` | General | همهٔ داده‌های فعلی با این نسخه از فایل داده جایگزین می‌شوند. نخست از داده‌های فعلی یک نسخهٔ دیگر ذخیره می‌شود. | Replaces all current data with this data-file snapshot. The current data is saved as another snapshot first. | Review tone and clarity. |
| `restoreSnapshotPhotosWarning` | General | عکس‌ها در این نسخه نیستند. عکس‌های مربوط به حرکت‌هایی که دیگر وجود ندارند برای همیشه حذف می‌شوند. | Photos are not in this snapshot. Photos whose workout no longer exists are deleted permanently. | Review tone and clarity. |
| `restoreSnapshotTitle` | General | این نسخه از داده‌ها بازگردانی شود؟ | Restore this data version? | Review tone and clarity. |
| `retry` | Shared controls | تلاش دوباره | Retry | Review tone and clarity. |
| `rirDescription` | Workout | {value} تکرار در ذخیره | {value, plural, =0{No reps in reserve} =1{1 rep in reserve} other{{value} reps in reserve}} | Placeholders: {value}; Plural |
| `rirFivePlus` | Workout | ۵+ | 5+ | Review tone and clarity. |
| `rirFivePlusDescription` | Workout | ۵+ تکرار در ذخیره | 5+ reps in reserve | Review tone and clarity. |
| `rirHintShort` | Workout | تکرارهای باقی‌مانده تا ناتوانی | Reps left before failure | Review tone and clarity. |
| `rirInfoButton` | Workout | دربارهٔ RIR | About RIR | Review tone and clarity. |
| `rirInfoClose` | Workout | فهمیدم | Got it | Review tone and clarity. |
| `rirInfoDefinition` | Workout | RIR یعنی چند تکرار دیگر می‌توانستی بزنی تا به ناتوانی برسی. مثلاً RIR ۲ یعنی هنوز دو تکرار تمیز در ذخیره داشتی. | RIR means Reps In Reserve: how many good reps you could still complete before failure. | Review tone and clarity. |
| `rirInfoFourFive` | Workout | ۴ تا ۵+ — از ناتوانی دوری؛ مناسب گرم‌کردن یا تمرین فرم. | 4–5+ — far from failure; useful for technique work or warm-ups. | Review tone and clarity. |
| `rirInfoOne` | Workout | ۱ — یک تکرار دیگر می‌توانستی بزنی. | 1 — one good rep left. | Review tone and clarity. |
| `rirInfoScaleTitle` | Workout | راهنمای مقیاس | Reading the scale | Review tone and clarity. |
| `rirInfoTip` | Workout | در بیشتر ست‌های کارآمد ۱ تا ۳ تکرار در ذخیره نگه دار تا کیفیت بالا بماند و خستگی الکی جمع نشود. | Keep 1–3 reps in reserve on most working sets to train productively without unnecessary fatigue. | Review tone and clarity. |
| `rirInfoTitle` | Workout | RIR چیست؟ | What is RIR? | Review tone and clarity. |
| `rirInfoTwoThree` | Workout | ۲ تا ۳ — محدودهٔ رایج ست‌های کارآمد؛ سخت، ولی با فرم تمیز. | 2–3 — typical working sets: hard, but technique stays clean. | Review tone and clarity. |
| `rirInfoZero` | Workout | ۰ — هیچ تکرار دیگری در ذخیره نمانده؛ به ناتوانی رسیده‌ای. | 0 — no reps left; you reached failure. | Review tone and clarity. |
| `rirLabel` | Workout | RIR | RIR | Review tone and clarity. |
| `rirSummary` | Workout | RIR {rir} | RIR {rir} | Placeholders: {rir} |
| `save` | Shared controls | ذخیره | Save | Review tone and clarity. |
| `saveAnyway` | Shared controls | ذخیره کن | Save anyway | Review tone and clarity. |
| `saveFailed` | Shared controls | ذخیره نشد. دوباره تلاش کن. | Could not save. Try again. | Review tone and clarity. |
| `searchExercisesHint` | Exercises | جستجوی حرکت‌ها | Search exercises | Review tone and clarity. |
| `searchTermHint` | Exercises | برای جستجوی تصویر استفاده می‌شود؛ اگر خالی باشد، نام حرکت به کار می‌رود. | Used for image lookup. Falls back to the name. | Review tone and clarity. |
| `searchTermLabel` | Exercises | عبارت جستجو | Search term | Review tone and clarity. |
| `sessionDeleted` | History / session | جلسه حذف شد. | Session deleted. | Review tone and clarity. |
| `sessionDetailTitle` | History / session | جزئیات جلسه | Session | Review tone and clarity. |
| `sessionNotFound` | History / session | این جلسه دیگر وجود ندارد. | This session no longer exists. | Review tone and clarity. |
| `sessionNoteLabel` | History / session | یادداشت جلسه | Session note | Review tone and clarity. |
| `sessionPhotoCount` | History / session | {count} از {max} | {count} of {max} | Placeholders: {count}, {max} |
| `sessionPhotosLabel` | History / session | عکس‌های جلسه | Session photos | Review tone and clarity. |
| `sessionSummaryTitle` | History / session | خلاصهٔ جلسه | Session summary | Review tone and clarity. |
| `sessionTime` | History / session | زمان جلسه | Session time | Review tone and clarity. |
| `sessionsTitle` | History / session | جلسات | Sessions | Review tone and clarity. |
| `setActions` | History / session | کارهای ست | Set actions | Review tone and clarity. |
| `setDeleted` | History / session | ست حذف شد. | Set deleted. | Review tone and clarity. |
| `setNumber` | Workout | ست {number} | Set {number} | Placeholders: {number} |
| `setProgress` | Progress | {done} از {target} ست | {done} of {target} sets | Placeholders: {done}, {target} |
| `setSaved` | Workout | ثبت شد | Saved | Review tone and clarity. |
| `setsLabel` | General | {count} ست | {count, plural, =0{No sets} =1{1 set} other{{count} sets}} | Placeholders: {count}; Plural |
| `setsPerMuscle` | Exercises | ست | Sets | Review tone and clarity. |
| `setsStatLabel` | General | ست‌ها | Sets | Review tone and clarity. |
| `settingsAppearanceSection` | General | زبان و نمایش | Language and display | Review tone and clarity. |
| `settingsDataSection` | General | داده و پشتیبان | Data and backup | Review tone and clarity. |
| `settingsGoalRow` | General | هدف هفتگی | Weekly goal | Review tone and clarity. |
| `settingsGoalValue` | General | {sessions} جلسه · {sets} ست | {sessions, plural, =1{1 session} other{{sessions} sessions}} · {sets, plural, =1{1 set} other{{sets} sets}} | Placeholders: {sessions}, {sets}; Plural |
| `settingsNoGoal` | General | تعیین نشده | Not set | Review tone and clarity. |
| `settingsTitle` | App shell / navigation | تنظیمات | Settings | Review tone and clarity. |
| `settingsTrainingSection` | General | تمرین و تجهیزات | Training and equipment | Review tone and clarity. |
| `showAll` | General | همه | Show all | Review tone and clarity. |
| `showArchived` | Exercises | نمایش بایگانی | Show archived | Review tone and clarity. |
| `showLess` | General | کمتر | Show less | Review tone and clarity. |
| `sinceLastCheckIn` | General | از آخرین ثبت | since last check-in | Review tone and clarity. |
| `startEmptyWorkout` | Workout | تمرین خالی | Start empty workout | Review tone and clarity. |
| `startTodayWorkout` | Workout | تمرین امروز را شروع کن | Start today's workout | Review tone and clarity. |
| `startWorkoutTitle` | Workout | شروع تمرین | Start a workout | Review tone and clarity. |
| `summaryBackHome` | General | بازگشت به خانه | Back to home | Review tone and clarity. |
| `summaryBreakdownTitle` | General | جزئیات حرکت‌ها | Exercise breakdown | Review tone and clarity. |
| `summaryDurationLabel` | General | مدت | Duration | Review tone and clarity. |
| `summaryExercisesLabel` | Exercises | حرکت‌ها | Exercises | Review tone and clarity. |
| `summaryHeadline` | General | تمرین تمام شد. | Workout complete. | Review tone and clarity. |
| `summaryKicker` | General | جلسه بسته شد | Session closed | Review tone and clarity. |
| `summaryNewPr` | General | رکورد جدید | New record | Review tone and clarity. |
| `summaryNoPrevious` | General | جلسهٔ قبلی برای مقایسه نیست. | No previous session to compare. | Review tone and clarity. |
| `summaryNoRecords` | General | امروز رکورد جدیدی ثبت نشد؛ کار انجام‌شده سر جایش است. | No new records today. The work still counts. | Review tone and clarity. |
| `summaryPrCountLabel` | General | {count} رکورد جدید | {count, plural, =1{1 new record} other{{count} new records}} | Placeholders: {count}; Plural |
| `summaryPrSetCount` | General | {count} ست رکورد | {count, plural, =1{1 PR set} other{{count} PR sets}} | Placeholders: {count}; Plural |
| `summaryRecordCount` | General | {count} رکورد | {count} records | Placeholders: {count} |
| `summaryRecordsTitle` | General | رکوردهای امروز | Today’s records | Review tone and clarity. |
| `summarySetLine` | General | {sets} ست · {volume} | {sets} sets · {volume} | Placeholders: {sets}, {volume} |
| `summaryStreak` | General | هفتهٔ {week} | Week {week} | Placeholders: {week} |
| `summaryViewSession` | History / session | دیدن جلسه | View session | Review tone and clarity. |
| `summaryVolumeDelta` | General | {change} نسبت به جلسهٔ قبل | {change} vs last session | Placeholders: {change} |
| `summaryVolumeLabel` | General | حجم | Volume | Review tone and clarity. |
| `summaryVsLast` | General | نسبت به جلسه قبل | vs last session | Review tone and clarity. |
| `summaryWorkingSetsLabel` | General | ست کارآمد | Working sets | Review tone and clarity. |
| `takePhoto` | General | گرفتن عکس | Take photo | Review tone and clarity. |
| `targetSetsLabel` | Programs | تعداد ست | Target sets | Review tone and clarity. |
| `thisMonth` | General | این ماه | This month | Review tone and clarity. |
| `thisWeek` | General | این هفته | This week | Review tone and clarity. |
| `timeLabel` | General | زمان | Time | Review tone and clarity. |
| `totalTime` | General | زمان کل | Total time | Review tone and clarity. |
| `trainingTotals` | General | مجموع تمرین | Training totals | Review tone and clarity. |
| `unarchive` | Exercises | بازگردانی | Restore | Review tone and clarity. |
| `unassignedMuscle` | Exercises | بدون گروه | Unassigned | Review tone and clarity. |
| `undo` | History / session | واگرد | Undo | Review tone and clarity. |
| `unitKilograms` | Settings / backup | کیلوگرم | kg | Review tone and clarity. |
| `unitPounds` | Settings / backup | پوند | lb | Review tone and clarity. |
| `updateWeightThisWeek` | Workout | وزن این هفته را به‌روز کن | Update this week's weight | Review tone and clarity. |
| `viewAll` | General | همه | View all | Review tone and clarity. |
| `viewWeeklySummary` | General | خلاصه هفته | Weekly summary | Review tone and clarity. |
| `volumeLabel` | General | حجم | Volume | Review tone and clarity. |
| `warmupLabel` | Workout | گرم‌کردن | Warm-up | Review tone and clarity. |
| `warmupSets` | Workout | گرم‌کردن | Warm-ups | Review tone and clarity. |
| `weekRange` | General | {start} – {end} | {start} – {end} | Placeholders: {start}, {end} |
| `weeklyAverage` | General | میانگین هفتگی | Weekly average | Review tone and clarity. |
| `weeklySummaryEmpty` | General | برای دیدن خلاصهٔ هفته، یک تمرین را تمام کن. | Finish a workout to see your weekly summary. | Review tone and clarity. |
| `weeklySummarySubtitle` | General | حجم، زمان و ست‌ها، هفته به هفته | Volume, time, and sets by week | Review tone and clarity. |
| `weeklySummaryTitle` | General | خلاصهٔ هفته | Weekly summary | Review tone and clarity. |
| `weightChangeSummary` | Workout | {change} {unit} از آخرین ثبت | {change} {unit} since last check-in | Placeholders: {change}, {unit} |
| `weightLabel` | Workout | وزن | Weight | Review tone and clarity. |
| `weightTrend` | Workout | روند وزن | Weight trend | Review tone and clarity. |
| `weightUnitLabel` | Settings / backup | واحد وزن | Weight unit | Review tone and clarity. |
| `workingSets` | General | ست‌های کارآمد | Working sets | Review tone and clarity. |
| `workoutDoneCat` | Workout | تمرین تموم شد! | Workout done! | Review tone and clarity. |
| `workoutDoneCatHint` | Workout | میو! حالا وقت استراحت و کششه. | Meow! Time to rest and stretch. | Review tone and clarity. |
| `workoutEmpty` | Workout | تمرین فعالی وجود ندارد. | No active workout. | Review tone and clarity. |
| `workoutTab` | App shell / navigation | تمرین | Workout | Review tone and clarity. |
| `workoutsLabel` | Workout | {count} جلسه | {count, plural, =0{No workouts} =1{1 workout} other{{count} workouts}} | Placeholders: {count}; Plural |
| `workoutsStatLabel` | Workout | جلسه‌ها | Workouts | Review tone and clarity. |
