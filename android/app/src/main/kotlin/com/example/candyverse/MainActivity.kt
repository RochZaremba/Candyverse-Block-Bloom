package com.example.candyverse

import android.media.AudioAttributes
import android.media.SoundPool
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private var soundPool: SoundPool? = null
    private val sounds = mutableMapOf<String, Int>()
    private val loaded = mutableSetOf<Int>()
    private val streams = ArrayDeque<Int>()
    private var feedbackChannel: MethodChannel? = null
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
            val path = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset("assets/audio/$cue.wav")
            try {
                assets.openFd(path).use { sounds[cue] = pool.load(it, 1) }
            } catch (_: IOException) {
                // Optional feedback must never prevent the game from opening.
            }
        }
        feedbackChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "candyverse/feedback")
        feedbackChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val id = sounds[call.arguments as? String]
                        if (foreground && id != null && loaded.contains(id)) {
                            if (streams.size >= 3) pool.stop(streams.removeFirst())
                            val stream = pool.play(id, .55f, .55f, 1, 0, 1f)
                            if (stream != 0) streams.addLast(stream)
                        }
                        result.success(null)
                    }
                    "stop" -> { stopSounds(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }
    private fun stopSounds() {
        for (stream in streams) soundPool?.stop(stream)
        streams.clear()
    }
    private fun releaseSounds() {
        feedbackChannel?.setMethodCallHandler(null)
        feedbackChannel = null
        stopSounds()
        soundPool?.setOnLoadCompleteListener(null)
        soundPool?.release()
        soundPool = null
        loaded.clear()
        sounds.clear()
    }
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        releaseSounds()
        super.cleanUpFlutterEngine(flutterEngine)
    }
    override fun onResume() { super.onResume(); foreground = true }
    override fun onPause() { foreground = false; stopSounds(); super.onPause() }
    override fun onDestroy() { releaseSounds(); super.onDestroy() }
}
