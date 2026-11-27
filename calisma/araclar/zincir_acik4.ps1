# 27.11 09:20 Jason: taban (LAND_ECHO=1) vs TEXTURE_NO_WAIT=1 (H27: doku suresinin %92'si runtime remap beklemesi). ABAB, dunya + 100 sn.
$ErrorActionPreference = 'Continue'
while (Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*zincir_acik3.ps1*' }) { Start-Sleep 5 }
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'af1-nw';  Ek = @{ VICTORY_TEXTURE_NO_WAIT = '1' } },
    @{ Tag = 'af1-tab'; Ek = @{} },
    @{ Tag = 'af2-nw';  Ek = @{ VICTORY_TEXTURE_NO_WAIT = '1' } },
    @{ Tag = 'af2-tab'; Ek = @{} }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 100 -Dakika 5
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
