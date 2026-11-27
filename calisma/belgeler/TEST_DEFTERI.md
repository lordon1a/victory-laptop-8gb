# Test defteri: ne denendi, bizde ne oldu, başkasında ne olmuştu

Makine: RTX 3070 Ti Laptop 8 GB, 16 GB RAM, i7-12700H, Series S profili, hapishane sahnesi.
Kural: her A/B sonucu buraya **aynı gün** yazılır ve repoya gönderilir. Sayı = dünya karesi medyanı (ms, düşük iyi).
"Başkasında" sütunu o değişikliği getirenin kendi iddiasıdır; biz tekrarlamadıysak öyle yazılır.
Ham koşu satırları: KOSULAR.md. Ayrıntılı günlük: STATUS.md. Aday listesi: ADAYLAR.md.

En önemli gerçek (26.11 09:55, kanıtlı): darboğaz **ekran kartı** (%91-100 dolu, kritik yolun ~119/145 ms'si).
Bu yüzden CPU/RAM tarafında kazandıran ayarlar başkasında fps artırsa da bizde kareyi kısaltmıyor.

## Kabul edilenler (tabanda)

| Ne | Kaynak | Başkasında | Bizde | Not |
|---|---|---|---|---|
| RT paketi: BVH_MISS + RT_SKIP_RESOLVE + RT_SKIP_ACTIVATE | cool_fox 8cc31ab3 + bizim BVH_MISS | cool_fox: iddia var, sayı yok | **184 → 150 ms (−%18)**, görüntü aynı | 26.11 11:50 |
| DYNAMIC_SLOTS=524288 | trustno1 taraması, bizim düzeltme | — | reddedilen tablo 562-1357/kare → 0, düşen indirect çizim 229-272 → 0; kare aynı | 09:25, görüntü düzeldi (avlu dolu) |
| CARD_HASH_WIDE (fxceless #1014) | fxceless | 3060 12 GB: hash 35 → 10 ms | geri kopya −%38, kart işi −%43; kare aynı | 25.11 23:14 (o zaman darboğaz gönderimdeydi) |
| İki düzlemli present (siyah ekran düzeltmesi) | ZSlayer PR #10 fikri, Sol portu | Series S siyah ekran düzeliyor | düzeldi, yükleme ekranı görünüyor | 26.11 03:35 |
| warm --used (pipeline ön hazırlığı) | upstream komutu | Nozy: fps değişmedi | fps aynı (172.5), **dünyaya giriş 177 → 105 sn, takılma p90 640 → 309** | Takılma için kabul, fps için değil |
| WINDOWS_BAR_PERCENT=88, WINDOW_KB=256, TAILS, SEND_KEPT_MB=128 | bizim RAM işi | — | kilitli RAM 4726 → 3252 MB, 10 dk sızıntısız | RAM kabulü, fps aynı |
| Windows 10 Agility SDK desteği | bizim | BlatWolf (4060, Win10) için | Win11'de etkisiz, Win10'da çökmeyi önler | 90d3c4f |
| CLAMP_WAITS=0 (victory-scarlett f748fb557a / Trexies 6b358fe, Sol portu 02d7284) | scarlett | Trexies: clamp başı 2 tam bekleme, ~30-50 ms kart iddiası (4080S) | cwb temiz çift **149.3 → 143.0 ms**, p90 250 → 146; cwa: taban bozuk (n=5, 389 ms), clampwaits 145.6 / p90 153 | Küçük kazanç (~%4) ama kareler çok daha düzgün (p90 hep ~145-153). Görüntü aynı (kare_0170s). Bizde clamp'ler zaten toplu, o yüzden 30-50 ms değil (TAHMİN). Tabana alınacak (kw serisi bitince). 26.11 14:10 |
| OWN_UPSCALER=1 + RENDER_SCALE=0.5 (trustno1 afd84de1 ← victory-perf ← ScarlettPort; Neon portu a8ae91f) | RTX 5070: GPU 110 → 82-88 ms | 2 tur × 150 sn, son 60 sn: taban **142/145** · yalnız OWN_UPSCALER **127/132 (−%10)** · OWN+0.5 **112/114 (−%21)** | Bizde de çalıştı çünkü darboğaz kart: piksel işi yarıya inince kart süresi doğrudan düşüyor. RENDER_SCALE tek başına (FSR yolu) açılışta 0xC0000094 sıfıra bölme ile çöküyor → OWN_UPSCALER şart. Görüntü daha yumuşak, avluda hareketli kişilerde hafif hayalet; yüzde 0.6/0.75 seçenekleri sırada. |
| RENDER_SCALE eğrisi (OWN_UPSCALER=1 ile, 2 tur × 150 sn) | — | **0.5: 115/113 · 0.6: 121/118 · 0.75: 2/2 açılışta çöktü** (0x80000003 @20 sn, -1 @3.5 sn) | 0.6 biraz daha keskin, ~5 ms yavaş. Tabanda 0.5 kalır; oyun için 0.6 da güvenli. 0.75 kullanılmaz (çöküş nedeni bilinmiyor). Not: OWN_UPSCALER ile saç ışığı belirgin koyulaşıyor (taban karesinde saç aydınlık). |
| RT_SKIP_ACTIVATE=0 (trustno1 77e13a9: screen-probe atlama gökkuşağı bırakır) — Yiğit 37 dk oyun | RTX 5070: iç mekân beyaz/gökkuşağı çöpü kalktı | dükkân/ara sahne mor + beyaz bloklar (ACTIVATE=1) → uçak sahnesinde görüntü temiz (kare_2089s); ms maliyeti A/B tabanına dahil edildi | görüntü kabul; wca/wcb tabanı ACTIVATE=0 ile |
| **SKIP_WC_BACK=1** (fxceless #868 + #1379 ≥1 MiB; Neon portu a36742c) — 2 tur × 150 sn, taban RT_SKIP_ACTIVATE=0 | RTX 4070 184 → 148 ms (−%20); 5080 −%11-22 | **144 → 130, 140 → 128 ms (−%9)**; geri kopya 66-76 → 36-38 ms/kare, 22 → 6 MB; sayaç: karede 1602 kopya / 105 MB atlandı; kare temiz (wcd-skip 265 sn) | bizde kazanç onlardan küçük çünkü under/kart tarafı hâlâ dolu; ilk 'sahiplik' değişikliği tuttu → PLAN adım 4 yönü doğrulandı |
| RT_SKIP_ACTIVATE=0 maliyeti — 2 tur × 150 sn, ikisinde de SKIP_WC_BACK=1 | trustno1: görüntü için şart | **124 → 128, 117 → 120 ms (+3-4 ms)**; önceki 140-144 tabanı kirliydi (Yiğit PC kullanıyordu) | görüntü için ucuz → tabana alındı. Yeni taban ≈ 120-128 ms, görüntü temiz |
| **Küçük tamponlar karta (Adım 2 x2):** MIN_KB=64 + CARD_BUFFERS_MB=1024 + FETCH_CHECK=1 + SKIP_WC_BACK_MIN_KB=16384 + CARD_STEPS=1 + TEXTURE_NO_WAIT=0 — temiz 2 tur | fxceless #1379 5080 kart 42 → 18.5; trustno1 5070 11 → 21.8 fps (MIN_MB=1); Op-lite scarlett-fox açık | **129-134 → 78 ms, 118 → 90 ms** (7.5-8.5 → 11-13 fps), kart 63 → 33 ms; görüntü 4/4 temiz | 8 GB kartta varsayılan eşik 16 MiB → 3693 küçük tampon (898 MB) sistem RAM'inde, kart PCIe'den okuyup bekliyordu; tek başına MIN_KB=64 tel/decal kaybettirdi (yırtık okuma + SKIP_WC yarışı), FETCH_CHECK + CARD_STEPS=1 + NO_WAIT=0 ile temiz |

## Reddedilenler

| Ne | Kaynak | Başkasında | Bizde | Neden bizde olmadı (kanıt / TAHMİN) |
|---|---|---|---|---|
| VICTORY_DESC_MARKS (MKmajster descriptor işaretleme, Neon portu vw-desc 60c28fe) — 27.11 dsca/dscb, 150 sn x2 ABBA | MKmajster/victory-fork-8gb, fxceless #1083 | RTX 3070: sync_heaps 17.2 → 0.2-0.6 ms, paket 185 → 144 ms | **descriptor sync 13.4-16.4 → 2.8-3.1 ms/kare** (6/6 kanca tuttu, kaçan 0), ama kare son 60 sn medyan açık 68/66 vs kapalı 67/68 ms. Görüntü temiz (posterler, yazılar yerinde). Hepsi temiz (0.25-0.47) | sync bizde paralel çalışıyor ve kritik yolda değil (SUBMIT BUSY ~53-57 ms değişmedi) → CPU zamanı kazanılıyor, kare değil. Ret değil PARK: kod hazır, darboğaz başka yere kayınca tekrar dene |
| RENDER_SCALE 0.4 / 0.33 (PLAN 8b) — 27.11 rsa, 150 sn | Discord önerisi (çözünürlük düşürme) | — | son 60 sn medyan 0.4: 67 ms, 0.5: 67 ms, 0.33: 73 ms (kirli 1.33 çekirdek, Neon derliyordu). 0.4'te GPU BUSY 32.7 (0.5'te ~43) → ölçek uygulandı, kart boşaldı ama kare aynı | Darboğaz CPU (kart ~33 ms, kare 66 ms): çözünürlük düşürmek kazandırmaz, yalnız görüntüyü bozar. 0.5 kalır; FG ile RS=1 bile aynı hızda (E8) |
| COPY_BACK_BESIDE (Neon portu vw-cbb 4335b34) — 27.11 cbba/cbbb, 150 sn x2 ABBA | Marvisak #3069 | 4070S: geri kopya 60.6 → 47.5 ms, VirtualProtect 5366 → 1556/kare | son 60 sn medyan açık 68/71 vs kapalı 67/65 ms; **yanından yazılan 0 sayfa** (hepsi fallback ~15 MB/5 sn), VirtualProtect ~600-650/kare iki kolda aynı. Hepsi temiz (0.29-0.41). Görüntü temiz | Bizde LAND_BESIDE zaten açık; VirtualProtect zaten ~600/kare (onlarınki 5366). Port'un yolu hiç devreye girmedi → etkisiz. #1407 taşma düzeltmesi ayrıca tutulabilir |
| POOL_DISCARD=1 MEM_RESET + yarış düzeltmesi (da2d163: taze yazılan sayfa korunur, yazma kapısı) — 27.11 prda/prdb, 10 dk hapishane x2, ABBA | Op-lite scarlett-fox | 4080S/32 GB: >500 ms donma 39 → 7 | **Çökme YOK** (önceki MEM_RESET çöküyordu; 7612 ve 2677 taze sayfa korundu). Son 60 sn medyan discard 70/71 vs taban 73/72 ms (~2 ms), 2. yarı sayfa girişi ort 469/393 vs 2454/925. Hepsi temiz (diğer CPU 0.26-0.56). **AMA prdb-discard dünya yüklenirken bozuk açıldı ve 10 dk öyle kaldı: güneş ışığı yok, sağ üst duvar posterleri yok, saç/tişört koyu** (sağ üst bölge parlaklığı 65 vs diğer 7 koşuda 115) | TAHMİN: yükleme sırasında boşaltılan havuz sayfasına oyunun KENDİ CPU yazısı (write_physical dışı, kapıdan geçmiyor) MEM_RESET ile yarışıyor; kazanç ~2 ms, risk görüntü kaybı → reddedildi. TRIM_ONLY çökmüyor ama sayfa girişi artırıyordu |
| REAPER (VICTORY_REAPER=1, bury arka iş parçacığında) — 27.11 rpra/rprb, 150 sn hapishane x2 | fxceless #1349 → Neon port 6650636 | RTX 5080: bury 51-63 ms/kare, kare 86-95 → 65-73 ms | son 60 sn medyan: reaper 73 / 80 ms, taban 70 / 65 ms; panel SUBMIT BUSY 71.9 vs 57.4. Görüntü iki kolda temiz. Kirli: diğer CPU 1.7/2.3/1.3 çekirdek (Neon ajanları çalışıyordu), yalnız rprb-taban temiz (0.29) | Bizde bury yalnız 1.5 ms/kare (5080'deki 50+ ms yok) → kazanç tavanı ~1 ms; oyun CPU'ya bağlı (7.1 çekirdek), ek iş parçacığı çekirdek çalıyor. TAHMİN: temiz ölçümde de nötr/olumsuz. Varsayılan kapalı kalır |
| POOL_DISCARD (Op-lite c45b43e96a, Neon portu 03e3792) MEM_RESET ve TRIM_ONLY modları | Op-lite 4080S/32 GB: >500 ms donma 39 → 7 | MEM_RESET: 2 koşunun 1inde gerçek çökme (oyunun ExitProcess -1); TRIM_ONLY: çökme yok ama sayfa girişi 5.5k → 14k/sn, fps taban 13.4-15.3 vs trim 10.5-12.8 (trim kolu kirli) | Boş havuz sayfaları bizde kısa sürede yeniden kullanılıyor; MEM_RESET DirectStorage yazımıyla yarışıyor (kilitsiz Section::window), trim yeniden okumaya yol açıyor. Kod kapalı duruyor |
| MIN_KB=64 + CARD_BUFFERS_MB=1024 TEK BAŞINA (mkc/mkd, 2 tur × 150 sn) — küçük tamponları karta al | fxceless #1379 Zignixx 5080: kart 42 → 18.5 ms; trustno1 5070 MIN_MB=1+1536: 11 → 21.8 fps | **129 / 134 → 74 / 80 ms (7.5 → 13 fps)**, kart 40/78 → 6/30 ms; AMA pencere teli ve INMATE decal kayboluyor | SKIP_WC_BACK yarışı + RELAY_COPY yırtık okuma (FETCH_CHECK karede 8 parça yakaladı) + CARD_STEPS=2/NO_WAIT=1. Tek başına ret; düzeltilmiş hâli (x2) kabul adayı |
| CARD_BUFFERS_MB=1024 + CARD_WINDOWS_MB=256 (Impre-visible GTX1660 / kelvaroq 0039) — 2 tur × 150 sn | GTX 1660 6 GB Linux: 360-410 → 98-112 ms | taban 127 / 117, 1024'lü 117 / 135 (ort. 122 vs 126) | gürültü içinde, kazanç yok; ret. Onlarda kart tamponu yoktu (Linux vkd3d), bizde zaten tampon/pencere yolu ayarlı |
| Yeni taban 2de9980'e geçiş — KARAR | — | y2b karesi: oda karanlık, tel örgü ve duvar dokusu yok, RAM 17.7 GB; bizim taban aynı sahnede tam (rsb 245 sn) | Yiğit 22:30 'bizimki görüntüde daha sağlam' + ölçüm 127 vs 113 → tabanı değiştirmiyoruz; yalnız hedefli parçalar (ör. PORT_GUARD) ayrı ayrı alınabilir |
| + VIEW_BYTES=0 — y2c, 1 koşu | RTX 5070: 106 → 77 ms (portsuz) | **127 → 140 ms**, kopyalar duruyor | bizde ters: o görünümleri reddetmek burada yavaşlatıyor; ret |
| 2de9980 + havuz + PORT 2+6+7 (DESCRIPTORS/GUARD/JOURNAL) — y2b, 1 koşu | RTX 5070 12 GB: 2+6+7 79 ms (1+2+5+6+7 135) | **138 → 127 ms** (JOURNAL bekleme 1.8 ms/kare, sayaç devrede) | yeni taban portlarla 11 ms iniyor; bizim taban 113. Yeni tabanda CLAMP_WAITS, RT skip, BVH_MISS yok → taşınacak |
| 2de9980 + pr0vId3nce #221 havuz yaması — y2a, 1 koşu | RTX 4080: 276 → 142 ms | **314 → 138 ms**, 377 kopya/kare hepsi havuzdan, kilit 1.4 ms | yama tutuyor ama hâlâ bizim tabandan (113) yavaş; portlar ve VIEW_BYTES=0 ölçülüyor |
| Yeni avatarmanz tabanı 2de9980 (yamasız) — y0, 1 koşu | RTX 4060 laptop 8 GB: f249fe0 5 fps → c9c932c 2-3 fps (#221) | **314 ms** (bizim taban 113); karede ~375 'own bytes' kopyası (#23) | #23 NVIDIA'da (raw twin yok) her yer değiştiren görünüme yeni tampon açıyor; AMD'de az tetikleniyor |
| Birleşik A/B (e49597a): MERGE_DEFER + GUARD_OUTSIDE (CPU) / TABLES_ON_CARD (GPU) / üçü — 2 tur × 150 sn | MERGE_DEFER 54.8 → 45 (5070 Ti); GUARD_OUTSIDE 10 → 11 fps (5090); TABLES_ON_CARD 9.7-10 → 10.3-11 fps (5080) | taban **116 / 114** · cpu **120 / 120** · gpu **116 / 122** · hepsi **114 / 129** → kazanç yok | Sayaçlar: MERGE_DEFER **0 ertelenen parça** (bütçe hiç aşılmıyor → bizde boş; 'under' birleştirmenin kendisi yalnız 6-8 ms/kare). GUARD_OUTSIDE devrede (kare başına ~150 koruma kilit dışında, kilit tutma 4.4 → 2.2 ms) ama toplam guard beklemesi 35-50 ms aynı kaldı, kare +4 ms. TABLES_ON_CARD devrede (2 tablo, 25 MB) ama nötr. Sonuç: TIMELINE'daki 'victory-under' 70 ms birleştirme işi DEĞİL (o 6-8 ms) — başka bir şeyde bekliyor; içini görmeden doğru çözüm seçilemiyor → Nsight Systems CPU örneklemesi şart. Hepsi kapalı. |
| SKIP_PIPELINES saç simülasyonu (4a05640e, 4115dd63, d474a0f1 = smh_sim_*) — 2 çift × 150 sn | vi-pc-combo: kart 178 → 162 ms | temiz çift **118 → 114 ms** (−%3); diğer çiftin tabanı kirli (126 → 108) | **Görüntü bozuk**: saç dağınık/patlamış teller halinde donuyor, sağdaki posterde renkli bozuk bloklar (ProbeGather atlamasındaki gibi) → kabul edilemez. Kazanç da tavanın (15 ms) altında: kart kısalınca CPU kareyi tutuyor (dengeli darboğaz). Kapalı. |
| VIEW_BYTES=0 (bizde var; avatarmanz #213 yorum) — 2 çift × 150 sn | RTX 5070/5800X3D Series S %50: 106 → 77 ms | taban **122 / 118** · VIEW_BYTES=0 **119 / 119** (nötr); kayıt iş parçacıkları 175 → 179 / 176 → 162 ms | Bizde kayıt süresi belirgin düşmedi (view_home onlarda %56'ydı, bizde değil) ve kart ~109 ms dolu olduğu için CPU tarafı tek başına kareyi kısaltamıyor (dengeli darboğaz). Kapalı; birleşik (CPU+GPU) denemede yeniden bakılabilir. |
| BATCH_OPEN=1 (#2849) + PARTIAL_TEX_DETILE=1 (#2985), Neon portu bb9d19e, 2 çift × 150 sn | RX 9070 XT paket: prep 92.7 → 71.8 | taban 129/120 · açık 120/118 | **SIFIR TEST**: sayaç BATCH_OPEN 0 run (ardışık korumalı blok açılmıyor), PARTIAL_TEX kare başına 1 yenileme, 142/142 satır (hepsi değişmiş) → ikisi de bizim sahnede iş bulmuyor. Fark taban oynaması. Kapalı. |
| ASYNC_SUBMIT=1 (bizde var; avatarmanz b8b30d1cf9) — CPU darboğazı teşhisinden sonra yeniden, temiz ortam, 2 çift × 150 sn | 7900XTX: 103 → 75 ms (paralel yenileme/kayıtla) | taban **117 / 114** · async **119 / 118** (nötr/+%2) | Gönderen iş parçacığının liste adımları gerçekten azaldı (35 → 21, 33.5 → 25.5 ms) AMA kare kısalmadı → kareyi bekleten zincir gönderen iş parçacığı değil; TIMELINE'daki 'victory-under' havuzu (uçuştaki yazmaların altındaki oyun baytları, 70 ms, ölçüm aralığı dışı) ve oyunun render iş parçacığı. Teşhisi daraltan sonuç. Not: temiz tabanın 113-117'ye dönmesi önceki serinin (127-147) indirme yüzünden kirli olduğunu doğruladı. |
| UPLOAD_VRAM=1 (Marvisak #3228, Neon portu 81f68c2 + bizim UPLOAD_VRAM_PERCENT) | 3060 8 GB/16 GB/Wine: GPU 6.0 → 4.9 ms | taban 127/147 · %80: 126/156 (sayaç: %90 RAM'e düştü, yer yok) · %95: 143/138 (sayaç: hepsi VRAM'de, 1117 tampon) | Devreye girdi (%95) ama kazanç yok; tabanlar 127↔147 oynadı (önceki seride 113) → bu seri gürültülü (aynı saatte Nsight indirmesi + ajanlar çalışıyordu). Kapalı. |
| CLAMP_WINDOW=1 (Marvisak #3197, Neon portu a478f49; 2 çift × 150 sn, son 60 sn medyanı) | RTX 3070 8 GB Win11: GPU 199 → 170 ms (kare başına ~5100 clamp geçişi olan main'e karşı) | **143→144, 135→146 ms** (kötü/nötr). Sayaç: tabanda kare başına yalnız **~158 clamp geçişi (hepsi batched)**; CLAMP_WINDOW ile 113 batched + 113 pencere (ort. 32 çizim) | Bizde INDIRECT_BATCH=2 clamp geçişlerini zaten ~5100 → ~158'e indirmiş; #3197'nin kazandığı yer bizde yok (3080 Ti karşı ölçümüyle aynı sonuç). **Clamp yönü bizde bitti** — HOIST ve CLAMP_WINDOW ikisi de bu yüzden boş. Kod kapalı kalır. |
| HOIST_CLAMPS=1 (fxceless #1184, Neon portu; yeni diag, 4 tur × 150 sn, son 60 sn medyanı) | 5070 Ti kontrollü A/B: kart 127 → 107 ms (−%16) | taban 151/142/147/141 (ort 145.3) · hoist 145/139/142/148 (ort **143.5, −1.2%**) · INDIRECT_WINDOW=0+hoist 143/138/162/139 (ort 145.5) | İlk iki tur −%3-4 gösterdi, son iki tur geri aldı → gürültü içinde. Neden bizde az: tabanda INDIRECT_WINDOW=1 + BATCH=2 + CLAMP_WAITS=0 clamp maliyetinin çoğunu zaten almış; 5070 Ti testi bunlar olmadan. Kod kapalı kalır (93146f5). INDIRECT_WINDOW=0 tek başına açılışta 3/3 çöküyor, hoist ile çökmüyor. |
| HOIST_CLAMPS=1 (fxceless #1184, Neon portu) — taban üstüne (2 çift × 150 sn) | 5070 Ti kontrollü A/B: kart 127 → 107 ms | **143→146, 148→147 ms** → GEÇERSİZ: kosu.ps1 **diag** derlemesini çalıştırıyor, port yalnız release'e derlenmişti (diag 15:09). hcc/hcd (WINDOW=0) da eski ikiliyle → geçersiz. Diag 16:33'te derlendi, hce/hcf tekrar koşuyor. | Bizim tabanda INDIRECT_WINDOW=1 + INDIRECT_BATCH=2 açık: tek kayıtlı indirect çizimler pencere/toplu yoldan gidiyor, ön listeye alma neredeyse hiç devreye girmiyor. Pencere kapalı üç kollu test (taban / WINDOW=0 / WINDOW=0+HOIST) sürüyor. |
| Pencereleri karta taşıma: RIPE_BLOCKS=4 + CARD_WINDOWS_MB=1536 + CARD_WINDOWS_PERCENT=95 (4 çift × 150 sn, son 60 sn medyanı) | bizim (80% kapısını açan anahtar) | — | **146→137, 146→147, 148→146, 138→141 ms** (ort. −1.8 ms, gürültü içinde); kartta kopya 12→495-665, +300-400 MB taşındı | Taşıma çalışıyor ama kare süresine yansımıyor: darboğaz kartın kendi hesap yükü, pencere verisinin PCIe'den okunması değil. ProbeGather sıçramaları kısaldı (32-42 → 26-28 ms) ama kare başına etkisi ~1 ms. Kapalı kalır. |
| SHADER_LOOP_LIMIT=4096 TEYİT (150 sn) | — | — | lld-loop **152 ms** (son 60 sn); aynı saatteki tabanlar 146 / 149 (lld-taban açılmadı) | İlk çiftteki 172 → 154 farkı tabanın kötü dilimiydi; teyitte kazanç yok → ret kesinleşti. 26.11 15:15 |
| RIPE_BLOCKS=4 + CARD_WINDOWS_MB=768 (150 sn, son 60 sn medyanı) | bizim (VRAM'de yer açma) | — | **146 → 143, 149 → 147 ms** (gürültü içi) | Kart 6.4 → 5.9 GB'a indi (boş doku bloğu 1279 → 838 MB) ama hâlâ %81 dolu: pencere kapısı %80 → pencerelerin çoğu yine taşınmadı. Sonraki: kapıyı ayarlanabilir yaptım (VICTORY_CARD_WINDOWS_PERCENT, 64631e4), %95 ile wp serisi. 26.11 15:15 |
| MESH_LAUNCH=1 (fablinoo/kelvaroq 32c4ab4fe9, Neon portu 84273df) | kelvaroq | **5080: ağır kare p50 198 → 120 ms, GPU %78 → 35** | **146 → 168, 139 → 178 ms** (iki çift, son 60 sn medyanı, her dilimde kötü); kare başına 3346 kayıt amplification aşamasıyla başlatıldı, 0 pipeline bekliyor | Çalışıyor ama yavaş: 'GPU'yu bekleme' 32-40 → 71-78 ms. Ampere'de (30xx) her mesh çizimine amplification aşaması eklemek pahalı; 5080 (Blackwell) bunu ucuza yapıyor + onun eski clamp yolu 58-94 ms tutuyordu, bizimki zaten topluydu (TAHMİN). Kod kalır, varsayılan kapalı. 26.11 14:55 |
| CARD_WINDOWS_MB=768 — **GEÇERSİZ TEST** | GTX 1660 RESULTS.md (Sol) | GTX 1660 6 GB: 271 → 100 ms (kart tamponu + pencere + mip drop birlikte) | 147.2 → 140.1, 148.5 → 149.9 ms (gürültü) | Hiçbir pencere karta gitmedi: shadow.rs window_room_for kapısı 'kullanılan + boyut > bütçenin %80'i ise hayır'; bizde kart hep %85-88 dolu (6.2-6.4/7.25 GB). VRAM'i dolduranlar (log): 12 kart kopyası 1954 MB, doku blok havuzunda 1147 MB BOŞ ayrılmış yer. Yer açılmadan bu ayar çalışmaz. 26.11 14:25 |
| SHADER_LOOP_LIMIT=4096 (ProbeGather döngüsü için) | Marvisak#898 deseni | 4070/4090/3060 TDR'lı dispatch: 183 → 79 ms; scarlett: LOOP_LIMIT=64 kazanç yok | temiz çift **159.3 → 158.8 ms** (fark yok); ikinci çift kirli (CPU 6.4 çekirdek, Sol derlemesi) | ProbeGather döngü sınırına çarpmıyor → yavaşlığı döngü değil. Kalan aday: okuduğu veri sistem RAM'inde (PCIe) — VRAM_WINDOW / VIDEO_BUDGET testi. 26.11 13:45 |
| SEND_BAR=1 | Neon GPU taraması (7900XTX forku) | 7900XTX: kart ~5 ms az | **152 → 180 ms** (temiz çift, +%18); ikinci çift 184 (tabanda takılma, p90 1607) → 174, belirsiz | Kopyalar kartta biter ama CPU kart belleğine veri yolu üzerinden yazıyor: "hazırlık" 95 → 145-160 ms'ye çıktı (log kanıtı) ve kritik yol oldu. 7900XTX masaüstünde tam Resizable BAR var; laptopta bu yazma yavaş (TAHMİN). Kilitli RAM ~230 MB az. 26.11 13:00 |
| INDIRECT_GATHER=1 (fxceless #1171, Sol portu 50ac222) | fxceless #1171 | **3090 Ti: GPU listeleri 56 → 43-45 ms, kare 116 → 105 ms** | **182 → 204 ms (p90 335 → 2625), 151 → 371 ms** (ikinci çift n=4, kare satırları 172-182 ms) | Bizde clamp'ler zaten toplu (batch) çalışıyor, toplayacak ~1000 ayrı geçiş yok; prelude ek bekleme/takılma getirdi (TAHMİN). Düşen çizim sayısı tabanla aynı (271 + ~690), yani bozulma yok, sadece yavaş. 26.11 12:45 |
| TEXTURE_DROP_MIPS=1 | fxceless #610 / soldsawn | soldsawn 4060L 8 GB: DROP_MIPS=2 ile 8-10 fps (A/B yok); #1022 5060L 16 GB RAM: 2-4 fps (A/B yok) | **153 → 168, 160 → 170 ms (+%6-10)** | VRAM'imiz taşmıyor (6.3/7.1 GB), yani kurtaracağı bir şey yok; ek kopya/eşleme işi kaldı (TAHMİN). Kimse temiz A/B yayınlamamış. |
| DISPLAY_MODE=1280x720 | Neon önerisi | — | 177 → 229, 154 → 278 ms | Oyun modu yok sayıyor, düzlemler yine 1920x1080 / 3840x2160 (log kanıtı). Çözünürlük için tek yol RENDER_SCALE. |
| KEEP_FREED=0 | Neon RAM taraması | — | 172 → 168, 159 → 175 ms | Fark gürültü içinde, RAM de düzelmedi. |
| RAM_TRIM (#1240) | fxceless #1240 | RAM rahatlaması iddiası | **155 → 223, 149 → 234 ms (+%45-55)** | Havuzlar hiç dolmadı, her snapshot yeniden ayrılıyor (profil: NtAllocateVirtualMemory %11, kanıt). |
| MEMORY_MAP=0 | bizim şüphe | — | 161 → 172, 156 → 167 ms | Kazanç yok; uzun kareler yalnız dünyaya girişin ilk 10-20 sn'si. |
| JOIN_PARTS=8 | fxceless | 4070: hız iddiası | 128-149 ms (hızlı) ama **görüntü bozuk** (bulanık, yıkanmış) | Hız ne olursa olsun ret. JOIN_PARTS=2 park. |
| CARD_BUFFERS_MIN_MB=1 | fxceless #413 reçetesi | **3070 Ti 8 GB: 2.05 → 4.62 fps** | **150 → 307 ms (2 kat yavaş)** | Karşılaştırma işi karta taşınıyor, kart işi 42 → 201 ms (log kanıtı). #413'te darboğaz CPU karşılaştırmasıydı, bizde kart. |
| RAW_VIEWS=0 | profil bulgusu | — | 149.7 vs 149.9 ms | Fark yok. |
| LTO thin | soldsawn Cargo.toml | soldsawn: ayrı ölçüm yok | 173 → 199 ms (+%15) | Gürültüden büyük; geri alındı. |
| Shader tablo yaması (e04c0781 elle) | fxceless | — | görüntü yok, RAM kazancı yok | Geri alındı. |
| TEXTURE_BUDGET_MB=768 | bizim | — | 149 ms ama **görüntü bozuk** (doku eksik, oda kararmış) | 1024+ kalır. |
| INPLACE=1 ("sans copie") | Nozy yayını | **Nozy: 16-18 fps** | 490. sn'de **cihaz sıfırlandı** (0x887A0005), yalnız 137 pencere yerinde | Nozy'nin 64 GB'ı var; bizde 16 GB'ta kilitli RAM 5.3 GB'a çıktı (kanıt). |
| COPY_MODE=plain | fxceless | — | 60. sn'de **çöktü** (0xC0000005) | Ham kopya eşlenmemiş sayfaya çarpıyor (Opus uyarısı doğrulandı). |
| WIDE_MERGE=1 (#1066) | fxceless | — | +18 ms (+%7) | Kopya işi arttı. |
| WINDOW_KB=128 | bizim | — | 263-272 → 296 ms | Daha çok parça; 256 kalır. |
| WIDE_REFRESH=1 | fxceless | — | fark yok | Kapalı. |
| cool_fox derlemesinin tamamı | codec-d/cool_fox | "çok hızlı" iddiası, ölçüm yok | **~2.5 kat yavaş + siyah ekran** | Siyah ekran: premultiplied alfa varsayımı (bizimki düz alfa). Repo silindi; iyi parçaları tek tek alınıyor. |


## Teşhis ölçümleri (kabul/ret değil, nereye bakacağımızı gösterir)

| Ne | Bizde | Anlamı |
|---|---|---|
| GPU_TIMING=1 + DRED (gt-teshis, 26.11 13:05) | tek komut baskın: indirect compute **3592426e3e9142d8 = ProbeGather** (ışık probu ışın toplama, XTP shader-roles), tek başına 32.5 / 42.5 ms | Başkasında: 4060 Ti 8 GB ort 9 ms, en kötü 40.7 ms (fxceless #10). Büyük listelerdeki "doku yükleme 8-30 ms" ölçüm hatası: liste başına 4096 damga, kalan komutlar sonuncuya yazılıyor (host.rs STAMPS). |
| SKIP_PIPELINES=3592426e3e9142d8 (tavan ölçümü) | temiz çift skc: **149.9 → 134.6 ms (−%10)**, p90 587 → 150 (takılmalar kayboldu); diğer çiftler 145/146 (tabanları kirli) | Kazanç tavanı ~15 ms + takılmalar. **Görüntü bozuluyor** (duvar posterlerinde renkli bozuk kareler) → atlamak çözüm değil; shader'ın kendisi hızlanmalı (LOOP_LIMIT testi). |
| GPU_TIMING + pencereler kartta (gtw-teshis-win95, 26.11 15:28; RIPE4, WIN1536, PERCENT95) | ProbeGather kare başına **~1 ms** (eski koşuda da 0.6-1.7 ms); 32-42 ms olan tek tük sıçramalardı, şimdi en uzunu 26-28 ms. Kart süresi tek komutta değil, 13-22 listelik birçok gruba yayılmış (her biri 9-18 ms/kare). | **Düzeltme:** ProbeGather kalıcı darboğaz değil, ara sıra takılma kaynağı. Pencereleri karta taşımak sıçramayı ~%30 kısalttı. Atlayınca gelen 15 ms'lik kazanç büyük ihtimalle takılmaların kaybolmasından geliyor. #2705 CARD_COPIES bu yüzden öncelikten düştü. |

## Belirsiz / tekrar gerek

| Ne | Bizde | Not |
|---|---|---|
| BVH_MISS tek başına | 176/162 vs 208 ms | Bir taban bozuktu; paketle birlikte kabul edildi. |
| ASYNC_SUBMIT=1 | 154 → 148 ms (1 temiz çift) | Küçük; ikinci temiz çift gerek. |
| CBV_DIRECT=1 | 267 → 255 ms (eski taban) | Gürültü eşiğinin altında; tekrar gerek. |

## Sırada (STATUS.md "TEST LİSTESİ")

fxceless #1171 indirect gruplama (Sol portluyor; 3090 Ti: kart 56 → 43 ms) → #1227 CARD_SYNC_BATCH (kartta 29 → 6 ms) → SEND_BAR=1 → GPU_TIMING teşhisi → RENDER_SCALE 480/540/720p.
Ölçüm serisinden önce `shaders` + `warm --used` tazelenir.

## 27.11 08:39-08:51 Açık dünya (Jason yatak odası) ac1/ac2: LAND_ECHO=1 / taban / WINDOW_KB 4096 (dünya+40 sn, dünya+10 sn sonrası medyan)
| Koşu | kare ms | hazırlık | kopya ms / MB | doku ms | geri kopya | çizim |
|---|---|---|---|---|---|---|
| ac1-eco | 87.8 | 69.4 | 23.8 / 75.0 | 5.5 | 15.8 | 6068 |
| ac1-tab | 95.8 | 78.7 | 25.1 / 70.3 | 5.5 | 14.4 | 5986 |
| ac1-w4k | 446.9 | 158.5 | 38.6 / 77.1 | 88.2 | 15.5 | 5913 |
| ac2-eco | 152.4 | 122.1 | 34.5 / 87.2 | 36.6 | 15.6 | 8242 |
| ac2-tab | 172.8 | 140.7 | 38.0 / 84.3 | 54.9 | 15.9 | 10059 |
| ac2-w4k | 134.1 | 85.5 | 27.0 / 71.7 | 14.3 | 14.7 | 5910 |
Kareler: 5/5 aynı yer (yatak odası, pencere), görüntü temiz (ac2-tab kare kaydı yok). ECHO=1 kare başına ~3 MB'ı karta tekrar yollamıyor (2-2.6 MB oyunun da yazdığı → gidiyor). **Hüküm yok:** dünya sonrası ilk 40 sn doku akışı (doku 5 → 88 ms) ve çizim 5900-10000 oynuyor; temiz çift (ac1, doku 5.5) eco 87.8 vs tab 95.8. Başkasında: ECHO hiç ölçülmemiş; WINDOW_KB 3070'te 157 → 147 (MKmajster). Neden: ölçüm penceresi ısınmaya denk geldi → ad1/ad2 zinciri dünya+100 sn, ilk 40 sn atılır.

## 27.11 08:52-09:11 Jason ad1/ad2 (dünya+100 sn, ilk 40 sn atıldı) — LAND_ECHO=1 KABUL
| Koşu | kare ms | hazırlık | kopya ms / MB | doku ms | geri kopya | çizim |
|---|---|---|---|---|---|---|
| ad1-eco | 93.4 | 76.2 | 24.0 / 67.8 | 10.9 | 15.2 | 5894 |
| ad1-tab | 129.5 | 96.6 | 31.3 / 84.3 | 26.9 | 14.1 | 7713 |
| ad1-w4k | 104.2 | 79.0 | 24.2 / 68.2 | 21.9 | 14.7 | 6050 |
| ad2-eco | 133.7 | 113.6 | 27.7 / 66.4 | 55.0 | 14.7 | 6074 |
| ad2-tab | 148.0 | 121.9 | 29.2 / 72.8 | 54.7 | 13.6 | 8362 |
| ad2-w4k | 122.8 | 101.2 | 28.5 / 66.7 | 31.4 | 14.2 | 5996 |
Kareler 6/6 aynı yer, temiz. **LAND_ECHO=1: 4/4 çift tabandan hızlı** (ac1 87.8/95.8, ac2 152/173, ad1 93/130, ad2 134/148), kopya MB 66-68 vs 72-84, ~3 MB/kare tekrar gönderim kesiliyor. Uyarı: taban koşularında çizim medyanı daha yüksek (7713/8362, 6500 altı kare yok) → kazancın bir kısmı sahne gürültüsü olabilir. Kod tarafı: avatarmanz'ın varsayılanı 1, bizdeki 0 -Safe kalıntısıydı → düşük risk. **kosu.ps1 tabanına LAND_ECHO=1 alındı.** Başkasında: ölçülmemiş. WINDOW_KB 4096: eski tabana göre 3/4 iyi, eco'ya göre fark yok → yeni taban üstünde ae1/ae2 ile ölçülüyor. Gözlem: geri kopya 14-15 ms ama yalnız 3.5 MB → bayt değil bekleme maliyeti (Neon'a soruldu).

## 27.11 09:30 DÜZELTME + ae1/ae2 (yeni taban LAND_ECHO=1 vs WINDOW_KB 4096)
**Yöntem hatası bulundu:** her koşunun kare yakalayıcısı sonraki koşularda da çalışıyor → `kareler` klasörlerine sonraki koşuların kareleri de düşüyor; önceki "6/6 aynı yer" kontrolü yanlış koşuların karesine bakmıştı. Doğru kareyle (koşunun kendi süresi içindeki son kare, sheet2.py) bakınca **Jason iki farklı odada uyanıyor: yatak odası (~5900-6100 çizim) ve cam kapılı oda (~7700-10000 çizim).** Cam oda: ad1-tab, ad2-tab, ae1-tab (+ ac2-eco 8242, ac2-tab 10059 çizime göre). Beyaz kareler yükleme geçişi, bozulma değil.
| Koşu | oda | kare ms | hazırlık | kopya ms / MB | doku | çizim |
|---|---|---|---|---|---|---|
| ae1-tab (yeni taban) | cam | 102.2 | 76.7 | 29.6 / 89.2 | 5.8 | 8324 |
| ae1-w4k | yatak | 112.8 | 92.0 | 30.4 / 68.0 | 22.8 | 6054 |
| ae2-tab (yeni taban) | yatak | 107.9 | 88.8 | 27.0 / 66.6 | 23.3 | 6014 |
| ae2-w4k | yatak | 113.1 | 85.7 | 27.1 / 67.4 | 26.1 | 5988 |
**LAND_ECHO yeniden değerlendirme (oda içinde):** yatak: eco 87.8 / 93.4 / 133.7 vs eski taban 95.8 (tek); cam: eco 152 / 102 vs eski taban 173 / 130 / 148. Yön aynı (eco ≤ taban) ama önceki "4/4" iddiası oda farkıyla karışıktı → **kanıt zayıf, ayar kalıyor** (avatarmanz varsayılanı, hiçbir odada kötü değil, ~3 MB/kare kesiyor). **WINDOW_KB 4096 RET:** aynı odada (yatak, yeni taban) 107.9 vs 112.8 / 113.1, kopya MB aynı (66-68); MKmajster'in 3070'teki 157 → 147 kazancı bizde yok (bizim kopya zaten 67 MB, onlarınki 154 MB idi). +0.5 GB RAM bedeli boşa. Görüntü: ae2-tab yatak odasında pencere altı duvarda soyuk boya izi var, ae2-w4k ve diğer yatak karelerinde yok → doku/decal akış zamanlaması (doğrulanmadı). Ayrıca gözlem: aynı ayarla ad2 > ad1 (≈ +30-40 ms), zaman/ısı etkisi olabilir.

## 27.11 09:25-09:37 Jason af1/af2: TEXTURE_NO_WAIT=1 vs taban (LAND_ECHO=1) — RET (kare kazancı yok)
| Koşu | oda | kare ms | hazırlık | kopya ms / MB | doku ms | remap bekleme | çizim |
|---|---|---|---|---|---|---|---|
| af1-nw | yatak | 111.4 | 81.0 | 24.9 / 68.3 | 6.2 | 0.0 | 5911 |
| af1-tab | cam | 117.6 | 93.8 | 34.5 / 83.8 | 17.4 | 39.6 | 8217 |
| af2-nw | yatak | 104.9 | 69.6 | 23.2 / 67.3 | 5.3 | 0.0 | 5836 |
| af2-tab | yatak | 107.0 | 82.4 | 25.8 / 67.2 | 19.3 | 60.0 | 5914 |
Yatak odası: NO_WAIT 111.4 / 104.9 (ort. 108.2) vs taban 107.0 / 107.9 (ae2-tab) (ort. 107.5) → **kare süresi değişmiyor**, ama doku 19 → 5-6 ms ve hazırlık ~12 ms düşüyor. Görüntü: af2-tab'da pencere altında su lekesi/kir var, iki NO_WAIT koşusunda da yok; ama taban koşularında da leke bazen yok (ad1-eco, ad2-w4k temiz duvar) → akış zamanlaması, NO_WAIT'e bağlanamadı (doğrulanmadı). **Hüküm: RET** (kazanç yok + olası görüntü riski). **★ Asıl öğrenilen:** hazırlık 12 ms düşünce kare düşmüyor → kareyi bizim hazırlık değil başka bir şey sınırlıyor (panel: SUBMIT BUSY ~86 ms / 100 ms kare, GPU boşta 45 ms). Darboğaz analizi Neon'a verildi. Başkasında: NO_WAIT edsuuu'da açık (hapishane), ayrı ölçüm yok.

## 27.11 09:50-10:10 Jason ah1/ah2: GUARD_OUTSIDE=1 / taban / GUARD_OUTSIDE+BATCH_OPEN — RET (ikisi de)
| Koşu | oda | kare ms | hazırlık | doku | guards kilit bekleme (sayı, ms/kare) | çizim |
|---|---|---|---|---|---|---|
| ah1-go | yatak | 100.7 | 78.2 | 6.3 | 324, 63.1 | 6003 |
| ah1-tab | yatak | 92.2 | 74.2 | 6.8 | 314, 55.0 | 5936 |
| ah1-gob | yatak | 146.9 | 119.3 | 52.5 | 298, 72.0 | 5942 |
| ah2-go | yatak | 117.2 | 96.1 | 31.2 | 304, 45.3 | 6062 |
| ah2-tab | cam | 132.4 | 101.1 | 21.2 | 402, 63.0 | 8264 |
| ah2-gob | yatak | 149.0 | 122.5 | 24.8 | 308, 68.7 | 5973 |
Kareler 6/6 temiz. GUARD_OUTSIDE guards kilit beklemesini düşürmedi (45-63 vs 55-63 ms), yatak odası kare 100.7/117.2 vs 92.2 → kazanç yok. BATCH_OPEN eklenince bekleme 69-72 ms'ye çıktı, kare 147-149 → kötü. Başkasında: GUARD_OUTSIDE fxceless #1315 (ölçüm bizim notlarda yok), avatarmanz PORT_GUARD (paylaşımlı kilit + atomik blok hakkı) 7900 XTX'te bekleme 29 → 2 ms. Neden: bizim bekleme VirtualProtect'in kilit içinde olmasından değil, kilidin kendisinin (GUARDS Mutex, tek) 7 thread arasında çekişmesinden → PORT_GUARD tipi paylaşımlı kilit gerekli.

## 27.11 10:27-10:55 Jason ai1/ai2: taban / RETIRE_BATCH / +LOOSE_FOUND / PORT_GUARD (exe d382668) — HÜKÜM YOK (kirli koşular)
| Koşu | oda | kare ms | hazırlık | guards bekleme (sayı, ms/kare) | bury main | diğer CPU medyan/maks (çekirdek) |
|---|---|---|---|---|---|---|
| ai1-rb | yatak | 103.9 | 82.5 | 341, 81.9 | 2.71 | 2.23 / 5.46 |
| ai1-tab | yatak | 95.9 | 77.3 | 329, 63.6 | 3.29 | 0.59 / 2.76 |
| ai1-rbl | yatak | 111.0 | 89.8 | 343, 72.9 | 4.54 | 1.48 / 4.03 |
| ai1-pg | yatak | 114.4 | 90.8 | **16, 2.6** | 2.80 | 1.21 / 3.61 |
| ai2-rb | yatak | 143.9 | 119.0 | 308, 75.5 | 3.36 | 2.09 / 4.67 |
| ai2-tab | yatak | 116.5 | 92.8 | 356, 75.2 | 2.85 | 2.11 / 4.66 |
| ai2-rbl | yatak | 98.4 | 79.2 | 359, 76.4 | 3.14 | 1.54 / 3.47 |
| ai2-pg | cam | 117.3 | 91.3 | **22, 3.9** | 4.66 | 0.27 / 1.18 |
Kareler temiz (sheet_ai). **PORT_GUARD mekanizması çalışıyor: guards kilit beklemesi 64-82 → 2.6-3.9 ms/kare (-%95), paylaşımlı kilit altında 489-558 fault açılıyor (1.2-1.5 ms bekleme)** — ama kare süresi bu gürültüde ayrışmıyor. Aynı ayarla iki koşu arası fark %20'ye kadar (tab 95.9 vs 116.5; rb 103.9 vs 143.9). **Neden: koşuların 6/8'i kirli** (diğer CPU medyanı > 1 çekirdek; en çok "T3 Code (Beta)" = alt ajan çıktıları/arayüz, ayrıca brave, Taskmgr) **+ oyun BelowNormal öncelikte** → arka plan yükü oyun thread'lerini kesiyor. RETIRE_BATCH bury süresini değiştirmedi (2.7-4.5 ms). Karar: üç bayrak da şimdilik kapalı; öncelik düzeltmesinden sonra ALT AJAN ÇALIŞMAZKEN yeniden ölçülecek. Yöntem kuralı: ölçüm zincirleri sırasında alt ajan yok.

## 27.11 11:00-11:20 Jason aj1/aj2: süreç önceliği Normal / BelowNormal (eski) / AboveNormal (exe 0b74ba0, kare süresi dağılımı ilk kez) — NORMAL KABUL
Temiz koşular (diğer CPU medyanı 0.26-0.51 çekirdek). Kareler 6/6 temiz.
| Koşu | oda | kare ms (5 sn ort.) | p50 | p90 | p99 | max | >150 ms | >250 ms | kare |
|---|---|---|---|---|---|---|---|---|---|
| aj1-nor | cam | 100.1 | 98 | 114 | **130** | 599 | 15 | 4 | 562 |
| aj1-bn | cam | 105.4 | 106 | 131 | 216 | 373 | 42 | 5 | 566 |
| aj1-an | cam | 108.8 | 108 | 120 | 145 | 430 | 30 | 4 | 564 |
| aj2-an | cam | 107.6 | 106 | 123 | 168 | 343 | 28 | 5 | 571 |
| aj2-nor | yatak | 102.8 | 98 | 130 | **184** | 375 | 28 | 2 | 557 |
| aj2-bn | yatak | 116.9 | 96 | 142 | 269 | 782 | 59 | **16** | 527 |
Normal, BelowNormal'a göre iki odada da: ortalama -5 / -14 ms, **p99 216 → 130 ve 269 → 184 ms, >150 ms kareler 42 → 15 ve 59 → 28, >250 ms 16 → 2 (yatak)**. AboveNormal Normal'den iyi değil. **kosu.ps1 varsayılanı -Oncelik Normal** (Yiğit'in -Oyna oturumları da). Başkasında: ölçülmemiş (guvenli_baslat bizim betiğimiz). Neden: BelowNormal'da arka plan süreçleri (T3, Defender) oyun thread'lerini kesiyordu → takılmaların bir kısmı bizim başlatıcıdan. Not: p50 her yerde 96-108 ms; takılma tepeleri (max 343-782 ms) hâlâ var → RAM/paging adımı.

## 27.11 11:22-11:41 Jason ak1/ak2: PORT_GUARD / taban / hep (PG+RETIRE_BATCH+LOOSE_FOUND), Normal öncelik, alt ajan yok (exe 0b74ba0) — HEP RED, PORT_GUARD HÜKÜM YOK
| Koşu | oda | kare ms | p50 | p90 | p99 | max | >150 | >250 | kare | guards ms/kare | diğer CPU medyan/p90 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| ak1-pg | cam | **94.8** | 93 | 106 | **119** | 381 | **9** | 1 | 650 | 7.2 | 0.64 / 1.54 |
| ak1-tab | yatak | 102.2 | 90 | 109 | 236 | 466 | 51 | 18 | 557 | 72.3 | 0.30 / 0.57 |
| ak1-hep | cam | 114.3 | 108 | 189 | 491 | 937 | 93 | 28 | 440 | 28.0 | 0.25 / 0.55 |
| ak2-pg | cam | 156.6 | 124 | 225 | 350 | 689 | 106 | 22 | 428 | 2.8 | 0.90 / 1.76 (kirli: süreç listelemem + taşan izleyiciler) |
| ak2-tab | yatak | 105.8 | 108 | 144 | 205 | 332 | 38 | 5 | 512 | 0.0 | 1.24 / 2.08 (kirli) |
| ak2-hep | yatak | 124.3 | 109 | 143 | 259 | 326 | 71 | 14 | 540 | 8.8 | 1.33 / 2.73 (kirli) |
Kareler 6/6 temiz (sheet_ak). Kıyas cam odası (aj1-nor 100.1, p99 130, >150 15): **ak1-pg şimdiye kadarki en iyi cam koşusu (94.8, p99 119, >150 9)** ama ak2-pg aynı odada 156.6 (kirli). **hep iki odada da kötü** (cam 114 / p99 491, yatak 124 vs taban 102-106) → RETIRE_BATCH + LOOSE_FOUND RED (ai'de de kazanç yoktu), kapalı kalır. PORT_GUARD: 1 iyi + 2 kötü (ikisi kirli) → arka plan temizliğinden sonra al zincirinde 3× tekrar.
Ek bulgu: erken_teshis/kullanim_izle/isi_izle bir sonraki koşuya taşıyordu (ad ile ya da süreyle bekliyordu; ak2-pg kullanım dosyasında iki izleyicinin satırları, 162 satır). Düzeltildi: üçü de ilk gördüğü victory PID'ine bağlı, o kapanınca çıkıyor. Başkasında: yok (bizim betik).

## 27.11 11:42-12:01 Jason al1-3: taban / PORT_GUARD ×3, arka plan temiz (webview2 88 → 6), izleyiciler PID'e bağlı (exe 0b74ba0) — PORT_GUARD KAZANÇ YOK (kapalı), TEMİZLİK FARK YOK
| Koşu | oda | kare ms | p50 | p90 | p99 | max | >150 | >250 | kare | diğer CPU medyan/p90 | boş RAM medyan GB |
|---|---|---|---|---|---|---|---|---|---|---|---|
| al1-tab | yatak | 105.4 | 91 | 140 | 262 | 470 | 52 | 12 | 618 | 0.46 / 1.79 | 0.60 |
| al1-pg | yatak | 105.2 | 98 | 148 | 289 | 752 | 60 | 10 | 588 | 0.22 / 0.43 | 1.13 |
| al2-pg | cam | 108.0 | 108 | 133 | 171 | 684 | 29 | 3 | 559 | 0.48 / 0.77 | 0.79 |
| al2-tab | yatak | **93.5** | 96 | 111 | 171 | 281 | 20 | 4 | 638 | 0.21 / 0.58 | 0.57 |
| al3-tab | cam | 120.4 | 111 | 161 | 302 | 491 | 61 | 10 | 481 | 0.78 / 2.01 | 1.22 |
| al3-pg | cam | 149.2 | 128 | 226 | 325 | 471 | 126 | 25 | 422 | 1.12 / 2.02 (kirli) | 0.54 |
Kareler 6/6 temiz (sheet_al). **PORT_GUARD toplam (ai+ak+al, 7 koşu):** cam 94.8 / 108.0 / 117.3 / 149.2* / 156.6* vs taban cam 100.1 / 120.4; yatak 105.2 / 114.4* vs taban 93.5-105.8. Mekanizma çalışıyor (guards beklemesi -%95) ama kare süresinde tutarlı kazanç yok → **kapalı kalır** (testlerde bayat VIEWS riski de var). Sebep: o bekleme kritik yolda değil; boşalan süre başka beklemeye kayıyor (H28'deki gibi).
**Arka plan temizliği:** taban yatak öncesi 102.2 / 105.8 (p99 236 / 205), sonrası 105.4 / 93.5 (p99 262 / 171) → ayırt edilemez. Boş RAM koşu sırasında yine 0.5-1.2 GB: RAM'i oyunun kendisi dolduruyor, arka plan değil.
**Asıl bulgu (isi_*.csv, 12 koşu):** koşu boyunca diskten ortalama **22.000-39.000 sayfa/sn** (~90-150 MB/sn) geri okunuyor, saniyelerin %57-90'ında >2000/sn. Aynı ayarla koşular arası fark (93.5 ↔ 120.4) bununla ve odayla açıklanıyor → bir sonraki adım RAM (plan 6). Başkasında: Marvisak #1820 (2.5 GB boşaltınca 4.6 → 7.5-8.6 fps), 16 GB'ta herkes aynı duvarda.
