package com.nimo.nimo_arizabakim

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
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
                    "installUpdate" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("INVALID_ARGUMENTS", "APK yolu eksik.", null)
                        } else {
                            // Play Protect'in kurulum-oncesi dogrulama ekrani
                            // (PlayProtectDialogsActivity) PackageInstaller
                            // callback zincirinin DISINDA, sistem tarafindan
                            // dogrudan acilmaya calisiliyor — bize
                            // STATUS_PENDING_USER_ACTION olarak hic haber
                            // gelmiyor. Ekran kilitliyken acilamayip session
                            // 75 saniye sonra INSTALL_FAILED_VERIFICATION_FAILURE
                            // ile reddediliyordu. Kilit bu yuzden onay
                            // istegini beklemeden, kurulumdan ONCE kaldirilir;
                            // onResume() kurulum bitince (basarili ya da
                            // basarisiz) otomatik geri kurar.
                            if (KioskPolicy.isDeviceOwner(this)) {
                                runCatching { stopLockTask() }
                                    .onFailure { Log.w(TAG, "Kilit kaldirilamadi", it) }
                            }
                            // ~85 MB oturuma kopyalanir; ana is parcaciginda
                            // yapilirsa arayuz donar.
                            Thread {
                                val outcome = runCatching { ApkInstaller.install(this, path) }
                                runOnUiThread {
                                    outcome
                                        .onSuccess { result.success(true) }
                                        .onFailure { result.error("INSTALL_FAILED", it.message, null) }
                                }
                            }.start()
                        }
                    }
                    "installedVersionCode" ->
                        result.success(ApkInstaller.installedVersionCode(this))
                    "consumeInstallError" -> result.success(ApkInstaller.consumeError(this))
                    else -> result.notImplemented()
                }
            }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handlePendingInstallConfirmation()
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
        // Bekleyen bir kurulum onay ekrani varsa kilit dahil edilmeden once
        // acilmasina izin ver; aksi halde Play Protect ekrani lock-task
        // ihlaliyle sessizce engellenir (bkz. ApkInstaller).
        if (handlePendingInstallConfirmation()) return
        enterLockTask()
    }

    /**
     * [ApkInstaller]'in ilettigi kurulum onay ekranini acar. Sistemin kendi
     * ekranini gosterebilmesi icin kilit GECICI olarak kaldirilir; ekran
     * kapanip buraya donulunce onResume() kilidi otomatik yeniden kurar.
     *
     * @return bir onay ekrani acildiysa true (bu durumda [enterLockTask]
     *   cagrilmamali).
     */
    private fun handlePendingInstallConfirmation(): Boolean {
        val confirm = intent?.getParcelableExtraCompat(EXTRA_INSTALL_CONFIRM_INTENT) ?: return false
        intent.removeExtra(EXTRA_INSTALL_CONFIRM_INTENT)
        if (KioskPolicy.isDeviceOwner(this)) {
            runCatching { stopLockTask() }
                .onFailure { Log.w(TAG, "Kilit kaldirilamadi", it) }
        }
        confirm.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return runCatching { startActivity(confirm) }
            .onFailure { Log.e(TAG, "Kurulum onay ekrani acilamadi", it) }
            .isSuccess
    }

    private fun Intent.getParcelableExtraCompat(name: String): Intent? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            getParcelableExtra(name, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            getParcelableExtra(name)
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

        /** [ApkInstaller]'dan gelen kurulum onay ekranini tasiyan extra adi. */
        const val EXTRA_INSTALL_CONFIRM_INTENT = "install_confirm_intent"

        /** Ayarlar'a cikis: uygulama silme ve sifirlama KAPALI kalir. */
        private const val OPERATOR_PASSWORD = "482910"

        /** Kurtarma: cihaz sahipligi tamamen birakilir. */
        private const val RECOVERY_PASSWORD = "905174"

        private const val NONE = ActivityManager.LOCK_TASK_MODE_NONE
        private const val LOCKED = ActivityManager.LOCK_TASK_MODE_LOCKED
    }
}
