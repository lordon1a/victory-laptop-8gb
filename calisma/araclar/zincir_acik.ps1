# 27.11 08:40 açık dünya (Jason) ardışık koşular: bekleme yok, dünya + 40 sn. Uyanma yeri değiştiği için A/B/C dönüşümlü.
# eco = LAND_ECHO=1 (sayaç: kaç MB kesiliyor), tab = taban, w4k = WINDOW_KB 4096.
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'ac1-eco'; Ek = @{ VICTORY_LAND_ECHO = '1' } },
    @{ Tag = 'ac1-tab'; Ek = @{} },
    @{ Tag = 'ac1-w4k'; Ek = @{ VICTORY_WINDOW_KB = '4096' } },
    @{ Tag = 'ac2-eco'; Ek = @{ VICTORY_LAND_ECHO = '1' } },
    @{ Tag = 'ac2-tab'; Ek = @{} },
    @{ Tag = 'ac2-w4k'; Ek = @{ VICTORY_WINDOW_KB = '4096' } }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 40 -Dakika 4
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
