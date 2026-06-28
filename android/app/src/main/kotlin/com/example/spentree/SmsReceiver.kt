package com.example.spentree

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent) ?: return
            
            var hasRelevantTransaction = false

            for (msg in messages) {
                val body = msg.displayMessageBody?.lowercase() ?: continue
                val sender = msg.originatingAddress ?: "Unknown"

                // Filter: Only process if it looks like a bank transaction
                val isFinancial = listOf("bank", "hdfc", "icici", "axis", "sbi", "kotak", "alert", "txn").any { body.contains(it) }
                val isDebit = listOf("debited", "spent", "withdrawn", "paid").any { body.contains(it) }
                
                if (isFinancial && isDebit) {
                    hasRelevantTransaction = true
                    break
                }
            }

            if (hasRelevantTransaction) {
                // Trigger Dart background task
                val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(
                    context,
                    Uri.parse("homeWidgetExample://sms_received")
                )
                backgroundIntent.send()
            }
        }
    }
}