package com.example.project

import android.Manifest
import android.content.pm.PackageManager
import android.telephony.SmsManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "alarm_sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {

                "sendSms" -> {
                    val number = call.argument<String>("number")
                    val message = call.argument<String>("message")

                    if (number != null && message != null) {
                        SmsManager.getDefault()
                            .sendTextMessage(number, null, message, null, null)
                        result.success(null)
                    } else {
                        result.error("ERR", "Invalid args", null)
                    }
                }

                "requestDefaultSms" -> {
                    requestPermissions()
                    result.success(null)
                }

                "getSms" -> {
                    result.success(emptyList<Any>())
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun requestPermissions() {
        val permissions = arrayOf(
            Manifest.permission.SEND_SMS,
            Manifest.permission.READ_SMS,
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.READ_PHONE_STATE
        )

        val need = permissions.filter { permission ->
            ContextCompat.checkSelfPermission(
                this,
                permission
            ) != PackageManager.PERMISSION_GRANTED
        }

        if (need.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                need.toTypedArray(),
                1
            )
        }
    }
}
