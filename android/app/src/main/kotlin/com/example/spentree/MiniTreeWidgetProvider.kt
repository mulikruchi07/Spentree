package com.example.spentree

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider // 🌟 THIS ALLOWS FLUTTER TO TRIGGER THE WIDGET

// 🌟 FIXED: Changed back to HomeWidgetProvider
class MiniTreeWidgetProvider : HomeWidgetProvider() {

    // 🌟 FIXED: Added widgetData to the function signature
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        
        // We no longer need to manually fetch SharedPreferences, HomeWidgetProvider hands it to us!
        val todayExpenseStr = widgetData.getString("widget_expense_str", "0.0")
        val todayExpense = todayExpenseStr?.toDoubleOrNull() ?: 0.0

        val dailyLimitStr = widgetData.getString("widget_limit_str", "5000")
        val dailyLimit = dailyLimitStr?.toIntOrNull() ?: 5000

        val pendingLimit = (dailyLimit - todayExpense).coerceIn(0.0, dailyLimit.toDouble())
        val percentage = if (dailyLimit > 0) (pendingLimit / dailyLimit).coerceIn(0.0, 1.0) else 0.0

        var badgeText = "Empty"
        var statusColor = "#FF383C" // Red
        var treeImageRes = R.drawable.tree_6

        if (percentage >= 0.83) { badgeText = "Great"; statusColor = "#34C759"; treeImageRes = R.drawable.tree_1 }
        else if (percentage >= 0.66) { badgeText = "Good"; statusColor = "#34C759"; treeImageRes = R.drawable.tree_2 }
        else if (percentage >= 0.50) { badgeText = "Warning"; statusColor = "#FFCC00"; treeImageRes = R.drawable.tree_3 }
        else if (percentage >= 0.33) { badgeText = "Careful"; statusColor = "#FFCC00"; treeImageRes = R.drawable.tree_4 }
        else if (percentage >= 0.16) { badgeText = "Poor"; statusColor = "#FF383C"; treeImageRes = R.drawable.tree_5 }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_mini_tree)

            views.setTextViewText(R.id.badge_text, badgeText)
            views.setTextColor(R.id.badge_text, Color.parseColor(statusColor))
            views.setInt(R.id.widget_background, "setBackgroundColor", Color.parseColor(statusColor))
            views.setImageViewResource(R.id.tree_image, treeImageRes)

            val intent = Intent(context, MainActivity::class.java).apply {
                action = "OPEN_DASHBOARD"
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_background, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}