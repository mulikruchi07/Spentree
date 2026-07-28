package com.spentree.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.util.Locale

class TreeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val todayExpense = widgetData.getString("widget_expense_str", "0.0")?.toDoubleOrNull() ?: 0.0
        val dailyLimit = widgetData.getString("widget_limit_str", "500")?.toIntOrNull() ?: 500
        val pendingLimit = (dailyLimit - todayExpense).coerceIn(0.0, dailyLimit.toDouble())
        val percentage = if (dailyLimit > 0) (pendingLimit / dailyLimit).coerceIn(0.0, 1.0) else 0.0

        // 6-Level Logic
        var badgeText = "Empty"
        var treeRes = R.drawable.tree_6
        var iconRes = R.drawable.ic_trending_down
        var bgRes = R.drawable.bg_red_rect // Default to Red

        when {
            percentage >= 0.83 -> { badgeText = "Great"; bgRes = R.drawable.bg_green_rect; treeRes = R.drawable.tree_1; iconRes = R.drawable.ic_trending_up }
            percentage >= 0.66 -> { badgeText = "Good"; bgRes = R.drawable.bg_green_rect; treeRes = R.drawable.tree_2; iconRes = R.drawable.ic_trending_up }
            percentage >= 0.50 -> { badgeText = "Warning"; bgRes = R.drawable.bg_yellow_rect; treeRes = R.drawable.tree_3; iconRes = R.drawable.ic_warning }
            percentage >= 0.33 -> { badgeText = "Careful"; bgRes = R.drawable.bg_yellow_rect; treeRes = R.drawable.tree_4; iconRes = R.drawable.ic_warning }
            percentage >= 0.16 -> { badgeText = "Poor"; bgRes = R.drawable.bg_red_rect; treeRes = R.drawable.tree_5; iconRes = R.drawable.ic_trending_down }
            else -> { badgeText = "Empty"; bgRes = R.drawable.bg_red_rect; treeRes = R.drawable.tree_6; iconRes = R.drawable.ic_trending_down }
        }

        val formatter = NumberFormat.getNumberInstance(Locale("en", "IN"))

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_tree)

            // Set Backgrounds and Images
            views.setInt(R.id.tree_bg_layer, "setBackgroundResource", bgRes)
            views.setInt(R.id.badge_container, "setBackgroundResource", bgRes)
            views.setImageViewResource(R.id.tree_image, treeRes)

            // Set Badge Info
            views.setImageViewResource(R.id.badge_icon, iconRes)
            views.setTextViewText(R.id.badge_text, badgeText)

            // Set Text Info
            views.setTextViewText(R.id.expense_text, "Rs. ${formatter.format(todayExpense)}")
            views.setTextViewText(R.id.limit_text, "Rs. ${formatter.format(pendingLimit)} / ${formatter.format(dailyLimit)}")

            val intent = Intent(context, MainActivity::class.java).apply {
                action = "OPEN_DASHBOARD"
            }
            val pending = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.widget_background, pending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}