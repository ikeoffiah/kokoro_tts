# Test coverage – flutter_kokoro_tts

This document describes what is tested and how to run tests across the Flutter package, Android plugin, and iOS plugin.

## Running tests

### Flutter (Dart) unit tests

From the package root:

```bash
flutter test
```

Runs all tests under `test/*_test.dart`.

### Android unit tests

From an app that depends on this plugin (e.g. example app), or from the plugin’s `android` directory:

```bash
cd android && ./gradlew testDebugUnitTest
```

### iOS

The iOS plugin does not define a separate unit test target. The Swift plugin is exercised when:

- The host app runs on a simulator or device and registers the plugin.
- Dart code calls into native code via FFI (espeak-ng symbols are force-linked by the plugin).

For full end-to-end coverage on iOS, run the **example app** (if present) and perform a smoke test (e.g. initialize TTS and generate a short utterance).

---

## What is covered

### 1. Flutter package (`test/`)

| Area | File | What is tested |
|------|------|----------------|
| **KokoroTts** | `flutter_kokoro_tts_test.dart` | `availableVoices`, `sampleRate`, `kokoroVoices` export; empty/whitespace input returns empty audio; `dispose()` (single and double) does not throw; all expected default voices present. |
| **TextCleaner** | `text_cleaner_test.dart` | `encode` / `encodeAndWrap`: empty input, pad tokens, known symbols, unknown chars dropped, consistency. |
| **TextPreprocessor** | `text_preprocessor_test.dart` | `process`: empty string, whitespace normalization, lowercase, URL removal, contractions, decimals, currency, percentages, time, ordinals, units, fractions, phone numbers, ranges, model names, number-to-words, mixed content. |
| **IntegrityVerifier** | `integrity_verifier_test.dart` | File not found throws; hash mismatch throws and deletes file; matching hash (empty file and “hello”) succeeds. |

Not covered by unit tests (require native/network):

- `KokoroTts.initialize()` and `generate()` with real text (needs model download and ONNX/espeak).
- `KokoroModelManager.download()` and `isReady()` (need HTTP and file I/O).
- `Phonemizer` / espeak-ng (need native lib).
- Invalid voice in `generate()` (would run `initialize()` first).

These are best covered by **integration tests** or a manual run of an example app.

### 2. Android plugin

| Area | File | What is tested |
|------|------|----------------|
| **FlutterKokoroTtsPlugin** | `FlutterKokoroTtsPluginTest.kt` | Plugin instantiates and implements `FlutterPlugin`. |

Full lifecycle (onAttachedToEngine / onDetachedFromEngine) can be covered by adding a mock `FlutterPluginBinding` and calling attach/detach in tests, or by running the app and using the plugin.

### 3. iOS plugin

| Area | What is tested |
|------|----------------|
| **FlutterKokoroTtsPlugin** | No dedicated unit test target. Relies on app integration: plugin registration and FFI usage when Dart loads espeak-ng from the process. |

---

## Summary

- **Flutter:** Unit tests cover public and internal Dart behavior (TTS API surface, text cleaning, preprocessing, integrity verification). No native or network.
- **Android:** Unit test ensures the plugin class exists and conforms to `FlutterPlugin`.
- **iOS:** Covered by integration (running an app that uses the plugin and TTS).
- **End-to-end:** Use an example app to run full init → generate → dispose on Android and iOS.
