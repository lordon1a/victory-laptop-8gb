# 27.11 açık dünya (Jason'ın evi) A/B: LAND_ECHO 0 (taban) vs 1. ABBA sırası, FG yok, her koşu -Sahne acik.
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'eca-taban'; Ek = @{} },
    @{ Tag = 'eca-echo';  Ek = @{ VICTORY_LAND_ECHO = '1' } },
    @{ Tag = 'ecb-echo';  Ek = @{ VICTORY_LAND_ECHO = '1' } },
    @{ Tag = 'ecb-taban'; Ek = @{} }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 5 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 60 -Dakika 5
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
    Start-Sleep 20
}
"ZINCIR BITTI"
