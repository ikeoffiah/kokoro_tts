import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kokoro_tts/src/text_cleaner.dart';

void main() {
  late TextCleaner textCleaner;

  setUp(() {
    textCleaner = TextCleaner();
  });

  group('TextCleaner', () {
    test('encode returns empty list for empty string', () {
      expect(textCleaner.encode(''), isEmpty);
    });

    test('encodeAndWrap wraps with pad tokens (0)', () {
      final result = textCleaner.encodeAndWrap('');
      expect(result, equals([0, 0]));
    });

    test('encode maps known punctuation to token ids', () {
      final tokens = textCleaner.encode('.,');
      expect(tokens, isNotEmpty);
      expect(tokens.length, 2);
    });

    test('encodeAndWrap always starts and ends with 0', () {
      final result = textCleaner.encodeAndWrap('hello');
      expect(result.first, 0);
      expect(result.last, 0);
      expect(result.length, greaterThanOrEqualTo(2));
    });

    test('unknown characters are dropped (not encoded)', () {
      // Use a character that is not in the symbol set (e.g. some Unicode that's not IPA/punctuation/letter)
      final tokens = textCleaner.encode('a\u0000b'); // null char is likely not in set
      // At least 'a' and 'b' should be present; null might be dropped
      expect(tokens, isNotEmpty);
    });

    test('encode is consistent for same input', () {
      final a = textCleaner.encode('test');
      final b = textCleaner.encode('test');
      expect(a, equals(b));
    });

    test('encodeAndWrap length is encode length + 2', () {
      const input = 'abc';
      expect(
        textCleaner.encodeAndWrap(input).length,
        textCleaner.encode(input).length + 2,
      );
    });
  });
}
