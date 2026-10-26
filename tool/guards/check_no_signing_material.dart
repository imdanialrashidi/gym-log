import 'dart:io';

/// Fails when signing material appears in the working tree (`DAT-005`,
/// `NFR-PRV-001`). The repository and its history must never contain a
/// keystore, a base64 keystore, a private key, a signing properties file, or a
/// literal signing password. This is a backstop; the real control is that keys
/// live outside the repository and only enter CI through secrets.
void main() {
  final List<String> findings = scanForSigningMaterial(Directory.current);
  if (findings.isNotEmpty) {
    stderr.writeln('Signing-material guard failed:');
    for (final String finding in findings) {
      stderr.writeln('  - $finding');
    }
    stderr.writeln(
      'Signing keys and passwords must never enter the repository, logs, '
      'prompts, or artifacts.',
    );
    exitCode = 1;
    return;
  }
  stdout.writeln(
    'Signing-material guard passed: no keystore, private key, or signing '
    'password in the tree.',
  );
}

/// Returns path-only findings for [root]. Never include a matched value, so a
/// real secret cannot leak through the guard's own output.
List<String> scanForSigningMaterial(Directory root) {
  const Set<String> skippedDirectories = <String>{
    '.git',
    '.dart_tool',
    '.artifacts',
    '.gradle',
    'build',
    'node_modules',
  };
  const Set<String> forbiddenExtensions = <String>{
    '.jks',
    '.keystore',
    '.p12',
    '.pfx',
    '.pem',
    '.key',
    '.p8',
    '.b64',
  };
  const Set<String> passwordFileExtensions = <String>{
    '.properties',
    '.env',
    '.sh',
    '.pem',
    '.key',
    '.b64',
  };
  final RegExp privateKey = RegExp(
    r'-----BEGIN (?:RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----',
  );
  final RegExp literalGradlePassword = RegExp(
    r'(?:storePassword|keyPassword)\s*[=:]\s*"[^"]+"',
  );
  // A bare assignment with a real value. Documentation placeholders that start
  // with `$`, `${`, or `<` are intentionally allowed.
  final RegExp literalUnquotedPassword = RegExp(
    r'(?:storePassword|keyPassword|GYM_LOG_KEYSTORE_PASSWORD|'
    r'GYM_LOG_KEY_PASSWORD)\s*[=:]\s*(?![\s$<])\S+',
  );

  final List<String> findings = <String>[];
  if (!root.existsSync()) {
    return <String>['required scan root is missing: ${root.path}'];
  }
  for (final FileSystemEntity entity in root.listSync(
    recursive: true,
    followLinks: false,
  )) {
    final String path = entity.path;
    if (path.split(Platform.pathSeparator).any(skippedDirectories.contains)) {
      continue;
    }
    if (entity is! File) {
      continue;
    }
    final String name = entity.uri.pathSegments.last;
    if (forbiddenExtensions.any(name.endsWith) ||
        name == 'key.properties' ||
        name == 'signing.properties' ||
        name == 'keystore.properties' ||
        name.startsWith('release-keystore')) {
      findings.add('forbidden signing file: $path');
      continue;
    }
    final bool readForSecrets =
        name.endsWith('.dart') ||
        name.endsWith('.kts') ||
        name.endsWith('.gradle') ||
        name.endsWith('.properties') ||
        name.endsWith('.env') ||
        name.endsWith('.sh') ||
        name.endsWith('.pem') ||
        name.endsWith('.key') ||
        name.endsWith('.b64') ||
        name.endsWith('.md') ||
        name.endsWith('.yaml') ||
        name.endsWith('.yml');
    if (!readForSecrets) {
      continue;
    }
    String contents;
    try {
      contents = entity.readAsStringSync();
    } on FileSystemException {
      continue;
    }
    if (privateKey.hasMatch(contents)) {
      findings.add('private key block: $path');
    }
    if (name.endsWith('.kts') ||
        name.endsWith('.gradle') ||
        name.endsWith('.properties')) {
      if (literalGradlePassword.hasMatch(contents)) {
        findings.add('literal signing password: $path');
      }
    }
    if (passwordFileExtensions.any(name.endsWith)) {
      if (literalUnquotedPassword.hasMatch(contents)) {
        findings.add('literal signing password: $path');
      }
    }
  }
  return findings;
}
