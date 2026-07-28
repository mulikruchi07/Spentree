package com.spentree.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

class CalendarWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val cal = Calendar.getInstance()
        val today = Calendar.getInstance()
        
        // 1. Get the dynamic limit set by the user
        val dailyLimit = widgetData.getInt("daily_expense_limit", 500).toDouble()
        val expensesJson = widgetData.getString("transactions_json", "{}") ?: "{}"
        
        val monthYearStr = SimpleDateFormat("MMMM yyyy", Locale.getDefault()).format(cal.time)

        cal.set(Calendar.DAY_OF_MONTH, 1)
        val daysInMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH)
        var offset = cal.get(Calendar.DAY_OF_WEEK) - Calendar.MONDAY
        if (offset < 0) offset += 7

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_calendar)
            views.setTextViewText(R.id.calendar_month_year, monthYearStr)

            // In onUpdate:
for (i in 1..42) {
    val viewId = context.resources.getIdentifier("day_$i", "id", context.packageName)
    if (viewId == 0) continue

    val dayNumber = i - offset
    if (dayNumber in 1..daysInMonth) {
        views.setViewVisibility(viewId, View.VISIBLE)
        views.setTextViewText(viewId, dayNumber.toString())

        val dateToCheck = Calendar.getInstance()
        dateToCheck.set(Calendar.DAY_OF_MONTH, dayNumber)
        
        // Normalize time to midnight
        val calCheck = dateToCheck.clone() as Calendar
        calCheck.set(Calendar.HOUR_OF_DAY, 0); calCheck.set(Calendar.MINUTE, 0)
        calCheck.set(Calendar.SECOND, 0); calCheck.set(Calendar.MILLISECOND, 0)
        
        val calToday = today.clone() as Calendar
        calToday.set(Calendar.HOUR_OF_DAY, 0); calToday.set(Calendar.MINUTE, 0)
        calToday.set(Calendar.SECOND, 0); calToday.set(Calendar.MILLISECOND, 0)

        if (!calCheck.after(calToday)) {
            val status = getStatusForDay(dayNumber, expensesJson, dailyLimit)
            val pillRes = when(status) {
                "Great" -> R.drawable.bg_pill_green
                "Warning" -> R.drawable.bg_pill_yellow
                "Poor" -> R.drawable.bg_pill_red
                else -> R.drawable.bg_pill_green
            }
            views.setInt(viewId, "setBackgroundResource", pillRes)
            views.setTextColor(viewId, Color.WHITE)
        } else {
            views.setInt(viewId, "setBackgroundResource", 0)
            views.setTextColor(viewId, Color.GRAY)
        }
    } else {
        views.setViewVisibility(viewId, View.INVISIBLE)
    }
}
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun getStatusForDay(day: Int, json: String, limit: Double): String {
    return try {
        val obj = JSONObject(json).optJSONObject(day.toString())
        // If data is null, treat as $0 spend
        val amt = obj?.optDouble("amount", 0.0) ?: 0.0
        
        val percentage = if (limit > 0) (amt / limit) else 0.0
        
        when {
            percentage < 0.33 -> "Great"   // Includes $0 spend
            percentage < 0.66 -> "Warning"
            else -> "Poor"
        }
    } catch (e: Exception) { "Great" } // Default to Green if JSON error
}
}