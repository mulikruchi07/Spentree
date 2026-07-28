package com.spentree.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class ThemeChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_CONFIGURATION_CHANGED) {
            
            // Check if the Flutter Engine is currently running in cache
            val flutterEngine = FlutterEngineCache.getInstance().get("spentree_engine")
            
            if (flutterEngine != null) {
                // Tell Flutter to re-render the widgets!
                MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "spentree_widget_channel")
                    .invokeMethod("themeChanged", null)
            }
        }
    }
}