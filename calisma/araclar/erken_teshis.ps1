# Koşu sırasında erken teşhis: YALNIZ victory.exe penceresinden aralıklı kare alır (ffmpeg gfxcapture),
# kareyi ve run.log'u denetler; görüntü yoksa / düz renkse / donmuşsa ya da dünya hiç gelmezse
# koşu klasörüne DURDUR yazıp (guvenli_baslat oyunu kapatır) erkenden bitirir.
# Kullanım: erken_teshis.ps1 [-AralikSn 15] [-AlarmSayisi 4] [-DunyaSiniriSn 240] [-SadeceUyar]
param(
    [ValidateRange(5, 120)][int]$AralikSn = 15,
    # Üst üste kaç kötü kontrolde alarm (15 sn × 4 = ~1 dk).
    [ValidateRange(2, 20)][int]$AlarmSayisi = 4,
    # Bu saniyeye kadar dünya çizimi (≥2000 draw/kare) yoksa alarm.
    [ValidateRange(60, 1200)][int]$DunyaSiniriSn = 240,
    # Verilirse DURDUR yazmaz, yalnız uyarır.
    [switch]$SadeceUyar,
    [ValidateRange(1, 30)][int]$BeklemeDk = 3
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$son = (Get-Date).AddMinutes($BeklemeDk)
while (-not (Get-Process victory -ErrorAction SilentlyContinue)) {
    if ((Get-Date) -gt $son) { Write-Output 'victory.exe başlamadı, çıkılıyor.'; exit 1 }
    Start-Sleep -Seconds 2
}
# 27.11: yalnız bu koşunun victory'sini izle (eskiden ad ile bakıyordu, sonraki koşuya taşıp eski klasöre kare yazıyordu).
$vpid = (Get-Process victory -ErrorAction SilentlyContinue | Sort-Object StartTime -Descending | Select-Object -First 1).Id
$kok = Join-Path $env:LOCALAPPDATA 'Victory\kosular'
$kosu = (Get-ChildItem $kok -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$kareDir = Join-Path $kosu 'kareler'
New-Item -ItemType Directory -Force $kareDir | Out-Null
$log = Join-Path $kosu 'run.log'
$teshis = Join-Path $kosu 'erken_teshis.txt'
function Yaz($m) { $s = '{0:HH:mm:ss} {1}' -f (Get-Date), $m; Write-Output $s; Add-Content -Path $teshis -Value $s -Encoding UTF8 }
Yaz "Koşu: $kosu"

# Tek kare: ffmpeg en çok 10 sn; gfxcapture pencere değişmezse yeni kare vermez ve bekler → zaman aşımı = "kare gelmedi".
function Kare-Al($dosya) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo 'ffmpeg'
    $psi.Arguments = "-hide_banner -loglevel quiet -y -filter_complex `"gfxcapture=window_exe='(?i)^victory\.exe$':capture_cursor=0:max_framerate=2,hwdownload,format=bgra,scale=960:-2`" -frames:v 1 -update 1 `"$dosya`""
    $psi.UseShellExecute = $false; $psi.CreateNoWindow = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    if (-not $p.WaitForExit(10000)) { try { $p.Kill() } catch {}; return $false }
    return (Test-Path $dosya)
}

# Kare özeti: 48×27 örnek noktada parlaklık ortalaması, sapması ve kaba parmak izi.
function Kare-Olc($dosya) {
    $bmp = [System.Drawing.Bitmap]::FromFile($dosya)
    try {
        $v = New-Object System.Collections.Generic.List[double]
        for ($y = 0; $y -lt 27; $y++) { for ($x = 0; $x -lt 48; $x++) {
            $c = $bmp.GetPixel([int](($x + 0.5) * $bmp.Width / 48), [int](($y + 0.5) * $bmp.Height / 27))
            $v.Add(0.299 * $c.R + 0.587 * $c.G + 0.114 * $c.B)
        } }
    } finally { $bmp.Dispose() }
    $ort = ($v | Measure-Object -Average).Average
    $sap = [math]::Sqrt((($v | ForEach-Object { ($_ - $ort) * ($_ - $ort) }) | Measure-Object -Average).Average)
    [pscustomobject]@{ Ort = $ort; Sap = $sap; Iz = $v.ToArray() }
}

# Pencere küçültülmüş ya da ekran dışında (-32000) ise gfxcapture kare vermez: odağı çalmadan geri getir.
Add-Type @"
using System; using System.Runtime.InteropServices;
public class EtPencere {
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cx, int cy, uint f);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  public struct RECT { public int L, T, R, B; }
}
"@
function Pencere-Kurtar {
    $p = Get-Process -Id $vpid -ErrorAction SilentlyContinue
    if (-not $p -or $p.MainWindowHandle -eq [IntPtr]::Zero) { return $false }
    $h = $p.MainWindowHandle
    $r = New-Object EtPencere+RECT
    [void][EtPencere]::GetWindowRect($h, [ref]$r)
    if (-not [EtPencere]::IsIconic($h) -and $r.L -gt -10000 -and $r.T -gt -10000) { return $false }
    [void][EtPencere]::ShowWindow($h, 4)   # SW_SHOWNOACTIVATE
    [void][EtPencere]::GetWindowRect($h, [ref]$r)
    if ($r.L -le -10000 -or $r.T -le -10000) {
        # SWP_NOZORDER | SWP_NOACTIVATE | SWP_SHOWWINDOW; 1280x720 iç alan + çerçeve.
        [void][EtPencere]::SetWindowPos($h, [IntPtr]::Zero, 60, 60, 1296, 759, 0x0054)
    }
    return $true
}

$baslangic = Get-Date
$kotu = 0; $onceki = $null; $dunyaGordu = $false; $alarm = $false; $logBoy = 0; $logSabit = 0
while (Get-Process -Id $vpid -ErrorAction SilentlyContinue) {
    $sn = [int]((Get-Date) - $baslangic).TotalSeconds
    $dosya = Join-Path $kareDir ('kare_{0:D4}s.png' -f $sn)

    # Log: son kare satırı ve log büyüyor mu.
    $draw = 0; $fps = 0
    if (Test-Path $log) {
        $boy = (Get-Item $log).Length
        if ($boy -eq $logBoy) { $logSabit++ } else { $logSabit = 0 }; $logBoy = $boy
        $satir = Get-Content $log -Tail 400 | Select-String 'host: ([\d.]+) fps.*?(\d+) draws/frame' | Select-Object -Last 1
        if ($satir) { $fps = [double]$satir.Matches[0].Groups[1].Value; $draw = [int]$satir.Matches[0].Groups[2].Value }
    }
    if ($draw -ge 2000) { $dunyaGordu = $true }

    $durum = 'tamam'
    if (Pencere-Kurtar) {
        # Oyunun değil pencerenin sorunu: bu kontrol sayılmaz.
        Yaz "$sn sn | pencere küçültülmüş/ekran dışındaydı → geri getirildi (sayılmadı)"
        Start-Sleep -Seconds 3
        $kotu = 0
        Start-Sleep -Seconds $AralikSn
        continue
    }
    if (-not (Kare-Al $dosya)) {
        $durum = 'KARE GELMEDİ (pencere güncellenmiyor/donuk)'
    } else {
        $o = Kare-Olc $dosya
        if ($o.Sap -lt 4) { $durum = ('DÜZ RENK (ort {0:N0}) — siyah/beyaz/boş ekran' -f $o.Ort) }
        elseif ($onceki) {
            $fark = 0; for ($i = 0; $i -lt $o.Iz.Length; $i++) { $fark += [math]::Abs($o.Iz[$i] - $onceki.Iz[$i]) }
            $fark /= $o.Iz.Length
            # Dünyada (fps var, kamera sabit olsa bile) kare hafifçe değişir; tıpatıp aynıysa donmuş say.
            if ($fark -lt 0.3 -and $fps -gt 0 -and $dunyaGordu) { $durum = 'AYNI KARE (donmuş görüntü)' }
        }
        $onceki = $o
    }
    if ($logSabit -ge 4) { $durum = "LOG DURDU ($([int]($logSabit * $AralikSn)) sn)" }
    if (-not $dunyaGordu -and $sn -ge $DunyaSiniriSn) { $durum = "DÜNYA GELMEDİ ($sn sn, son draw $draw)" }

    # Yükleme ekranı aşamasında (dünya yok) düz renk/aynı kare normal olabilir; yalnız dünya varken ya da sınır aşılınca say.
    # "AYNI KARE" yalnız bilgi: hapishane hücresinde kamera sabitken yanlış alarm olabilir; donma zaten "KARE GELMEDİ" verir.
    $sayilir = ($durum -ne 'tamam') -and ($durum -notlike 'AYNI KARE*') -and ($dunyaGordu -or $durum -like 'DÜNYA GELMEDİ*' -or $durum -like 'LOG DURDU*')
    if ($sayilir) { $kotu++ } else { $kotu = 0 }
    Yaz ('{0,4} sn | {1:N1} fps {2} draw | {3}{4}' -f $sn, $fps, $draw, $durum, $(if ($kotu) { " [$kotu/$AlarmSayisi]" } else { '' }))

    if ($kotu -ge $AlarmSayisi -and -not $alarm) {
        $alarm = $true
        Yaz "ALARM: $durum — $AlarmSayisi kontrol üst üste."
        if (-not $SadeceUyar) {
            Set-Content -Path (Join-Path $kosu 'DURDUR') -Value "erken_teshis: $durum" -Encoding UTF8
            Yaz 'DURDUR yazıldı, koşu kapatılıyor.'
        }
    }
    Start-Sleep -Seconds $AralikSn
}
Yaz ("Bitti. {0} kare. Sonuç: {1}" -f (Get-ChildItem $kareDir -Filter *.png).Count, $(if ($alarm) { 'ALARM' } else { 'temiz' }))
exit 0
