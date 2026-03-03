import Flutter
import UIKit

@_silgen_name("flutter_kokoro_tts_force_link_espeak")
func flutterKokoroTtsForceLink()

public class FlutterKokoroTtsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Force linker to retain espeak-ng C symbols for Dart FFI
    flutterKokoroTtsForceLink()
  }
}
