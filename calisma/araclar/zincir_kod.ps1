# 27.11 10:20 Jason: taban vs RETIRE_BATCH=1 vs RETIRE_BATCH=1+LOOSE_FOUND=1 vs PORT_GUARD=1 (Neon kodu, H29-H31; exe d382668). dunya + 100 sn, oda kareden.
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'ai1-rb';  Ek = @{ VICTORY_RETIRE_BATCH = '1' } },
    @{ Tag = 'ai1-tab'; Ek = @{} },
    @{ Tag = 'ai1-rbl'; Ek = @{ VICTORY_RETIRE_BATCH = '1'; VICTORY_LOOSE_FOUND = '1' } },
    @{ Tag = 'ai1-pg';  Ek = @{ VICTORY_PORT_GUARD = '1' } },
    @{ Tag = 'ai2-rb';  Ek = @{ VICTORY_RETIRE_BATCH = '1' } },
    @{ Tag = 'ai2-tab'; Ek = @{} },
    @{ Tag = 'ai2-rbl'; Ek = @{ VICTORY_RETIRE_BATCH = '1'; VICTORY_LOOSE_FOUND = '1' } },
    @{ Tag = 'ai2-pg';  Ek = @{ VICTORY_PORT_GUARD = '1' } }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 100 -Dakika 5
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
