package com.example.spentree 

import io.flutter.embedding.engine.FlutterEngineCache
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val SMS_CHANNEL = "sms_channel"
    private val WIDGET_CHANNEL = "spentree_widget_channel"
    private var pendingWidgetAction: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        FlutterEngineCache.getInstance().put("spentree_engine", flutterEngine)
        super.configureFlutterEngine(flutterEngine)

        // 1. Your Existing SMS Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
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

        // 2. NEW: The Widget Redirect Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getWidgetAction") {
                    val actionToReturn = pendingWidgetAction ?: intent.action
                    result.success(actionToReturn)
                    
                    pendingWidgetAction = null
                    intent.action = null
                } else {
                    result.notImplemented()
                }
            }
    }

    // Required to catch the intent if the app is already open in the background
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingWidgetAction = intent.action
    }
}