# 27.11 Adim 4 + PORT_GUARD tekrar: arka plan temizlendi (webview2 88 -> 6, WhatsApp/GameBar/Widgets/Unity relay kapali),
# izleme betikleri artik kendi PID'ine bagli (onceki kosuya tasma yok). taban / PORT_GUARD x3 donusumlu. Exe 0b74ba0. Alt ajan YOK.
$ErrorActionPreference = 'Continue'
$k = Join-Path $PSScriptRoot 'kosu.ps1'
$sira = @(
    @{ Tag = 'al1-tab'; Ek = @{} },
    @{ Tag = 'al1-pg';  Ek = @{ VICTORY_PORT_GUARD = '1' } },
    @{ Tag = 'al2-pg';  Ek = @{ VICTORY_PORT_GUARD = '1' } },
    @{ Tag = 'al2-tab'; Ek = @{} },
    @{ Tag = 'al3-tab'; Ek = @{} },
    @{ Tag = 'al3-pg';  Ek = @{ VICTORY_PORT_GUARD = '1' } }
)
foreach ($r in $sira) {
    while (Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue) { Start-Sleep 2 }
    "$(Get-Date -Format HH:mm:ss) BASLA $($r.Tag)"
    & $k -Tag $r.Tag -Ek $r.Ek -Sahne acik -DunyaSn 100 -Dakika 5
    "$(Get-Date -Format HH:mm:ss) BITTI $($r.Tag)"
}
"ZINCIR BITTI"
