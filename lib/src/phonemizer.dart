import 'espeak_ffi.dart';

/// Convert English text to IPA phonemes using espeak-ng via DArt FFI.

class Phonemizer {
  final EspeakFfi _espeak = EspeakFfi();

  bool get isInitialized => _espeak.isReady;

  // Initialize espeak-ng. [dataPath] is the directory containing the espeak-ng-data directory
  void initialize({required String dataPath}) {
    _espeak.load();
    _espeak.init(dataPath: dataPath);
  }

  // Convert text to IPA phonemes
  String phonemize(String text) {
    if (!isInitialized) throw Exception('Espeak-ng not initialized');

    return _espeak.phonemize(text);
  }

  // Dispose of espeak-ng
  void dispose() {
    _espeak.dispose();
  }
}
