# 27.11 Adim 3: oncelik A/B (H34: tum kosular BelowNormal'di). Exe 0b74ba0+ (kare suresi dagilimi). dunya + 100 sn.
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'aj1-nor'; On = 'Normal' },
    @{ Tag = 'aj1-bn';  On = 'BelowNormal' },
    @{ Tag = 'aj1-an';  On = 'AboveNormal' },
    @{ Tag = 'aj2-nor'; On = 'Normal' },
    @{ Tag = 'aj2-bn';  On = 'BelowNormal' },
    @{ Tag = 'aj2-an';  On = 'AboveNormal' }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Sahne acik -DunyaSn 100 -Dakika 5 -Oncelik $r.On
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
