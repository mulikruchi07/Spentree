package com.example.spentree

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class AuthOverlayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_auth_overlay)
            val imagePath = widgetData.getString("img_auth_overlay", null) // Matches Dart key!
            if (imagePath != null) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                views.setImageViewBitmap(R.id.widget_image_auth_overlay, bitmap)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}