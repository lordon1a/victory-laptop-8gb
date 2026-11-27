# Koşu sırasında PC'nin başka işlerle ne kadar meşgul olduğunu kaydeder: Yiğit PC'yi kullanabilir (Brave vb.),
# ölçümü bozan koşuyu sonradan bu kayıt ayıklar (kisa_ozet "kullanım" satırı).
# 2 sn'de bir: öndeki pencerenin süreci, oyun/victory dışı süreçlerin toplam CPU'su (çekirdek) ve RAM'i, boş RAM.
# Oyun süreci kapanınca (ya da -Dakika dolunca) biter. Çıktı: kosular\kullanim_<Tag>.csv
param([Parameter(Mandatory)][string]$Tag, [int]$Dakika = 8)
$ErrorActionPreference = 'SilentlyContinue'
Add-Type -Namespace Kz -Name W -MemberDefinition @'
[DllImport("user32.dll")] public static extern System.IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(System.IntPtr h, out uint pid);
'@
$cikti = Join-Path "$env:LOCALAPPDATA\Victory\kosular" "kullanim_$Tag.csv"
'saat,on_surec,diger_cpu_cekirdek,diger_ram_gb,bos_ram_gb' | Set-Content -Encoding utf8 $cikti
$oyun = '^(victory|game_scarlett_master)$'
$cekirdek = [Environment]::ProcessorCount
$once = @{}
$son = (Get-Date).AddMinutes($Dakika)
$goruldu = $false
$vpid = $null
$t0 = Get-Date
while ((Get-Date) -lt $son) {
    $hepsi = Get-Process
    # 27.11: ilk görülen victory PID'ine bağlı; o kapanınca biter (eskiden süre dolana dek sonraki koşuya taşıyordu).
    if (-not $vpid) { $vpid = ($hepsi | Where-Object ProcessName -eq 'victory' | Sort-Object StartTime -Descending | Select-Object -First 1).Id }
    $oyunVar = [bool]($vpid -and ($hepsi | Where-Object Id -eq $vpid))
    if ($oyunVar) { $goruldu = $true } elseif ($goruldu) { break }
    $pid0 = 0; [void][Kz.W]::GetWindowThreadProcessId([Kz.W]::GetForegroundWindow(), [ref]$pid0)
    $on = ($hepsi | Where-Object Id -eq $pid0).ProcessName
    $diger = $hepsi | Where-Object { $_.ProcessName -notmatch $oyun -and $_.Id -ne 0 -and $_.ProcessName -ne 'Idle' }
    $simdi = @{}; $cpu = 0.0
    foreach ($p in $diger) { if ($p.CPU) { $simdi[$p.Id] = $p.CPU; if ($once.ContainsKey($p.Id)) { $cpu += $p.CPU - $once[$p.Id] } } }
    $once = $simdi
    $ara = ((Get-Date) - $t0).TotalSeconds; $t0 = Get-Date; if ($ara -le 0) { $ara = 2 }
    $ram = ($diger | Measure-Object WorkingSet64 -Sum).Sum / 1GB
    $bos = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
    [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0},{1},{2:F2},{3:F2},{4:F2}', (Get-Date -Format 'HH:mm:ss'), $on, ($cpu / $ara), $ram, $bos) |
        Add-Content -Encoding utf8 $cikti
    Start-Sleep 2
}
