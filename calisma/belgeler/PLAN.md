# PLAN — NVIDIA 8 GB / 16 GB'ta fps (27.11.2026, Yiğit onaylı yön)

Kayıt: her bulgu BULGULAR.md, her A/B TEST_DEFTERI.md, her adım STATUS.md; adım sonunda kaydet.ps1 -Gonder + acik_guncelle.ps1.
Her adımdan önce: BULGULAR.md'ye bak + ajana "kim yaptı/ölçtü" taraması (Amerika'yı yeniden keşfetme). Kendi yapımızda kalıyoruz (taban değişikliği yok).

## 0. Ölçüm düzeni (değişmez)
- Sahne 1 **hapishane** (save yedek_saves_20261126_0520): kosu.ps1, dünya+150 sn, son 60 sn medyanı, 2 tur A/B, kare yan yana bakılır.
- Sahne 2 **uçak/dış dünya** (save yedek_saves_20261127_ucak_sahnesi): yeni; dış dünya ölçümü için. Kurulacak (adım 0b).
- Uzun koşu: 20 dk, RAM/commit/working set eğrisi (olcum.csv) — RAM işleri için.
- Yiğit oynadıysa: ilerlemeyi yedekle, hapishane save'ini geri koy (memory: victory-restore-prison-save).
- Kabul: 2 turda da daha iyi + kare temiz + sayaç devrede. Fark < ~3 ms = gürültü.

## Bugünkü durum (ölçülmüş)
- Hapishane: 114 ms (ACTIVATE=1). ACTIVATE=0 ile 144? (kirli olabilir, adım 0a).
- Dış dünya (uçak): 150-250 ms, kart 127 ms meşgul, 6-7k çizim, prep 80-110, copy back 28-37 ms.
- RAM: 19 GB private, 3.8 GB fiziksel. VRAM 6.2/7.1 + shared 3.6-5.3 GB.

## Adım 0 — tabanı netleştir (bu gece)
- 0a. `RT_SKIP_ACTIVATE=0` maliyeti: temiz 2 tur (ACTIVATE 1 vs 0). Görüntü için 0 kabul; maliyet yüksekse D2/D3 ile ucuz düzeltme ara.
- 0b. Uçak sahnesi save'iyle ölçüm düzeni: kosu.ps1'e `-Sahne ucak` (save kopyalama + geri koyma otomatik).
- Bitti kanıtı: iki sahnede taban sayısı TEST_DEFTERI'nde.

## Adım 1 — geri kopyayı kes (A1, sürüyor)
- `SKIP_WC_BACK=1` hapishane 2 tur (wcc/wcd) + uçak 2 tur. Sayaç: "skipped WC copy-back N copies X MB".
- Ayrıca bak: settle/RAM refresh süresi artıyor mu (A2 tuzağı), kare temiz mi.
- Kabul olursa tabana. Beklenen −15-25 ms (4070'te −%20).

## Adım 2 — VRAM taşmasının içini ölç, sonra boşalt (B)
- 2a. Ölçüm: SHARED 3.6-5.3 GB ne? (doku / title tamponu kopyası / pencere / staging). Araç: `VICTORY_BOOK=1` + kart bellek muhasebesi (`CARD_ACCOUNTING`) + PIPELINE_TIMING ile en pahalı pipeline'ların hangi kaynakları okuduğu. Tarama: aynı ölçümü yapan var mı.
- 2b. Kanıt: kart beklemesi taşmadan mı? (Taşmayı azaltan tek ayarla kart ms'i düşüyor mu — ör. RENDER_SCALE değil, DROP_MIPS=2.)
- 2c. İçeriğe göre: doku → B3 DROP_MIPS=2 / B2 VRAM_EVICT tek parça; tampon → C6 WINDOW_REUSE / A11 MIN_KB=64; pencere → WINDOWS_BAR ayarı.
- Bitti kanıtı: SHARED < 1.5 GB ve kart ms düşüşü, kare temiz.

## Adım 3 — RAM'i 16 GB'a sığdır (C)
- 3a. Uzun koşu `VICTORY_BOOK=1`: 19 GB'ın sahipleri (title belleği, host kopyaları, pipeline kütüphanesi, staging, listeler).
- 3b. En büyük sahibe göre: GPU-only belleğin RAM kopyasını kaldırma (A sınıflandırmasıyla aynı iş), C6, C4, C2.
- Bitti kanıtı: 20 dk'da private < 14 GB veya fiziksel payı belirgin artmış, fps düşüşü yok.

## Adım 4 — bellek sınıflandırması (asıl mühendislik işi, birkaç gün)
- Oyunun her XMem ayırmasını sınıfla: yalnız CPU / yalnız GPU / ortak (XMem bayrakları WC/uncached/GPU erişim bitleri + gözlenen erişim; #868 census temeli).
- Census: sınıf başına MB, karede yukarı/aşağı trafik.
- Yalnız GPU → VRAM'de tek kopya, geri kopya yok, RAM kopyası yok. Yalnız CPU → karta hiç gitmez. Ortak → mevcut senkron.
- Referans: kelvaroq 0063 UMA, scarlett KNOWN_WRITES/GPU_ONLY, Sol'un emülatör taraması (Dolphin EFB-to-texture, yuzu/Ryujinx GPU-modified takibi, Xenia, shadPS4).
- Bitti kanıtı: copy back + under (70 ms) belirgin düşer; iki sahnede A/B.

## Adım 5 — takılmalar
- `victory warm` (avatarmanz) portu: yeni bölgede 291 shader derlemesi takılması.
- Uçak sahnesinde ilk giriş vs ikinci giriş karşılaştırması.

## Beklenti (dürüst)
- Hapishane 9 → 12-15 fps, dış dünya 5 → 8-10 fps hepsi tutarsa. 30 fps bu donanımda yok (kelvaroq RTX 4090 ~11 fps).

## Açık araştırmalar (27.11 00:23)
- Neon: AMD neden hızlı (RDNA2 = Xbox, raw twin, ReBAR/GPU upload heap, VRAM).
- Sol: emülatörler ortak belleği nasıl çözüyor (26.11 19:15 taramasının ayrıntısı kaybolmuştu; bu kez BULGULAR'a işlenecek).

## Adım 6 — motion blur kapatma (Yiğit isteği 27.11 01:50)
- Önce tarama (Neon, 01:50): kim kapattı, oyun ayarı mı / pipeline hash atlama mı / shader yaması mı; bizde SKIP_PIPELINES benzeri yol var mı.
- Sonra: tek koşu + kare karşılaştırma (hareket halinde bulanıklık, ghosting yok mu), fps etkisi.
- Bitti kanıtı: hareketli karelerde bulanıklık yok, başka efekt bozulmamış.

## Adım 2 sonucu (27.11 01:50) — küçük tamponları karta al
- MIN_KB=64 + MB=1024: 130 → 74-80 ms (7.5 → 13 fps). Görüntü bedeli: tel/INMATE kaybı (SKIP_WC_BACK yarışı), tişört/saç ışığı farkı.
- Temiz aday: min64 + CARD_STEPS=1 + TEXTURE_NO_WAIT=0 (mkf-x2, 78 ms, tel + INMATE var, saç doğru koyu). Kabul için 2. tur + SKIP_WC_BACK=0 varyantı.

## Adım 7 — FSR 3 frame gen (Yiğit 27.11 03:00, BULGULAR E2/E3)
- 7a. Ölçüm: OWN_UPSCALER=0 (konsol FSR yolu açık) maliyeti — FG'nin girdisi (MV/depth) bu yoldan geliyor.
- 7b. Port (Neon, ayrı dal, varsayılan kapalı): gleaf-6 252ccc10 framegen.rs + hle fidelityfx.rs + Marvisak #1868 (RGB9E5→FP16) + 3.x provider seçimi + tek present listesi (late_free_present çökmesi).
- 7c. SDK: FidelityFX SDK kaynaktan derleme (hazır DLL kuralı) — Yiğit onayı ile AMD imzalı DLL de olabilir.
- 7d. A/B: gösterilen fps, gerçek fps, kare (ghosting/HUD), 10 dk çökme.
- Not: 13-14 fps tabanda gecikme düşmez; görüntü akıcılaşır.

## Adım 8 — görüntü ayarları (Yiğit 27.11 03:02)
- 8a. Motion blur maliyeti: `victory translate` ile hash→isim listesi, MotionBlur shader'larının kart süresi (PIPELINE_TIMING); oynarken menüden 0 (BULGULAR D5). Beklenen: görüntü belirgin temiz, fps +0.5 civarı.
- 8b. Çözünürlük: şu an RENDER_SCALE=0.5 (OWN_UPSCALER). Eğri: 0.5 = 115/113, 0.6 = 121/118, 0.75 açılışta çöktü (TEST_DEFTERI s.24); DISPLAY_MODE=1280x720 ret (oyun yok sayıyor). Sırada: 0.4 ve 0.33 A/B + kare (bulanıklık). Not: kart artık 33 ms / kare ~75 ms → kazanç sınırlı bekleniyor; ölçmeden bilinmez.
