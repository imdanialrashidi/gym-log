/// Persian/Latin search normalization shared by exercise search.
///
/// D15 (`EXR-003`, `L10N-008`): searches are case-insensitive, Arabic yeh
/// (U+064A) equals Persian yeh (U+06CC), Arabic kaf (U+0643) equals Persian
/// keheh (U+06A9), and ZWNJ (U+200C) is ignored. Whitespace runs collapse so a
/// query with extra spaces still matches.
library;

const String _arabicYeh = '\u064A';
const String _persianYeh = '\u06CC';
const String _arabicKaf = '\u0643';
const String _persianKeheh = '\u06A9';
const String _zwnj = '\u200C';

/// Returns the comparison form used for every exercise search.
String normalizeForSearch(String input) {
  return input
      .toLowerCase()
      .replaceAll(_arabicYeh, _persianYeh)
      .replaceAll(_arabicKaf, _persianKeheh)
      .replaceAll(_zwnj, '')
      .replaceAll(RegExp(r'[\s\u00A0]+'), ' ')
      .trim();
}

/// True when [text] contains [query] after normalization.
///
/// An empty query matches every text, which is the unfiltered picker state.
bool matchesSearchQuery(String text, String query) {
  final String normalizedQuery = normalizeForSearch(query);
  if (normalizedQuery.isEmpty) {
    return true;
  }
  return normalizeForSearch(text).contains(normalizedQuery);
}
