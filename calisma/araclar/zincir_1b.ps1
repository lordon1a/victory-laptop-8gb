# 27.11 Adim 1b: Normal oncelik, alt ajan YOK. taban / PORT_GUARD / PORT_GUARD+RETIRE_BATCH+LOOSE_FOUND x2. Exe 0b74ba0. dunya + 100 sn.
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$hepsi = @{ VICTORY_PORT_GUARD = '1'; VICTORY_RETIRE_BATCH = '1'; VICTORY_LOOSE_FOUND = '1' }
$sira = @(
    @{ Tag = 'ak1-pg';  Ek = @{ VICTORY_PORT_GUARD = '1' } },
    @{ Tag = 'ak1-tab'; Ek = @{} },
    @{ Tag = 'ak1-hep'; Ek = $hepsi },
    @{ Tag = 'ak2-pg';  Ek = @{ VICTORY_PORT_GUARD = '1' } },
    @{ Tag = 'ak2-tab'; Ek = @{} },
    @{ Tag = 'ak2-hep'; Ek = $hepsi }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 100 -Dakika 5
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
