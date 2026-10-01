package com.nimo.nimo_arizabakim

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.os.Build
import android.util.Log
import java.io.File

/**
 * OTA guncellemesini sistem yukleyici ekranini ACMADAN kurar.
 *
 * Kiosk (lock task) modunda paket yukleyici etkinligi acilamaz: izin
 * listesinde yalnizca bu uygulama var. Device owner ise PackageInstaller
 * oturumuyla kullanici onayi olmadan kurabilir. Kendini guncellerken surec
 * sonlandirilir; kalici ana ekran atamasi ve [PackageReplacedReceiver]
 * uygulamayi yeniden acar.
 */
object ApkInstaller {

    private const val TAG = "ApkInstaller"
    private const val PREFS = "nimo_update"
    private const val KEY_LAST_ERROR = "last_error"

    /** Kurulumu baslatir; sonuc [InstallResultReceiver]'a asenkron gelir. */
    fun install(context: Context, apkPath: String) {
        val apk = File(apkPath)
        require(apk.isFile) { "APK bulunamadi: $apkPath" }
        clearError(context)

        val installer = context.packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL,
        ).apply {
            setAppPackageName(context.packageName)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
            }
        }

        val sessionId = installer.createSession(params)
        try {
            installer.openSession(sessionId).use { session ->
                apk.inputStream().use { input ->
                    session.openWrite("base.apk", 0, apk.length()).use { output ->
                        input.copyTo(output)
                        session.fsync(output)
                    }
                }
                // Sistem sonuc bilgisini bu intent'e ekledigi icin API 31+'da
                // MUTABLE olmak zorunda.
                val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0)
                val callback = PendingIntent.getBroadcast(
                    context,
                    sessionId,
                    Intent(context, InstallResultReceiver::class.java),
                    flags,
                )
                session.commit(callback.intentSender)
            }
            Log.i(TAG, "Kurulum oturumu gonderildi: $sessionId")
        } catch (e: Exception) {
            runCatching { installer.abandonSession(sessionId) }
            throw e
        }
    }

    /** Kurulu uygulamanin versionCode'u (pubspec'teki +N). */
    fun installedVersionCode(context: Context): Long {
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
    }

    /** Son basarisiz kurulumun mesajini dondurur ve siler. */
    fun consumeError(context: Context): String? {
        val prefs = context.prefs()
        val error = prefs.getString(KEY_LAST_ERROR, null)
        if (error != null) prefs.edit().remove(KEY_LAST_ERROR).apply()
        return error
    }

    internal fun recordError(context: Context, message: String) {
        context.prefs().edit().putString(KEY_LAST_ERROR, message).apply()
    }

    private fun clearError(context: Context) {
        context.prefs().edit().remove(KEY_LAST_ERROR).apply()
    }

    private fun Context.prefs() =
        applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}

/** PackageInstaller oturumunun sonucu. */
class InstallResultReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        val detail = intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)

        when (status) {
            PackageInstaller.STATUS_SUCCESS -> Log.i(TAG, "Guncelleme kuruldu")

            // Android sessiz kurulumu reddedip kullanici onayi istedi. En sik
            // sebep: Play Protect'in kurulum-oncesi dogrulamasi imzayi
            // taniyamiyor (verdict=3) ve kendi onay ekranini
            // (PlayProtectDialogsActivity) acmaya calisiyor. Cihaz sahibi
            // olarak bu dogrulamayi kapatmak mumkun degil (Android
            // "device owners cannot update package_verifier_enable" diyerek
            // reddediyor); o yuzden ekran acilsin diye kiosk kilidi GECICI
            // olarak kaldirilir. Ekran kapanip MainActivity'ye donuldugunde
            // onResume() kilidi kendiliginden geri kurar.
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val deviceOwner = KioskPolicy.isDeviceOwner(context)
                val confirm = confirmationIntent(intent)
                Log.w(TAG, "Kurulum onay istedi: deviceOwner=$deviceOwner")

                if (confirm == null) {
                    ApkInstaller.recordError(context, "Kurulum onay ekranı hazırlanamadı.")
                    return
                }
                if (!deviceOwner) {
                    ApkInstaller.recordError(
                        context,
                        "Bu tablette sessiz kurulum izni yok: uygulama cihaz sahibi (device owner) " +
                            "değil. Tabletin kiosk kurulumu kurulum script'iyle yeniden yapılmalı.",
                    )
                    return
                }
                // MainActivity zaten on planda (kullanici az once "Guncelle"ye
                // bastigi icin); confirm intent'i ona iletip kilidi orada
                // kaldiriyoruz. BroadcastReceiver'in kendi context'i bir
                // Activity olmadigi icin stopLockTask() burada cagrilamaz.
                val relay = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    putExtra(MainActivity.EXTRA_INSTALL_CONFIRM_INTENT, confirm)
                }
                runCatching { context.startActivity(relay) }
                    .onFailure {
                        Log.e(TAG, "Onay ekrani acilamadi", it)
                        ApkInstaller.recordError(context, "Kurulum onay ekranı açılamadı.")
                    }
            }

            else -> {
                Log.e(TAG, "Guncelleme kurulamadi: durum=$status, ayrinti=$detail")
                ApkInstaller.recordError(context, messageFor(status, detail))
            }
        }
    }

    private fun confirmationIntent(intent: Intent): Intent? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_INTENT)
        }

    // Android birden fazla nedeni ayni durum koduyla bildiriyor (or. surum
    // dusurme de STATUS_FAILURE_INVALID geliyor); once ayrintiya bakilir.
    private fun messageFor(status: Int, detail: String?): String = when {
        detail?.contains("VERSION_DOWNGRADE") == true ->
            "Sunucudaki güncelleme dosyası tablettekinden daha eski bir sürüm " +
                "(version.json ile yüklenen APK'nın sürüm numarası uyuşmuyor)."
        detail?.contains("UPDATE_INCOMPATIBLE") == true ||
            detail?.contains("SIGNATURE") == true ->
            "Güncelleme farklı bir imza anahtarıyla imzalanmış; ortak anahtarla (nimo-release.jks) derlenmeli."
        detail?.contains("NO_MATCHING_ABIS") == true ->
            "Güncelleme bu tabletin işlemci mimarisiyle uyumsuz."
        else -> messageForStatus(status)
    }

    private fun messageForStatus(status: Int): String = when (status) {
        PackageInstaller.STATUS_FAILURE_INCOMPATIBLE ->
            "Güncelleme bu tabletteki sürümle uyumsuz (imza anahtarı farklı ya da sürüm daha eski)."
        PackageInstaller.STATUS_FAILURE_STORAGE -> "Tablette yeterli depolama alanı yok."
        PackageInstaller.STATUS_FAILURE_BLOCKED -> "Kurulum cihaz tarafından engellendi."
        PackageInstaller.STATUS_FAILURE_INVALID -> "İndirilen güncelleme dosyası geçersiz (bozuk ya da tamamlanmamış olabilir)."
        PackageInstaller.STATUS_FAILURE_ABORTED -> "Kurulum iptal edildi."
        else -> "Güncelleme kurulamadı (kod $status)."
    }

    companion object {
        private const val TAG = "InstallResultReceiver"
    }
}

/** Uygulama kendini guncelledikten sonra arayuzu yeniden acar. */
class PackageReplacedReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_MY_PACKAGE_REPLACED) return
        Log.i("PackageReplaced", "Guncelleme sonrasi uygulama yeniden aciliyor")
        val launch = Intent(context, KioskBootstrapActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        runCatching { context.startActivity(launch) }
    }
}
