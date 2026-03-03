package dev.piusikeoffiah.flutter_kokoro_tts

import io.flutter.embedding.engine.plugins.FlutterPlugin

/** Registers the Kokoro TTS plugin. Native espeak-ng is loaded by Dart FFI via libespeak-ng.so. */
class FlutterKokoroTtsPlugin : FlutterPlugin {
    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // No method channel needed; Dart FFI loads libespeak-ng.so when Phonemizer is used.
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
