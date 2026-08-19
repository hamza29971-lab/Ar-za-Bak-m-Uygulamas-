# Görseller

| Dosya / klasör | Kullanım |
|---|---|
| `sol/Euclid.png`, `sol/Euclid2.png` … `sol/Euclid11.png` | Euclid araçlarının sol görünümü (`Euclid-1` dosyası numarasızdır) |
| `sağ/Euclid1yansıma.png` … `sağ/Euclid11yansıma.png` | Aynı araçların sağ (yansımalı) görünümü |
| `euclid.png` | Taraflı görseli olmayan Euclid araçları (ör. `Euclid-12`) |
| `vehicle_default.png` | Görseli tanımlı olmayan diğer araçlar (`VehiclePhoto`) |
| `nimo_logo.png` | NIMO robot simgesi: üst bar ve giriş ekranı (`NimoLogo`) |

Dosyaların tümü isteğe bağlıdır: bulunamazsa uygulama sırasıyla vektörel
çizilmiş bir kaya kamyonu ve robot simgesi gösterir, yani görsel eklemeden de
arayüz eksiksiz çalışır. Robot simgesini değiştirmek için PNG'yi bu klasöre
`nimo_logo.png` adıyla kopyalamak yeterlidir; kod değişikliği gerekmez.
Simgenin tuvalindeki şeffaf kenarları kırpın — `NimoLogo` görseli kutusuna
sığdırdığı için boşluklu bir dosya küçük görünür.

## Hangi görsel nerede kullanılır?

`Lastik Değişimi` ekranındaki **Sol / Sağ** sekmesi aracın hangi tarafının
gösterileceğini belirler; **Tümü** ve **Sol** aynı (sol) görseli kullanır.
Diğer tüm ekranlar (Anasayfa, Yağ Takviyesi, Servis Raporu, giriş ekranları)
sol görünümü gösterir.

## Fotoğraftaki tekerlek bölgeleri

Lastik Değişimi ekranında fotoğraftaki tekerlekler tıklanabilir. Bölgeler
`lib/widgets/vehicle_photo.dart` içindeki `_leftViewHotspots` /
`_rightViewHotspots` listelerinde, görselin sol üst köşesine göre 0..1
aralığında normalize edilmiş dikdörtgenler olarak tutulur. Yeni bir görsel
farklı çekim açısındaysa bu değerler güncellenmelidir.

## Yeni Euclid görseli eklemek

`sol/` ve `sağ/` klasörlerine dosyayı yukarıdaki adlandırmayla kopyalayın, sonra
`lib/widgets/vehicle_photo.dart` içindeki `_euclidSideImageCount` sabitini
güncelleyin (şu an 11).

## Araç tipine göre görsel eklemek

1. Görseli bu klasöre kopyalayın (ör. `excavator.png`).
2. `lib/widgets/vehicle_photo.dart` içindeki `_assetByType` tablosunda ilgili
   tipin yolunu güncelleyin:

```dart
'EXCAVATOR': 'assets/images/excavator.png',
```

## Belirli araçlara (markaya) göre görsel eklemek

Aynı tipteki araçlar farklı görsel kullanacaksa `_assetByCodePrefix` tablosuna
araç kodunun küçük harfli ön eki yazılır; bu tablo tipten önce değerlendirilir:

```dart
'euclid': 'assets/images/euclid.png',
```

> Yeni bir klasör eklerseniz `pubspec.yaml` içindeki `assets:` listesine de
> eklemeyi unutmayın; Flutter alt klasörleri kendiliğinden taramaz.
