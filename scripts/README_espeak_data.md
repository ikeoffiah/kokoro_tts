# Obtaining espeak-ng-data for flutter_kokoro_tts

The phonemizer needs the compiled espeak-ng data files (`phontab`, `phonindex`, `phondata`, `intonations`, `config`, and language files) in a directory named **espeak-ng-data**.

## Option 1: Build from the plugin’s third_party tree

From the **package root** (directory containing `pubspec.yaml`):

1. Install build deps for espeak-ng (e.g. autoconf, automake, libtool, or use CMake).
2. Build espeak-ng so it produces the data files:

   ```bash
   cd third_party/espeak-ng
   # If using autotools (older releases):
   ./autogen.sh && ./configure && make
   # Or with CMake:
   mkdir build && cd build && cmake .. && make
   ```

3. After a successful build, `espeak-ng-data/` will contain `phontab`, `phonindex`, `phondata`, etc.
4. Copy that **entire** `espeak-ng-data` directory to a place your app can use:
   - **Default:** next to the Kokoro model dir, i.e. under app documents `.../kokoro/espeak-ng-data/`.
   - Or pass that path as `espeakDataPath` when calling `KokoroTts.initialize(espeakDataPath: '/path/to/parent/of/espeak-ng-data')`.

To ship the data with the app, add `espeak-ng-data` as an asset or native resource, then at runtime copy it to the app documents dir (or a temp dir) and pass that parent path as `espeakDataPath`.

## Option 3: Use a system or prebuilt install

If you have espeak-ng installed (e.g. `/usr/share/espeak-ng-data` on Linux), you can pass that parent path:

- Parent of data dir: `KokoroTts.initialize(espeakDataPath: '/usr/share')` (espeak looks for `.../espeak-ng-data`).
- Or the data dir itself: `KokoroTts.initialize(espeakDataPath: '/usr/share/espeak-ng-data')`.

On iOS/Android there is no system install, so run `./scripts/build_espeak_data.sh` or build from Option 1 and copy the data.
