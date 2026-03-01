import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef _EspeakIntializeC =
    Int32 Function(
      Int32 output,
      Int32 buflength,
      Pointer<Char> path,
      Int32 options,
    );

typedef _EspeakInitializeDart =
    int Function(int output, int buflength, String path, int options);

typedef _EspeakSetVoiceByNameC = Int32 Function(Pointer<Char> name);

typedef _EspeakSetVoiceByNameDart = int Function(String name);

typedef _EspeakTextToPhonemesC =
    Pointer<Utf8> Function(
      Pointer<Pointer<Void>> textptr,
      Int32 textmode,
      Int32 phonememode,
    );

typedef _EspeakTextToPhonemesDart =
    String Function(
      Pointer<Pointer<Void>> textptr,
      int textmode,
      int phonememode,
    );

typedef _EspeakTerminateC = Int32 Function();

typedef _EspeakTerminateDart = int Function();

/// Low-level FFI wrapper around the espeak-ng C library.
class EspeakFfi {
  DynamicLibrary? _lib;
  _EspeakInitializeDart? _espeakInitialize;
  _EspeakSetVoiceByNameDart? _espeakSetVoiceByName;
  _EspeakTextToPhonemesDart? _espeakTextToPhonemes;
  _EspeakTerminateDart? _espeakTerminate;

  bool _loaded = false;
  bool _ready = false;
  bool get isReady => _ready;

  void load() {
    if (_loaded) return;
    if (Platform.isIOS || Platform.isMacOS) {
      _lib = DynamicLibrary.process();
    } else if (Platform.isAndroid) {
      _lib = DynamicLibrary.open('libespeak-ng.so');
    } else if (Platform.isLinux) {
      _lib = DynamicLibrary.open('libespeak-ng.so');
    } else if (Platform.isWindows) {
      _lib = DynamicLibrary.open('espeak-ng.dll');
    } else {
      throw UnsupportedError(
        'Unsupported platform: ${Platform.operatingSystem}',
      );
    }
  }
}
