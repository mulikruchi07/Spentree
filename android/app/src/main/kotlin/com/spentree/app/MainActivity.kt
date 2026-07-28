package com.spentree.app

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngineCache
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val SMS_CHANNEL = "sms_channel"
    private val WIDGET_CHANNEL = "spentree_widget_channel"
    private var pendingWidgetAction: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)

        // Disable Android's automatic nav bar contrast enforcement.
        // Without this, Android 10+ forces a semi-transparent scrim over the
        // nav area even when Flutter sets a solid color — causing the "see-through"
        // effect on pushed routes. This single line is the fix for secondary screens.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.isNavigationBarContrastEnforced = false
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        FlutterEngineCache.getInstance().put("spentree_engine", flutterEngine)
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SMS_CHANNEL)
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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingWidgetAction = intent.action
    }
}