# Güncel en iyi ayarlarla (B13b / c0-ltosuz tabanı) tek komutla ölçüm koşusu.
# Taban koşul her seferinde aynı kalsın diye ayarlar burada sabit; deneme yalnız -Ek ile eklenir (TEK değişken).
# Kullanım:
#   kosu.ps1 -Tag p1-profil -Ek @{ VICTORY_PROFILE = '150,240,10,C:\...\profil.txt' }
#   kosu.ps1 -Tag c2-deneme -Ek @{ VICTORY_LOOKUP_CACHE = '1' } -Dakika 4.5
param(
    [Parameter(Mandatory)][ValidatePattern('^[\p{L}\p{Nd}_-]{1,64}$')][string]$Tag,
    [hashtable]$Ek = @{},
    [double]$Dakika = 4.5,
    [string]$VictoryExe = 'C:\CLLL\.calisma\vw-avatar\target\diag\victory.exe',
    [switch]$DryRun,
    # Bizim taban ayarlarını kaldır, yalnız -Ek uygula (başka bir build'i kendi ayar setiyle ölçmek için; ör. Neptune).
    [switch]$TabanYok,
    # Dünya göründükten kaç sn sonra koşu biter (0 = Dakika dolana kadar).
    [int]$DunyaSn = 80,
    # Betikli tuş(lar): bizde Enter = klavye Enter + pad A. Neptune'de pad A = Space (gameinput.rs A_KEY) ama ara sahne
    # klavye Enter'ı basılı tutarak geçiliyor → Neptune için 'Enter,Space' (ikisi birden).
    [string[]]$Tus = @('Enter'),
    # Yiğit oynuyor (27.11): betikli tuş yok, erken teşhis (donma/düz renk → kapat) yok, dünya sonrası durdurma yok.
    [switch]$Oyna,
    # Test sahnesi (27.11): koşudan önce saves bu yedekle değiştirilir (oyunun kendi kaydı sahneyi kaydırmasın).
    # 'acik' = Yiğit'in açık dünya kaydı, 'hapishane' = eski sahne, '' = dokunma.
    [ValidateSet('', 'acik', 'hapishane')][string]$Sahne = ''
)
if ($Oyna) { $Tus = @(); $DunyaSn = 0 }
$ErrorActionPreference = 'Stop'

if ($Sahne -and -not $DryRun) {
    $kayitlar = @{
        acik      = '%USERPROFILE%\AppData\Local\Victory\yedek_saves_20261127_0730_acikdunya'
        hapishane = '%USERPROFILE%\AppData\Local\Victory\yedek_saves_20261127_0710_hapishane'
    }
    $saves = '%USERPROFILE%\AppData\Local\Victory\data-root\data\7952987A\saves'
    $kaynak = Join-Path $kayitlar[$Sahne] '0009000000000001'
    if (-not (Test-Path -LiteralPath $kaynak)) { throw "Sahne kaydı yok: $kaynak" }
    if (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { throw 'Oyun açıkken kayıt değiştirilmez.' }
    $hedef = Join-Path $saves '0009000000000001'
    if (Test-Path -LiteralPath $hedef) { Remove-Item -LiteralPath $hedef -Recurse -Force }
    Copy-Item -LiteralPath $kaynak -Destination $hedef -Recurse
    $a = Get-ChildItem -Recurse -File $kaynak | ForEach-Object { (Get-FileHash $_.FullName).Hash } | Sort-Object
    $b = Get-ChildItem -Recurse -File $hedef | ForEach-Object { (Get-FileHash $_.FullName).Hash } | Sort-Object
    if (Compare-Object $a $b) { throw 'Sahne kaydı kopyası tutmadı.' }
    "Sahne: $Sahne ($($b.Count) dosya, hash aynı)"
}

# 26.11 taban ayar seti (c0-ltosuz 172.7 ms, B13b 169.6 ms; kaynak: kosular\20261126-050543_c0-ltosuz\ayarlar.txt).
$taban = [ordered]@{
    VICTORY_AMBIENT            = '0.8'
    VICTORY_BOOK               = '0'
    VICTORY_CARD_ACCOUNTING    = $null
    VICTORY_CARD_AWAKE         = '0'
    # 27.11 02:07 KABUL (Adim 2): kucuk tamponlar karta. mkc/mkd + mkh: 129/134/118 -> 74/80/90 ms, kart 63 -> 33 ms, goruntu 4/4 temiz
    VICTORY_CARD_BUFFERS_MB    = '1024'
    VICTORY_CARD_BUFFERS_MIN_KB = '64'
    VICTORY_FETCH_CHECK        = '1'
    VICTORY_SKIP_WC_BACK_MIN_KB = '16384'
    VICTORY_CARD_REHASH_RUNS   = '1'
    VICTORY_CARD_STEPS         = '1'
    VICTORY_D3D12_DRED         = 'light'
    # D1 (26.11): 1M view heap'inde dinamik tablo yuvaları 2^18 → 524288; reddedilen tablo (= düşen çizim) ~1000/kare → 0.
    VICTORY_DYNAMIC_SLOTS      = '524288'
    # 26.11 RT paketi kabul (rtb: 184 -> 150 ms, goruntu ayni): BVH yapisi kurulmadan bosa calisan isin izleme isi kesilir.
    VICTORY_BVH_MISS           = '1'
    # 26.11 12:35 Yigit: overlay her kosuda acik (F9 kapatir); A ve B'de ayni, olcumu bozmaz.
    VICTORY_PANEL              = '1'
    # 26.11 14:25 CLAMP_WAITS=0 kabul (cwb 149.3 -> 143.0 ms, p90 250 -> 146; goruntu ayni).
    VICTORY_CLAMP_WAITS        = '0'
    # 26.11 18:30 KABUL: oyunun kendi TAA upscaler'i + %50 ic cozunurluk (rsa/rsb: 143.5 -> 113 ms, -%21)
    VICTORY_OWN_UPSCALER       = '1'
    VICTORY_RENDER_SCALE       = '0.5'
    # 27.11 00:40 KABUL: #868 geri kopya atlama (144 -> 130, 140 -> 128 ms)
    VICTORY_SKIP_WC_BACK       = '1'
    VICTORY_RT_SKIP_RESOLVE    = '1'
    # 27.11 00:50 KABUL: 0 = screen-probe acik (mor/gokkusagi duzeldi), maliyet 3-4 ms
    VICTORY_RT_SKIP_ACTIVATE   = '0'
    VICTORY_INDIRECT_BATCH     = '2'
    VICTORY_INDIRECT_WINDOW    = '1'
    VICTORY_INPLACE_PROBE      = $null
    VICTORY_JOIN_COPIES        = '1'
    VICTORY_LAND_ECHO          = '0'
    VICTORY_MAP_THREADS        = '1'
    VICTORY_MEMORY_MAP         = '1'
    VICTORY_PIPELINE_BOOK      = '1'
    VICTORY_RELAY              = '2'
    VICTORY_RELAY_COPY         = '1'
    VICTORY_SEND_KEPT_MB       = '128'
    VICTORY_SHOW_AFTER         = '1'
    VICTORY_SKIP_PIPELINES     = $null
    VICTORY_TEXTURE_BUDGET_MB  = '1024'
    VICTORY_TEXTURE_NO_WAIT    = '0'
    VICTORY_TEXTURE_ROOM_PERCENT = $null
    VICTORY_TITLE_PRIORITIES   = '0'
    VICTORY_UNDER_WIDE         = '0'
    VICTORY_WIDE_BACK          = '1'
    VICTORY_WINDOW_KB          = '256'
    VICTORY_WINDOW_TAILS       = '1'
    VICTORY_WINDOWS_BAR_MB     = '2048'
    VICTORY_WINDOWS_BAR_PERCENT = '88'
}
$set = @{}
foreach ($k in $taban.Keys) { $set[$k] = if ($TabanYok) { $null } else { $taban[$k] } }
foreach ($k in $Ek.Keys) { $set[$k] = $Ek[$k] }

# Enter deseni (Yiğit "unutma", 26.11): 20-150 sn, 2.5 sn basılı / 0.5 sn bırak (intro/hikâye basılı-tut ile atlanır).
$tuslar = foreach ($k in $Tus) { @(for ($t = 20; $t -lt 149; $t += 3) { "$t-$($t + 2.5):$k" }) + "149-150:$k" }

$arg = @{
    Keys           = $tuslar -join ','
    Game           = '<OYUN_KLASORU>\game_scarlett_master.exe'
    Build          = 'diag'
    VictoryExe     = $VictoryExe
    Console        = 'series-s'
    Tag            = $Tag
    MaxMinutes     = $Dakika
    Set            = $set
    # Yiğit onaylı koruma (26.11): boş RAM 0.2 GB / 30 sn, commit tavanı 28 GB.
    MinFreeRamGB   = 0.2
    SustainSeconds = 30
    MaxCommitGB    = 28
}
if ($DryRun) { $arg.DryRun = $true }
"Koşu $Tag | ek: " + (($Ek.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ', ')
# Erken teşhis (düz renk / donma / dünya gelmedi → DURDUR) koşuyla birlikte, ayrı süreçte.
if (-not $DryRun) {
    if (-not $Oyna) {
        Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
            (Join-Path $PSScriptRoot 'erken_teshis.ps1') | Out-Null
    }
    # PC kullanımı kaydı (26.11): Yiğit koşu sırasında PC'yi kullanabilir; bozulan koşuyu bu kayıt ayıklar.
    Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        (Join-Path $PSScriptRoot 'kullanim_izle.ps1'), '-Tag', $Tag, '-Dakika', ($Dakika + 2) | Out-Null
    # Isı/kısma ve diskten sayfa okuma kaydı (27.11): uzun koşuda fps düşüşü RAM mı ısı mı.
    Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
        (Join-Path $PSScriptRoot 'isi_izle.ps1'), '-Tag', $Tag, '-Dakika', ($Dakika + 2) | Out-Null
    # Dünya göründükten DunyaSn sonra bitir (Yiğit 26.11: fps oturuyor; 0 = tam süre, ör. profil koşuları).
    if ($DunyaSn -gt 0) {
        Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File',
            (Join-Path $PSScriptRoot 'dunya_sonra_dur.ps1'), '-Tag', $Tag, '-Saniye', $DunyaSn | Out-Null
    }
}
& (Join-Path $PSScriptRoot 'olcum_profili.ps1') @arg
