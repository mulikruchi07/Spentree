package com.example.spentree

import android.app.PendingIntent
import android.content.Intent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.NumberFormat
import java.util.Locale

class ExpensesWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        val todayExpenseStr = widgetData.getString("widget_expense_str", "0.0")
        val todayExpense = todayExpenseStr?.toDoubleOrNull() ?: 0.0

        val formatter = NumberFormat.getNumberInstance(Locale("en", "IN"))
        val expenseFormatted = "Rs. ${formatter.format(todayExpense)}"

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_expenses)
            views.setTextViewText(R.id.expense_text, expenseFormatted)

            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 2, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_background, pendingIntent)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}