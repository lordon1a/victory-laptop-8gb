# 27.11 09:15 Jason: yeni taban (LAND_ECHO=1) vs + WINDOW_KB 4096, ABAB, dünya + 100 sn (ilk 40 sn ölçülmez).
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'ae1-tab'; Ek = @{} },
    @{ Tag = 'ae1-w4k'; Ek = @{ VICTORY_WINDOW_KB = '4096' } },
    @{ Tag = 'ae2-tab'; Ek = @{} },
    @{ Tag = 'ae2-w4k'; Ek = @{ VICTORY_WINDOW_KB = '4096' } }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 100 -Dakika 5
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
