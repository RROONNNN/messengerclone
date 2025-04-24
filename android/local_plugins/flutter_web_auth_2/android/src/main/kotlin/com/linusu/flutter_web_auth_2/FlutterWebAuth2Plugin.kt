package com.linusu.flutter_web_auth_2

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterWebAuth2Plugin : MethodCallHandler, FlutterPlugin {
    private var channel: MethodChannel? = null
    private var context: Context? = null

    companion object {
        val callbacks = mutableMapOf<String, Result>()
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_web_auth_2")
        channel?.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "authenticate" -> authenticate(call, result)
            "cleanUpDanglingCalls" -> cleanUp(result)
            else -> result.notImplemented()
        }
    }

    private fun authenticate(call: MethodCall, result: Result) {
        val url = call.argument<String>("url")!!
        val callbackUrlScheme = call.argument<String>("callbackUrlScheme")!!
        val options = call.argument<Map<String, Any>>("options")!!

        callbacks[callbackUrlScheme] = result

        val intent = CustomTabsIntent.Builder().build()
        intent.intent.addFlags(options["intentFlags"] as Int)
        intent.launchUrl(context!!, Uri.parse(url))
    }

    private fun cleanUp(result: Result) {
        callbacks.values.forEach { it.error("CANCELED", "User canceled login", null) }
        callbacks.clear()
        result.success(null)
    }
}