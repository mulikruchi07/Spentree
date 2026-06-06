package com.example.spentree

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class GreetingWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        
        // 1. Fetch Data from Flutter
        val todayExpenseStr = widgetData.getString("widget_expense_str", "0.0")
        val todayExpense = todayExpenseStr?.toDoubleOrNull() ?: 0.0

        val dailyLimitStr = widgetData.getString("widget_limit_str", "5000")
        val dailyLimit = dailyLimitStr?.toIntOrNull() ?: 5000

        // Fetch User Name (Default to User if missing)
        val userName = widgetData.getString("widget_user_name", "User")

        // 2. Math & Logic
        val pendingLimit = (dailyLimit - todayExpense).coerceIn(0.0, dailyLimit.toDouble())
        val percentage = if (dailyLimit > 0) (pendingLimit / dailyLimit).coerceIn(0.0, 1.0) else 0.0

        var badgeText = "Poor"
        var statusColor = "#FF383C" // Red
        var textColor = "#FFFFFF"

        if (percentage >= 0.66) { badgeText = "Great"; statusColor = "#34C759" }
        else if (percentage >= 0.33) { badgeText = "Warning"; statusColor = "#FFCC00"; textColor = "#000000" }

        // Format Currency & Date
        val formatter = NumberFormat.getInstance(Locale("en", "IN"))
        val formattedAmount = "Rs. ${formatter.format(todayExpense)}"
        val dateFormatter = SimpleDateFormat("E, d MMMM ''yy", Locale.getDefault())
        val formattedDate = "Today's Expense  •  ${dateFormatter.format(Date())}"

        // 3. Update the Views
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_greeting)

            views.setTextViewText(R.id.tv_hello_name, "Hello, $userName")
            views.setTextViewText(R.id.tv_amount, formattedAmount)
            views.setTextViewText(R.id.tv_date, formattedDate)
            
            views.setTextViewText(R.id.badge_text, badgeText)
            views.setTextColor(R.id.badge_text, Color.parseColor(textColor))
            views.setInt(R.id.badge_container, "setBackgroundColor", Color.parseColor(statusColor))

            // Click Redirect
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "OPEN_DASHBOARD"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_background_greeting, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}