# PDF Okuyucu – Program Dokümantasyonu

## 1) Genel Bakış

`pdf_projesi`, Flutter ile geliştirilmiş bir PDF okuma ve çalışma uygulamasıdır. Kullanıcı PDF dosyasını seçer, metinleri işaretleyip not alabilir, seçilen metinleri sözlük/arama/AI akışlarına gönderebilir ve okuma odak araçlarını kullanabilir.

Uygulama adı arayüzde **PDF Okuyucu** olarak görünür.

---

## 2) Temel Kullanım Senaryosu

1. Kullanıcı cihazdan PDF seçer.
2. PDF ekranda açılır ve metin seçimi yapılır.
3. Seçilen metin için alt panelden aksiyon seçilir.
4. Uygulama okuma süresini takip eder, pasiflikte uyarı verir, gerekirse otomatik kaydırma ile okumayı sürdürür.

---

## 3) Özellikler

### 3.1 PDF ve Okuma

- PDF açma (`file_picker`)
- PDF görüntüleme (`syncfusion_flutter_pdfviewer`)
- Metin seçimi
- PDF içinde arama (önceki/sonraki/temizle)

### 3.2 Seçili Metin Aksiyonları

- Google Translate ile çeviri
- Google arama
- TDK araması
- AI menüsü:
  - ChatGPT: Açıkla / Özetle / Konuşalım
  - Gemini: Açıkla / Özetle / Konuşalım
- Not ekleme
- Paylaşım paneline gönderme
- Hızlı okuma moduna gönderme
- Renk işaretleme kaydı
- Kelime defterine ekleme

### 3.3 Yardımcı Panel

- Yer imleri
- Kelime defteri
- Notlar
- Son açılan dosyalar
- TXT/CSV dışa aktarma (panoya kopyalama)

### 3.4 Okuma Takibi ve Odak

- Okuma süresi takibi (aktif kullanımda saniye bazlı)
- Ödül puanları:
  - Her aktif saniye: `+1` gümüş
  - Her `60` saniye: `+1` altın
- Hızlı kaydırma tespiti ve kısa flaş uyarısı
- Pasiflik yönetimi:
  - İlk eşik: `3 dakika`
  - Sonraki aşamalar: kademeli uyarı (45 saniye aralıklarla)
  - Titreşim (haptic + cihaz vibratör fallback)
  - Metin bozma/scramble/silme efektleri kaldırılmıştır
  - Idle emoji tam ekran katmanı (0–81 saniye zaman çizelgesi):
    - `0s 🤨`, `2s 🧐`, `4s 🥸`, `6s 🤩`, `8s 🫣`
    - `10s 🤗`, `12s 🫣`, `14s 🤗`, `16s 🫵`, `18s 🥱`
    - `20s 😴`, `22s 🤤`, `24s 😪`, `26s 😮‍💨`, `28s 🙋`
    - `30s 😛`, `32s 😝`, `34s 😜`, `36s 🤪`, `38s 😏`
    - `40s 😵‍💫`, `42s 🥴`, `44s 👻`, `46s 💩`, `48s 🤡`
    - `50s 🫵`, `52s 👎`, `54s 😈`, `56s 👾`, `58s 👾👾👾👾`
    - `60s 🤨`, `62s 😡`, `64s 😈`, `66s 🔥📚`
    - `70s 📚🔥`, `72s 🔥📚`, `74s ✂️📚`, `76s 🗑️🗑️`, `78s 🧹🧹`
    - `80s 📄`, `81s 😴`
  - Kullanıcı dokunma/kaydırma yaptığında veya cihaz hareket algıladığında idle emoji süreci anında iptal edilir
- Ekran kapanmama politikası:
  - Etkileşim olduğunda ekran `15 dakika` açık tutulur
  - `15 dakika` sonunda ekran açık tutma otomatik kapatılır

### 3.5 Kalınan Yeri Hatırlama

- Son okunan sayfa dosya adına bağlı olarak yerel olarak saklanır (`shared_preferences`)
- Aynı PDF tekrar açıldığında kaydedilen sayfaya otomatik gidilir

### 3.6 Otomatik Kaydırma

- AppBar üzerinden aç/kapat
- Sayfa bazlı otomatik ilerleme
- Son sayfada otomatik kapanma

### 3.7 Alt Durum Çubuğu

- Sol tarafta kitap kurdu ilerleme şeridi gösterilir (`🐛 ... 📚`)
- İlerleme sayfa oranına göre hesaplanır
- Sağ tarafta `Sayfa aktif/toplam` bilgisi görünür

---

## 4) URL Açma Stratejisi

Harici servisler için bağlantı açma akışı şu sıradadır:

1. Yerel uygulama URI’si denenir (varsa)
2. Dış uygulamada açma denenir
3. Başarısız olursa uygulama içi web görünümüne düşülür

Bu sayede cihazda yüklü uygulama varsa daha doğal kullanıcı deneyimi sağlanır.

---

## 5) Proje Yapısı

- `lib/main.dart`
  - Ana uygulama akışının tamamı
  - UI, state ve yardımcı servis fonksiyonları
- `pubspec.yaml`
  - Bağımlılıklar
- `test/widget_test.dart`
  - Temel widget testi
- `docs/`
  - Program ve değişiklik dokümanları

---

## 6) Kullanılan Paketler

- `syncfusion_flutter_pdfviewer`
- `file_picker`
- `url_launcher`
- `share_plus`
- `syncfusion_flutter_pdf`
- `wakelock_plus`
- `webview_flutter`
- `sensors_plus`
- `vibration`
- `shared_preferences`
- `cupertino_icons`

---

## 7) Kurulum ve Çalıştırma

1. Bağımlılıkları yükleyin:
   - `flutter pub get`
2. Cihaza bağlayıp çalıştırın:
   - `flutter run -d <device_id>`
3. Test:
   - `flutter test`

---

## 8) Bilinen Sınırlar

- Dışa aktarma şu an dosya oluşturmaz, panoya kopyalar.
- Çok fazla aksiyon aynı panelde bulunduğu için yeni kullanıcı için yoğun olabilir.
- Otomatik kaydırma sayfa bazlıdır; satır bazlı kaydırma yapılmaz.

---

## 9) Sonuç

Uygulama, temel PDF görüntüleme yaklaşımından ileri seviyede okuma asistanı davranışına taşınmıştır. Metin odaklı çalışma, araştırma, notlama, odak ve süre takibi tek uygulama içinde birleştirilmiştir.
