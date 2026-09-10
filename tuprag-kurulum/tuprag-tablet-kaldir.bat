@echo off
setlocal EnableExtensions

title TUPRAG Kiosk - Uygulama Kaldirma

rem ============================================================
rem  Device owner olan bir uygulama ADB ile dogrudan silinemez.
rem  Once uygulamanin kendi kurtarma parolasi ile cihaz sahipligi
rem  birakilir, ardindan bu script adb uninstall calistirir.
rem ============================================================

set "PACKAGE=com.tuprag.onoffswitch"
set "OWNER_STATUS=%TEMP%\tuprag-kiosk-owner-%RANDOM%-%RANDOM%.txt"
set "ADB=%~dp0platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=C:\platform-tools\adb.exe"
if not exist "%ADB%" set "ADB=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
if not exist "%ADB%" (
  echo [HATA] adb.exe bulunamadi.
  pause
  exit /b 1
)

echo.
echo ============================================================
echo   TUPRAG KIOSK - UYGULAMA KALDIRMA
echo ============================================================
echo.

"%ADB%" get-state 1>nul 2>nul
if errorlevel 1 (
  echo [HATA] Tablet gorunmuyor.
  echo USB hata ayiklamanin acik oldugunu ve USB kablosunu kontrol edin.
  pause
  exit /b 1
)

echo [1/4] Uygulama kontrol ediliyor...
"%ADB%" shell pm list packages %PACKAGE% 2>nul | findstr /I /C:"package:%PACKAGE%" >nul
if errorlevel 1 (
  echo [BILGI] Uygulama tablette zaten kurulu degil.
  pause
  exit /b 0
)
echo [TAMAM] Uygulama tablette kurulu.

echo.
echo [2/4] Cihaz sahipligi kontrol ediliyor...
"%ADB%" shell dpm list-owners 1>"%OWNER_STATUS%" 2>nul
findstr /I /C:"%PACKAGE%" "%OWNER_STATUS%" >nul
if not errorlevel 1 (
  echo [UYARI] Uygulama halen DEVICE OWNER durumunda.
  echo Android, device owner uygulamasinin ADB ile silinmesine izin vermez.
  echo.
  echo Simdi tablette su adimlari uygulayin:
  echo   1. Uygulamayi acin.
  echo   2. Sol ust koseye 3 saniye icinde 5 kez dokunun.
  echo   3. Normal cikis parolasi yerine KURTARMA parolasini girin.
  echo   4. KIOSK KORUMASI KALDIRILDI mesajini bekleyin.
  echo Yalnizca ana ekrana donulmesi yeterli degildir.
  echo.
  echo Script uygulamayi on plana getirmeyi deniyor...
  "%ADB%" shell monkey -p %PACKAGE% -c android.intent.category.LAUNCHER 1 1>nul 2>nul
  echo.
  pause

  echo.
  echo Cihaz sahipligi yeniden kontrol ediliyor...
  "%ADB%" shell dpm list-owners 1>"%OWNER_STATUS%" 2>nul
  findstr /I /C:"%PACKAGE%" "%OWNER_STATUS%" >nul
  if not errorlevel 1 (
    echo [HATA] Device owner sahipligi halen devam ediyor.
    echo Normal cikis parolasi degil, KURTARMA parolasi kullanilmalidir.
    echo KIOSK KORUMASI KALDIRILDI mesaji gorulmeden devam etmeyin.
    echo Uygulama kaldirilmadi.
    echo.
    type "%OWNER_STATUS%"
    del /Q "%OWNER_STATUS%" 1>nul 2>nul
    pause
    exit /b 1
  )
)

del /Q "%OWNER_STATUS%" 1>nul 2>nul
echo [TAMAM] Device owner sahipligi bulunmuyor.

echo.
echo [3/4] Uygulama kaldiriliyor...
"%ADB%" shell am force-stop %PACKAGE% 1>nul 2>nul
"%ADB%" uninstall %PACKAGE%

echo.
echo [4/4] Kaldirma sonucu dogrulaniyor...
"%ADB%" shell pm list packages %PACKAGE% 2>nul | findstr /I /C:"package:%PACKAGE%" >nul
if not errorlevel 1 (
  echo [HATA] Uygulama hala tablette kurulu gorunuyor.
  echo Ayrinti icin yukaridaki adb uninstall mesajini kontrol edin.
  "%ADB%" shell dpm list-owners 1>"%OWNER_STATUS%" 2>nul
  findstr /I /C:"%PACKAGE%" "%OWNER_STATUS%" >nul
  if not errorlevel 1 (
    echo [NEDEN] Device owner sahipligi halen etkin.
    echo Kurtarma parolasi uygulanmadan paket kaldirilamaz.
    type "%OWNER_STATUS%"
  )
  del /Q "%OWNER_STATUS%" 1>nul 2>nul
  pause
  exit /b 1
)

echo [BASARILI] TUPRAG kiosk uygulamasi tamamen kaldirildi.
echo Device owner sahipligi ve uygulama paketi artik bulunmuyor.
pause
exit /b 0
