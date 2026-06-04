package com.example.spentree 

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class SpentreeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.spentree_widget)
            
            // Get the image path saved by Flutter
            val imagePath = widgetData.getString("tree_widget_image", null)
            
            if (imagePath != null) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                views.setImageViewBitmap(R.id.widget_image, bitmap)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}