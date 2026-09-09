package com.nimo.nimo_arizabakim

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.telephony.SmsManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val smsChannel = "com.nimo.nimo_arizabakim/sms"
    private val kioskChannel = "com.nimo.nimo_arizabakim/kiosk"

    /**
     * Ayarlar'dan donuldugunde kiosk'u geri kurmak icin isaret. Ayarlar
     * acilirken true olur; uygulama tekrar on plana geldiginde politika
     * sifirlanir ve ekran kilidi yeniden daraltilir.
     */
    private var returningFromSettings = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, smsChannel)
            .setMethodCallHandler { call, result ->
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, kioskChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(statusMap())
                    "unlock" -> handleUnlock(call.argument<String>("password"), result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        if (!KioskPolicy.isDeviceOwner(this)) return

        // Kullanici Ayarlar'dan dondu: izin listesini yeniden daralt.
        if (returningFromSettings || KioskPolicy.isSettingsMode(this)) {
            returningFromSettings = false
            KioskPolicy.applyAll(this)
            Log.i(TAG, "Ayarlar kapandi; kiosk geri kuruldu")
        }
        enterLockTask()
    }

    /** Zaten kilitliyse tekrar cagirmak zararsizdir; kilitli degilse kilitler. */
    private fun enterLockTask() {
        if (!KioskPolicy.isLockTaskPermitted(this)) {
            Log.w(TAG, "Uygulama lock task izin listesinde degil")
            return
        }
        if (lockTaskState() == LOCKED) return
        runCatching { startLockTask() }
            .onFailure { Log.e(TAG, "Ekran kilidi baslatilamadi", it) }
    }

    private fun handleUnlock(password: String?, result: MethodChannel.Result) {
        when (password?.trim()) {
            OPERATOR_PASSWORD -> {
                if (!KioskPolicy.isDeviceOwner(this)) {
                    result.success("no_owner")
                    return
                }
                if (!KioskPolicy.allowSettings(this)) {
                    result.success("failed")
                    return
                }
                returningFromSettings = true
                KioskPolicy.openSettings(this)
                Log.i(TAG, "Ayarlar modu acildi")
                result.success("settings")
            }

            RECOVERY_PASSWORD -> {
                if (!KioskPolicy.isDeviceOwner(this)) {
                    result.success("no_owner")
                    return
                }
                // Once kilit birakilir; aksi halde sahiplik kalksa bile
                // ekran kilitli kalir ve tablet kurtarilamaz gorunur.
                runCatching { stopLockTask() }
                val released = KioskPolicy.releaseOwnership(this)
                Log.i(TAG, "Kurtarma parolasi uygulandi; sonuc=$released")
                result.success(if (released) "released" else "failed")
            }

            else -> result.success("invalid")
        }
    }

    private fun statusMap(): Map<String, Any> = mapOf(
        "deviceOwner" to KioskPolicy.isDeviceOwner(this),
        "lockTaskPermitted" to KioskPolicy.isLockTaskPermitted(this),
        "locked" to (lockTaskState() == LOCKED),
        "settingsMode" to KioskPolicy.isSettingsMode(this),
    )

    /**
     * Ekran kilidi durumu. PINNED (kullanicinin kendi baslattigi ekran
     * sabitleme) guvenli kiosk sayilmaz; yalnizca LOCKED kabul edilir.
     */
    private fun lockTaskState(): Int {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager ?: return NONE
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            am.lockTaskModeState
        } else {
            @Suppress("DEPRECATION")
            if (am.isInLockTaskMode) LOCKED else NONE
        }
    }

    companion object {
        private const val TAG = "KioskMode"

        /** Ayarlar'a cikis: uygulama silme ve sifirlama KAPALI kalir. */
        private const val OPERATOR_PASSWORD = "482910"

        /** Kurtarma: cihaz sahipligi tamamen birakilir. */
        private const val RECOVERY_PASSWORD = "905174"

        private const val NONE = ActivityManager.LOCK_TASK_MODE_NONE
        private const val LOCKED = ActivityManager.LOCK_TASK_MODE_LOCKED
    }
}
