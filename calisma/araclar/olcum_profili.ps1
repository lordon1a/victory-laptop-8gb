[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Game,
    [string]$GameDir,
    [ValidateSet('diag', 'release')]
    [string]$Build = 'diag',
    [string]$VictoryExe,
    [ValidateSet('run', 'warm')]
    [string]$Mode = 'run',
    [ValidateRange(1, 1024)]
    [int]$Jobs = [Math]::Max(4, [Environment]::ProcessorCount - 4),
    [ValidateSet('series-s', 'series-x')]
    [string]$Console = 'series-s',
    [ValidatePattern('^[\p{L}\p{Nd}_-]{1,64}$')]
    [string]$Tag = 'kosu',
    [ValidateRange(0.01, 1440)]
    [double]$MaxMinutes,
    [string]$Keys,
    [hashtable]$Set = @{},
    # guvenli_baslat'ın boş fiziksel RAM eşiği (GB). Verilmezse onun varsayılanı (1.5).
    [ValidateRange(0.2, 8)]
    [double]$MinFreeRamGB,
    # Eşik aşımının durdurmadan önce kaç saniye sürmesi gerektiği. Verilmezse onun varsayılanı (5).
    [ValidateRange(1, 60)]
    [double]$SustainSeconds,
    # Job Object süreç commit tavanı (GB). Verilmezse onun varsayılanı (13). Not: VRAM dokuları da commit'e sayılır.
    # 24 → 32 (26.11, Yiğit "devam" onayı; AvatarManz tabanında VRAM commit payı büyük, fiziksel koruma MinFreeRamGB aynen).
    [ValidateRange(8, 32)]
    [double]$MaxCommitGB,
    # Süreç önceliği (27.11: guvenli_baslat varsayılanı BelowNormal'dı; Normal/AboveNormal A/B için).
    [ValidateSet('Idle', 'BelowNormal', 'Normal', 'AboveNormal', 'High')]
    [string]$Priority,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$culture = [Globalization.CultureInfo]::InvariantCulture
$utf8 = [Text.UTF8Encoding]::new($false)
$workspace = 'C:\CLLL\.calisma'
$runtime = Join-Path $workspace 'vw-runtime'
# Cache (GB'larca shader) ve kayıtlar C:\CLLL git deposu / beyin kasası dışında dursun.
$dataRoot = Join-Path $env:LOCALAPPDATA 'Victory\data-root'
$config = Join-Path $dataRoot 'victory.toml'
$runRoot = Join-Path $workspace 'kosular'
$ledger = Join-Path $workspace 'victory-fork\KOSULAR.md'
$started = Get-Date

function Get-LocalPath([string]$Path) {
    $full = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    if ($full -notmatch '^[A-Za-z]:[\\/]' -or
        [IO.DriveInfo]::new([IO.Path]::GetPathRoot($full)).DriveType -eq 'Network') {
        throw "Yerel sürücüde bir yol gerekli ($Path)."
    }
    return $full
}

function Assert-OutsideGit([string]$Path) {
    for ($dir = [IO.DirectoryInfo]::new($Path); $null -ne $dir; $dir = $dir.Parent) {
        if (Test-Path -LiteralPath (Join-Path $dir.FullName '.git')) {
            throw "Çalışma klasörü Git deposu içinde ($($dir.FullName))."
        }
        if ($dir.Exists -and ($dir.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw "Çalışma klasörünün Git sınırı bağlantı üzerinden doğrulanamadı ($($dir.FullName))."
        }
    }
}

function ConvertTo-Argument([string]$Value) {
    # A quoted Windows argument must double any backslashes before the closing quote.
    return '"' + ($Value -replace '(\\+)$', '$1$1') + '"'
}

function ConvertTo-TomlLiteral([string]$Value) {
    if ($Value.Contains("'''")) { throw "TOML yolunda art arda üç tek tırnak kullanılamaz ($Value)." }
    if ($Value.Contains("'")) { return "'''$Value'''" }
    return "'$Value'"
}

function Format-Number($Value) {
    if ($null -eq $Value) { return 'yok' }
    return ([double]$Value).ToString('0.###', $culture)
}

function Get-Median([double[]]$Values) {
    if (!$Values.Count) { return }
    $sorted = @($Values | Sort-Object)
    $middle = [int][Math]::Floor($sorted.Count / 2)
    if ($sorted.Count % 2) { return $sorted[$middle] }
    return ($sorted[$middle - 1] + $sorted[$middle]) / 2
}

function Add-Captures($Samples, [string[]]$Names, $Groups) {
    for ($i = 0; $i -lt $Names.Count; $i++) {
        $name = $Names[$i]
        $Samples[$name].Add([double]::Parse($Groups[$i + 1].Value, $culture))
    }
}

function Get-Timing([string]$Log) {
    $frame = [regex]'^(\S+Z)\s+\w+\s+\S+:\s+([\d.]+) fps, ([\d.]+) ms/frame \((.*?)\), (\d+) draws/frame, dropped (\d+) without a host pipeline \((\d+) being made\) and (\d+) indirect'
    $cost = [regex]'([\d.]+) preparing: copies ([\d.]+) ms ([\d.]+) MB, textures ([\d.]+) ms ([\d.]+) MB; ([\d.]+) on the GPU; ([\d.]+) copying back ([\d.]+) MB'
    $busy = [regex]'cpu ([\d.]+)% gpu ([\d.]+)% busy ram ([\d.]+) MB'
    $wait = [regex]'submissions sent ahead per frame: [\d.]+ in [\d.]+ settles \([\d.]+ flights each time\), ([\d.]+) ms waiting for the card in them; settled for:'
    $buffer = [regex]'buffer copies per frame: [\d.]+ on the card from host copies \(([\d.]+) MB\), [\d.]+ read from title memory on the CPU \(([\d.]+) MB: .*?\), [\d.]+ of them settled the flights in the air \(([\d.]+) MB\)'
    $clockFields = 'sync_ms title_ms prelude_ms compare_ms fetch_ms own_ms sum_ms wall_ms cpu_core_pct cpu_all_pct private_bytes working_set_bytes io_read_bytes io_read_ops io_write_bytes io_write_ops game_vol_free_bytes game_vol_total_bytes' -split ' '
    $samples = [ordered]@{}
    foreach ($name in @('Kare ms', 'Draws/kare', 'CPU %', 'GPU meşgul %', 'Victory RAM MB', 'Card wait ms', 'Hazırlık ms', 'Kopya ms', 'Kopya MB', 'Doku ms', 'Doku MB', 'GPU ms', 'Geri kopya ms', 'Geri kopya MB', 'Kart tampon kopyası MB', 'CPU tampon kopyası MB', 'Settle tampon kopyası MB') + $clockFields) {
        $samples[$name] = [Collections.Generic.List[double]]::new()
    }
    $window = 'yok'
    if (Test-Path -LiteralPath $Log -PathType Leaf) {
        $hasFrame = $false
        # Paylaşımlı aç: çökme izleyici veya kapanan süreç dosyayı tutuyor olabilir.
        $fs = [IO.FileStream]::new($Log, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete)
        $sr = [IO.StreamReader]::new($fs, [Text.Encoding]::UTF8)
        $logLines = [Collections.Generic.List[string]]::new()
        try { while ($null -ne ($l = $sr.ReadLine())) { $logLines.Add($l) } } finally { $sr.Dispose() }
        foreach ($raw in $logLines) {
            $line = $raw -replace '\x1b\[[0-9;]*m', ''
            if ($window -ne 'settled' -and $line -cmatch '^harness: settled at \d+ s \(waiting \d+, [\d.]+ fps\)\s*$') {
                $window = 'settled'
                $hasFrame = $false
                foreach ($values in $samples.Values) { $values.Clear() }
                continue
            }
            $sample = $frame.Match($line)
            if ($sample.Success) {
                if ($window -in 'yok', 'tüm kare satırları') {
                    if ([int]$sample.Groups[5].Value -ge 1000) {
                        $window = 'ağır kareler'
                        foreach ($values in $samples.Values) { $values.Clear() }
                    }
                    else { $window = 'tüm kare satırları' }
                }
                $hasFrame = $true
                $samples['Kare ms'].Add([double]::Parse($sample.Groups[3].Value, $culture))
                $samples['Draws/kare'].Add([double]::Parse($sample.Groups[5].Value, $culture))
                $match = $cost.Match($line)
                if ($match.Success) {
                    Add-Captures $samples @('Hazırlık ms', 'Kopya ms', 'Kopya MB', 'Doku ms', 'Doku MB', 'GPU ms', 'Geri kopya ms', 'Geri kopya MB') $match.Groups
                }
                $match = $busy.Match($line)
                if ($match.Success) { Add-Captures $samples @('CPU %', 'GPU meşgul %', 'Victory RAM MB') $match.Groups }
                continue
            }
            if (!$hasFrame) { continue }
            $match = $wait.Match($line)
            if ($match.Success) { Add-Captures $samples @('Card wait ms') $match.Groups }
            $match = $buffer.Match($line)
            if ($match.Success) { Add-Captures $samples @('Kart tampon kopyası MB', 'CPU tampon kopyası MB', 'Settle tampon kopyası MB') $match.Groups }
            if ($line -cmatch 'card clock:\s*(.*)$') {
                foreach ($token in ($Matches[1] -split '\s+')) {
                    if ($token -cmatch '^(\w+)=([\d.]+)$' -and $Matches[1] -cin $clockFields) {
                        $samples[$Matches[1]].Add([double]::Parse($Matches[2], $culture))
                    }
                }
            }
        }
    }

    $sortedMs = @($samples['Kare ms'] | Sort-Object)
    $result = [ordered]@{
        'Kare penceresi' = $window
        'Kare satırı' = $sortedMs.Count
        'Kare ms medyan' = Format-Number (Get-Median $sortedMs)
        'Kare ms p10' = 'yok'
        'Kare ms p90' = 'yok'
    }
    if ($sortedMs.Count) {
        $result['Kare ms p10'] = Format-Number $sortedMs[([int][Math]::Ceiling(0.1 * $sortedMs.Count) - 1)]
        $result['Kare ms p90'] = Format-Number $sortedMs[([int][Math]::Ceiling(0.9 * $sortedMs.Count) - 1)]
    }
    foreach ($name in $samples.Keys) {
        if ($name -eq 'Kare ms') { continue }
        $label = if ($name -cin $clockFields) { "Card clock $name medyan" } else { "$name medyan" }
        $result[$label] = Format-Number (Get-Median $samples[$name])
    }
    return $result
}

function Get-DriverVersion {
    $command = Get-Command nvidia-smi.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (!$command) { return 'yok' }
    $probe = [Diagnostics.Process]::new()
    $probe.StartInfo.FileName = $command.Source
    $probe.StartInfo.Arguments = '--query-gpu=driver_version --format=csv,noheader'
    $probe.StartInfo.UseShellExecute = $false
    $probe.StartInfo.CreateNoWindow = $true
    $probe.StartInfo.RedirectStandardOutput = $true
    $probe.StartInfo.RedirectStandardError = $true
    try {
        $null = $probe.Start()
        $output = $probe.StandardOutput.ReadToEndAsync()
        $errorOutput = $probe.StandardError.ReadToEndAsync()
        if (!$probe.WaitForExit(2000)) {
            try { $probe.Kill() } catch [InvalidOperationException] {}
        }
        elseif ($probe.ExitCode -eq 0 -and $output.Wait(500) -and $errorOutput.Wait(500)) {
            $versions = @($output.Result.Trim() -split '\r?\n' | Where-Object { $_ } | Select-Object -Unique)
            if ($versions.Count) { return $versions -join ', ' }
        }
    }
    catch { Write-Verbose "NVIDIA sürücü sürümü okunamadı ($($_.Exception.Message))." }
    finally { $probe.Dispose() }
    return 'yok'
}

function Get-SummaryField($Fields, [string]$Name) {
    $value = $Fields[$Name]
    if ($value -and $value -ne '-') { return $value }
    return 'yok'
}

function Write-RunSummary([string]$Folder, [string]$Sha, [string]$Changes) {
    $stats = Get-Timing (Join-Path $Folder 'run.log')
    $fields = @{}
    $guardSummary = Join-Path $Folder 'ozet.txt'
    if (Test-Path -LiteralPath $guardSummary -PathType Leaf) {
        foreach ($line in [IO.File]::ReadLines($guardSummary)) {
            if ($line -match '^([^:]+):\s*(.*)$') { $fields[$Matches[1]] = $Matches[2] }
        }
    }
    $ram = 'yok'
    $csv = Join-Path $Folder 'olcum.csv'
    if (Test-Path -LiteralPath $csv -PathType Leaf) {
        $workingSets = @(Import-Csv -LiteralPath $csv | ForEach-Object {
            if ($_.WorkingSet_GB) { [double]::Parse($_.WorkingSet_GB, $culture) }
        })
        if ($workingSets.Count) { $ram = Format-Number (($workingSets | Measure-Object -Maximum).Maximum) }
    }
    $vram = 'yok'
    if ($fields['En yüksek VRAM kullanımı'] -match '^([\d.]+) MiB$') {
        $vram = Format-Number ([double]::Parse($Matches[1], $culture) / 1024)
    }
    $temp = Get-SummaryField $fields 'En yüksek GPU sıcaklığı'
    $reason = Get-SummaryField $fields 'Durdurma sebebi'
    $duration = 'yok'
    if ($fields['Başlangıç'] -and $fields['Bitiş']) {
        $from = [DateTimeOffset]::Parse($fields['Başlangıç'], $culture)
        $until = [DateTimeOffset]::Parse($fields['Bitiş'], $culture)
        $duration = (Format-Number (($until - $from).TotalSeconds)) + ' sn'
    }
    $report = @(
        "# Koşu özeti — $Tag"
        ''
        "- Mod / derleme / konsol | $Mode / $Build / $Console"
        "- Süre | $duration"
        "- Çıkış nedeni | $reason"
        "- Çıkış kodu | $(Get-SummaryField $fields 'Çıkış kodu')"
        "- Tepe süreç RAM (working set, GB) | $ram"
        "- Tepe süreç commit (private bytes) | $(Get-SummaryField $fields 'En yüksek private bytes')"
        "- En düşük boş RAM | $(Get-SummaryField $fields 'En düşük boş RAM')"
        "- Tepe VRAM (GB) | $vram"
        "- Tepe sıcaklık | $temp"
        ''
        '## Kare ölçümleri'
        ''
        foreach ($name in $stats.Keys) { "- $name | $($stats[$name])" }
    )
    [IO.File]::WriteAllLines((Join-Path $Folder 'kosu_ozeti.md'), [string[]]$report, $utf8)
    Write-Host ($report -join [Environment]::NewLine)

    $columns = @('Tarih', 'Tag', 'Build', 'Git SHA', 'Console', 'Farklı ayarlar (-Set)', 'Süre', 'Çıkış nedeni', 'Kare ms medyan/p90', 'Tepe RAM GB', 'Tepe VRAM GB', 'Tepe °C', 'Klasör')
    $shortSha = if ($Sha.Length -gt 8) { $Sha.Substring(0, 8) } else { $Sha }
    $cells = @($started.ToString('yyyy-MM-dd HH:mm:ss'), $Tag, $Build, $shortSha, $Console, $Changes, $duration, $reason,
        "$($stats['Kare ms medyan']) / $($stats['Kare ms p90'])", $ram, $vram, ($temp -replace ' °C$', ''), $Folder)
    $row = '| ' + (($cells | ForEach-Object { $_ -replace '\|', '\|' -replace '[\r\n]+', ' ' }) -join ' | ') + ' |'
    $nl = [Environment]::NewLine
    if (!(Test-Path -LiteralPath $ledger)) {
        $header = "# Koşular$nl$nl| " + ($columns -join ' | ') + " |$nl|" + ('---|' * $columns.Count) + $nl
        [IO.File]::WriteAllText($ledger, $header, $utf8)
    }
    $existing = [IO.File]::ReadAllText($ledger)
    if ($existing.Length -and !$existing.EndsWith("`n")) { $row = $nl + $row }
    [IO.File]::AppendAllText($ledger, $row + $nl, $utf8)
}

$original = @{}
$effective = @{}
foreach ($entry in [Environment]::GetEnvironmentVariables('Process').GetEnumerator()) {
    if ($entry.Key.StartsWith('VICTORY_', [StringComparison]::OrdinalIgnoreCase)) { $original[$entry.Key] = $entry.Value }
}
$effective = $original.Clone()
$defaults = @{
    VICTORY_CONFIG = $config
    VICTORY_DISPLAY_MODE = '1920x1080'
    VICTORY_CARD_BUFFERS_MB = '512'
    VICTORY_TEXTURE_ROOM_PERCENT = '85'
    VICTORY_WINDOW_KB = '512'
    VICTORY_WINDOW_TAILS = '1'
    VICTORY_RT_RESOLVE = '0'
    VICTORY_ACTIVATE_RAYS = '0'
    VICTORY_CARD_ACCOUNTING = '1'
}
foreach ($name in $defaults.Keys) { $effective[$name] = $defaults[$name] }
foreach ($name in @('VICTORY_WAVE_WIDE', 'VICTORY_GPU_TIMING')) {
    $effective.Remove($name)
    if ($Set.ContainsKey($name)) { Write-Warning "$name elle değiştirildi. Bu donanım için varsayılan profil ayarı değildir." }
}
if ($Keys -and $Build -eq 'diag') { $effective['VICTORY_KEYS'] = $Keys }

try {
    foreach ($name in $Set.Keys) {
        if (([string]$name).ToUpperInvariant() -cnotmatch '^VICTORY_[A-Z0-9_]+$') { throw "Geçersiz -Set değişkeni ($name). VICTORY_* biçimini kullanın." }
        if ([string]$Set[$name] -eq '') { $effective.Remove($name) }
        else { $effective[$name] = [string]$Set[$name] }
    }
    if ($Build -eq 'release') {
        if ($Keys -or $effective.ContainsKey('VICTORY_KEYS')) { Write-Warning 'VICTORY_KEYS yalnız diag derlemesinde çalışır. Release koşusunda kaldırıldı.' }
        $effective.Remove('VICTORY_KEYS')
    }

    $Game = Get-LocalPath $Game
    if (!$GameDir) { $GameDir = [IO.Path]::GetDirectoryName($Game) }
    $GameDir = Get-LocalPath $GameDir
    if (!$VictoryExe) { $VictoryExe = Join-Path $runtime "target\$Build\victory.exe" }
    $VictoryExe = Get-LocalPath $VictoryExe
    if (!$PSBoundParameters.ContainsKey('MaxMinutes')) {
        $MaxMinutes = if ($Mode -eq 'run') { 10 } else { 30 }
    }
    $arguments = if ($Mode -eq 'run') {
        "run $(ConvertTo-Argument $Game) --execute --console $Console"
    }
    else {
        "warm $(ConvertTo-Argument $GameDir) --jobs $Jobs"
    }
    $commandLine = "$(ConvertTo-Argument $VictoryExe) $arguments"

    # The requested path may be under the enclosing workspace's Git checkout.
    try { Assert-OutsideGit $runRoot }
    catch {
        $runRoot = Get-LocalPath (Join-Path $env:LOCALAPPDATA 'Victory\kosular')
        Write-Warning "C:\CLLL\.calisma\kosular için depo dışında bir yol doğrulanamadı. Koşu kökü $runRoot."
    }
    $folder = Join-Path $runRoot ($started.ToString('yyyyMMdd-HHmmss') + '_' + $Tag)
    Assert-OutsideGit $folder
    $environmentLines = @($effective.Keys | Sort-Object | ForEach-Object { "$_=$($effective[$_])" })
    $changes = @($Set.Keys | Sort-Object | ForEach-Object {
        if ($effective.ContainsKey($_)) { "$_=$($effective[$_])" } else { "$_=<kaldırıldı>" }
    }) -join ', '
    if (!$changes) { $changes = 'yok' }
    $toml = @(
        '[paths]'
        "game_dir = $(ConvertTo-TomlLiteral $GameDir)"
        "cache_dir = $(ConvertTo-TomlLiteral (Join-Path $dataRoot 'cache'))"
        "data_dir = $(ConvertTo-TomlLiteral (Join-Path $dataRoot 'data'))"
    )

    if ($DryRun) {
        Write-Host "Komut | $commandLine"
        Write-Host "Koşu klasörü | $folder"
        Write-Host "Azami süre | $MaxMinutes dk"
        Write-Host "Config | $config"
        Write-Host ($toml -join [Environment]::NewLine)
        Write-Host "Ortam`n$($environmentLines -join [Environment]::NewLine)"
        return
    }
}
catch {
    Write-Host "Ön kontrol başarısız. $($_.Exception.Message)"
    exit 2
}

$mutex = [Threading.Mutex]::new($false, 'Local\VictoryOlcumProfili_CLLL')
$locked = $false
$environmentChanged = $false
try {
    try { $locked = $mutex.WaitOne(0) }
    catch [Threading.AbandonedMutexException] { $locked = $true }
    try {
        if (!$locked -or (Get-Process -Name victory -ErrorAction SilentlyContinue)) { throw 'Başka bir Victory koşusu çalışıyor.' }
        if (!(Test-Path -LiteralPath $VictoryExe -PathType Leaf) -or [IO.Path]::GetExtension($VictoryExe) -ine '.exe') {
            throw "Victory exe bulunamadı ($VictoryExe)."
        }
        $gpu = Get-Item -LiteralPath 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' -ErrorAction SilentlyContinue
        if (!$gpu -or $gpu.GetValue($VictoryExe) -cne 'GpuPreference=2;') {
            throw "victory.exe NVIDIA'ya atanmamış, Intel'de açılır ($VictoryExe)."
        }
        if (!(Test-Path -LiteralPath $Game -PathType Leaf)) { throw "Oyun dosyası bulunamadı ($Game)." }
        if (!(Test-Path -LiteralPath $GameDir -PathType Container)) { throw "Oyun klasörü bulunamadı ($GameDir)." }
        if (Test-Path -LiteralPath $folder) { throw "Koşu klasörü zaten var ($folder)." }
    }
    catch {
        Write-Host "Ön kontrol başarısız. $($_.Exception.Message)"
        exit 2
    }

    $victoryHash = (Get-FileHash -LiteralPath $VictoryExe -Algorithm SHA256).Hash
    # SHA, kullanılan exe'nin kendi deposundan (<repo>\target\<profil>\victory.exe).
    $exeRepo = Split-Path (Split-Path (Split-Path $VictoryExe -Parent) -Parent) -Parent
    $gitSha = git -C $exeRepo rev-parse HEAD
    if ($LASTEXITCODE -ne 0 -or $gitSha -notmatch '^[0-9a-f]{40,64}$') {
        throw "Runtime Git SHA okunamadı ($runtime)."
    }
    $gameMetadata = @()
    if ($Mode -eq 'run') {
        $watch = [Diagnostics.Stopwatch]::StartNew()
        if ((Get-Item -LiteralPath $Game).Length -ge 100MB) { Write-Host "Oyun SHA-256 hesaplanıyor ($Game)." }
        $gameHash = (Get-FileHash -LiteralPath $Game -Algorithm SHA256).Hash
        $gameMetadata = @("Oyun SHA-256: $gameHash", "Oyun SHA-256 süresi: $(Format-Number $watch.Elapsed.TotalSeconds) sn")
        if ((Get-Item -LiteralPath $Game).Length -ge 100MB) { Write-Host $gameMetadata[1] }
    }
    $driverVersion = Get-DriverVersion
    $null = [IO.Directory]::CreateDirectory($dataRoot)
    [IO.File]::WriteAllLines($config, [string[]]$toml, $utf8)
    $null = New-Item -ItemType Directory -Path $folder
    [IO.File]::WriteAllLines((Join-Path $folder 'ayarlar.txt'), [string[]](@(
        "Tarih: $($started.ToString('o'))"
        "Mod: $Mode"
        "Derleme: $Build"
        "Komut: $commandLine"
        "Azami süre: $MaxMinutes dk"
        "Victory SHA-256: $victoryHash"
        "Runtime Git SHA: $gitSha"
        "NVIDIA sürücü sürümü: $driverVersion"
        "Farklı ayarlar (-Set): $changes"
    ) + $gameMetadata + @('', 'Ortam') + $environmentLines), $utf8)

    $environmentChanged = $true
    $envNames = @( @($original.Keys) + @($effective.Keys) | Sort-Object -Unique )
    foreach ($name in $envNames) { [Environment]::SetEnvironmentVariable($name, $effective[$name], 'Process') }
    $guard = @{
        Exe = $VictoryExe
        ArgumentList = $arguments
        WorkDir = $folder
        LogDir = $folder
        MaxMinutes = $MaxMinutes
        StdOutFile = Join-Path $folder 'out.log'
        StdErrFile = Join-Path $folder 'run.log'
    }
    if ($PSBoundParameters.ContainsKey('MinFreeRamGB')) { $guard.MinFreeRamGB = $MinFreeRamGB }
    if ($PSBoundParameters.ContainsKey('SustainSeconds')) { $guard.SustainSeconds = $SustainSeconds }
    if ($PSBoundParameters.ContainsKey('MaxCommitGB')) { $guard.MaxCommitGB = $MaxCommitGB }
    if ($PSBoundParameters.ContainsKey('Priority')) { $guard.Priority = $Priority }
    try { & (Join-Path $PSScriptRoot 'guvenli_baslat.ps1') @guard }
    finally {
        foreach ($name in $envNames) { [Environment]::SetEnvironmentVariable($name, $original[$name], 'Process') }
        $environmentChanged = $false
        if (Test-Path -LiteralPath (Join-Path $folder 'ozet.txt') -PathType Leaf) {
            Write-RunSummary $folder $gitSha $changes
        }
    }
}
finally {
    if ($environmentChanged) {
        foreach ($name in $envNames) { [Environment]::SetEnvironmentVariable($name, $original[$name], 'Process') }
    }
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
