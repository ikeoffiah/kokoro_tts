# flutter_kokoro_tts example

This example demonstrates the `flutter_kokoro_tts` plugin:

1. Enter text and choose a voice.
2. Tap **Generate** to synthesize speech (the model and voices are downloaded on first run).
3. Tap **Play** to hear the generated audio.

Requires a device or simulator; the plugin uses native code (ONNX, espeak-ng) and is not supported on web.

```bash
cd example
flutter run
```
