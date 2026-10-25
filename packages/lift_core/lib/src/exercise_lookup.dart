/// External image-search hand-off for an exercise (`EXR-004`, scenario A8).
///
/// The app has no network permission; the operating system opens this URL in
/// an external browser. The query is always URL-encoded by [Uri].
library;

/// Google image search endpoint.
const String exerciseLookupHost = 'www.google.com';
const String exerciseLookupPath = '/search';

/// Builds the image-search URL for [name], preferring a non-empty
/// [searchTerm].
///
/// Throws [ArgumentError] when both values are empty; the UI only enables the
/// lookup action while a term exists.
Uri buildExerciseLookupUri({required String name, String? searchTerm}) {
  final String trimmedTerm = searchTerm?.trim() ?? '';
  final String query = trimmedTerm.isNotEmpty ? trimmedTerm : name.trim();
  if (query.isEmpty) {
    throw ArgumentError.value(
      name,
      'name',
      'A name or search term is required',
    );
  }
  return Uri.https(exerciseLookupHost, exerciseLookupPath, <String, String>{
    'tbm': 'isch',
    'q': query,
  });
}
