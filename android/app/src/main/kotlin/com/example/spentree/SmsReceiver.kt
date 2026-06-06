package com.example.spentree

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.widget.Toast
import android.os.Handler
import android.os.Looper
import java.util.regex.Pattern

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            
            // 🌟 DEBUG TOAST 1: Proves Android woke the app up
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(context, "SpenTree: SMS Intercepted!", Toast.LENGTH_SHORT).show()
            }

            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            var totalNewExpense = 0.0

            for (msg in messages) {
                val body = msg.displayMessageBody?.lowercase() ?: ""
                val originalBody = msg.displayMessageBody ?: ""
                
                // 1. FILTER: Is this a Debit?
                val isDebit = listOf("debited", "paid", "spent", "withdrawn", "sent to").any { body.contains(it) }
                val isCredit = listOf("credited", "received", "refund").any { body.contains(it) }
                
                if (isDebit && !isCredit) {
                    // 2. REGEX: Extract the Amount
                    val amountPattern = Pattern.compile("(?i)(?:rs\\.?|inr|₹)\\s*([\\d,]+\\.?\\d*)")
                    val matcher = amountPattern.matcher(originalBody)
                    
                    if (matcher.find()) {
                        val amountStr = matcher.group(1)?.replace(",", "")
                        val amount = amountStr?.toDoubleOrNull() ?: 0.0
                        totalNewExpense += amount
                    }
                }
            }

            if (totalNewExpense > 0) {
                // 🌟 DEBUG TOAST 2: Proves the Regex found the money
                Handler(Looper.getMainLooper()).post {
                    Toast.makeText(context, "SpenTree Logged: Rs.$totalNewExpense", Toast.LENGTH_LONG).show()
                }
                updateWidgetsNatively(context, totalNewExpense)
            }
        }
    }

    private fun updateWidgetsNatively(context: Context, newExpenseAmount: Double) {
        val widgetData = context.getSharedPreferences("es.antonborri.home_widget.preferences", Context.MODE_PRIVATE)
        
        val currentExpenseStr = widgetData.getString("widget_expense_str", "0.0")
        val currentExpense = currentExpenseStr?.toDoubleOrNull() ?: 0.0
        
        val updatedExpense = currentExpense + newExpenseAmount
        widgetData.edit().putString("widget_expense_str", updatedExpense.toString()).apply()

        val appWidgetManager = AppWidgetManager.getInstance(context)
        
        // Update Mini Tree
        val miniTreeIds = appWidgetManager.getAppWidgetIds(ComponentName(context, MiniTreeWidgetProvider::class.java))
        val miniTreeIntent = Intent(context, MiniTreeWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, miniTreeIds)
        }
        context.sendBroadcast(miniTreeIntent)

        // Update Main Tree
        val treeIds = appWidgetManager.getAppWidgetIds(ComponentName(context, TreeWidgetProvider::class.java))
        val treeIntent = Intent(context, TreeWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, treeIds)
        }
        context.sendBroadcast(treeIntent)
        
        // Update Greeting
        val greetingIds = appWidgetManager.getAppWidgetIds(ComponentName(context, GreetingWidgetProvider::class.java))
        val greetingIntent = Intent(context, GreetingWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, greetingIds)
        }
        context.sendBroadcast(greetingIntent)
    }
}