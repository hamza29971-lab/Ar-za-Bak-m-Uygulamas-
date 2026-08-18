package com.nimo.nimo_arizabakim

import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.nimo.nimo_arizabakim/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val phone = call.argument<String>("phone")
                val message = call.argument<String>("message")
                
                if (phone != null && message != null) {
                    try {
                        val smsManager = SmsManager.getDefault()
                        smsManager.sendTextMessage(phone, null, message, null, null)
                        result.success("SMS Sent")
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", "Failed to send SMS.", e.localizedMessage)
                    }
                } else {
                    result.error("INVALID_ARGUMENTS", "Phone or message is missing.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
