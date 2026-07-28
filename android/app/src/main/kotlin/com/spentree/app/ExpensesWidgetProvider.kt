package com.spentree.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class ExpensesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    private fun iconFor(category: String): Int {
        return when (category) {
            "Food & Beverages" -> R.drawable.ic_food
            "Shopping" -> R.drawable.ic_shopping
            "Fuel" -> R.drawable.ic_fuel
            "Bills & Subscriptions" -> R.drawable.ic_bills
            "To People" -> R.drawable.ic_person
            else -> R.drawable.ic_rupee
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_expenses)

        val jsonString = widgetData.getString("today_transactions_json", "[]") ?: "[]"

        val slotIds = intArrayOf(R.id.slot_0, R.id.slot_1, R.id.slot_2, R.id.slot_3)
        val rowIds = intArrayOf(R.id.row_0, R.id.row_1, R.id.row_2, R.id.row_3)
        val iconIds = intArrayOf(R.id.icon_0, R.id.icon_1, R.id.icon_2, R.id.icon_3)
        val titleIds = intArrayOf(R.id.title_0, R.id.title_1, R.id.title_2, R.id.title_3)
        val subtitleIds = intArrayOf(R.id.subtitle_0, R.id.subtitle_1, R.id.subtitle_2, R.id.subtitle_3)
        val amountIds = intArrayOf(R.id.amount_0, R.id.amount_1, R.id.amount_2, R.id.amount_3)
        val timeIds = intArrayOf(R.id.time_0, R.id.time_1, R.id.time_2, R.id.time_3)

        val txArray = try {
            JSONArray(jsonString)
        } catch (e: Exception) {
            JSONArray()
        }

        val count = txArray.length().coerceAtMost(4)

        // Fill visible slots with transaction data, hide unused slots entirely
        for (i in 0 until 4) {
            if (i < count) {
                val tx = txArray.getJSONObject(i)
                val title = tx.optString("title", "Unknown")
                val category = tx.optString("category", "Other")
                val amount = tx.optDouble("amount", 0.0)
                val time = tx.optString("time", "")
                val isManual = tx.optBoolean("isManual", false)

                views.setViewVisibility(slotIds[i], View.VISIBLE)
                views.setViewVisibility(rowIds[i], View.VISIBLE)

                views.setImageViewResource(iconIds[i], iconFor(category))
                views.setTextViewText(titleIds[i], title)
                views.setTextViewText(subtitleIds[i], if (isManual) "Cash" else "Bank account")
                views.setTextViewText(amountIds[i], "- Rs. ${formatAmount(amount)}")
                views.setTextViewText(timeIds[i], time)
            } else {
                // Hide the whole slot (removes it from weight distribution)
                views.setViewVisibility(slotIds[i], View.GONE)
            }
        }

        // Show exactly one combined empty block based on how many slots are empty
        val emptySlots = 4 - count
        views.setViewVisibility(R.id.empty_all4, if (emptySlots == 4) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.empty_3of4, if (emptySlots == 3) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.empty_2of4, if (emptySlots == 2) View.VISIBLE else View.GONE)
        views.setViewVisibility(R.id.empty_1of4, if (emptySlots == 1) View.VISIBLE else View.GONE)

        val intent = Intent(context, MainActivity::class.java).apply {
            action = "OPEN_DASHBOARD"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 2, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    private fun formatAmount(amount: Double): String {
        val rounded = Math.round(amount)
        return String.format("%,d", rounded)
    }
}