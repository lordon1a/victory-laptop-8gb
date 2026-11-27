# Uzun koşuda fps düşüşünün sebebini ayırmak için (27.11): ısı/kısma mı, RAM/diskten sayfa okuma mı.
# 2 sn'de bir: GPU sıcaklığı, grafik saati, güç, NVIDIA kısma sebebi (bit maskesi), CPU performans yüzdesi
# (100 = taban frekans; düşerse işlemci kısıyor), diskten geri okunan sayfa/sn (RAM yetmiyorsa artar).
# Oyun süreci kapanınca (ya da -Dakika dolunca) biter. Çıktı: kosular\isi_<Tag>.csv
param([Parameter(Mandatory)][string]$Tag, [int]$Dakika = 12)
$ErrorActionPreference = 'SilentlyContinue'
$cikti = Join-Path "$env:LOCALAPPDATA\Victory\kosular" "isi_$Tag.csv"
# kisma_maske: 0x20 = yazılım ısı kısması, 0x40 = donanım ısı kısması, 0x4 = güç sınırı, 0x1 = boşta.
'saat,gpu_c,gpu_mhz,gpu_w,kisma_maske,cpu_perf_yuzde,sayfa_girisi_sn,sayfa_okuma_sn' | Set-Content -Encoding utf8 $cikti
$oyun = '^(victory|game_scarlett_master)$'
# Sayaç adları Windows diline göre değişir; CIM sınıf adları değişmez.
$son = (Get-Date).AddMinutes($Dakika)
$goruldu = $false
$vpid = $null
while ((Get-Date) -lt $son) {
    # 27.11: ilk görülen victory PID'ine bağlı; o kapanınca biter (eskiden süre dolana dek sonraki koşuya taşıyordu).
    if (-not $vpid) { $vpid = (Get-Process victory -ErrorAction SilentlyContinue | Sort-Object StartTime -Descending | Select-Object -First 1).Id }
    $oyunVar = [bool]($vpid -and (Get-Process -Id $vpid -ErrorAction SilentlyContinue))
    if ($oyunVar) { $goruldu = $true } elseif ($goruldu) { break }
    $g = (& nvidia-smi --query-gpu=temperature.gpu,clocks.gr,power.draw,clocks_throttle_reasons.active --format=csv,noheader,nounits 2>$null) -split ',\s*'
    $m = Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory
    $perf = (Get-CimInstance Win32_PerfFormattedData_Counters_ProcessorInformation -Filter "Name='_Total'").PercentProcessorPerformance
    $giris = $m.PagesInputPersec
    $okuma = $m.PageReadsPersec
    [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0},{1},{2},{3},{4},{5:F0},{6:F0},{7:F0}',
        (Get-Date -Format 'HH:mm:ss'), $g[0], $g[1], $g[2], $g[3], $perf, $giris, $okuma) | Add-Content -Encoding utf8 $cikti
    Start-Sleep 1
}
