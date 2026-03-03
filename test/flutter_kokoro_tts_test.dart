import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kokoro_tts/flutter_kokoro_tts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KokoroTts', () {
    test('exposes availableVoices and sampleRate', () {
      final tts = KokoroTts();
      expect(tts.availableVoices, isNotEmpty);
      expect(tts.availableVoices, contains('Default'));
      expect(tts.sampleRate, 24000);
    });

    test('availableVoices matches exported kokoroVoices', () {
      final tts = KokoroTts();
      expect(tts.availableVoices, equals(kokoroVoices));
    });

    test('availableVoices are unique and non-empty', () {
      final tts = KokoroTts();
      expect(tts.availableVoices.toSet().length, tts.availableVoices.length);
      for (final voice in tts.availableVoices) {
        expect(voice.isNotEmpty, isTrue);
      }
    });

    test('generate with empty string returns empty audio without initializing', () async {
      final tts = KokoroTts();
      final audio = await tts.generate('');
      expect(audio, isEmpty);
    });

    test('generate with whitespace-only string returns empty audio', () async {
      final tts = KokoroTts();
      final audio = await tts.generate('   \n\t  ');
      expect(audio, isEmpty);
    });

    test('dispose does not throw when not initialized', () async {
      final tts = KokoroTts();
      await expectLater(tts.dispose(), completes);
    });

    test('dispose does not throw when called twice', () async {
      final tts = KokoroTts();
      await tts.dispose();
      await expectLater(tts.dispose(), completes);
    });

    test('all expected default voices are present', () {
      final tts = KokoroTts();
      const expected = ['Default', 'Bella', 'Nicole', 'Sarah', 'Adam', 'Michael'];
      for (final name in expected) {
        expect(tts.availableVoices, contains(name));
      }
    });

    // Requires model download; run with: flutter test --run-skipped
    test('generate with invalid voice throws Exception with "Invalid voice"', () async {
      final tts = KokoroTts();
      await expectLater(
        tts.generate('hello', voice: 'NonExistentVoice'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid voice'),
        )),
      );
    }, skip: 'Integration: requires network and model download');
  });
}
