package com.example.spentree

import android.app.PendingIntent
import android.content.Intent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ExpensesWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_expenses) 
            val imagePath = widgetData.getString("img_expenses", null) 
            
            if (imagePath != null) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                views.setImageViewBitmap(R.id.widget_image_expenses, bitmap) 
            }

            // --- FIXED NATIVE ANDROID CLICK HANDLER ---
            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_image_expenses, pendingIntent) 
            // ------------------------------------------

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}