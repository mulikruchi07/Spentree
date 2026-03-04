package com.example.spentree // Ensure this matches your package name

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "sms_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getAllSms") {
                    // Assuming SmsReader is your custom Kotlin class
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
}