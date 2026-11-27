# 27.11 08:40 açık dünya (Jason) ardışık koşular: bekleme yok, dünya + 100 sn (ilk 40 sn doku akışı, ölçülmez). Uyanma yeri değiştiği için A/B/C dönüşümlü.
# eco = LAND_ECHO=1 (sayaç: kaç MB kesiliyor), tab = taban, w4k = WINDOW_KB 4096.
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'ad1-eco'; Ek = @{ VICTORY_LAND_ECHO = '1' } },
    @{ Tag = 'ad1-tab'; Ek = @{} },
    @{ Tag = 'ad1-w4k'; Ek = @{ VICTORY_WINDOW_KB = '4096' } },
    @{ Tag = 'ad2-eco'; Ek = @{ VICTORY_LAND_ECHO = '1' } },
    @{ Tag = 'ad2-tab'; Ek = @{} },
    @{ Tag = 'ad2-w4k'; Ek = @{ VICTORY_WINDOW_KB = '4096' } }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 100 -Dakika 5
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
