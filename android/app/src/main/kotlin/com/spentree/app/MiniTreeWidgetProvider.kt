package com.spentree.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class MiniTreeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val todayExpense = widgetData.getString("widget_expense_str", "0.0")?.toDoubleOrNull() ?: 0.0
        val dailyLimit = widgetData.getString("widget_limit_str", "500")?.toIntOrNull() ?: 500
        val pendingLimit = (dailyLimit - todayExpense).coerceIn(0.0, dailyLimit.toDouble())
        val percentage = if (dailyLimit > 0) (pendingLimit / dailyLimit).coerceIn(0.0, 1.0) else 0.0

        var badgeText = "Empty"
        var statusColor = "#FF383C"
        var treeImageRes = R.drawable.tree_6
        var iconRes = R.drawable.ic_trending_down

        if (percentage >= 0.83) {
            badgeText = "Great"; statusColor = "#34C759"; treeImageRes = R.drawable.tree_1; iconRes = R.drawable.ic_trending_up
        } else if (percentage >= 0.66) {
            badgeText = "Good"; statusColor = "#34C759"; treeImageRes = R.drawable.tree_2; iconRes = R.drawable.ic_trending_up
        } else if (percentage >= 0.50) {
            badgeText = "Warning"; statusColor = "#FFCC00"; treeImageRes = R.drawable.tree_3; iconRes = R.drawable.ic_warning
        } else if (percentage >= 0.33) {
            badgeText = "Careful"; statusColor = "#FFCC00"; treeImageRes = R.drawable.tree_4; iconRes = R.drawable.ic_warning
        } else if (percentage >= 0.16) {
            badgeText = "Poor"; statusColor = "#FF383C"; treeImageRes = R.drawable.tree_5; iconRes = R.drawable.ic_trending_down
        } else {
            badgeText = "Empty"; statusColor = "#FF383C"; treeImageRes = R.drawable.tree_6; iconRes = R.drawable.ic_trending_down
        }

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_mini_tree)

            // Background Color Update
            views.setInt(R.id.widget_background, "setBackgroundColor", Color.parseColor(statusColor))

            // Badge text & icon — tinted to status color, sit on white badge box
            views.setTextViewText(R.id.badge_text, badgeText)
            views.setTextColor(R.id.badge_text, Color.parseColor(statusColor))
            views.setImageViewResource(R.id.badge_icon, iconRes)
            views.setInt(R.id.badge_icon, "setColorFilter", Color.parseColor(statusColor))

            // Tree Image
            views.setImageViewResource(R.id.tree_image, treeImageRes)

            // Click action
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "OPEN_DASHBOARD"
            }
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_background, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}