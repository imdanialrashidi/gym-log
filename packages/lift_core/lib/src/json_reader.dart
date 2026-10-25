/// Typed readers for the versioned on-device JSON document.
///
/// Values come from an app-private file, but a truncated or tampered file is
/// still untrusted input; readers throw instead of silently fabricating data.
library;

String readString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }
  throw FormatException('"$key" must be a non-empty string');
}

String? readOptionalString(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw FormatException('"$key" must be a string or null');
}

bool readBool(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is bool) {
    return value;
  }
  throw FormatException('"$key" must be a boolean');
}

int readInt(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is int) {
    return value;
  }
  throw FormatException('"$key" must be an integer');
}

int? readOptionalInt(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  throw FormatException('"$key" must be an integer or null');
}

DateTime readDateTime(Map<String, Object?> json, String key) {
  final String value = readString(json, key);
  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('"$key" must be an ISO-8601 timestamp');
  }
  return parsed.toUtc();
}

DateTime? readOptionalDateTime(Map<String, Object?> json, String key) {
  final String? value = readOptionalString(json, key);
  if (value == null) {
    return null;
  }
  final DateTime? parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('"$key" must be an ISO-8601 timestamp or null');
  }
  return parsed.toUtc();
}

List<Object?> readList(Map<String, Object?> json, String key) {
  final Object? value = json[key];
  if (value is List) {
    return value.cast<Object?>();
  }
  throw FormatException('"$key" must be a list');
}

Map<String, Object?> readMap(Object? value, String key) {
  if (value is Map) {
    return value.cast<String, Object?>();
  }
  throw FormatException('"$key" must be an object');
}
