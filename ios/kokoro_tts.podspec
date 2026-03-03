Pod::Spec.new do |s|
    s.name             = 'flutter_kokoro_tts'
    s.version          = '0.0.4'
    s.summary          = 'KokoroTTS - Offline text-to-speech for Flutter.'
    s.description      = <<-DESC
  High-quality offline text-to-speech using the KokoroML ONNX model with espeak-ng phonemization.
                         DESC
    s.homepage         = 'https://github.com/ikeoffiah/kokoro_tts'
    s.license          = { :file => '../LICENSE' }
    s.author           = { 'KokoroTTS' => 'dev@example.com' }
    s.source           = { :path => '.' }
  
    espeak_dir = 'flutter_kokoro_tts/Sources/espeak_ng'
  
    s.source_files = [
      'flutter_kokoro_tts/Sources/flutter_kokoro_tts/**/*.swift',
      "#{espeak_dir}/**/*.c",
      "#{espeak_dir}/**/*.h",
    ]
  
    # Only expose the bridge header to avoid duplicate header conflicts
    s.public_header_files = ["#{espeak_dir}/include/espeak_bridge.h"]
  
    s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
      'HEADER_SEARCH_PATHS' => [
        "$(PODS_TARGET_SRCROOT)/#{espeak_dir}/include",
        "$(PODS_TARGET_SRCROOT)/#{espeak_dir}/include/espeak-ng",
        "$(PODS_TARGET_SRCROOT)/#{espeak_dir}",
        "$(PODS_TARGET_SRCROOT)/#{espeak_dir}/ucd-include",
        "$(PODS_TARGET_SRCROOT)/#{espeak_dir}/include/ucd",
      ].join(' '),
      'GCC_PREPROCESSOR_DEFINITIONS' => [
        'HAVE_STDINT_H=1',
        'HAVE_MKSTEMP=1',
        'USE_ASYNC=0',
        'USE_KLATT=1',
        'USE_LIBPCAUDIO=0',
        'USE_LIBSONIC=0',
        'USE_MBROLA=0',
        'USE_SPEECHPLAYER=0',
        'PACKAGE_VERSION=\"1.52.0\"',
      ].join(' '),
      'OTHER_CFLAGS' => "-w -include $(PODS_TARGET_SRCROOT)/#{espeak_dir}/config.h",
    }
  
    s.dependency 'Flutter'
    s.platform = :ios, '16.0'
    s.swift_version = '5.0'
  end
  