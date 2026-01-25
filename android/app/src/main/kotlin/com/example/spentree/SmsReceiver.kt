package com.example.spentree

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        for (msg in messages) {
            val sender = msg.originatingAddress ?: ""
            val body = msg.messageBody ?: ""
            val timestamp = msg.timestampMillis

            // For now, just log or store later
            println("NEW SMS -> $sender : $body")
        }
    }
}
