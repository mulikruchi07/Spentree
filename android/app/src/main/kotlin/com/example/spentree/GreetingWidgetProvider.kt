package com.example.spentree

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.util.Base64
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class GreetingWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val todayExpense = widgetData.getString("widget_expense_str", "0.0")?.toDoubleOrNull() ?: 0.0
        val dailyLimit = widgetData.getString("widget_limit_str", "5000")?.toIntOrNull() ?: 5000
        val userName = widgetData.getString("widget_user_name", "Ruchi")
        val base64Image = widgetData.getString("profile_image", null)
        
        val percentage = if (dailyLimit > 0) ((dailyLimit - todayExpense) / dailyLimit).coerceIn(0.0, 1.0) else 0.0

        val badgeText: String
        val statusIconRes: Int
        val level: Int

when {
    percentage >= 0.83 -> { badgeText = "Great"; statusIconRes = R.drawable.ic_trending_up; level = 1 }
    percentage >= 0.66 -> { badgeText = "Good"; statusIconRes = R.drawable.ic_trending_up; level = 2 }
    percentage >= 0.50 -> { badgeText = "Warning"; statusIconRes = R.drawable.ic_warning; level = 3 }
    percentage >= 0.33 -> { badgeText = "Careful"; statusIconRes = R.drawable.ic_warning; level = 4 }
    percentage >= 0.16 -> { badgeText = "Poor"; statusIconRes = R.drawable.ic_trending_down; level = 5 }
    else -> { badgeText = "Empty"; statusIconRes = R.drawable.ic_trending_down; level = 6 }
}

        val formattedAmount = "Rs. ${NumberFormat.getNumberInstance(Locale("en", "IN")).format(todayExpense)}"
        val formattedDate = "Today's Expense • ${SimpleDateFormat("E, d MMMM ''yy", Locale.getDefault()).format(Date())}"

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_greeting)

            // Profile Image Logic
            if (base64Image != null) {
                try {
                    val bytes = Base64.decode(base64Image, Base64.DEFAULT)
                    views.setImageViewBitmap(R.id.profile_image, BitmapFactory.decodeByteArray(bytes, 0, bytes.size))
                } catch (e: Exception) {
                    views.setImageViewResource(R.id.profile_image, R.drawable.ic_avatar_placeholder)
                }
            } else {
                views.setImageViewResource(R.id.profile_image, R.drawable.ic_avatar_placeholder)
            }

            views.setTextViewText(R.id.tv_hello_name, "Hello, $userName")
            views.setTextViewText(R.id.tv_amount, formattedAmount)
            views.setTextViewText(R.id.tv_date, formattedDate)
            
            // CORRECTED: This switches colors via your badge_bg.xml (level-list)
            views.setInt(R.id.badge_container, "setImageLevel", level)
            
            views.setImageViewResource(R.id.badge_icon, statusIconRes)
            views.setTextViewText(R.id.badge_text, badgeText)

            val intent = Intent(context, MainActivity::class.java).apply {
                action = "OPEN_DASHBOARD"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            views.setOnClickPendingIntent(R.id.widget_background_greeting, PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE))
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}