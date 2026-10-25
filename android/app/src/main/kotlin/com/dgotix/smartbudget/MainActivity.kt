package com.dgotix.smartbudget

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity: needed by local_auth (fingerprint / face unlock).
class MainActivity : FlutterFragmentActivity() {
    // Text shared to the app ("Share" on a bank message), until Flutter takes it.
    private var sharedText: String? = null
    private var sharedChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        readShared(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (readShared(intent)) sharedChannel?.invokeMethod("shared", null)
    }

    private fun readShared(intent: Intent?): Boolean {
        if (intent?.action != Intent.ACTION_SEND) return false
        if (intent.type?.startsWith("text/") != true) return false
        val text = intent.getStringExtra(Intent.EXTRA_TEXT) ?: return false
        sharedText = text
        return true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // While the app lock is on, the screens stay out of the recent-apps
        // preview and of screenshots / screen recording (FLAG_SECURE).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smartbudget/secure_screen")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    val on = call.arguments as? Boolean ?: false
                    runOnUiThread {
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        }
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        // Shared text is handed over once, then forgotten.
        sharedChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "smartbudget/shared_text")
            .also { channel ->
                channel.setMethodCallHandler { call, result ->
                    if (call.method == "take") {
                        result.success(sharedText)
                        sharedText = null
                    } else {
                        result.notImplemented()
                    }
                }
            }
    }
}
