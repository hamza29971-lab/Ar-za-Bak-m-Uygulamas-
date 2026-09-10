# NIMO Bakım Uygulaması — Tablet Kiosk Kurulumu

Tableti device-owner kiosk moduna alır. Kurulumdan sonra kullanıcı, parola
girmeden uygulamadan çıkamaz; tablet kapanıp açıldığında doğrudan uygulama
gelir.

## Klasör içeriği

- `README.md` — bu dosya
- `nimobakim.apk` — kurulacak uygulama
- `nimobakim-tablet-kur.bat` — kurulum / güncelleme scripti
- `nimobakim-tablet-kaldir.bat` — kaldırma scripti
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
4. Wi-Fi'ye bağlayın.
5. Geliştirici seçeneklerini açın: Ayarlar > Tablet hakkında >
   Yazılım bilgileri > **Derleme numarası**na 7 kez dokunun.
6. Ayarlar > Geliştirici seçenekleri > **USB hata ayıklama**yı açın.
7. USB kabloyu takın, tablette çıkan **"Bu bilgisayara güven"** uyarısını
   onaylayın.

## PC'de

1. Bu klasörü diske çıkarın.
2. `nimobakim-tablet-kur.bat` dosyasına çift tıklayın.
3. Script 8 adımı sırayla yapar ve sonunda 4 doğrulama çalıştırır.
   Güncelleme modunda 3. ve 5. adımlar atlanır.

**Dört doğrulamanın da TAMAM olması şart.** Biri bile BAŞARISIZ derse tablet
sahaya verilmemelidir.

Doğrulanan durumlar cihaz sahipliği, gerçek `LOCKED` modu, ön plandaki arayüz
ve güvenli başlangıç bileşeninin kalıcı ana ekran olmasıdır. Android'in
kullanıcı tarafından kapatılabilen `PINNED` ekran sabitleme modu başarı
sayılmaz; script bunu ayrıca hata olarak bildirir.

## Kurulumdan sonra

- Ana ekran, son uygulamalar, bildirim paneli ve güç menüsü kapalıdır.
- Tablet kapatılıp açıldığında doğrudan uygulama gelir.
- Uygulama silme, fabrika ayarlarına sıfırlama, güvenli mod ve ikinci
  kullanıcı ekleme kapalıdır.
- ADB **bilerek açık bırakılır**; kapatılırsa sonraki güncellemeler
  yapılamaz.

## Uygulamadan çıkış — iki parola

Parola ekranını açmanın iki yolu vardır:

1. **Kenardan kaydırın.** Ekranın herhangi bir kenarından (sağ, sol, üst veya
   alt) içeri doğru kaydırın. Kiosk kilidi bu hareketleri işletim sistemine
   ulaştırmadığı için uygulama kendisi yakalar ve parola ekranını açar. Saha
   kullanıcısının çıkmayı denerken bulacağı normal yol budur.
2. **Gizli köşe.** Ekranın **sol üst köşesine 3 saniye içinde 5 kez** dokunun.
   Kaydırma çalışmayan bir cihazda yedek yoldur.

Ayrı bir menü veya buton yoktur.

### `482910` — Ayarlar'a çıkış (günlük kullanım)

- Tablet **kiosk modunda kalır**; yalnızca Ayarlar uygulaması izin listesine
  eklenir ve Ayarlar açılır.
- Kullanıcı **Ayarlar dışında hiçbir yere gidemez**: ana ekran, son
  uygulamalar ve diğer uygulamalar kapalı kalır.
- **Uygulamayı silemez, tableti sıfırlayamaz.** Bu seçenekler Android
  tarafından engellenmiş durumdadır.
- Ayarlar'dan çıkıldığı anda tablet **kendiliğinden uygulamaya döner** ve
  kiosk yeniden daraltılır.

### `905174` — Kurtarma (cihaz sahipliğinden çıkış)

- Cihaz sahipliği tamamen bırakılır, tüm kısıtlamalar kaldırılır.
- Bundan sonra **uygulama silinebilir ve tablet sıfırlanabilir**.
- **Geri dönüşü yoktur**; tableti yeniden kiosk moduna almak için
  `nimobakim-tablet-kur.bat` baştan çalıştırılmalıdır.
- Uygulamayı kaldırmak için tek yol budur: device owner kaldırılmadan ADB de
  paketi silemez.

## Kaldırma

`nimobakim-tablet-kaldir.bat` çalıştırın. Script cihaz sahipliğini kendisi
kaldıramaz; sizi tablette `905174` parolasını girmeye yönlendirir, sonra
paketi siler ve sonucu doğrular.

## Sorun giderme

| Belirti | Sebep / çözüm |
|---|---|
| `[3/8]` hesap hatası | Tablette hesap var. Fabrika ayarı + hesap atlama. |
| `[5/8]` Device Owner atanamadı | Hesap var veya başka yönetici atanmış. Fabrika ayarı. |
| `[2/8]` "Cihaz sahibi BASKA bir uygulama" | Tablette önceden farklı bir kiosk uygulaması var. Fabrika ayarı zorunlu. |
| `[4/8]` APK kurulamadı | İmza uyuşmazlığı. Farklı anahtarla imzalı eski sürüm varsa önce kaldırılmalı. |
| Doğrulamada "PINNED guvenli kiosk degildir" | Lock-task izin listesi hazır değil. Tablet sahaya verilmemeli. |
| Doğrulamada "uygulama LOCKED modunda degil" | Güvenli başlangıç tamamlanamamış. Arayüz açık görünse bile tablet sahaya verilmemeli. |
| Doğrulamada "Ana ekran BASARISIZ" | Kalıcı ana ekran uygulanmamış. Uygulamayı açıp kapatın, tekrar doğrulayın. |
| 482910 sonrası Ayarlar açılmıyor | Cihaz sahipliği yok. Kurulumu baştan yapın. |
| Ayarlar'dan çıkınca uygulama gelmiyor | Kalıcı ana ekran ataması bozulmuş. Kurulum scriptini tekrar çalıştırın. |
| Tablet açılışta kilit ekranında bekliyor | Ekran kilidi tanımlı. 482910 ile Ayarlar'a çıkıp kaldırın. |

Teşhis komutu:

```
platform-tools\adb.exe logcat -s KioskBootstrap KioskMode KioskPolicy KioskAdmin
```

## Yeni APK üretme

Uygulamada değişiklik yaptıktan sonra proje kökünde:

```
flutter build apk --release
```

Çıkan `build\app\outputs\flutter-apk\app-release.apk` dosyasını bu klasöre
`nimobakim.apk` adıyla kopyalayın ve `version.txt` içeriğini güncelleyin.

> **Not:** Şu an release derlemesi Flutter'ın varsayılan debug anahtarıyla
> imzalanıyor (`android/app/build.gradle.kts`). Aynı bilgisayardan yapılan
> güncellemeler sorunsuz kurulur, ancak başka bir bilgisayarda üretilen APK
> imza uyuşmazlığı verir. Sahaya çıkmadan önce kalıcı bir release keystore
> tanımlanması önerilir.
