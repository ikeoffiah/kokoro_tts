# flutter_kokoro_tts

A Flutter plugin for **Kokoro TTS** (text-to-speech) using ONNX Runtime and espeak-ng. Generates high-quality speech from text with multiple voices, runs fully on-device (no cloud API required).

## Features

- **On-device inference** — ONNX model runs locally; no internet after initial model download
- **Multiple voices** — Default, Bella, Nicole, Sarah, Adam, Michael
- **Configurable speed** — Adjust speech rate per call (e.g. 0.5–2.0)
- **24 kHz output** — Mono PCM at 24,000 Hz (Float32)
- **Android & iOS** — Plugin supports both platforms (espeak-ng linked per platform)

---

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

**espeak-ng data** — Phonemization requires the espeak-ng data files. By default the plugin extracts them from the bundled asset; see [scripts/README_espeak_data.md](scripts/README_espeak_data.md) if you need a custom path or to build the data yourself.

---

## Step-by-step usage

### Step 1: Add the dependency and import

```yaml
# pubspec.yaml
dependencies:
  flutter_kokoro_tts: ^0.0.1
```

```dart
import 'package:flutter_kokoro_tts/flutter_kokoro_tts.dart';
```

### Step 2: Create an instance

```dart
final tts = KokoroTts();
```

### Step 3: Initialize (optional but recommended)

Initialize early (e.g. when your app or screen loads) so the first speech is faster. The plugin will download the model and voices if needed.

```dart
await tts.initialize(
  onProgress: (progress, status) {
    // progress: 0.0 to 1.0
    // status: e.g. 'Downloading model...', 'Generating...', 'Ready'
    print('$status ${(progress * 100).round()}%');
  },
  espeakDataPath: null,  // or path to dir containing espeak-ng-data
);
```

If you skip this, `generate()` will initialize automatically on first use.

### Step 4: Generate speech

```dart
final audio = await tts.generate(
  'Hello, this is Kokoro speaking.',
  voice: 'Bella',   // see "Changing voice" below
  speed: 1.0,       // see "Adjusting speed" below
);
// audio is Float32List, mono, 24 kHz (tts.sampleRate)
```

### Step 5: Play or save the audio

The plugin returns raw PCM (Float32, -1.0 to 1.0). Convert to WAV (or another format) and play with your preferred player, e.g. `audioplayers`:

```dart
// Example: write WAV and play with audioplayers
final wavBytes = buildWavBytes(audio, tts.sampleRate);
final file = File('${(await getTemporaryDirectory()).path}/speech.wav');
await file.writeAsBytes(wavBytes);
await audioPlayer.play(DeviceFileSource(file.path));
```

See the [example/](example/) app for a full WAV-building and playback example.

### Step 6: Dispose when done

```dart
await tts.dispose();
```

Call this when you no longer need TTS (e.g. when leaving the screen or closing the app) to release the ONNX session and native resources.

---

## All features and options

### Changing voice

Use the `voice` parameter in `generate()`. Available voices:

| Voice   | Description |
|--------|-------------|
| `Default` | Default voice |
| `Bella`   | Female |
| `Nicole`  | Female |
| `Sarah`   | Female |
| `Adam`    | Male |
| `Michael` | Male |

Get the list programmatically:

```dart
final voices = tts.availableVoices;  // ['Default', 'Bella', 'Nicole', 'Sarah', 'Adam', 'Michael']

final audio = await tts.generate(
  'Hello world',
  voice: 'Nicole',
  speed: 1.0,
);
```

### Adjusting speed

Use the `speed` parameter in `generate()`. Values are relative (1.0 = normal).

- **Slower:** `0.5` – `0.9`
- **Normal:** `1.0`
- **Faster:** `1.1` – `2.0` (or higher)

```dart
final audio = await tts.generate(
  'Speaking slowly.',
  voice: 'Default',
  speed: 0.7,
);

final fastAudio = await tts.generate(
  'Speaking quickly.',
  voice: 'Default',
  speed: 1.5,
);
```

### Initialize options

| Parameter          | Type     | Description |
|--------------------|----------|-------------|
| `onProgress`       | `void Function(double progress, String status)?` | Called during download/init; use for a progress bar or status text. |
| `espeakDataPath`   | `String?` | Directory containing `espeak-ng-data`, or `null` to use the default (extracted from package asset). |

```dart
await tts.initialize(
  onProgress: (progress, status) => updateUI(progress, status),
  espeakDataPath: '/custom/path/to/espeak-ng-data',  // optional
);
```

### Generate options

| Parameter | Type     | Default   | Description |
|-----------|----------|-----------|-------------|
| `text`    | `String` | —         | Text to speak. Empty or whitespace returns empty audio. |
| `voice`   | `String` | `'Default'` | One of `availableVoices`. |
| `speed`   | `double` | `1.0`     | Playback speed (e.g. 0.5–2.0). |

### Other API

| Member            | Description |
|-------------------|-------------|
| `availableVoices` | List of voice names. |
| `sampleRate`      | Output sample rate (24000). |
| `dispose()`       | Releases ONNX session and native resources. |

Empty or whitespace-only text returns an empty `Float32List` without initializing. An invalid `voice` throws an `Exception`.

---

## Example

See the [example/](example/) app for a minimal UI: text input, voice picker, generate + play using `audioplayers` and a small WAV writer.

```bash
cd example && flutter run
```

## Platform notes

- **Android** — Native espeak-ng and ONNX are built via CMake/NDK. Install CMake and NDK from SDK Manager if needed.
- **iOS** — Plugin force-links espeak-ng for Dart FFI. Run on simulator or device to verify.

## License

MIT. See [LICENSE](LICENSE).
