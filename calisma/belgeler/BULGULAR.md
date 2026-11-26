# BULGULAR — tek defter (her ajan bulgusu buraya, aynı tur içinde)

Kural (Yiğit 27.11 00:23): ajan ne bulursa, ölçülmüş olsun olmasın, buraya yazılır. Her yeni tarama görevi önce bu dosyayı okur.
Durum: **bizde var** / **bizde yok** / **denendi → sonuç** / **ölçülmemiş** (kimse sayı vermemiş) / **ölçülmüş: kimde, ne**.
Ayrıntılı A/B sonuçları: TEST_DEFTERI.md. Eski geniş aday tablosu: ADAYLAR.md. Plan: PLAN.md.

## A. Ortak bellek (unified memory) — asıl darboğaz

| # | Bulgu | Kaynak | Ölçüm (kimde) | Bizde | Sıradaki |
|---|---|---|---|---|---|
| A1 | WC (write-combining) bellekteki kart yazımlarını RAM'e geri getirme (`SKIP_WC_BACK`), yalnız ≥1 MiB kopyalar (#1379) | fxceless PR #868 + issue #1379 | RTX 4070: 184 → 148 ms (−%20), copy back 76-100 → 20 ms; RTX 5080 −%11-22; #1379 RTX 5080 copy back 12.8 → 4.6, kare 77.7 → 69.5; küçükler de atlanırsa siyah görüntü | **portlandı a36742c** (Neon, sayaçlı) | A/B wcc/wcd sürüyor; wcc: 144 → 130 ms (tek tur) |
| A2 | "Hiç okunmayan geri kopyayı atla" (`BACK_ONLY_READ` / `BACK_SKIP_UNREAD`) | Op-lite/victory-scarlett copy-back-design.md | **ters sonuç:** 2094 MB'ın %67-71'i sonra gerekti, kare 2× yavaş | yok | yapma; A1'de settle/refresh süresine bak |
| A3 | `RELAY_COPY=1 + FETCH_CHECK=1` | avatarmanz #213 (rafaconvaitis) | RTX 4070: copy back 36.7 → 24.6 ama kare 71.5 → 76.3 (kötü) | RELAY_COPY=1 tabanda | — |
| A4 | Tembel geri kopya (CPU okuyunca fault ile getir) | avatarmanz #43 P6 (fikir), fxceless #1178 `LAZY_COPYBACK` | #1178 sentetik %2 CPU okuma: 40.8 → 16.8 ms; **oyunda ölçülmemiş** | yok | A1 sonrası aday |
| A5 | kelvaroq 0057 `RELAY_LAZY_PATCH` (fault değil: CPU farkını compute ile kuyrukta yamalar) | stellarr-studio/kelvaroq | **ölçülmemiş** | yok | — |
| A6 | kelvaroq 0063 `UMA`/`UMA_POOL` (CPU+GPU ortak havuz, kopya yok) | kelvaroq | kopya >100 MB → <8 MB (test); **fps ölçülmemiş** | yok | sınıflandırma işinde referans |
| A7 | kelvaroq belgesi: "kart uçuştayken oyun aynı yere yazınca ~80 ms bekleme" = bizim under 70 ms | kelvaroq documentation.md | kendi teşhisleri, çözülmemiş | — | A sınıflandırma planı |
| A8 | Geri kopyayı CPU'nun okuduğu aralığa indirme (yuzu/Ryujinx/Kyty fikri) | Sol 26.11 19:30 (rapor ayrıntısı kaybolmuş) | — | yok | Sol 00:23 taramasıyla yenileniyor |
| A9 | avatarmanz #23 `shadow::exact` (NVIDIA'da raw twin yok → karede ~375 kopya) + pr0vId3nce #221 havuz yaması | avatarmanz 2de9980 | bizde y0 314 ms, havuzla 138 ms; RTX 4080 276 → 142 | eski tabanda #23 yok (iyi) | yeni tabana geçilmedi |
| A10 | `PORT_CONSTANTS` (174 MB sabit heap'i kart yerinde okur) | avatarmanz | 7900XTX kazanç; **NVIDIA RTX 5080: kart beklemesi 38 → 119 ms** (#1379) | yeni tabanda | NVIDIA'da yapma |
| A11 | `CARD_BUFFERS_MIN_KB=64` (küçük tamponlar kartta) | fxceless c36971b, #1163, #1379 | RTX 5080 kart komut süresi 42 → 18.5 ms; flamingo RTX 4070 tekne 9.8 → 11.1 fps | env bizde var | 8 GB'ta VRAM riski; A1 sonrası dene |
| A12 | `CARD_BUFFERS_MB=1024 + CARD_WINDOWS_MB=256` | Impre-visible GTX 1660 (Linux) | 360 → 98-112 ms | var | **denendi → ret** (122 vs 126): CPU −6.5 ms, kart +17.4 ms |

## B. VRAM taşması / kartın sistem RAM'inden okuması

| # | Bulgu | Kaynak | Ölçüm | Bizde | Sıradaki |
|---|---|---|---|---|---|
| B1 | Panel: VRAM 6.2/7.1 GB + SHARED 3.6-5.3 GB; kart %92 "meşgul" ama SM %5-8 (dkdknight 5080) | bizim oyna-fare + dkdknight | ölçüm (bizde) | — | SHARED'ın içeriğini ölç (doku mu tampon mu) |
| B2 | `VRAM_EVICT` (QueryVideoMemoryInfo + boşta doku havuzlarını Evict/MakeResident) + `DROP_DXIL` | polackangry/POLSKAGUROM 93f36baf (residency.rs 399 satır, 10.5K satırlık yama) | **ölçülmemiş** (README "RTX 5060 Ti 16 GB'ta test edildi", sayı yok, test dosyaları silinmiş) | yok | B1 doku çıkarsa tek parça port |
| B3 | `TEXTURE_DROP_MIPS=2` | soldsawn (RTX 4060L 8 GB, 48 GB RAM) | 8 GB VRAM dolmasını önler; 104-129 ms (Series X 1080p) | var (DROP_MIPS=1 bizde ret 26.11) | B1'e göre 2 ile yeniden |
| B4 | `WINDOWS_BAR_MB=3072` | trustno1 #6 (RTX 3060 12 GB) | shared 7.5 → 4.4 GB; 1.6-3 → 10-12 fps | var (2048) | 8 GB'ta riskli; B1'e göre |
| B5 | ReBAR / GPU upload heap (AMD'de hızlı) | hipotez | — | WINDOWS_BAR var | Neon 00:23 AMD taraması |

## C. RAM (16 GB)

| # | Bulgu | Kaynak | Ölçüm | Bizde | Sıradaki |
|---|---|---|---|---|---|
| C1 | Uzun oyunda 19 GB private, 3.8 GB fiziksel (oyna-fare 37 dk); oyna-yigit'te 8. dk boş RAM 0.05 GB → 2 fps | bizim loglar | ölçüm | — | `VICTORY_BOOK=1` uzun koşu: 19 GB kimin |
| C2 | `MAX_PRELUDES` / `PRELUDE_IDLE` | WASDeKeys e611e10 | **ölçülmemiş**; bizim logda 1437 prelude, listeler private'ı yalnız +591 MB büyüttü | yok | düşük öncelik (≤0.5 GB) |
| C3 | `STAGING_KEPT` + commit headroom ram_idle | WASDeKeys bc37f3a | ölçülmemiş | STAGING sınırı bizde var | — |
| C4 | `forget_heap`, `LIST_POOL_CAP/TRIM` | ka1qux (avatarmanz c9c932c) | RX 7800 XT; uzun oturumda RAM yine 25 → 32 GB | yok | C1 sonrası |
| C5 | `POOL_CAP`/`POOL_DISCARD`/`PAGE_POOL` | victory-scarlett fox-port-V | karışık (run-159 daha kötü) | yok | zayıf |
| C6 | `WINDOW_REUSE` | fxceless PR #1362 | RTX 3060 Ti 8 GB: kopyalar 3962 → 3209 MB, shared 5033 → 4385 MB; fps ölçülmemiş | yok | C1/B1'e göre aday |
| C7 | `LEVELS_ON_DEMAND=0` | scarlett c45b43e | 4080S: doku kopyası 6.4 GB → 14 MB, commit 37 → 33 GB | **varsayılan 0 (zaten)** | — |

## D. Görüntü

| # | Bulgu | Kaynak | Ölçüm | Bizde | Sıradaki |
|---|---|---|---|---|---|
| D1 | `RT_SKIP_ACTIVATE=1` screen-probe'u atlıyor → mor/gökkuşağı + beyaz bloklar | trustno1 77e13a9 | Yiğit oyunda gördü; ACTIVATE=0 ile uçak sahnesi temiz | **ACTIVATE=0 kabul (görüntü)** | ms maliyeti: wcc tabanı 144 (kirli olabilir) → ayrı ölç |
| D2 | `TEXTURE_NO_WAIT=0` + `CARD_STEPS=1` + `RELAY=2` | #323 (RTX 5060 8 GB: yüzler düzeldi, 11 → 13 fps), #1379 (5080 temiz) | ölçüm başkasında | tabanda NO_WAIT=1, CARD_STEPS=2 | görüntü+hız A/B |
| D3 | Magenta probe filtresi (ambient.rs 1 satır) | Belobug e942896 | ölçülmemiş | yok | D1 yetmezse |
| D4 | `NAN_SCRUB`, `AMBIENT_MOST` | trustno1 77e13a9 | ölçülmemiş | yok | — |

## E. Giriş / kullanım

| # | Bulgu | Kaynak | Durum |
|---|---|---|---|
| E1 | Klavye + fare (ham fare girdisi, ClipCursor, keys.txt) | proneonn/Vertex fae65570 + 2ce20b71 | **portlandı 5f01a4c + d2167ae**, Yiğit oyunda kullandı (20 yakalama) |
| E2 | Alternatifler: Marvisak #3345 (SetCursorPos), #1529 (raw + TOML), Neptune_VI | Neon 23:20 | kullanılmadı |

## F. Taban / genel

| # | Bulgu | Durum |
|---|---|---|
| F1 | avatarmanz 2de9980 yeni taban | **denendi → ret**: 127 ms + karanlık oda/eksik doku (Yiğit: "bizimki daha sağlam"). Kendi yapımızda kalıyoruz |
| F2 | 8 GB / 16 GB NVIDIA sınıfında kaynaklı en iyi sonuç bizim 114 ms (Neon 22:50) | soldsawn 104-129 (48 GB RAM), GTX1660 98-112 (62 GB, Linux, bozuk kafa) |
| F3 | mandyhub-sinkfinger v0.2.0 | yalnız launcher, exe CI'sız/imzasız → ret |
| F4 | Discord listesi: retailayer/ztrx 404, VIctory-loud kaynak yok, VIctory-S/GDeflate/DexNom/xcl/VItoriaBr değer yok; flamingo d56f7b04 heap geçişi 31.6 → 27.0 ms (RTX 4070) | not |

## G. AMD neden hızlı (Neon 00:35; Claude descriptor/host.rs:1332-1405 ve HANDOFF.md:12'yi doğruladı)

| # | Neden | Kanıt | Bize etkisi |
|---|---|---|---|
| G1 | **Raw twin**: AMD 2^21 view heap alır → raw_twins açık; NVIDIA 1,000,000'da sınırlı → yok → hizasız tamponlar kopyaya düşer (#23 patlaması), `PORT_CBV` NVIDIA'da işe yaramaz | descriptor/host.rs:1332-1408, avatarmanz #23/#221, fxceless #1379 | **güçlü**; NVIDIA'ya özel en büyük ceza. Eski tabanımızda #23 yok |
| G2 | NVIDIA sistem RAM'inden (PCIe) okurken çok yavaş: PORT_CONSTANTS 5080'de kart beklemesi 38 → 119 ms; küçük tamponlar VRAM'e alınınca 42 → 18.5 | fxceless #1379 | **güçlü**; B1 (SHARED 3.6-5.3 GB) ile aynı mekanizma |
| G3 | VRAM: 16-24 GB'ta taşma yok; 8 GB'ta %80+ dolu | çok kaynak | güçlü |
| G4 | Wave64: Xbox RDNA2 64-lane; NVIDIA 32-lane'de çift/yarım yol, bazı pipeline'lar reddediliyor | host.rs:1001-1010, fxceless #854 | doğruluk etkisi; **fps etkisi ölçülmemiş** |
| G5 | Geliştirici AMD'de ölçüp optimize ediyor (avatarmanz "7900 XTX first") | README | doğrudan |
| G6 | Bizim laptopta ReBAR **açık** (HANDOFF.md:12), GPU_UPLOAD heap çalışıyor (WINDOWS_BAR_MB kilitli RAM 4726 → 3252) | bizde | B adımında kullanılabilir |
| G7 | CPU: `State::bind` örneklerin %22'si, `ListViews` her listede `made.clear()` → karede ~11k `make_twinned` | bizim STATUS 101/113 (eski profil) | **bizde düzeltilmedi** → aday (CPU tarafı) |
| — | Neon ayrıca MESH_LAUNCH'u önerdi ama **bizde denendi → ret** (146 → 168, 139 → 178 ms; TEST_DEFTERI). WATCH_RESERVATION için bugünkü logda write-watch 5.7 ms (eski 43 ms değil) | — | tekrar önerme |

## H. Başka emülatörler ortak belleği nasıl çözüyor (Sol 00:40; 26.11 19:15 taramasının yerine, bu kez kayıtlı)

| # | Proje | Yöntem | Ölçüm | Bizdeki karşılığı |
|---|---|---|---|---|
| H1 | **Ryujinx** | GPU'nun değiştirdiği aralıkları izler; CPU erişince yalnız o sayfaları flush eder (lazy flush-on-read, commit 1fc0f569) | ölçülmemiş | watch.rs + card_back → **desen 1** |
| H2 | **shadPS4** | CPU/GPU kirli sayfaları ayrı; CPU erişiminde GPU aralığı flush. Precise vs Disabled modları | **RTX 5090 Bloodborne: Precise 106 bekleme/kare, 7.23 ms; Disabled 0; p99 her ikisinde 50 ms** (issue #4316); Disabled DriveClub pozlamasını bozuyor | desen 1; bedel ölçülebilir küçük |
| H3 | **yuzu** | GPU-modified tampon takibi + normal doğrulukta bazı fence/koşullu çizim geri okumalarını atlar | ilerleme raporu ort. %50, en çok %87 (sürüm + ayar birlikte değişmiş) | relay_card_back |
| H4 | **Dolphin** | EFB/XFB'yi yalnız GPU dokusunda tut ("to texture only"); RAM kopyalarını ertele/birleştir, örtülen kopyayı düşür | sayı yok (performans rehberi) | relay_card_back; **desen 2** |
| H5 | **Xenia / Canary** | misafir belleği GPU tamponunda yansıtır, memory watch; `readback_resolve=fast` bir kare önceki sonucu kullanır | ölçülmemiş | shadow.rs, card_back |
| H6 | **Cemu** | streamout GPU'da kalır, RAM'e imza; CPU sayfayı değiştirirse yalnız o alt aralık yeniden yüklenir | ölçülmemiş | under 70 ms birleştirmeye en yakın |
| H7 | **Eden / Citron-NEO** | tampon geri okumasını ayarla kapatma (bazı efektler bozulur); 64 B kullanım takibi | ölçülmemiş | card_back seçimi |
| H8 | **vkd3d-proton / DXVK** | UPLOAD heap'i CPU'nun görebildiği VRAM'e koy (ReBAR); VRAM baskısında kullanılmayanı RAM'e taşı | NVIDIA blog: GPU upload heap tek vertex-fetch 0.20 → <0.01 ms | host.rs upload 24-27 ms; **desen 3**; bizde ReBAR açık (G6) |
| H9 | Kyty, RPCS3, Apple UMA, NCE | aralık→nesne eşleme + hash; çakışmada sıra ile flush; Shared vs Managed | ölçülmemiş | referans |

**Sol'un 3 deseni (PLAN adım 4'e girdi):** (1) GPU'nun yazdığını ilk CPU erişimine kadar VRAM'de tut, yalnız gereken aralığı getir (Ryujinx, shadPS4) → copy back 30-60 ms; (2) örtülen yazıları ele, GPU'da kalan kaynakları sınıflandır (Dolphin, Xenia, Cemu) → under ~70 ms; (3) belleği erişim desenine göre yerleştir, CPU yazma tamponlarını GPU_UPLOAD heap'ine (vkd3d) → upload 24-27 ms + PCIe taşması + RAM.
