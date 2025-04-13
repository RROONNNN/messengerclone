package com.linusu.flutter_web_auth_2

import android.app.Service
import android.content.Intent
import android.os.IBinder

class KeepAliveService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
}