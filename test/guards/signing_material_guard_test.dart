import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/guards/check_no_signing_material.dart';

Directory _tempTree() {
  final Directory directory = Directory.systemTemp.createTempSync(
    'gym_log_signing_guard_',
  );
  addTearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  return directory;
}

void _write(Directory root, String relativePath, String contents) {
  final File file = File(
    '${root.path}${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}

void main() {
  test('a clean tree has no findings', () {
    final Directory root = _tempTree();
    _write(root, 'README.md', 'No keys here.\n');
    _write(root, 'lib/main.dart', 'void main() {}\n');

    expect(scanForSigningMaterial(root), isEmpty);
  });

  test('an unquoted password in signing.properties is a finding', () {
    final Directory root = _tempTree();
    _write(root, 'android/signing.properties', 'storePassword=hunter2\n');

    final List<String> findings = scanForSigningMaterial(root);

    expect(findings, hasLength(1));
    expect(findings.single, contains('signing.properties'));
    expect(findings.single, isNot(contains('hunter2')));
  });

  test('a release.b64 key file is a finding', () {
    final Directory root = _tempTree();
    _write(root, 'release.b64', 'ZmFrZQ==\n');

    expect(scanForSigningMaterial(root), hasLength(1));
  });

  test('a private-key PEM block is a finding by path only', () {
    final Directory root = _tempTree();
    // Split so the guard does not flag its own test fixture source.
    const String begin =
        '-----BEGIN RSA '
        'PRIVATE KEY-----';
    const String end =
        '-----END RSA '
        'PRIVATE KEY-----';
    _write(root, 'keys/id_rsa.pem', '$begin\nfake\n$end\n');

    final List<String> findings = scanForSigningMaterial(root);

    expect(findings, hasLength(1));
    expect(findings.single, contains('id_rsa.pem'));
  });

  test('documentation placeholders are not findings', () {
    final Directory root = _tempTree();
    _write(
      root,
      'docs/RELEASE.md',
      'export GYM_LOG_KEYSTORE_PASSWORD=<from password manager>\n'
          'export GYM_LOG_KEY_PASSWORD="<from password manager>"\n'
          'Key path: \${GYM_LOG_KEYSTORE_PATH}\n',
    );

    expect(scanForSigningMaterial(root), isEmpty);
  });

  test('a missing root fails closed', () {
    final Directory root = _tempTree();
    final Directory missing = Directory('${root.path}/missing');

    expect(scanForSigningMaterial(missing), hasLength(1));
  });
}
