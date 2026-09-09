@echo off
setlocal EnableExtensions EnableDelayedExpansion

title TUPRAG Guvenlik Uygulamasi - Tablet Kiosk Kurulumu

rem ============================================================
rem  Bu script IKI durumu birden ele alir:
rem
rem    YENI KURULUM - tablet fabrika ayarlarinda, hesap yok.
rem                   APK kurulur ve cihaz sahipligi atanir.
rem
rem    GUNCELLEME   - tablet zaten kiosk modunda.
rem                   Yalnizca APK yenilenir; cihaz sahipligi zaten
rem                   atanmis oldugu icin o adim ATLANIR. Formata veya
rem                   hesap silmeye gerek yoktur.
rem
rem  Ayrimi 2. adim yapar. Eskiden bu ayrim yoktu ve zaten kiosk olan
rem  bir tablette script "device owner is already set" ile duruyordu -
rem  APK kurulmus olmasina ragmen kurulum basarisiz gorunuyordu.
rem
rem  DIKKAT: PACKAGE ve DEVICE_ADMIN degerleri uygulamanin
rem  manifestindeki degerlerle BIREBIR ayni olmali.
rem
rem  Ekran kilidi izin listesi (setLockTaskPackages) BILEREK burada
rem  ayarlanmiyor: "adb shell dpm set-lock-task-packages" diye bir alt
rem  komut YOK, oyle bir satir sessizce hicbir sey yapmaz ve kurulumun
rem  dogru bittigi yanilsamasi yaratir. O is uygulamanin kendi kodunda
rem  (KioskPolicy.applyAll) yapiliyor; bu script uygulamayi baslatip
rem  [8/8] adiminda sonucu DOGRULUYOR.
rem ============================================================

set "PACKAGE=com.tuprag.onoffswitch"
set "DEVICE_ADMIN=%PACKAGE%/.KioskDeviceAdminReceiver"
set "BOOTSTRAP_ACTIVITY=%PACKAGE%/.KioskBootstrapActivity"
set "MAIN_ACTIVITY=%PACKAGE%/.MainActivity"
set "START_STATUS=%TEMP%\tuprag-kiosk-start-%RANDOM%-%RANDOM%.txt"
set "LOCK_STATUS=%TEMP%\tuprag-kiosk-lock-%RANDOM%-%RANDOM%.txt"

rem adb: once klasordeki platform-tools, sonra sistemdekiler
set "ADB=%~dp0platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=C:\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" (
  echo.
  echo [HATA] adb.exe bulunamadi.
  echo   Bu klasorde su dosya olmali: platform-tools\adb.exe
  echo.
  pause
  exit /b 1
)

rem APK: tuprag.apk veya tuprag-*.apk
set "APK="
if exist "%~dp0tuprag.apk" set "APK=%~dp0tuprag.apk"
if not defined APK (
  for %%F in ("%~dp0tuprag-*.apk") do (
    set "APK=%%~fF"
    goto apk_ok
  )
)
:apk_ok
if not defined APK (
  echo.
  echo [HATA] APK bulunamadi.
  echo   Bu klasore tuprag.apk koyun:
  echo   %~dp0
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   TUPRAG GUVENLIK UYGULAMASI - TABLET KIOSK KURULUMU
echo ============================================================
echo.
echo   adb : %ADB%
echo   apk : %APK%
echo.
echo   YENI bir tablet kuruyorsaniz once sunlar hazir olmali:
echo     - Fabrika ayarlarina sifirlanmis
echo     - Google / Samsung hesabi EKLENMEMIS
echo     - Ekran kilidi ^(PIN, desen, parmak izi^) YOK
echo.
echo   Her iki durumda da:
echo     - Gelistirici secenekleri ve USB hata ayiklama ACIK
echo     - USB kablo bagli, "Bu bilgisayara guven" ONAYLANMIS
echo.
echo   Tablet ZATEN kiosk modundaysa yalnizca uygulama guncellenir;
echo   formata gerek yoktur.
echo.
pause

echo.
echo [1/8] Tablet baglantisi kontrol ediliyor...
rem Sunucuyu once baslat: ilk komut daemon'u ayaga kaldirirken cihaz
rem numaralandirmasi henuz bitmemis olabiliyor ve yanlis "cihaz yok"
rem hatasi uretiyordu.
"%ADB%" start-server 1>nul 2>nul
rem Bekleme icin "timeout" KULLANILMIYOR: stdin bir konsol degilse
rem ("Input redirection is not supported") aninda hata verip toplu isi
rem bozuyor. ping her ortamda calisir.
ping -n 4 127.0.0.1 >nul 2>&1

rem Durumu tek tek ayirt et: her biri farkli bir cozum gerektiriyor.
"%ADB%" devices 2>nul | findstr /I "unauthorized" >nul
if not errorlevel 1 (
  echo   [HATA] Tablet YETKILENDIRILMEMIS.
  echo.
  echo   Tabletin ekranina bakin: "USB hata ayiklamaya izin verilsin mi?"
  echo   sorusu duruyor olmali.
  echo     1. "Bu bilgisayardan her zaman izin ver" kutusunu isaretleyin
  echo     2. IZIN VER deyin
  echo     3. Bu scripti tekrar calistirin
  echo.
  echo   Soru hic cikmadiysa: Gelistirici secenekleri ^> "USB hata ayiklama
  echo   yetkilerini sifirla" deyip kabloyu cikarip takin.
  echo.
  pause
  exit /b 1
)

"%ADB%" devices 2>nul | findstr /I "offline" >nul
if not errorlevel 1 (
  echo   [HATA] Tablet CEVRIMDISI gorunuyor.
  echo   Kablo veya port kararsiz. Baska bir kablo ve dogrudan anakart
  echo   uzerindeki bir USB portu deneyin ^(USB hub kullanmayin^).
  echo.
  pause
  exit /b 1
)

"%ADB%" get-state 1>nul 2>nul
if errorlevel 1 (
  echo   [HATA] Tablet HIC gorunmuyor.
  echo.
  echo   Bu genellikle ADB veya surucu sorunu DEGILDIR. Sirayla deneyin:
  echo.
  echo     1. KABLO. Sadece sarj eden kablolar veri tasimaz - en sik sebep
  echo        budur. Veri aktarmakta kullandiginizi bildiginiz bir kabloyla
  echo        deneyin.
  echo.
  echo     2. TABLETTEKI USB MODU. Kabloyu taktiktan sonra tablette cikan
  echo        USB bildirimine dokunun ve "Dosya aktarimi" ^(MTP^) secin.
  echo        "Sadece sarj" modunda tablet bilgisayara hic gorunmez.
  echo.
  echo     3. PORT. Anakart uzerindeki bir porta dogrudan takin.
  echo        Hub, dock ve on panel portlari sorun cikarabiliyor.
  echo.
  echo     4. Tabletin acik ve ekraninin kilitsiz oldugundan emin olun.
  echo.
  "%ADB%" devices
  echo.
  pause
  exit /b 1
)
echo   OK

echo.
echo [2/8] Mevcut kurulum durumu belirleniyor...
rem "dpm list-owners" kullaniliyor, "dumpsys device_policy" DEGIL:
rem dumpsys ciktisinda sahip HIC YOKKEN bile "Device Owner Type: -1"
rem satiri bulunuyor ve duz bir "Device Owner" aramasi yanlis pozitif
rem veriyor. list-owners sahip yokken tam olarak "no owners" yazar.
set "MODE=YENI"
"%ADB%" shell dpm list-owners 2>nul | findstr /I /C:"%PACKAGE%" >nul
if not errorlevel 1 goto mode_update

"%ADB%" shell dpm list-owners 2>nul | findstr /I /C:"no owners" >nul
if not errorlevel 1 goto mode_done

echo   [HATA] Cihaz sahibi BASKA bir uygulama.
echo   Bu tablete daha once baska bir kiosk uygulamasi kurulmus.
echo   Mevcut sahip:
"%ADB%" shell dpm list-owners
echo.
echo   Fabrika ayarlarina donmeden bu uygulama kurulamaz.
echo.
pause
exit /b 1

:mode_update
set "MODE=GUNCELLEME"

:mode_done
echo   Mod: !MODE!

if "!MODE!"=="GUNCELLEME" goto skip_account_check

echo.
echo [3/8] Cihazda hesap var mi kontrol ediliyor...
rem Device Owner yalnizca HIC hesap eklenmemis cihaza atanabilir.
rem Bu kontrol olmadan hata 5. adimda ortaya cikiyor ve tablete bastan
rem format atmak gerekiyor - kurulumun en sik zaman kaybi buydu.
"%ADB%" shell dumpsys account 2>nul | findstr /C:"Account {" >nul
if not errorlevel 1 (
  echo   [HATA] Tablette en az bir hesap tanimli.
  echo   Device Owner atanamaz. Yapilmasi gereken:
  echo     1. Ayarlar ^> Genel yonetim ^> Sifirla ^> Fabrika ayarlari
  echo     2. Kurulum sihirbazinda Google hesabini ATLAYIN
  echo     3. Bu scripti tekrar calistirin
  echo.
  pause
  exit /b 1
)
echo   OK - hesap yok
goto account_done

:skip_account_check
echo.
echo [3/8] Hesap kontrolu atlandi ^(guncelleme modu^).

:account_done

echo.
echo [4/8] Uygulama kuruluyor...
"%ADB%" install -r "%APK%"
if errorlevel 1 (
  echo   [HATA] APK kurulamadi.
  echo   Imza uyusmazligi olabilir: tablette farkli bir anahtarla
  echo   imzalanmis bir surum varsa once onu kaldirmak gerekir.
  echo.
  pause
  exit /b 1
)
echo   OK

echo.
if "!MODE!"=="GUNCELLEME" (
  echo [5/8] Cihaz sahipligi zaten atanmis, atlaniyor.
  goto owner_done
)

echo [5/8] Cihaz sahipligi ^(Device Owner^) ataniyor...
"%ADB%" shell dpm set-device-owner %DEVICE_ADMIN%
if errorlevel 1 (
  echo   [HATA] Device Owner atanamadi.
  echo   En sik sebep: cihazda hesap var veya daha once baska bir
  echo   yonetici atanmis. Fabrika ayarlarina donup tekrar deneyin.
  echo.
  pause
  exit /b 1
)
echo   OK

:owner_done

echo.
echo [6/8] Sarjdayken ekran acik kalacak sekilde ayarlaniyor...
"%ADB%" shell settings put global stay_on_while_plugged_in 3
echo   OK

echo.
echo [7/8] Guvenli bootstrap baslatiliyor...
rem MainActivity ASLA dogrudan baslatilmaz. Bootstrap once device-owner
rem politikasini ve isLockTaskPermitted sonucunu dogrular, sonra dashboard'u
rem ActivityOptions.setLockTaskEnabled ile kilitli acar.
"%ADB%" shell am force-stop %PACKAGE%
if errorlevel 1 (
  echo   [HATA] Eski uygulama sureci durdurulamadi.
  pause
  exit /b 1
)

set "LOCK_READY=0"
set "BOOTSTRAP_ATTEMPT=0"

:bootstrap_retry
set /a BOOTSTRAP_ATTEMPT+=1
echo   Deneme !BOOTSTRAP_ATTEMPT!/15
"%ADB%" shell am start -W -n %BOOTSTRAP_ACTIVITY% >"%START_STATUS%" 2>&1
if errorlevel 1 goto bootstrap_start_failed
findstr /I /C:"Error:" /C:"Exception" "%START_STATUS%" >nul
if not errorlevel 1 goto bootstrap_start_failed

rem Android 14+ politika sonucu sisteme kisa bir gecikmeyle yerlesebilir.
rem Sabit uzun bekleme yerine gercek LOCKED durumunu gozlemliyoruz.
ping -n 2 127.0.0.1 >nul 2>&1
"%ADB%" shell dumpsys activity activities >"%LOCK_STATUS%" 2>nul
findstr /I /C:"mLockTaskModeState=LOCKED" "%LOCK_STATUS%" >nul
if not errorlevel 1 goto bootstrap_ready

findstr /I /C:"mLockTaskModeState=PINNED" "%LOCK_STATUS%" >nul
if not errorlevel 1 goto bootstrap_pinned

if !BOOTSTRAP_ATTEMPT! LSS 15 goto bootstrap_retry

echo   [HATA] Uygulama 15 denemede gercek LOCKED moduna giremedi.
echo   Dashboard guvenli olmadigi icin kurulum durduruldu.
del /Q "%START_STATUS%" "%LOCK_STATUS%" 1>nul 2>nul
pause
exit /b 1

:bootstrap_start_failed
echo   [HATA] Guvenli bootstrap baslatilamadi.
type "%START_STATUS%"
del /Q "%START_STATUS%" "%LOCK_STATUS%" 1>nul 2>nul
pause
exit /b 1

:bootstrap_pinned
echo   [HATA] Guvensiz PINNED ekran sabitleme durumu algilandi.
echo   Bu durum kiosk olarak kabul edilmez ve tablet sahaya verilemez.
del /Q "%START_STATUS%" "%LOCK_STATUS%" 1>nul 2>nul
pause
exit /b 1

:bootstrap_ready
set "LOCK_READY=1"
del /Q "%START_STATUS%" 1>nul 2>nul
echo   OK - gercek LOCKED modu dogrulandi

echo.
echo [8/8] Dogrulama...
rem Buradaki komutlarin hepsi GERCEK komutlar. "dpm is-device-owner-app" ve
rem "dpm set-lock-task-packages" gibi var olmayan alt komutlar sessizce
rem basarisiz olur ve kurulumun dogru bittigi yanilsamasini yaratir.
set "FAIL=0"

echo   - Cihaz sahipligi:
"%ADB%" shell dpm list-owners 2>nul | findstr /I /C:"%PACKAGE%" >nul
if errorlevel 1 (
  echo       BASARISIZ - cihaz sahibi bu uygulama degil
  set "FAIL=1"
) else (
  echo       TAMAM
)

echo   - Ekran kilidi ^(lock task^):
"%ADB%" shell dumpsys activity activities >"%LOCK_STATUS%" 2>nul
findstr /I /C:"mLockTaskModeState=LOCKED" "%LOCK_STATUS%" >nul
if errorlevel 1 (
  findstr /I /C:"mLockTaskModeState=PINNED" "%LOCK_STATUS%" >nul
  if not errorlevel 1 (
    echo       BASARISIZ - PINNED guvenli kiosk degildir
  ) else (
    echo       BASARISIZ - uygulama LOCKED modunda degil
  )
  set "FAIL=1"
) else (
  echo       TAMAM - LOCKED
)

echo   - On plandaki guvenli dashboard:
findstr /I /C:"%PACKAGE%/.MainActivity" "%LOCK_STATUS%" >nul
if errorlevel 1 (
  echo       BASARISIZ - MainActivity on planda degil
  set "FAIL=1"
) else (
  echo       TAMAM
)

echo   - Ana ekran uygulamasi:
"%ADB%" shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME 2>nul | findstr /I /C:"%PACKAGE%" | findstr /I /C:"KioskBootstrapActivity" >nul
if errorlevel 1 (
  echo       BASARISIZ - acilista bu uygulama gelmez
  set "FAIL=1"
) else (
  echo       TAMAM
)

del /Q "%LOCK_STATUS%" 1>nul 2>nul

echo.
if "!FAIL!"=="1" (
  echo ============================================================
  echo   KURULUM DOGRULANAMADI
  echo ============================================================
  echo   Bu tablet SAHAYA VERILMEMELIDIR.
  echo.
  echo   Teshis icin:
  echo     "%ADB%" logcat -s KioskMode KioskPolicy KioskAdmin KioskBootstrap
  echo.
  pause
  exit /b 1
)

echo ============================================================
if "!MODE!"=="GUNCELLEME" (
  echo   GUNCELLEME TAMAM
) else (
  echo   KURULUM TAMAM
)
echo ============================================================
echo.
echo   Ekran kilidi devrede. Ana ekran, son uygulamalar, bildirim
echo   paneli ve guc menusu kapali. Tablet acilip kapandiginda
echo   dogrudan uygulama gelir.
echo.
echo   Uygulamadan cikis: ekranin SOL UST kosesine 3 saniye icinde
echo   5 kez dokunun, ardindan yetkili parolasini girin. Uygulama
echo   tekrar acildiginda kendini yeniden kiosk'a alir.
echo.
echo   USB kabloyu cikarip tableti teslim edebilirsiniz.
echo.
pause
exit /b 0
