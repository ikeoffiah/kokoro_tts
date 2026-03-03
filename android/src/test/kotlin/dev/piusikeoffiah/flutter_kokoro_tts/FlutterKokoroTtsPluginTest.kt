package dev.piusikeoffiah.flutter_kokoro_tts

import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlin.test.Test
import kotlin.test.assertTrue

internal class FlutterKokoroTtsPluginTest {
    @Test
    fun pluginInstantiates() {
        val plugin = FlutterKokoroTtsPlugin()
        assertTrue(plugin is FlutterPlugin)
    }
}
