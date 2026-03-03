import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_kokoro_tts/flutter_kokoro_tts.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kokoro TTS Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TtsExamplePage(),
    );
  }
}

class TtsExamplePage extends StatefulWidget {
  const TtsExamplePage({super.key});

  @override
  State<TtsExamplePage> createState() => _TtsExamplePageState();
}

class _TtsExamplePageState extends State<TtsExamplePage> {
  final KokoroTts _tts = KokoroTts();
  final TextEditingController _textController = TextEditingController(
    text: 'Hello! This app uses Kokoro text to speech.',
  );
  final AudioPlayer _player = AudioPlayer();

  String? _selectedVoice = 'Default';
  bool _isGenerating = false;
  String? _status;
  double _progress = 0;
  Float32List? _audio;
  String?
  _wavPath; // Pre-written .wav so Play works on iOS (BytesSource not reliable there)
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    _player.dispose();
    unawaited(_tts.dispose());
    super.dispose();
  }

  Future<void> _generate() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _error = 'Enter some text';
        _audio = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _audio = null;
      _wavPath = null;
      _isGenerating = true;
      _status = 'Initializing...';
      _progress = 0;
    });

    try {
      await _tts.initialize(
        onProgress: (p, status) {
          if (mounted) {
            setState(() {
              _progress = p;
              _status = status;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _status = 'Generating...');

      final audio = await _tts.generate(
        text,
        voice: _selectedVoice ?? 'Default',
        speed: 1.0,
      );

      if (!mounted) return;
      final wavBytes = _buildWavBytes(audio, _tts.sampleRate);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/kokoro_example.wav';
      await File(path).writeAsBytes(wavBytes);
      if (!mounted) return;
      setState(() {
        _audio = audio;
        _wavPath = path;
        _isGenerating = false;
        _status = null;
        _progress = 0;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isGenerating = false;
        _status = null;
      });
      debugPrint('Generate error: $e\n$st');
    }
  }

  Future<void> _play() async {
    final path = _wavPath;
    if (path == null || path.isEmpty) return;

    try {
      await _player.play(DeviceFileSource(path));
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Play failed: $e');
      }
    }
  }

  /// Build WAV bytes and pre-write to file so Play works on iOS (file with .wav extension).
  static Uint8List _buildWavBytes(Float32List samples, int sampleRate) {
    final numSamples = samples.length;
    final dataLen = numSamples * 2;
    const headerLen = 44;
    final total = headerLen + dataLen;
    final out = Uint8List(total);
    var offset = 0;

    void add(List<int> bytes) {
      for (var i = 0; i < bytes.length; i++) {
        out[offset++] = bytes[i];
      }
    }

    add('RIFF'.codeUnits);
    add(_uint32ToBytes(headerLen - 8 + dataLen));
    add('WAVE'.codeUnits);
    add('fmt '.codeUnits);
    add(_uint32ToBytes(16));
    add(_uint16ToBytes(1));
    add(_uint16ToBytes(1));
    add(_uint32ToBytes(sampleRate));
    add(_uint32ToBytes(sampleRate * 2));
    add(_uint16ToBytes(2));
    add(_uint16ToBytes(16));
    add('data'.codeUnits);
    add(_uint32ToBytes(dataLen));

    for (var i = 0; i < numSamples; i++) {
      var s = samples[i];
      if (s > 1) s = 1;
      if (s < -1) s = -1;
      final int16 = (s * 32767).round();
      add(_int16ToBytes(int16));
    }
    return out;
  }

  static List<int> _uint32ToBytes(int v) => [
    v & 0xff,
    (v >> 8) & 0xff,
    (v >> 16) & 0xff,
    (v >> 24) & 0xff,
  ];
  static List<int> _uint16ToBytes(int v) => [v & 0xff, (v >> 8) & 0xff];
  static List<int> _int16ToBytes(int v) => [v & 0xff, (v >> 8) & 0xff];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kokoro TTS Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Text to speak',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedVoice,
              decoration: const InputDecoration(
                labelText: 'Voice',
                border: OutlineInputBorder(),
              ),
              items: _tts.availableVoices
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: _isGenerating
                  ? null
                  : (v) => setState(() => _selectedVoice = v),
            ),
            const SizedBox(height: 24),
            if (_status != null) ...[
              Text(_status!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 16),
            ],
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                FilledButton(
                  onPressed: _isGenerating ? null : _generate,
                  child: Text(_isGenerating ? 'Generating…' : 'Generate'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed:
                      (_wavPath != null &&
                          _audio != null &&
                          _audio!.isNotEmpty &&
                          !_isGenerating)
                      ? _play
                      : null,
                  child: const Text('Play'),
                ),
              ],
            ),
            if (_audio != null && _audio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Generated ${_audio!.length} samples (${_tts.sampleRate} Hz)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
