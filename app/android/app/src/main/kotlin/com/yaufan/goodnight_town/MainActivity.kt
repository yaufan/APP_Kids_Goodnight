package com.yaufan.goodnight_town

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * The lullaby plays with the screen black but awake (docs/design.md 「搖籃曲」).
 * Both are flags on the app's own window, so no permission is needed:
 * - keepOn: FLAG_KEEP_SCREEN_ON while the evening and the lullaby run;
 * - dim: this window's own brightness turned right down while the screen is
 *   black (the phone's brightness setting is not touched).
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "goodnight_town/screen").setMethodCallHandler { call, result ->
            val on = call.arguments as? Boolean ?: false
            when (call.method) {
                "keepOn" -> {
                    if (on) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                "dim" -> {
                    val attrs = window.attributes
                    attrs.screenBrightness = if (on) 0.01f else WindowManager.LayoutParams.BRIGHTNESS_OVERRIDE_NONE
                    window.attributes = attrs
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
