package com.example.spentree   // ← replace with your real applicationId

import android.app.Activity
import android.content.Intent
import android.os.Bundle

class RedirectActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val forward = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            data = intent.data
            flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(forward)
        finishAndRemoveTask()
    }
}