import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kokoro_tts/src/integrity_verifier.dart';

void main() {
  group('IntegrityVerifier', () {
    test('throws when file does not exist', () async {
      final path =
          '${Directory.systemTemp.path}/flutter_kokoro_tts_nonexistent_${DateTime.now().millisecondsSinceEpoch}';
      expect(
        () => IntegrityVerifier.verify(path: path, expectedSha256: 'abc'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('File not found'),
          ),
        ),
      );
    });

    test('throws and deletes file on hash mismatch', () async {
      final dir = await Directory.systemTemp.createTemp('flutter_kokoro_tts_');
      final file = File('${dir.path}/bad.txt');
      await file.writeAsString('content');
      final path = file.path;

      await expectLater(
        IntegrityVerifier.verify(
          path: path,
          expectedSha256:
              '0000000000000000000000000000000000000000000000000000000000000000',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('SHA256 mismatch'),
          ),
        ),
      );

      expect(await file.exists(), isFalse);
      await dir.delete(recursive: true);
    });

    test('succeeds when hash matches', () async {
      // SHA256 of empty file
      const emptyFileSha256 =
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';
      final dir = await Directory.systemTemp.createTemp('flutter_kokoro_tts_');
      final file = File('${dir.path}/empty.txt');
      await file.writeAsBytes([]);
      final path = file.path;

      await expectLater(
        IntegrityVerifier.verify(path: path, expectedSha256: emptyFileSha256),
        completes,
      );

      expect(await file.exists(), isTrue);
      await dir.delete(recursive: true);
    });

    test('succeeds for non-empty file with correct hash', () async {
      // SHA256 of "hello" (UTF-8)
      const helloSha256 =
          '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
      final dir = await Directory.systemTemp.createTemp('flutter_kokoro_tts_');
      final file = File('${dir.path}/hello.txt');
      await file.writeAsString('hello');
      final path = file.path;

      await expectLater(
        IntegrityVerifier.verify(path: path, expectedSha256: helloSha256),
        completes,
      );

      expect(await file.exists(), isTrue);
      await dir.delete(recursive: true);
    });
  });
}
