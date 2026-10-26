abstract final class AppRoutes {
  static const String about = '/about';
  static const String exercises = '/exercises';
  static const String exercisePicker = '/exercise-picker';
  static const String bodyWeight = '/body-weight';
  static const String weeklySummary = '/weekly-summary';

  static String exerciseEditor(String exerciseId) =>
      '/exercise-editor/$exerciseId';

  static String programEditor(String programId) => '/program-editor/$programId';

  static String dayEditor(String programId, String dayId) =>
      '/day-editor/$programId/$dayId';

  static String planItemEditor(String dayId, String itemId) =>
      '/plan-item-editor/$dayId/$itemId';

  static String session(String sessionId) => '/session/$sessionId';

  static String sessionSummary(String sessionId) =>
      '/session-summary/$sessionId';

  static String exerciseProgress(String exerciseId) => '/progress/$exerciseId';
}
