# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-03-02

### Added

- Initial release of `flutter_kokoro_tts`.
- Kokoro TTS pipeline: text preprocessing, phonemization (espeak-ng), ONNX inference.
- Model and voice download from Hugging Face with SHA256 verification.
- Six voices: Default, Bella, Nicole, Sarah, Adam, Michael.
- Configurable speed and chunked generation for long text.
- Android and iOS plugin registration (FFI-based; no method channel).
- Dart API: `KokoroTts`, `initialize()`, `generate()`, `dispose()`, `availableVoices`, `sampleRate`, `kokoroVoices` export.
