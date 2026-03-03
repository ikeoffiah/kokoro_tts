# flutter_kokoro_tts

A Flutter plugin for **Kokoro TTS** (text-to-speech) using ONNX Runtime and espeak-ng. Generates high-quality speech from text with multiple voices, runs fully on-device (no cloud API required).

## Features

- **On-device inference** — ONNX model runs locally; no internet after initial model download
- **Multiple voices** — Default, Bella, Nicole, Sarah, Adam, Michael
- **Configurable speed** — Adjust speech rate per call
- **24 kHz output** — Mono PCM at 24,000 Hz (Float32)
- **Android & iOS** — Plugin supports both platforms (espeak-ng linked per platform)

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_kokoro_tts: ^0.0.1
```

Then run:

```bash
flutter pub get
```

### Requirements

- **Flutter** — SDK 3.10+
- **Android** — minSdk 21+ (plugin uses NDK/CMake for native code). Install **CMake** and **NDK** via Android Studio → SDK Manager → SDK Tools if you see a CMake-not-found error.
- **iOS** — iOS 11.0+

On first use, the plugin downloads the Kokoro ONNX model and voice files from Hugging Face (~50 MB). Ensure the app has network and storage permissions as needed.

**espeak-ng data** — Phonemization requires the espeak-ng data files (e.g. `phontab`, `phonindex`, `phondata`) in a directory named `espeak-ng-data`. By default the plugin looks for `.../kokoro/espeak-ng-data` next to the model. You must either (1) build from the package’s `third_party/espeak-ng` (run `make` or CMake, then copy the generated `espeak-ng-data` folder to your app’s kokoro dir or bundle it and pass `espeakDataPath`), or (2) pass a custom path via `initialize(espeakDataPath: ...)`. Run `./scripts/build_espeak_data.sh` (Docker or cmake) to generate **assets/espeak_ng_data.zip**, or pass `espeakDataPath`. See [scripts/README_espeak_data.md](scripts/README_espeak_data.md).

## Usage

```dart
import 'package:flutter_kokoro_tts/flutter_kokoro_tts.dart';

final tts = KokoroTts();

// Optional: initialize early with progress callback (e.g. for a loading UI)
// Pass espeakDataPath if your espeak-ng-data is not in the default kokoro dir.
await tts.initialize(
  onProgress: (progress, status) => print('$status ${(progress * 100).round()}%'),
  espeakDataPath: null,  // or path to dir containing espeak-ng-data
);

// Generate audio (initializes automatically if needed)
final audio = await tts.generate(
  'Hello, this is Kokoro speaking.',
  voice: 'Bella',  // or Default, Nicole, Sarah, Adam, Michael
  speed: 1.0,
);

// audio is Float32List at tts.sampleRate (24000) Hz, mono.
// Play via your preferred audio backend (e.g. write as WAV and use audioplayers).
print('Generated ${audio.length} samples');

// When done
await tts.dispose();
```

### API summary

| Member | Description |
|--------|-------------|
| `availableVoices` | List of voice names (e.g. `Default`, `Bella`, `Nicole`, `Sarah`, `Adam`, `Michael`) |
| `sampleRate` | Output sample rate (24000) |
| `initialize({onProgress, espeakDataPath})` | Downloads model/voices if needed; optional path to espeak-ng-data dir |
| `generate(text, {voice, speed})` | Returns `Future<Float32List>` PCM mono at 24 kHz |
| `dispose()` | Closes ONNX session and releases native resources |

Empty or whitespace-only text returns an empty `Float32List` without initializing. Invalid `voice` throws an `Exception`.

## Example

See the [example/](example/) app for a minimal UI: text input, voice picker, generate + play using `audioplayers` and a small WAV writer.

```bash
cd example && flutter run
```

## Platform notes

- **Android** — Native espeak-ng and ONNX are built via CMake/NDK. No extra setup.
- **iOS** — Plugin force-links espeak-ng so that Dart FFI can resolve symbols when using the dynamic library. Run on simulator or device to verify.

## License

MIT. See [LICENSE](LICENSE).
