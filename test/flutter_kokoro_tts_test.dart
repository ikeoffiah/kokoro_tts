import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_kokoro_tts/flutter_kokoro_tts.dart';

void main() {
  test('KokoroTts exposes availableVoices and sampleRate', () {
    final tts = KokoroTts();
    expect(tts.availableVoices, isNotEmpty);
    expect(tts.availableVoices, contains('Default'));
    expect(tts.sampleRate, 24000);
  });

  test('kokoroVoices is exported and matches availableVoices', () {
    final tts = KokoroTts();
    expect(tts.availableVoices, equals(kokoroVoices));
  });
}
