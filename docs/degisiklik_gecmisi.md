# PDF Okuyucu – Değişiklik Geçmişi

Bu doküman, projede yapılan önemli değişiklikleri güncel davranışa göre özetler.

---

## Güncel Sürüm Özeti

- Uygulama adı `PDF Okuyucu` olarak standardize edildi.
- Seçili metin aksiyonları genişletildi (TDK, AI, paylaşım, not, hızlı okuma vb.).
- Yerel uygulama öncelikli link açma stratejisi eklendi.
- Pasiflik sistemi `3 dakika` başlangıç ve kademeli uyarı akışına geçirildi.
- Idle emoji zaman çizelgesi güncellendi (0–81 saniye, tam ekran büyük emoji overlay).
- Titreşim sistemi haptic + doğrudan vibratör fallback ile güçlendirildi.
- Ekran açık tutma akışı `15 dakika` etkileşim penceresi ile güncellendi.
- Son kalınan sayfa dosya bazlı olarak kaydedilip geri yüklenir.
- Metin bozma/scramble/silme ve piksel overlay efektleri kaldırıldı.
- Yatay yön zorlama özelliği kaldırıldı.

---

## 1) Arayüz ve İsimlendirme

- AppBar başlığı `PDF Okuyucu` olarak değiştirildi.
- Metin seçimi menüsünde ikon ağırlıklı aksiyonlar yazılı butonlarla sadeleştirildi.

---

## 2) Metin Seçimi Aksiyonları

Eklenen/iyileştirilen aksiyonlar:

- Çevir (Google Translate)
- Ara (Google)
- TDK
- Not ekle
- AI menüsü (ChatGPT/Gemini)
- Paylaş
- Hızlı okuma modu
- Deftere ekle

---

## 3) AI ve Dış Bağlantılar

- Seçili metin için AI prompt üretimi eklendi:
  - Açıkla
  - Özetle
  - Konuşalım
- Bağlantı açma akışı iyileştirildi:
  1. Yerel URI dene
  2. Harici uygulamada açmayı dene
  3. Gerekirse uygulama içi web görünümüne düş

---

## 4) Okuma Takibi ve Ödül

- Aktif okuma saniye bazlı takip edilir.
- Her saniye `gümüş`, her 60 saniye `altın` puanı artar.
- Alt bilgi çubuğunda süre ve puanlar görünür.

---

## 5) Pasiflik Akışı (Güncel)

Pasiflik başlangıcı: **3 dakika**

Etkileşim yoksa aşamalı ilerleme:

1. Aşama: titreşim uyarısı
2. Aşama: tam ekran idle emoji zaman çizelgesi
3. Aşama sonu: `81s` noktasında `😴`

İptal koşulları:

- Ekrana dokunma / kaydırma / pointer hareketi
- Cihaz hareketi (ivmeölçer)

Aşamalar arası süre: **45 saniye**

Not: Eski sürümde bulunan yön (landscape) zorlama kaldırılmıştır.

---

## 6) Otomatik Kaydırma

- AppBar üzerinden aç/kapat kontrolü eklendi.
- Sayfa bazlı ilerleme vardır.
- Son sayfada otomatik kapanır.

---

## 7) Ekran Kapanmama

- Etkileşim olduğunda ekran açık tutma tekrar başlatılır.
- Ekran en fazla `15 dakika` açık tutulur, sonra açık tutma otomatik kapatılır.

---

## 8) Kalınan Yerden Devam

- Son sayfa dosya adına bağlı anahtarla yerel olarak saklanır (`shared_preferences`).
- PDF tekrar açıldığında kayıtlı sayfaya otomatik atlanır.

---

## 9) Stabilite İyileştirmeleri

- Timer yönetimi güçlendirildi.
- Yeni PDF açıldığında oturum state’i temizlenir.
- PDF seçilmeden pasiflik uyarısı çalışmaması sağlandı.
- `vibration` entegrasyonu ile cihaz destekliyorsa doğrudan titreşim pattern’i çalıştırılır.
- Test beklentileri güncel başlığa göre düzeltildi.

---

## 10) Açık İyileştirme Alanları

- Aksiyon panelindeki yoğunluk azaltılabilir.
- Dışa aktarma dosya kaydı (TXT/CSV) eklenebilir.
- Ayarlar ekranı ile pasiflik/otomatik kaydırma eşikleri kullanıcıya açılabilir.
