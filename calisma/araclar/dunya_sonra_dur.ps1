# Koşuyu dünya göründükten -Saniye sonra bitirir (Yiğit 26.11: dünyaya girince fps oturuyor, uzun koşu vakit kaybı).
# kosu.ps1 başlatır. Koşu klasörünü (*_<Tag>) bekler, run.log'da ilk dünya karesini (draw >= 2000) bulur,
# -Saniye sonra victory süreçlerini kapatır. Dünya gelmezse dokunmaz (olcum_profili'nin süre sınırı geçerli).
param([Parameter(Mandatory)][string]$Tag, [int]$Saniye = 60, [int]$Bekle = 400)
$ErrorActionPreference = 'SilentlyContinue'
$kok = "$env:LOCALAPPDATA\Victory\kosular"
$bas = Get-Date
$klasor = $null
while (-not $klasor -and ((Get-Date) - $bas).TotalSeconds -lt 60) {
    $klasor = Get-ChildItem $kok -Directory | Where-Object { $_.Name -like "*_$Tag" -and $_.CreationTime -ge $bas.AddSeconds(-30) } |
        Sort-Object CreationTime -Descending | Select-Object -First 1
    if (-not $klasor) { Start-Sleep 1 }
}
if (-not $klasor) { return }
$log = Join-Path $klasor.FullName 'run.log'
$dunya = $null
while (-not $dunya -and ((Get-Date) - $bas).TotalSeconds -lt $Bekle) {
    Start-Sleep 2
    if (-not (Get-Process victory -ErrorAction SilentlyContinue)) { return }
    $dunya = Select-String -Path $log -Pattern 'host: [\d.]+ fps, [\d.]+ ms/frame.*?(\d+) draws/frame' |
        Where-Object { [int]$_.Matches[0].Groups[1].Value -ge 2000 } | Select-Object -First 1
}
if (-not $dunya) { return }
"dünya: $(Get-Date -Format HH:mm:ss), $Saniye sn sonra durdurulacak" | Set-Content -Encoding utf8 (Join-Path $klasor.FullName 'dunya_sonra_dur.txt')
# 27.11: yalnız BU koşunun süreçlerini kapat. Eskisi uyuyup ada göre öldürüyordu; koşu önce bitince
# SONRAKİ koşunun oyununu kapatıyordu (pda-pool, pdb-pool, pdb-taban 'çökmeleri').
$bizim = @(Get-Process victory, game_scarlett_master -ErrorAction SilentlyContinue | ForEach-Object { $_.Id })
$son = (Get-Date).AddSeconds($Saniye)
while ((Get-Date) -lt $son) {
    Start-Sleep 1
    if (-not ($bizim | Where-Object { Get-Process -Id $_ -ErrorAction SilentlyContinue })) { 'koşu kendi bitti, dokunulmadı' | Add-Content -Encoding utf8 (Join-Path $klasor.FullName 'dunya_sonra_dur.txt'); return }
}
$bizim | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
"durduruldu: $(Get-Date -Format HH:mm:ss)" | Add-Content -Encoding utf8 (Join-Path $klasor.FullName 'dunya_sonra_dur.txt')
