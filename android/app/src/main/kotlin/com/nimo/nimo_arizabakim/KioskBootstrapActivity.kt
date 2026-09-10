package com.nimo.nimo_arizabakim

import android.app.Activity
import android.app.ActivityOptions
import android.content.Intent
import android.os.Bundle
import android.util.Log

/**
 * Kalici ana ekran (HOME) bileseni ve guvenli baslangic noktasi.
 *
 * MainActivity asla dogrudan baslatilmaz. Bu aktivite once device-owner
 * politikasini uygular ve `isLockTaskPermitted` sonucunu dogrular, sonra
 * arayuzu `ActivityOptions.setLockTaskEnabled` ile KILITLI acar.
 *
 * Boylece tablet acildiginda, ana ekran tusuna basildiginda ve Ayarlar'dan
 * donuldugunde her seferinde ayni dogrulanmis yoldan gecilir.
 *
 * Cihaz sahibi atanmamissa (gelistirme makinesi, `flutter run`) uygulama
 * kilitsiz acilir; boylece gunluk gelistirme bozulmaz.
 */
class KioskBootstrapActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        launchDashboard()
        finish()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        launchDashboard()
        finish()
    }

    private fun launchDashboard() {
        val deviceOwner = KioskPolicy.isDeviceOwner(this)

        // Ayarlar modunda politikayi sifirlamiyoruz: kullanici Ayarlar'dan
        // ana ekran tusuyla buraya dusmus olabilir, izin listesi korunur.
        if (deviceOwner && !KioskPolicy.isSettingsMode(this)) {
            KioskPolicy.applyAll(this)
        }

        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val locked = deviceOwner && KioskPolicy.isLockTaskPermitted(this)
        if (!locked) {
            Log.w(TAG, "Kilitli mod kullanilamiyor; uygulama normal aciliyor")
            startActivity(intent)
            return
        }

        val options = ActivityOptions.makeBasic().apply { setLockTaskEnabled(true) }
        runCatching { startActivity(intent, options.toBundle()) }
            .onFailure {
                Log.e(TAG, "Kilitli baslatma basarisiz; normal aciliyor", it)
                startActivity(intent)
            }
    }

    companion object {
        private const val TAG = "KioskBootstrap"
    }
}
