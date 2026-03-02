import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'model_manager.dart';
import 'phonemizer.dart';
import 'text_cleaner.dart';
import 'text_preprocessor.dart';

const List<String> kokoroVoices = [
  'Default', // af.bin
  'Bella', // af_bella.bin
  'Nicole', // af_nicole.bin
  'Sarah', // af_sarah.bin
  'Adam', // am_adam.bin
  'Michael', // am_michael.bin
];

/// Map of voice names to their corresponding file names
const Map<String, String> _kokoroVoiceMap = {
  'Default': 'af.bin',
  'Bella': 'af_bella.bin',
  'Nicole': 'af_nicole.bin',
  'Sarah': 'af_sarah.bin',
  'Adam': 'am_adam.bin',
  'Michael': 'am_michael.bin',
};

const Map<String, double> _speedPriors = {
  'af.bin': 0.8,
  'af_bella.bin': 0.8,
  'af_nicole.bin': 0.8,
  'af_sarah.bin': 0.8,
  'am_adam.bin': 0.8,
  'am_michael.bin': 0.8,
};

class KokoroTts {
  final KokoroModelManager _modelManager = KokoroModelManager();
  final Phonemizer _phonemizer = Phonemizer();
  final TextCleaner _textCleaner = TextCleaner();
  final TextPreprocessor _textPreprocessor = TextPreprocessor();
  static const int _maxTokens = 500;

  OrtSession? _session;
  bool _isInitialized = false;

  /// Output sample rate (always 24 000 Hz)
  int sampleRate = 24000;

  /// Name of available voices.
  List<String> get availableVoices => List.unmodifiable(kokoroVoices);

  /// Voice cache
  final Map<String, Float32List> _voiceCache = {};

  /// Intialize the Kokoro TTS engine.
  Future<void> initialize({
    void Function(double progress, String status)? onProgress,
  }) async {
    if (_isInitialized) return;

    onProgress?.call(0.0, 'Downloading model...');

    // 1. Download the model + voices + espeak data
    await _modelManager.download(
      onProgress: (p, status) {
        onProgress?.call(p, status);
      },
    );

    // 2. Initialize the phonemizer
    _phonemizer.initialize(dataPath: _modelManager.modelDir);

    // 3. Load ONNX session

    onProgress?.call(0.97, 'Loading ONNX session...');
    final ort = OnnxRuntime();
    final session = await ort.createSession(_modelManager.modelPath);
    debugPrint('[kokoroTTS]: session inputs ${session.inputNames}');
    debugPrint('[kokoroTTS]: session outputs ${session.outputNames}');

    _isInitialized = true;
    onProgress?.call(1.0, 'Ready');
  }

  Future<Float32List> _getVoice(String voice) async {
    if (_voiceCache.containsKey(voice)) {
      return _voiceCache[voice]!;
    }

    final path = '${_modelManager.modelDir}/voices/${_kokoroVoiceMap[voice]!}';

    final bytes = await File(path).readAsBytes();
    final embedding = bytes.buffer.asFloat32List();

    _voiceCache[voice] = embedding;
    return embedding;
  }

  Future<Float32List> generate(
    String text, {
    String voice = 'Default',
    double speed = 1.0,
  }) async {
    if (!_isInitialized) throw Exception('Kokoro TTS not initialized');

    final chunks = _splitIntoChunks(text);
    final parts = <Float32List>[];

    for (final chunk in chunks) {
      final audio = await _generateChunk(chunk, voice: voice, speed: speed);
      if (audio.isNotEmpty) parts.add(audio);
    }

    if (parts.isEmpty) return Float32List(0);
    if (parts.length == 1) return parts.first;

    final total = parts.fold<int>(0, (sum, part) => sum + part.length);
    final result = Float32List(total);
    var offset = 0;
    for (final part in parts) {
      result.setRange(offset, offset + part.length, part);
      offset += part.length;
    }
    return result;
  }

  Future<Float32List> _generateChunk(
    String chunk, {
    required String voice,
    required double speed,
  }) async {
    // --Text Cleaning & Preprocessing--
    final cleanText = _textPreprocessor.process(chunk);
    final cleanTextWithPunctuation = _addTrailingPunctuation(cleanText.trim());
    debugPrint('[kokoroTTS]: clean text: $cleanTextWithPunctuation');

    // --Phonemization--
    final phonemes = _phonemizer.phonemize(cleanTextWithPunctuation);
    debugPrint('[kokoroTTS]: phonemes: $phonemes');

    // --Encoding--
    final encodedTokens = _textCleaner.encodeAndWrap(phonemes);
    debugPrint('[kokoroTTS]: encoded: $encodedTokens');

    // -- Guard: split if tokens exceed model capacity --
    if (encodedTokens.length > _maxTokens) {
      debugPrint(
        '[kokoroTTS]: splitting chunk into multiple parts due to token limit',
      );
      final mid = encodedTokens.length ~/ 2;
      int splitAt = chunk.indexOf(RegExp(r'[.!?,;:\s]'), mid);
      if (splitAt < 0 || splitAt == chunk.length - 1) splitAt = mid;
      final firstHalf = chunk.substring(0, splitAt);
      final secondHalf = chunk.substring(splitAt);
      debugPrint('[kokoroTTS]: first half: $firstHalf');
      debugPrint('[kokoroTTS]: second half: $secondHalf');

      final parts = <Float32List>[];
      if (firstHalf.isNotEmpty) {
        parts.add(await _generateChunk(firstHalf, voice: voice, speed: speed));
      }
      if (secondHalf.isNotEmpty) {
        parts.add(await _generateChunk(secondHalf, voice: voice, speed: speed));
      }

      if (parts.isEmpty) return Float32List(0);
      if (parts.length == 1) return parts.first;

      final total = parts.fold<int>(0, (sum, part) => sum + part.length);
      final result = Float32List(total);
      var offset = 0;
      for (final part in parts) {
        result.setRange(offset, offset + part.length, part);
        offset += part.length;
      }
      return result;
    }

    // -- Voice---
    final style = await _getVoice(voice);
    debugPrint('[kokoroTTS]: style embedding: ${style.length}');

    // -- Speed Adjustment --
    final speedFactor = _speedPriors[voice]!;
    debugPrint('[kokoroTTS]: speed factor: $speedFactor');

    final effectiveSpeed = speed * speedFactor;

    // - ONNX inference --
    final inputIds = await OrtValue.fromList(
      Int64List.fromList(encodedTokens),
      [1, encodedTokens.length],
    );

    final styleTensor = await OrtValue.fromList(style, [1, style.length]);

    final speedTensor = await OrtValue.fromList([effectiveSpeed], [1]);

    final outputs = await _session!.run({
      'input_ids': inputIds,
      'style': styleTensor,
      'speed': speedTensor,
    });

    // Dispose inputs
    await inputIds.dispose();
    await styleTensor.dispose();
    await speedTensor.dispose();

    // Find the audio output tensor (largest)

    OrtValue? audioOut;
    int audioLen = 0;
    for (final entry in outputs.entries) {
      final len = entry.value.shape.fold<int>(1, (a, b) => a * b);
      if (len > audioLen) {
        audioOut = entry.value;
        audioLen = len;
      }
    }

    if (audioOut == null) {
      return Float32List(0);
    }

    final rawList = await audioOut.asFlattenedList();

    // Dispose all output tensors
    for (final v in outputs.values) {
      await v.dispose();
    }

    Float32List audio;

    if (rawList is List<double>) {
      audio = Float32List.fromList(rawList.cast<double>());
    } else {
      audio = Float32List.fromList(
        rawList.map((e) => (e as num).toDouble()).toList(),
      );
    }

    // Trim trailing silence
    if (audio.length > 5000) {
      audio = Float32List.sublistView(audio, 0, audio.length - 5000);
    }

    debugPrint(
      '[kokoroTTS]: audio length: ${audio.length}, samples: ${audio.length ~/ 2}',
    );

    return audio;
  }

  // ── Helpers ──

  List<String> _splitIntoChunks(String text, {int maxLen = 200}) {
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    final chunks = <String>[];
    final buf = StringBuffer();

    for (final s in sentences) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) continue;
      if (buf.length + trimmed.length + 1 > maxLen && buf.isNotEmpty) {
        chunks.add(_addTrailingPunctuation(buf.toString().trim()));
        buf.clear();
      }
      if (buf.isNotEmpty) buf.write(' ');
      buf.write(trimmed);
    }
    if (buf.isNotEmpty) {
      chunks.add(_addTrailingPunctuation(buf.toString().trim()));
    }
    return chunks.isEmpty ? [_addTrailingPunctuation(text.trim())] : chunks;
  }

  static String _addTrailingPunctuation(String t) {
    t = t.trim();
    if (t.isEmpty) return t;
    return '.!?,;:'.contains(t[t.length - 1]) ? t : '$t,';
  }

  // static String _trunc(String s, [int n = 60]) =>
  //     s.length <= n ? s : '${s.substring(0, n)}…';

  Future<void> dispose() async {}
}
