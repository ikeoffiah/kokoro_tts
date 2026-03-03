import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kokoro_tts/src/text_preprocessor.dart';

void main() {
  late TextPreprocessor preprocessor;

  setUp(() {
    preprocessor = TextPreprocessor();
  });

  group('TextPreprocessor', () {
    test('empty string returns empty', () {
      expect(preprocessor.process(''), '');
    });

    test('normalizes whitespace', () {
      expect(preprocessor.process('  hello   world  '), 'hello world');
      expect(preprocessor.process('a\nb\tc'), 'a b c');
    });

    test('converts to lowercase', () {
      expect(preprocessor.process('HELLO'), 'hello');
    });

    test('removes URLs', () {
      expect(
        preprocessor.process('Visit https://example.com and http://test.org'),
        isNot(contains('https://')),
      );
      expect(
        preprocessor.process('Go to www.foo.com'),
        isNot(contains('www.')),
      );
    });

    test('expands contractions', () {
      expect(preprocessor.process("can't"), contains('cannot'));
      expect(preprocessor.process("won't"), contains('will not'));
      expect(preprocessor.process("it's"), contains('it is'));
    });

    test('expands leading decimal point', () {
      final result = preprocessor.process('.5');
      expect(result, contains('zero'));
      expect(result, contains('point'));
    });

    test('expands currency', () {
      final result = preprocessor.process('\$10');
      expect(result, contains('dollar'));
      expect(result, contains('ten'));
    });

    test('expands percentages', () {
      final result = preprocessor.process('50%');
      expect(result, contains('percent'));
      expect(result, contains('fifty'));
    });

    test('expands time', () {
      final result = preprocessor.process('3:30 pm');
      expect(result.toLowerCase(), contains('three'));
      expect(result.toLowerCase(), contains('thirty'));
    });

    test('expands ordinals', () {
      expect(preprocessor.process('1st'), contains('first'));
      expect(preprocessor.process('2nd'), contains('second'));
      expect(preprocessor.process('3rd'), contains('third'));
      expect(preprocessor.process('4th'), contains('fourth'));
    });

    test('expands units', () {
      final result = preprocessor.process('5 km');
      expect(result, contains('kilometers'));
      expect(result, contains('five'));
    });

    test('expands fractions', () {
      final result = preprocessor.process('1/2');
      expect(result, contains('half'));
      expect(result, contains('one'));
    });

    test('expands phone number pattern', () {
      final result = preprocessor.process('555-123-4567');
      expect(result, isNotEmpty);
      expect(result, isNot(contains('555-123-4567')));
    });

    test('expands ranges', () {
      final result = preprocessor.process('1-5');
      expect(result, contains('to'));
      expect(result, contains('one'));
      expect(result, contains('five'));
    });

    test('expands model names (e.g. GPT-3)', () {
      final result = preprocessor.process('GPT-3');
      expect(result.toLowerCase(), contains('gpt'));
      expect(result, contains('three'));
    });

    test('replaces standalone numbers with words', () {
      expect(preprocessor.process('0'), 'zero');
      expect(preprocessor.process('42'), contains('forty-two'));
      expect(preprocessor.process('100'), contains('hundred'));
    });

    test('handles mixed content', () {
      final result = preprocessor.process('Hello world 123.');
      expect(result, contains('hello'));
      expect(result, contains('world'));
      // 123 is expanded to words
      expect(result, isNot(contains('123')));
    });

    test('same input gives same output', () {
      const input = 'hello world';
      expect(preprocessor.process(input), preprocessor.process(input));
    });
  });
}
