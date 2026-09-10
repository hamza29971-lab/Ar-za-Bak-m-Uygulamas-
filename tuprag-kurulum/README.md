# TÜPRAŞ Güvenlik Uygulaması — Tablet Kiosk Kurulumu

Tableti device-owner kiosk moduna alır. Kurulumdan sonra kullanıcı, yetkili
parolasını girmeden uygulamadan çıkamaz; tablet kapanıp açıldığında doğrudan
uygulama gelir.

## Klasör içeriği

- `README.md` — bu dosya
- `tuprag.apk` — kurulacak uygulama (release imzalı)
- `tuprag-tablet-kur.bat` — kurulum scripti
- `tuprag-tablet-kaldir.bat` — durum raporu ve kurtarma yönergesi
- `platform-tools/` — adb
- `version.txt` — bu paketteki APK sürümü

## Script iki modda çalışır

Script 2. adımda tabletin durumunu kendisi belirler:

| Mod | Ne zaman | Ne yapar |
|---|---|---|
| **YENİ** | Tablet fabrika ayarlarında, cihaz sahibi atanmamış | APK kurar **ve** cihaz sahipliğini atar |
| **GÜNCELLEME** | Tablet zaten bu uygulamayla kiosk modunda | Yalnızca APK'yı yeniler; sahiplik adımını atlar |

**Güncelleme için formata, hesap silmeye veya ekran kilidi kaldırmaya gerek
yoktur** — kabloyu takıp scripti çalıştırmanız yeterli. Aşağıdaki hazırlık
adımları sadece YENİ kurulum içindir.

Cihaz sahibi başka bir uygulamaysa script durur; o durumda fabrika ayarları
zorunludur.

## Tablette (YENİ kurulumdan önce, bir kez)

Sıra önemli:

1. **Fabrika ayarlarına sıfırlayın.**
   Ayarlar > Genel yönetim > Sıfırla > Fabrika ayarlarına sıfırla
2. Kurulum sihirbazında **Google/Samsung hesabı EKLEMEYİN.** Atlayın.
   Device owner yalnızca hiç hesabı olmayan cihaza atanabilir.
3. **Ekran kilidi koymayın** (PIN / desen / parmak izi).
   Güvenli kilit varsa tablet her açılışta kilit ekranında bekler ve uygulama
   otomatik gelmez.
4. Wi-Fi'ye bağlayın (MOXA ağı ve güncelleme için).
5. Geliştirici seçeneklerini açın: Ayarlar > Tablet hakkında >
   Yazılım bilgileri > **Derleme numarası**na 7 kez dokunun.
6. Ayarlar > Geliştirici seçenekleri > **USB hata ayıklama**yı açın.
7. USB kabloyu takın, tablette çıkan **"Bu bilgisayara güven"** uyarısını
   onaylayın.

## PC'de

1. Bu klasörü diske çıkarın.
2. `tuprag-tablet-kur.bat` dosyasına çift tıklayın.
3. Script 8 adımı sırayla yapar ve sonunda 4 doğrulama çalıştırır.
   Güncelleme modunda 3. ve 5. adımlar atlanır.

**Dört doğrulamanın da TAMAM olması şart.** Biri bile BAŞARISIZ derse tablet
sahaya verilmemelidir.

Doğrulanan durumlar cihaz sahipliği, gerçek `LOCKED` modu, ön plandaki
dashboard ve güvenli başlangıç bileşeninin kalıcı ana ekran olmasıdır.
Android'in kullanıcı tarafından kapatılabilen `PINNED` ekran sabitleme modu
başarı sayılmaz; script bunu ayrıca hata olarak bildirir.

## Kurulumdan sonra

- Ana ekran, son uygulamalar, bildirim paneli ve güç menüsü kapalıdır.
- Bölünmüş ekran/pencere menüsü uygulamanın ilk açılışından itibaren kapalıdır.
- Tablet kapatılıp açıldığında doğrudan uygulama gelir.
- Sonraki sürümler uygulama içinden OTA ile sessizce kurulur; bu script bir
  daha gerekmez.

## Uygulamadan çıkış

1. Ekranın **sol üst köşesine** 3 saniye içinde **5 kez** dokunun.
   (Geri tuşu/jesti de aynı ekranı açar.)
2. Yetkili parolasını girin.
3. Uygulama kapanır, tabletin normal ana ekranına dönersiniz.

Uygulamayı tekrar açtığınızda kendini otomatik olarak yeniden kiosk moduna
alır ve kilitler — kurulum scriptini tekrar çalıştırmanız gerekmez.

## Kiosk'tan tamamen çıkma

Aynı çıkış ekranına, yetkili parolası yerine **kurtarma parolasını** girin.
Ayrı bir menü veya buton yoktur.

Bu işlem cihaz sahipliğini kaldırır ve **geri dönüşü yoktur**; tableti yeniden
kiosk moduna almak için `tuprag-tablet-kur.bat` baştan çalıştırılmalıdır.

Bu yol kapatılamaz: cihaz sahipliği kaldırılmadan fabrika ayarlarına
dönülemiyor ve ADB de device owner'ı temizleyemiyor.

## Sorun giderme

| Belirti | Sebep / çözüm |
|---|---|
| `[3/8]` hesap hatası | Tablette hesap var. Fabrika ayarı + hesap atlama. |
| `[5/8]` Device Owner atanamadı | Hesap var veya başka yönetici atanmış. Fabrika ayarı. |
| `[2/8]` "Cihaz sahibi BAŞKA bir uygulama" | Tablette önceden farklı bir kiosk uygulaması var. Fabrika ayarı zorunlu. |
| `[4/8]` APK kurulamadı | İmza uyuşmazlığı. Farklı anahtarla imzalı eski sürüm varsa önce kaldırılmalı. |
| Doğrulamada "PINNED guvenli kiosk degildir" | Device-owner lock-task izin listesi hazır değildir. Tablet sahaya verilmemeli; logcat kontrol edilmelidir. |
| Doğrulamada "uygulama LOCKED modunda degil" | Güvenli başlangıç tamamlanamamıştır. Uygulama arayüzü açılmış görünse bile tablet sahaya verilmemelidir. |
| Doğrulamada "Ana ekran BAŞARISIZ" | Kalıcı ana ekran uygulanmamış. Uygulamayı açıp kapatın, tekrar doğrulayın. |
| Uygulamada kırmızı "KİOSK KORUMASI YOK" şeridi | Device owner atanamamış. Kurulumu baştan yapın. |
| Tablet açılışta kilit ekranında bekliyor | Ekran kilidi tanımlı. Çıkış parolasıyla uygulamadan çıkıp Ayarlartan kaldırın. |
| Güncelleme "Kurulum başlatılamadı" diyor | Cihaz sahipliği yok; sessiz kurulum çalışmaz. |
| Çıkışta "Tablette başka ana ekran uygulaması bulunamadı" | Cihazda tek launcher bu uygulama. Çıkılacak yer yok; kurtarma parolasını kullanın. |

Teşhis komutu:

```
platform-tools\adb.exe logcat -s KioskBootstrap KioskMode KioskPolicy KioskAdmin KioskInstall
```
