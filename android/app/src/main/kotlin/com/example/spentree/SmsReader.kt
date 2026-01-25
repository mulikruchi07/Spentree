package com.example.spentree

import android.content.Context
import android.database.Cursor
import android.net.Uri

data class SmsData(
    val address: String,
    val body: String,
    val date: Long
)

object SmsReader {

    fun getAllSms(context: Context): List<SmsData> {
        val smsList = mutableListOf<SmsData>()
        val uri = Uri.parse("content://sms/inbox")

        val cursor: Cursor? = context.contentResolver.query(
            uri,
            arrayOf("address", "body", "date"),
            null,
            null,
            "date DESC"
        )

        cursor?.use {
            while (it.moveToNext()) {
                val address = it.getString(0) ?: ""
                val body = it.getString(1) ?: ""
                val date = it.getLong(2)

                smsList.add(
                    SmsData(
                        address = address,
                        body = body,
                        date = date
                    )
                )
            }
        }

        return smsList
    }
}
