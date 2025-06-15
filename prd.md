🗺️ Roqua - Product Requirements Document (PRD)

⸻

📌 Ürün İsmi: Roqua

⸻

🎯 Ürün Amacı

Kullanıcının gerçek hayatta gezdiği yerleri dairesel şekilde harita üzerinde aydınlatarak, dünyayı ne kadar “keşfettiğini” gösteren gizlilik dostu, minimal bir mobil uygulamadır.

Uygulama:
	•	Arka planda konumu takip eder
	•	İnternet gerektirmez
	•	Kayıt, üyelik, veri paylaşımı içermez
	•	Sadece seni ilgilendiren dijital bir keşif haritası sunar

⸻

👤 Hedef Kitle
	•	Dijital detoks yapanlar
	•	Seyahat ve yürüyüş meraklıları
	•	Veriye değil deneyime önem veren kullanıcılar
	•	Harita ve istatistik düşkünleri
	•	“Ben nereye gittim?” sorusunu görsel olarak hissetmek isteyen herkes

⸻

🔐 Gizlilik & Güvenlik
	•	Uygulama tamamen offline çalışır
	•	Kullanıcıdan hiçbir kişisel bilgi alınmaz
	•	Konum verileri sadece cihazda, SQLite içinde saklanır
	•	Harici sunucuya gönderim yoktur, App Store açıklamasında bu açıkça belirtilir
	•	Kullanıcı isterse verileri silebilir

⸻

🔑 Temel Özellikler

🧭 1. Arka Plan Konum Takibi (iOS)
	•	CLLocationManager ile Always Authorization alınır
	•	Konum değiştikçe konum SQLite veritabanına kaydedilir
	•	Uygulama açık olmasa bile gezilen yerler birikir

🌐 2. Harita Üzerine Karanlık Katman
	•	Tüm dünya haritası ilk açıldığında karanlık görünür
	•	Sadece gezilen yerlerde dairesel alanlar (örneğin 150m radius) açılır
	•	Bu alanlar üst üste geldikçe birleşir, harita “aydınlanmış” gibi görünür

🔆 3. Dairesel Açılma (Fog of War Tarzı)
	•	Kullanıcı her yeni konuma girdiğinde o konum merkezli Polygon Circle oluşturulur (GeoJSON)
	•	Daire büyüklüğü:
	•	Yürüyorsa → 100–150m
	•	Araçla ise → 300–500m (ileride hız tespit ile dinamik)
	•	Bu daireler haritada mask layer olarak görünür

📊 4. Keşif Yüzdesi ve İstatistikler
	•	“Dünyanın %2.13’ünü keşfettin” gibi veriler
	•	Ülke/şehir/kıta bazında breakdown (ileride opsiyonel)
	•	Son 7 gün, bu ay, tüm zamanlar gibi filtreler (opsiyonel)

📍 5. Offline Harita Desteği
	•	Mapbox GL SDK kullanılarak offline tile cache kullanımı
	•	Harita stili: Siyah zemin, detay azaltılmış sade görünüm
	•	Harita render tamamen cihaz üstünden yapılır

⸻

🧪 Minimum Viable Product (MVP)

Özellik	Durum
iOS arka planda konum takibi	✅
Dairesel GeoJSON üretimi	✅
SQLite ile veri saklama	✅
Haritada karanlık katman & maskeleme	✅
Keşif yüzdesi hesaplama	✅
Offline çalışma (airplane mode uyumu)	✅


⸻

🧱 Teknik Mimarî (iOS)
	•	Swift + Mapbox SDK
	•	CLLocationManager ile konum dinleme
	•	SQLite veya CoreData ile lokal veri kaydı
	•	Harita katmanı:
	•	FillLayer (karanlık katman)
	•	GeoJSONSource (visited alanlar)
	•	MapView.style.addLayer(...) ile custom render
	•	App Lifecycle:
	•	Arka plan izni alındığında startUpdatingLocation()
	•	Her konum değişiminde yeni daire çizimi ve kaydı
	•	Offline harita paketi .mbtiles destekli opsiyonel

⸻

💡 UX Notları
	•	Harita açıldığında sade, yazısız, ikon barındırmayan bir görünüm
	•	Açılan daireler fade-in ile belirir
	•	Daire kenarına hafif glow efekti verilebilir
	•	Harita üzerinde “şu anki konum” sade bir dot ile gösterilir
	•	Ayarlar ekranı: Veriyi temizle, konum izni durumu, harita stili

⸻

⚠️ Riskler / Sınırlamalar

Risk	Açıklama
iOS arka plan izni kısıtlamaları	Kullanıcının “Always Allow” izni vermemesi durumunda takip durur
Batarya tüketimi	Optimize edilmezse konum güncellemeleri çok fazla enerji harcayabilir
Offline harita boyutu	Ön yüklü harita verisi cihazda yer kaplayabilir
iOS update’leri	Arka plan çalışmayı pasifleştirebilir, bu yüzden foreground’da destek şart


⸻

🚀 Genişleme Planı (Future Scope)
	•	Hız tespit ile otomatik radius değişimi (yürüyor/motorlu)
	•	Ülke / şehir bazlı “keşif rozetleri”
	•	Kullanıcıya offline backup alma seçeneği (yerel JSON export)
	•	Map paylaşımı (isteğe bağlı)
	•	Android sürümü

⸻

📄 Sonuç

Roqua, kullanıcıyı yormadan, kişisel bir keşif yolculuğuna çıkarır.
Kendi hayat yolculuğunu, hiçbir hesap açmadan ve hiçbirine görünmeden sadece kendine haritalar.