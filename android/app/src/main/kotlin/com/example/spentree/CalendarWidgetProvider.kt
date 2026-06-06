package com.example.spentree

import android.app.PendingIntent
import android.content.Intent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class CalendarWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val calendar = Calendar.getInstance()
        val dayFormat = SimpleDateFormat("dd", Locale.getDefault())
        val monthYearFormat = SimpleDateFormat("MMM yyyy", Locale.getDefault())

        val dayStr = dayFormat.format(calendar.time)
        val monthYearStr = monthYearFormat.format(calendar.time).uppercase()

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_calendar)
            views.setTextViewText(R.id.calendar_date_display, dayStr)
            views.setTextViewText(R.id.calendar_month_year, monthYearStr)

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 3, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_background, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}