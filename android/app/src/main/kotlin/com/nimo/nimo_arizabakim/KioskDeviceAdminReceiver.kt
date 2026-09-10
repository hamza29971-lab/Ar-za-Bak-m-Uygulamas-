package com.nimo.nimo_arizabakim

import android.app.admin.DeviceAdminReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Cihaz yoneticisi alicisi.
 *
 * `adb shell dpm set-device-owner com.nimo.nimo_arizabakim/.KioskDeviceAdminReceiver`
 * komutu bu sinifi hedefler. Sahiplik atandigi anda kiosk politikasi
 * uygulanir; boylece tablet kurulum scriptinden sonra elle bir islem
 * gerektirmeden kilitli hale gelir.
 */
class KioskDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Cihaz yoneticisi etkinlestirildi")
        KioskPolicy.applyAll(context)
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.w(TAG, "Cihaz yoneticisi devre disi birakildi")
    }

    /**
     * Device owner uygulamasinin kaldirilmasi engellenir. Kullanici
     * kurtarma parolasi ile sahipligi birakmadan uygulama silinemez.
     */
    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        return "Bu uygulama tabletin kiosk yoneticisidir. Kaldirmak icin " +
            "uygulama icinden yonetici parolasi ile cikis yapin."
    }

    companion object {
        private const val TAG = "KioskAdmin"

        fun componentName(context: Context): ComponentName =
            ComponentName(context.applicationContext, KioskDeviceAdminReceiver::class.java)
    }
}
