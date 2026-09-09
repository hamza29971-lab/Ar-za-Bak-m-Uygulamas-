package com.nimo.nimo_arizabakim

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.UserManager
import android.provider.Settings
import android.util.Log

/**
 * Kiosk (device-owner) politikasinin tek merkezi.
 *
 * Kurulum scripti yalnizca `dpm set-device-owner` calistirir; ekran kilidi
 * izin listesi, kalici ana ekran ve kullanici kisitlamalari BURADA
 * uygulanir. ("adb shell dpm set-lock-task-packages" diye bir alt komut
 * yoktur; scriptten yapilmaya calisilirsa sessizce hicbir sey olmaz.)
 */
object KioskPolicy {

    private const val TAG = "KioskPolicy"

    private const val PREFS = "nimo_kiosk"

    /** Kullanici 482910 ile Ayarlar'a cikti mi? */
    private const val KEY_SETTINGS_MODE = "settings_mode"

    /** Ayarlar uygulamasinin paket adi (AOSP ve Samsung'da ayni). */
    private const val SETTINGS_PACKAGE = "com.android.settings"

    /**
     * Cihaz sahipligi durdugu surece yerinde kalan kisitlamalar.
     *
     * 482910 ile Ayarlar'a cikildiginda bunlar KALDIRILMAZ: kullanici
     * Ayarlar'i gezebilir ama uygulamayi silemez, tableti sifirlayamaz,
     * guvenli modda acamaz, ikinci kullanici ekleyemez.
     *
     * DISALLOW_DEBUGGING_FEATURES bilerek YOK: ADB kapanirsa kurulum
     * scripti bir daha guncelleme yapamaz.
     */
    private val LOCKED_RESTRICTIONS = listOf(
        UserManager.DISALLOW_FACTORY_RESET,
        UserManager.DISALLOW_UNINSTALL_APPS,
        UserManager.DISALLOW_APPS_CONTROL,
        UserManager.DISALLOW_ADD_USER,
        UserManager.DISALLOW_SAFE_BOOT,
    )

    fun isDeviceOwner(context: Context): Boolean {
        val dpm = context.dpm() ?: return false
        return dpm.isDeviceOwnerApp(context.packageName)
    }

    fun isSettingsMode(context: Context): Boolean =
        context.prefs().getBoolean(KEY_SETTINGS_MODE, false)

    /**
     * Tam kiosk politikasi. Device owner atandiginda, uygulama her
     * acildiginda ve Ayarlar'dan donuldugunde cagrilir.
     */
    fun applyAll(context: Context) {
        val dpm = context.dpm() ?: return
        if (!dpm.isDeviceOwnerApp(context.packageName)) {
            Log.w(TAG, "Cihaz sahibi bu uygulama degil; politika uygulanmadi")
            return
        }
        val admin = KioskDeviceAdminReceiver.componentName(context)

        restrictToApp(context)
        setPersistentHome(context, dpm, admin)

        LOCKED_RESTRICTIONS.forEach { restriction ->
            runCatching { dpm.addUserRestriction(admin, restriction) }
                .onFailure { Log.w(TAG, "Kisitlama uygulanamadi: $restriction", it) }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            runCatching { dpm.setStatusBarDisabled(admin, true) }
            runCatching { dpm.setKeyguardDisabled(admin, true) }
        }
        // Sarjdayken ekran kapanmasin (kurulum scriptindeki ayarin kalicisi).
        runCatching {
            dpm.setGlobalSetting(admin, Settings.Global.STAY_ON_WHILE_PLUGGED_IN, "3")
        }
        Log.i(TAG, "Kiosk politikasi uygulandi")
    }

    /** Ekran kilidi yalnizca bu uygulamaya izin verir. */
    fun restrictToApp(context: Context) {
        val dpm = context.dpm() ?: return
        if (!dpm.isDeviceOwnerApp(context.packageName)) return
        val admin = KioskDeviceAdminReceiver.componentName(context)
        runCatching { dpm.setLockTaskPackages(admin, arrayOf(context.packageName)) }
            .onFailure { Log.e(TAG, "Lock task izin listesi yazilamadi", it) }
        context.prefs().edit().putBoolean(KEY_SETTINGS_MODE, false).apply()
    }

    /**
     * 482910 modunun kalbi.
     *
     * Ekran kilidinden CIKILMAZ; yalnizca Ayarlar izin listesine eklenir.
     * Boylece kullanici Ayarlar'i acabilir, ama ana ekrana, son
     * uygulamalara veya baska bir uygulamaya gecemez. Ayarlar'dan
     * cikildigi anda tablet kendiliginden bu uygulamaya doner.
     */
    fun allowSettings(context: Context): Boolean {
        val dpm = context.dpm() ?: return false
        if (!dpm.isDeviceOwnerApp(context.packageName)) return false
        val admin = KioskDeviceAdminReceiver.componentName(context)
        return runCatching {
            dpm.setLockTaskPackages(admin, arrayOf(context.packageName, SETTINGS_PACKAGE))
            context.prefs().edit().putBoolean(KEY_SETTINGS_MODE, true).apply()
            true
        }.getOrElse {
            Log.e(TAG, "Ayarlar izin listesine eklenemedi", it)
            false
        }
    }

    /** Ayarlar ekranini acar. Once [allowSettings] cagrilmis olmalidir. */
    fun openSettings(context: Context) {
        val intent = Intent(Settings.ACTION_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        runCatching { context.startActivity(intent) }
            .onFailure { Log.e(TAG, "Ayarlar acilamadi", it) }
    }

    /**
     * 905174 modu: cihaz sahipliginden tamamen cikar.
     *
     * Bundan sonra uygulama silinebilir ve tablet fabrika ayarlarina
     * dondurulebilir. Geri donusu yoktur; tableti yeniden kiosk'a almak
     * icin kurulum scripti bastan calistirilmalidir.
     */
    fun releaseOwnership(context: Context): Boolean {
        val dpm = context.dpm() ?: return false
        if (!dpm.isDeviceOwnerApp(context.packageName)) return true
        val admin = KioskDeviceAdminReceiver.componentName(context)

        LOCKED_RESTRICTIONS.forEach { restriction ->
            runCatching { dpm.clearUserRestriction(admin, restriction) }
                .onFailure { Log.w(TAG, "Kisitlama kaldirilamadi: $restriction", it) }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            runCatching { dpm.setStatusBarDisabled(admin, false) }
            runCatching { dpm.setKeyguardDisabled(admin, false) }
        }
        runCatching { dpm.clearPackagePersistentPreferredActivities(admin, context.packageName) }
        runCatching { dpm.setLockTaskPackages(admin, emptyArray()) }
        context.prefs().edit().putBoolean(KEY_SETTINGS_MODE, false).apply()

        return runCatching {
            @Suppress("DEPRECATION")
            dpm.clearDeviceOwnerApp(context.packageName)
            Log.i(TAG, "Cihaz sahipligi birakildi")
            true
        }.getOrElse {
            Log.e(TAG, "Cihaz sahipligi birakilamadi", it)
            false
        }
    }

    /** Uygulama, ekran kilidi izin listesinde mi? */
    fun isLockTaskPermitted(context: Context): Boolean {
        val dpm = context.dpm() ?: return false
        return runCatching { dpm.isLockTaskPermitted(context.packageName) }.getOrDefault(false)
    }

    /**
     * Acilista ve ana ekran tusunda bu uygulama gelsin diye kalici ana
     * ekran atamasi. Kullanici bunu Ayarlar'dan degistiremez.
     */
    private fun setPersistentHome(
        context: Context,
        dpm: DevicePolicyManager,
        admin: ComponentName,
    ) {
        val filter = IntentFilter(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            addCategory(Intent.CATEGORY_DEFAULT)
        }
        val home = ComponentName(context.applicationContext, KioskBootstrapActivity::class.java)
        runCatching {
            dpm.clearPackagePersistentPreferredActivities(admin, context.packageName)
            dpm.addPersistentPreferredActivity(admin, filter, home)
        }.onFailure { Log.e(TAG, "Kalici ana ekran atanamadi", it) }
    }

    private fun Context.dpm(): DevicePolicyManager? =
        getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager

    private fun Context.prefs() =
        applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
