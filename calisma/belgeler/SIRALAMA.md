# Bulgular sıralaması (27.11 08:35) — en işe yarardan en kötüye

Ölçüt: bizim açık dünya darboğazına (CPU kopya/hazırlık 89-122 ms, kopya 35-48 ms, geri kopya 14-20 ms; GPU bekleme 4-6 ms) oturuyor mu + gerçek ölçüm var mı + mühendislik derinliği.

## ★ 27.11 09:55 GÜNCELLEME — kritik yol bulundu (H29)
Profil: oyun thread'leri zamanının %67'si bizim çizim çevirimizde (execute_indirect > bind %21, gönderim %13). Kopya/geri kopya/doku işleri kare kazancı vermedi (WINDOW_KB, TEXTURE_NO_WAIT, DESC_MARKS). **Yeni 1. sıra: bind/descriptor maliyeti + kilit çekişmesi** (HostHeap::keep/retire_resource mutex, shadow::lookup RwLock, watch::guards). 2.: gönderimi oyun thread'inden almak (ASYNC_SUBMIT). Akıllı kurye ve kopya işleri kritik yol bu tarafa geçince ikinci aşama.

## A. Gerçek mühendislik, asıl darboğaza oturuyor
1. **Akıllı kurye (GPU-yazılı aralığı katman tekrar okumasın/yüklemesin)** — shadPS4 modeli (gpu_modified_ranges, 2 yılda üretime girdi), Ryujinx/Xenia aynı fikir. VIctory'de kanıt: fxceless #1169 oyun geri kopyanın %0.1-0.3'ünü okuyor, katman okumalarının %92'si kendi çıktısı. Adımlar: (a) LAND_ECHO=1 kodsuz [TEST EDİLİYOR], (b) LAND_SKIP=1, (c) land_back + note_landing (PC kopyaları), (d) tam GPU-kirli takip. Risk: bayat veri. H22, H23, H25.
2. **Op-lite SOFT_VIEWS=copies paketi (bc264a41)** — re-upload 6.4 GB → <15 MB, 4080S 59-66 → 46-49 ms. Aynı sorunu (tekrar yükleme) başka yoldan çözmüş; 1 ile birleşebilir. Tek tek alınmalı.
3. **cool_fox büyük tampon VRAM rezervi (#40, ana dala girdi)** — 4060 Laptop 8 GB: 348 → 88 ms. Bizde büyük tamponlar RAM'e düşüyorsa doğrudan kopyayı keser. Önce sayaç.
4. **WINDOW_KB 256 → 4096** — aynı kart (3070 8 GB + 16 GB) MKmajster: 153.7 → 88.6 MB/kare, 157 → 147 ms, +0.5 GB RAM. Kodsuz.
5. **XCL #2844 CUSTOM L0 pencere** — 5070 Ti dünya 0.62 → 3.03 fps. Neon raporu bekleniyor.

## B. Gerçek ölçüm var, orta etki
6. **Series S çok-düzlemli present'i beklemeden gönder (edsuuu 511f629a)** — ~20 ms/kare bekleme. Bizde var mı önce kodu oku.
7. **Descriptor işaretleme (MKmajster/#1083)** — 3070: 185 → 144 ms. Bizde DESC_MARKS denendi, PARK.
8. **SPREAD_LEAN (fxceless #1352)** — 3060: 225 → 208 ms (9/9).
9. **ASYNC_SUBMIT (edsuuu / fxceless f85101b6)** — 4060 Ti min 14.4 → 18.6 fps. 16 GB'ta thread çekişmesi riski.
10. **MERGE_SUBMISSIONS (Peppa #20)** — 5080 −1.86 ms.

## C. Küçük / ölçülmemiş / GPU tarafı
11. RT atlama genişletmesi (Skinning/TraceRays_BVH/VBuffer/Hair, edsuuu) — GPU işi; açık dünyada GPU darboğaz değil. Hapishanede işe yarar.
12. CARD_COMPARE_JOIN (edsuuu 2f59f1df) — ölçülmemiş.
13. Write-watch rezervasyon sorgusu (#1365) — p95 206 → 193.
14. #1407 geri kopya taşma düzeltmesi — doğruluk, hız değil.
15. VRAM_EVICT (POLSKAGUROM) — ölçüm yok.
16. MAX_PRELUDES (WASDeKeys) — en fazla ~0.5 GB RAM.

## D. Denendi / kötü / kullanma
- Bizde reddedildi: COPY_BACK_BESIDE, REAPER, POOL_DISCARD (görüntü kaybı), RENDER_SCALE 0.4/0.33.
- Başkasında kötü: TABLED_ALL (8 GB'ta 166 → 195), BACK_ONLY_READ (2× yavaş), #1178 v1 lazy copyback VEH (5.09 → 4.73 fps), Op-lite BACK_SKIP_UNREAD (87 → 92 ms), PORT_CONSTANTS / zero-copy (NVIDIA'da GPU 52 → 134 ms), mimalloc (16 GB'ta RAM), AMBIENT=constant (görüntü ödünü).
- KULLANMA (hazır ikili/güvenlik): i95 launcher, ZRen runtime ZIP, Mandyhub.
