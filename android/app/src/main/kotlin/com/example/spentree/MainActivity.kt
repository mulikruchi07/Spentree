package com.example.spentree

import android.os.Bundle
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterFragmentActivity

// We inherit from FlutterFragmentActivity to support biometrics
class MainActivity: FlutterFragmentActivity() {

    private val CHANNEL = "sms_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Integrating your SMS Reader MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getAllSms") {
                    val smsList = SmsReader.getAllSms(this)
                    val mapped = smsList.map {
                        mapOf(
                            "address" to it.address,
                            "body" to it.body,
                            "date" to it.date
                        )
                    }
                    result.success(mapped)
                } else {
                    result.notImplemented()
                }
            }
    }
    override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    // This line prevents screenshots and blurs the app in the task switcher
    window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
}
}