package com.example.spentree

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.widget.Toast
import android.os.Handler
import android.os.Looper
import java.util.regex.Pattern
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import android.net.Uri

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

                val isDebit = listOf("debited", "paid", "spent", "withdrawn", "sent to").any { body.contains(it) }
                val isCredit = listOf("credited", "received", "refund").any { body.contains(it) }

                if (isDebit && !isCredit) {
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

                // Trigger Dart background isolate to re-parse SMS + sync ALL widgets
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("homeWidgetExample://sms_received")
                )
                backgroundIntent.send()
            }
        }
    }
}