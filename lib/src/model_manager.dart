import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class KokoroModelManager {
  static const _hfBase =
      'https://huggingface.co/onnx-community/Kokoro-82M-ONNX/resolve/main';
  static const _modelDirName = 'Kokoro-82M-ONNX';
  static const _readyMarker = '.ready';

  String? _modelDir;

  String get modelDir => _modelDir ?? '';
  String get modelPath => p.join(modelDir, 'model_quantized.onnx');

  Future<bool> isReady() async {
    final dir = await _getModelDir();
    return File(p.join(dir.path, _readyMarker)).existsSync();
  }

  Future<void> download({
    void Function(double progress, String status)? onProgress,
  }) async {
    final dir = await _getModelDir();
    _modelDir = dir.path;
    final marker = File(p.join(dir.path, _readyMarker));
    if (marker.existsSync()) {
      onProgress?.call(1.0, 'Ready');
      return;
    }

    // Download ONNX Model
    await _downloadFile(
      url: '$_hfBase/model_quantized.onnx',
      destination: p.join(dir.path, 'model_quantized.onnx'),
      onProgress: (p) => onProgress?.call(p * 0.6, 'Downloading model...'),
    );

    // Download Voices
    final voices = [
      'af.bin',
      'af_bella.bin',
      'af_nicole.bin',
      'af_sarah.bin',
      'am_adam.bin',
      'am_michael.bin',
    ];

    final voiceDir = Directory(p.join(dir.path, 'voices'));
    if (!voiceDir.existsSync()) await voiceDir.create(recursive: true);

    for (int i = 0; i < voices.length; i++) {
      final voice = voices[i];
      await _downloadFile(
        url: '$_hfBase/voices/$voice',
        destination: p.join(voiceDir.path, voice),
        onProgress: (p) {
          final overall = 0.6 + ((i + p) / voices.length) * 0.4;
          onProgress?.call(overall, 'Downloading voice $voice...');
        },
      );
    }

    await marker.create();
    onProgress?.call(1.0, 'Ready');
  }

Future<void> _downloadFile({
  required String url,
  required String destination,
  required void Function(double progress)? onProgress,
}) async {
  final file = File(destination);
  if (file.existsSync()) return;

  final tempPath = '$destination.part';
  final tempFile = File(tempPath);

  final client = http.Client();

  try {
    final response = await client.send(
      http.Request('GET', Uri.parse(url)),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final total = response.contentLength ?? 0;
    final sink = tempFile.openWrite();

    var received = 0;

    await for (final chunk in response.stream) {
      sink.add(chunk);
      received += chunk.length;

      if (total > 0) {
        onProgress?.call(received / total);
      }
    }

    await sink.close();

    // Optional integrity check
    if (total > 0 && received != total) {
      throw Exception('Incomplete download');
    }

    // Atomic rename
    await tempFile.rename(destination);

  } catch (e) {
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
    rethrow;
  } finally {
    client.close();
  }
}

  Future<Directory> _getModelDir() async {
    if (_modelDir != null) return Directory(_modelDir!);

    final appDir = await getApplicationDocumentsDirectory();
    final modelPath = p.join(appDir.path, 'kokoro', _modelDirName);
    final dir = Directory(modelPath);
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }
}
