import 'dart:io';

/// Fails when signing material appears in the working tree (`DAT-005`,
/// `NFR-PRV-001`). The repository and its history must never contain a
/// keystore, a base64 keystore, `key.properties`, or a literal signing
/// password. This is a backstop; the real control is that keys live outside
/// the repository and only enter CI through secrets.
void main() {
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
  };
  final RegExp privateKey = RegExp(
    r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
  );
  final RegExp literalGradlePassword = RegExp(
    r'(?:storePassword|keyPassword)\s*=\s*"[^"]+"',
  );

  final List<String> findings = <String>[];
  for (final FileSystemEntity entity in Directory.current.listSync(
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
        name.endsWith('.jks.b64') ||
        name.endsWith('.keystore.b64')) {
      findings.add('forbidden signing file: $path');
      continue;
    }
    if (name.endsWith('.dart') ||
        name.endsWith('.kts') ||
        name.endsWith('.gradle') ||
        name.endsWith('.properties') ||
        name.endsWith('.sh') ||
        name.endsWith('.md') ||
        name.endsWith('.yaml') ||
        name.endsWith('.yml')) {
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
    }
  }

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
    'Signing-material guard passed: no keystore or private key in the tree.',
  );
}
