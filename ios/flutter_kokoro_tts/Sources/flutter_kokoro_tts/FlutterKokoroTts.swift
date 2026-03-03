import Flutter
import UIKit

@_silgen_name("flutter_kokoro_tts_force_link_espeak")
func flutterKokoroTtsForceLink()

public class FlutterKokoroTtsPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // Force linker to retain espeak-ng C symbols for Dart FFI
    flutterKokoroTtsForceLink()

    let channel = FlutterMethodChannel(
      name: "flutter_kokoro_tts_flutter",
      binaryMessenger: registrar.messenger()
    )
    let instance = FlutterKokoroTtsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
