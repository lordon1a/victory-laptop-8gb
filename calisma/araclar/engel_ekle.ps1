# Yönetici olarak çalıştır (UAC). vw-avatar ve vw-fg diag exe'lerine gelen/giden engel kuralı ekler.
foreach ($p in 'C:\CLLL\.calisma\vw-fg\target\diag\victory.exe','C:\CLLL\.calisma\vw-avatar\target\diag\victory.exe','C:\CLLL\.calisma\vw-cbb\target\diag\victory.exe','C:\CLLL\.calisma\vw-desc\target\diag\victory.exe') {
  $ad = Split-Path (Split-Path (Split-Path (Split-Path $p))) -Leaf
  foreach ($dir in 'Outbound','Inbound') {
    if (-not (Get-NetFirewallApplicationFilter | Where-Object Program -eq $p | Get-NetFirewallRule | Where-Object Direction -eq $dir)) {
      New-NetFirewallRule -DisplayName "victory-fork engel $ad diag $dir" -Direction $dir -Action Block -Program $p | Out-Null
    }
  }
}
'tamam'
