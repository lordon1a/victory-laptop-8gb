# 27.11 09:55 Jason: taban vs GUARD_OUTSIDE=1 vs GUARD_OUTSIDE=1+BATCH_OPEN=1 (H29: guards kilit beklemesi 39.5 ms/kare). dunya + 100 sn, oda kareden belirlenir.
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'ah1-go';  Ek = @{ VICTORY_GUARD_OUTSIDE = '1' } },
    @{ Tag = 'ah1-tab'; Ek = @{} },
    @{ Tag = 'ah1-gob'; Ek = @{ VICTORY_GUARD_OUTSIDE = '1'; VICTORY_BATCH_OPEN = '1' } },
    @{ Tag = 'ah2-go';  Ek = @{ VICTORY_GUARD_OUTSIDE = '1' } },
    @{ Tag = 'ah2-tab'; Ek = @{} },
    @{ Tag = 'ah2-gob'; Ek = @{ VICTORY_GUARD_OUTSIDE = '1'; VICTORY_BATCH_OPEN = '1' } }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 100 -Dakika 5
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
