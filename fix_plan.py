import os

file_path = r'C:\Users\hamza\.gemini\antigravity-ide\brain\48d0fb34-165a-4f3d-864a-37bf33f5e800\implementation_plan.md'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

new_content = """# Nimo Fleet API ve UI/UX İyileştirmeleri Planı

Önceki Nimo Fleet API entegrasyonu planına, belirttiğin 4 yeni UI/UX düzeltmesini (Pop-up, Klavye açılması, Bildirim eksikliği ve Yağ sayfasındaki resim) de dahil ettim.

## ⚠️ User Review Required
Aşağıdaki planı inceleyebilirsin. Sorun yoksa onayladığında tüm bu 5 maddeyi (API + 4 Düzeltme) uygulamaya geçeceğim.

## 📝 Open Questions
1. Gönderim sırasında `deviceId` (Tablet ID) değerini nasıl belirleyelim? Geçici bir sabit (Örn: `saha-tablet-1`) kullanmamı ister misin?
2. `operatorLabel` (Şoför/Operatör adı) alanını uygulamadaki giriş yapmış olan kişinin isminden (`AppState.user?.fullName`) mi almalıyım?
3. Nimo Fleet Vercel API'sine "Gönder" butonuna bastığında mı kayıt yollanmalı, yoksa her "Tamamla" işleminde anlık olarak mı gitmeli? (Mevcut yapıda listede biriktirip Gönder ile yollanıyor, bunu koruyorum).

---

## 🛠 Proposed Changes

### 1. "Gönder" İşlemlerine Emin misin? (Pop-up) Onayı
- `tire_change_screen.dart`, `oil_screen.dart` ve `service_report_screen.dart` dosyalarındaki "Gönder" butonu (genellikle `_sendPending` metodu) güncellenerek; işleme başlamadan önce ekranda `AlertDialog` ile "Göndermek istediğinize emin misiniz?" (Evet/Hayır) popup'ı çıkarılacak. Yalnızca "Evet" denilirse kayıtlar API'ye gönderilecek.

### 2. Lastik Ekranındaki Otomatik Klavye Açılmasının İptali
- `tire_change_screen.dart` içerisindeki araç seçme (arama) kutusundaki `autofocus: true` özelliği `autofocus: false` olarak değiştirilerek, sekmeye tıklandığında klavyenin zıplaması engellenecek.

### 3. Lastik İşlemlerinin "Son İşlemler" ve "Bildirimlere" Düşmesi
- `tire_change_screen.dart` sayfasındaki `_submit` ve `_sendPending` metodlarına müdahale edilerek; işlemin başarıyla tamamlanması durumunda `AppState.addActivity()` ve `AppState.addNotification()` fonksiyonları çağrılacak. Böylece yapılan lastik işlemleri anasayfada ve bildirim panelinde görünecek.

### 4. Yağ Ekranındaki Araç Fotoğrafının Kaldırılması
- `oil_screen.dart` sayfasında sağ panelde boş durumdayken (araç seçilmediğinde) çıkan `VehiclePhoto` widget'ı kaldırılarak, Lastik sayfasındaki gibi sade (ikon + mesaj) bir EmptyState widget'ı yerleştirilecek.

### 5. `lib/services/publish_service.dart` (Nimo Fleet API Entegrasyonu)
- `http` paketi kullanılarak `https://nimo-fleet-panel.vercel.app/api/event` adresine (Nimo Fleet test ortamına) POST isteği atan bir yapı kurulacak.
- Headerlara `X-Fleet-Key: nimo-fleet-test-tablet-key` eklenecek.
- Gönderilecek veri payload'u Nimo Fleet'in beklediği JSON formatına (`type`, `title`, `note`, `vehicleLabel`, `operatorLabel`, `occurredAt`, `fields`) dönüştürülecek.

## ✅ Verification Plan
- Lastik sekmesine girilip klavyenin otomatik açılmadığı test edilecek.
- Yağ sekmesinde sağda fotoğraf olmadığı görülecek.
- Herhangi bir ekranda işlem yapılıp "Gönder" butonuna tıklandığında "Emin misin?" popup'ı görülecek.
- İşlem onaylandığında verinin Nimo Fleet API'sine başarıyla `200 OK` ile iletildiği loglardan kontrol edilecek.
- Anasayfaya dönülüp Lastik işleminin bildirim ve geçmişte yer aldığı teyit edilecek.
"""

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)
print("Plan updated")
