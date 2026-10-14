package com.example.candyverse

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private val sounds = mutableMapOf<String, Int>()
    private val loaded = mutableSetOf<Int>()
    private var foreground = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val pool = SoundPool.Builder().setMaxStreams(3).setAudioAttributes(
            AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
        ).build()
        soundPool = pool
        pool.setOnLoadCompleteListener { _, id, status -> if (status == 0) loaded.add(id) }
        for (cue in listOf("place", "clear", "upgrade")) {
            val path = flutterEngine.dartExecutor.flutterJNI.getLookupKeyForAsset("assets/audio/$cue.wav")
            assets.openFd(path).use { sounds[cue] = pool.load(it, 1) }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "candyverse/feedback")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val id = sounds[call.arguments as? String]
                        if (foreground && id != null && loaded.contains(id)) pool.play(id, .55f, .55f, 1, 0, 1f)
                        result.success(null)
                    }
                    "stop" -> { pool.autoPause(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }
    override fun onResume() { super.onResume(); foreground = true }
    override fun onPause() { foreground = false; soundPool?.autoPause(); super.onPause() }
    override fun onDestroy() { soundPool?.release(); soundPool = null; super.onDestroy() }
}
