package eu.wroblewscy.marcin.floating.floating

import android.app.Activity
import android.app.PictureInPictureParams
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Rect
import android.os.Build
import android.util.Rational
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** FloatingPlugin */
class FloatingPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private lateinit var activity: Activity

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "floating")
    channel.setMethodCallHandler(this)
    context = binding.applicationContext
  }

  @RequiresApi(Build.VERSION_CODES.N)
  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "enablePip" -> enablePip(call, result)
      "pipAvailable" -> result.success(
        context.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
      )
      "inPipAlready" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
          result.success(activity.isInPictureInPictureMode)
        } else {
          result.error("UNSUPPORTED_VERSION", "isInPictureInPictureMode requires API 24+", null)
        }
      }
      "cancelAutoEnable" -> cancelAutoEnable(result)
      else -> result.notImplemented()
    }
  }

  @RequiresApi(Build.VERSION_CODES.N)
  private fun enablePip(call: MethodCall, result: Result) {
    if (!context.packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)) {
      result.error("PIP_UNAVAILABLE", "Picture-in-Picture is not supported on this device", null)
      return
    }

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      val builder = PictureInPictureParams.Builder().apply {
        // Thiết lập tỷ lệ khung hình
        setAspectRatio(Rational(
          call.argument<Int>("numerator") ?: 16,
          call.argument<Int>("denominator") ?: 9
        ))

        // Thiết lập source rect hint nếu có
        val sourceRectHintLTRB = call.argument<List<Int>>("sourceRectHintLTRB")
        if (sourceRectHintLTRB?.size == 4) {
          setSourceRectHint(Rect(
            sourceRectHintLTRB[0],
            sourceRectHintLTRB[1],
            sourceRectHintLTRB[2],
            sourceRectHintLTRB[3]
          ))
        }

        // Kích hoạt auto-enter nếu được yêu cầu
        val autoEnable = call.argument<Boolean>("autoEnable") ?: false
        if (autoEnable && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
          setAutoEnterEnabled(true)
          activity.setPictureInPictureParams(build())
          result.success(true)
          return
        } else if (autoEnable && Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
          result.error(
            "UNSUPPORTED_VERSION",
            "AutoEnterEnabled requires API 31+, current API: ${Build.VERSION.SDK_INT}",
            null
          )
          return
        }
      }

      result.success(activity.enterPictureInPictureMode(builder.build()))
    } else {
      result.success(activity.enterPictureInPictureMode())
    }
  }

  private fun cancelAutoEnable(result: Result) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      activity.setPictureInPictureParams(
        PictureInPictureParams.Builder()
          .setAutoEnterEnabled(false)
          .build()
      )
      result.success(true)
    } else {
      result.error(
        "UNSUPPORTED_VERSION",
        "CancelAutoEnable requires API 31+, current API: ${Build.VERSION.SDK_INT}",
        null
      )
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {}

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {}
}