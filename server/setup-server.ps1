<#
.SYNOPSIS
    Sets up a dedicated Fabric server for Voidhome (Minecraft 26.3, Fabric loader 0.19.5).

.DESCRIPTION
    1. Finds Java 25: the Minecraft Launcher's bundled runtime, JAVA_HOME, or java on PATH.
    2. Downloads the Fabric server launcher from meta.fabricmc.net as fabric-server-launch.jar
       and checks its pinned sha1.
    3. Runs it once with --initSettings to create server.properties and eula.txt. The first
       run also downloads the vanilla server and the Fabric libraries.
    4. Applies server.properties.template over server.properties. Other keys are kept.
    5. Sets eula=true only when you pass -AcceptEula.
    6. Installs the server mods from ..\modpack\mods.lock.json (group "server") and the
       Voidhome jar. Jars you added to mods\ yourself are never touched.
    7. Copies start.ps1 and start.bat into the folder.
    Safe to run again, for example after a mod update.

.PARAMETER Dir
    The server folder. Pick one outside the repository, for example C:\mc\skyblock-server.

.PARAMETER ModJar
    Path to the Voidhome jar: build\libs\voidhome-<version>.jar.

.PARAMETER Include
    Optional server tooltip support: appleskin, jade, shulkerboxtooltip, or all.
    Example: -Include appleskin,jade

.PARAMETER AcceptEula
    You have read and accept the Minecraft EULA: https://aka.ms/MinecraftEULA

.PARAMETER ServerJarSha1
    The sha1 to expect for fabric-server-launch.jar, if Fabric has rebuilt it since the pin.

.PARAMETER DryRun
    Only print what would happen. Nothing is downloaded or written.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File server\setup-server.ps1 -Dir C:\mc\skyblock-server -ModJar build\libs\voidhome-3.3.2.jar -AcceptEula
#>
[CmdletBinding()]
param(
    [string]$Dir,
    [string]$ModJar,
    [string[]]$Include = @(),
    [switch]$AcceptEula,
    [string]$ServerJarSha1,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$MinecraftVersion = '26.3'
$LoaderVersion = '0.19.5'
$InstallerVersion = '1.1.2'
$ServerJarUrl = "https://meta.fabricmc.net/v2/versions/loader/$MinecraftVersion/$LoaderVersion/$InstallerVersion/server/jar"
# meta.fabricmc.net builds this jar on request and publishes no hash; this is the sha1 it served on 2026-09-22.
$PinnedServerJarSha1 = 'aa46be16fbca1b52d18cc680bdac1d0e95a815b6'
$EulaUrl = 'https://aka.ms/MinecraftEULA'
$UserAgent = 'ultimate-skyblock-modpack/1.0 (github.com/TorMartin-ops/ultimate-skyblock)'
$ManifestName = '.ultimateskyblock-managed.json'
$OurModId = 'ultimateskyblock'
$StoreJava = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.4297127D64EC6_8wekyb3d8bbwe\LocalCache\Local\runtime\java-runtime-epsilon\windows-x64\java-runtime-epsilon\bin\java.exe'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$LockFile = Join-Path $RepoRoot 'modpack\mods.lock.json'
$TemplateFile = Join-Path $PSScriptRoot 'server.properties.template'
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Invariant = [Globalization.CultureInfo]::InvariantCulture
$Failures = New-Object System.Collections.ArrayList

# ---------------------------------------------------------------- helpers

function Write-Step([string]$Text) { Write-Host ''; Write-Host "== $Text" -ForegroundColor Cyan }
function Write-Info([string]$Text) { Write-Host "   $Text" }
function Write-Plan([string]$Text) { Write-Host "   [dry run] $Text" -ForegroundColor Yellow }
function Write-Warn([string]$Text) { Write-Host "   WARNING: $Text" -ForegroundColor Yellow }
function Stop-Setup([string]$Text) {
    Write-Host ''
    Write-Host "ERROR: $Text" -ForegroundColor Red
    exit 1
}

function Get-Prop($Object, [string]$Name) {
    if ($null -eq $Object) { return $null }
    $p = $Object.PSObject.Properties[$Name]
    if ($p) { return $p.Value }
    return $null
}

function Resolve-FullPath([string]$Path) {
    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    $full = [IO.Path]::GetFullPath($ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($expanded))
    if ($full.Length -gt 3) { $full = $full.TrimEnd('\') }
    return $full
}

function Get-Sha1([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA1).Hash.ToLowerInvariant()
}

function Test-PlainJarName([string]$Name) {
    return ($Name -match '^[^\\/:*?"<>|]+\.jar$') -and -not $Name.StartsWith('.')
}

function Get-PartPath([string]$Destination) {
    # Wildcard characters in -OutFile paths trip up Windows PowerShell, so they become "_" in the .part name.
    $name = (Split-Path -Leaf $Destination) -replace '[\[\]\*\?`]', '_'
    return Join-Path (Split-Path -Parent $Destination) "$name.part"
}

function Move-Into([string]$Part, [string]$Destination) {
    if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Force }
    [IO.File]::Move($Part, $Destination)
}

function Save-Download([string]$Url, [string]$Destination, [string]$Sha1) {
    # Downloads to <name>.part, checks the sha1, then renames over the destination.
    $part = Get-PartPath $Destination
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            if (Test-Path -LiteralPath $part) { Remove-Item -LiteralPath $part -Force }
            Invoke-WebRequest -Uri $Url -OutFile $part -UseBasicParsing -UserAgent $UserAgent -TimeoutSec 300
            break
        } catch {
            if ($attempt -eq 3) { throw "download failed: $Url ($($_.Exception.Message))" }
            Start-Sleep -Seconds (3 * $attempt)
        }
    }
    $actual = Get-Sha1 $part
    if ($actual -ne $Sha1.ToLowerInvariant()) {
        Remove-Item -LiteralPath $part -Force
        throw "sha1 mismatch for $(Split-Path -Leaf $Destination): expected $Sha1, got $actual"
    }
    Move-Into $part $Destination
}

function Invoke-Native([string]$Exe, [string[]]$Arguments) {
    # Windows PowerShell can turn a native program's stderr into errors; never let that stop us.
    $saved = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Exe @Arguments | Out-Host } finally { $ErrorActionPreference = $saved }
    return $LASTEXITCODE
}

function Get-JavaMajor([string]$Exe) {
    # 25 for 'openjdk version "25.0.1"', 8 for 'java version "1.8.0_391"', 0 if unknown.
    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $Exe
        $psi.Arguments = '-version'
        $psi.UseShellExecute = $false
        $psi.RedirectStandardError = $true
        $psi.RedirectStandardOutput = $true
        $psi.CreateNoWindow = $true
        $proc = [Diagnostics.Process]::Start($psi)
        $text = $proc.StandardError.ReadToEnd() + $proc.StandardOutput.ReadToEnd()
        $proc.WaitForExit()
        $m = [regex]::Match($text, 'version "(\d+)(?:\.(\d+))?')
        if (-not $m.Success) { return 0 }
        $major = [int]$m.Groups[1].Value
        if ($major -eq 1 -and $m.Groups[2].Success) { $major = [int]$m.Groups[2].Value }
        return $major
    } catch {
        return 0
    }
}

function Find-Java25 {
    $candidates = New-Object System.Collections.ArrayList
    [void]$candidates.Add($StoreJava)
    [void]$candidates.Add((Join-Path $env:APPDATA '.minecraft\runtime\java-runtime-epsilon\windows-x64\java-runtime-epsilon\bin\java.exe'))
    if ($env:JAVA_HOME) { [void]$candidates.Add((Join-Path $env:JAVA_HOME 'bin\java.exe')) }
    $onPath = Get-Command java.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($onPath) { [void]$candidates.Add($onPath.Path) }
    foreach ($c in $candidates) {
        if (-not (Test-Path -LiteralPath $c -PathType Leaf)) { continue }
        $major = Get-JavaMajor $c
        if ($major -ge 25) {
            Write-Info "Using Java $major at $c"
            return $c
        }
        Write-Info "Skipping Java $major at $c (the server needs 25 or newer)"
    }
    return $null
}

function Read-ZipText($Entry) {
    $reader = New-Object System.IO.StreamReader($Entry.Open())
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

function Get-ModIdFromJson([string]$Text) {
    try { return [string](Get-Prop ($Text | ConvertFrom-Json) 'id') }
    catch {
        $m = [regex]::Match($Text, '"id"\s*:\s*"([^"]+)"')
        if ($m.Success) { return $m.Groups[1].Value }
        return $null
    }
}

function Get-JarModId([string]$JarPath) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = $null
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($JarPath)
        $entry = $zip.GetEntry('fabric.mod.json')
        if ($null -eq $entry) { return $null }
        return Get-ModIdFromJson (Read-ZipText $entry)
    } catch {
        return $null
    } finally {
        if ($zip) { $zip.Dispose() }
    }
}

function Get-JarProblem([string]$JarPath) {
    # Why this jar is not the Voidhome mod, or $null when it is.
    $name = Split-Path -Leaf $JarPath
    if (-not (Test-PlainJarName $name)) { return "$name is not a .jar file" }
    if ($name -like '*-sources.jar') { return "$name is the sources jar; use the jar without -sources" }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = $null
    try {
        $zip = [IO.Compression.ZipFile]::OpenRead($JarPath)
        $entry = $zip.GetEntry('fabric.mod.json')
        if ($null -eq $entry) { return "$name has no fabric.mod.json, so it is not a Fabric mod" }
        $id = Get-ModIdFromJson (Read-ZipText $entry)
        if ($id -ne $OurModId) { return "$name is the Fabric mod '$id', not Voidhome ('$OurModId')" }
        foreach ($e in $zip.Entries) { if ($e.FullName -like '*.class') { return $null } }
        return "$name contains no compiled classes"
    } catch {
        return "$name could not be read as a jar ($($_.Exception.Message))"
    } finally {
        if ($zip) { $zip.Dispose() }
    }
}

function Get-PropKey([string]$Line) {
    # The key of a .properties line, or $null for comments and blank lines.
    $t = $Line.TrimStart()
    if ($t -eq '' -or $t.StartsWith('#') -or $t.StartsWith('!')) { return $null }
    $m = [regex]::Match($t, '^((?:\\.|[^\\=:\s])+)')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Merge-Properties([string]$Target, [string]$Template) {
    # Template keys replace the same keys in the target; everything else is kept.
    $wanted = [ordered]@{}
    foreach ($line in [IO.File]::ReadAllLines($Template)) {
        $key = Get-PropKey $line
        if ($key) { $wanted[$key] = $line.Trim() }
    }
    $lines = New-Object System.Collections.ArrayList
    if (Test-Path -LiteralPath $Target -PathType Leaf) {
        foreach ($line in [IO.File]::ReadAllLines($Target)) { [void]$lines.Add($line) }
    }
    $done = @{}
    $changes = New-Object System.Collections.ArrayList
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $key = Get-PropKey $lines[$i]
        if (-not $key -or -not $wanted.Contains($key) -or $done.ContainsKey($key)) { continue }
        $done[$key] = $true
        if ($lines[$i].Trim() -ne $wanted[$key]) {
            [void]$changes.Add("$($lines[$i].Trim())  ->  $($wanted[$key])")
            $lines[$i] = $wanted[$key]
        }
    }
    foreach ($key in $wanted.Keys) {
        if (-not $done.ContainsKey($key)) {
            [void]$lines.Add($wanted[$key])
            [void]$changes.Add("(new)  $($wanted[$key])")
        }
    }
    return @{ Lines = $lines; Changes = $changes }
}

# ---------------------------------------------------------------- arguments

if ($DryRun) { Write-Host 'DRY RUN: nothing will be downloaded or written.' -ForegroundColor Yellow }

if (-not $Dir) { Stop-Setup 'Pass -Dir <server folder>, for example -Dir C:\mc\skyblock-server' }
$Dir = Resolve-FullPath $Dir
if (-not $ModJar) { Stop-Setup 'Pass -ModJar <path to voidhome-<version>.jar>.' }
if (-not (Test-Path -LiteralPath $ModJar -PathType Leaf)) { Stop-Setup "Mod jar not found: $ModJar" }
$ModJar = (Resolve-Path -LiteralPath $ModJar).ProviderPath
$ModJarName = Split-Path -Leaf $ModJar
$problem = Get-JarProblem $ModJar
if ($problem) {
    if ($DryRun) { Write-Warn "$problem (a real run stops here)" } else { Stop-Setup $problem }
}
if ($ServerJarSha1 -and $ServerJarSha1 -notmatch '^[0-9a-fA-F]{40}$') { Stop-Setup '-ServerJarSha1 must be 40 hex digits.' }

if (-not (Test-Path -LiteralPath $LockFile -PathType Leaf)) { Stop-Setup "mods.lock.json not found ($LockFile)." }
try { $Lock = [IO.File]::ReadAllText($LockFile) | ConvertFrom-Json }
catch { Stop-Setup "Cannot read $LockFile ($($_.Exception.Message))." }
if ($Lock.minecraft -ne $MinecraftVersion -or $Lock.fabric_loader -ne $LoaderVersion) {
    Stop-Setup "mods.lock.json is for Minecraft $($Lock.minecraft) with loader $($Lock.fabric_loader), but this script sets up $MinecraftVersion with $LoaderVersion."
}

$OptionalChoices = @($Lock.entries | Where-Object { $_.group -eq 'server' -and $_.explicit -and $_.optional } | ForEach-Object { $_.slug } | Sort-Object -Unique)
$Included = New-Object System.Collections.ArrayList
foreach ($i in @($Include)) {
    foreach ($piece in ([string]$i -split ',')) {
        $name = $piece.Trim().ToLowerInvariant()
        if (-not $name) { continue }
        if ($name -eq 'all') { foreach ($c in $OptionalChoices) { if (-not $Included.Contains($c)) { [void]$Included.Add($c) } }; continue }
        if ($OptionalChoices -notcontains $name) {
            Stop-Setup "Unknown optional server mod '$name'. Choose from: $($OptionalChoices -join ', '), or all."
        }
        if (-not $Included.Contains($name)) { [void]$Included.Add($name) }
    }
}

# ---------------------------------------------------------------- server folder

Write-Step "Server folder: $Dir"
$repoFull = Resolve-FullPath $RepoRoot
if (($Dir + '\').StartsWith($repoFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
    Write-Warn "This folder is inside the repository, so worlds and jars could end up in git. A folder such as C:\mc\skyblock-server is safer."
}
if (Test-Path -LiteralPath $Dir -PathType Container) { Write-Info 'Exists; updating it.' }
elseif ($DryRun) { Write-Plan "create $Dir" }
else { [void][IO.Directory]::CreateDirectory($Dir); Write-Info 'Created.' }

# ---------------------------------------------------------------- 1. Java 25

Write-Step 'Java 25'
$Java = Find-Java25
if (-not $Java) {
    $hint = "Java 25 or newer was not found. Install it with:`n       winget install EclipseAdoptium.Temurin.25.JRE`n   then open a new PowerShell window and run this again."
    if ($DryRun) { Write-Warn $hint; $Java = 'java' } else { Stop-Setup $hint }
}

# ---------------------------------------------------------------- 2. server launcher

Write-Step 'Fabric server launcher'
$Launcher = Join-Path $Dir 'fabric-server-launch.jar'
$expected = $PinnedServerJarSha1
if ($ServerJarSha1) { $expected = $ServerJarSha1.ToLowerInvariant() }
if ((Test-Path -LiteralPath $Launcher -PathType Leaf) -and (Get-Sha1 $Launcher) -eq $expected) {
    Write-Info "fabric-server-launch.jar is in place (sha1 $expected)."
} elseif ($DryRun) {
    Write-Plan "download $ServerJarUrl"
    Write-Plan "  as fabric-server-launch.jar, expecting sha1 $expected"
} else {
    try {
        Save-Download $ServerJarUrl $Launcher $expected
    } catch {
        $msg = $_.Exception.Message
        if ($msg -like 'sha1 mismatch*') {
            $msg += "`n   meta.fabricmc.net builds this jar on request and publishes no hash, so this script pins the sha1 it served on 2026-09-22. If Fabric has rebuilt it, run again with -ServerJarSha1 <the new sha1>."
        }
        Stop-Setup $msg
    }
    Write-Info "Downloaded fabric-server-launch.jar (sha1 $expected)."
}

# ---------------------------------------------------------------- 3. first start

Write-Step 'Default settings'
$PropsFile = Join-Path $Dir 'server.properties'
$EulaFile = Join-Path $Dir 'eula.txt'
if ((Test-Path -LiteralPath $PropsFile -PathType Leaf) -and (Test-Path -LiteralPath $EulaFile -PathType Leaf)) {
    Write-Info 'server.properties and eula.txt already exist.'
} elseif ($DryRun) {
    Write-Plan "run in ${Dir}: `"$Java`" -jar fabric-server-launch.jar --initSettings"
    Write-Plan '  (the first run also downloads the vanilla server and the Fabric libraries)'
} else {
    Write-Info 'Starting the server once with --initSettings. The first run downloads the vanilla server and the Fabric libraries.'
    Push-Location -LiteralPath $Dir
    try { $code = Invoke-Native $Java @('-jar', 'fabric-server-launch.jar', '--initSettings') } finally { Pop-Location }
    if ($code -ne 0) { Stop-Setup "The first start failed (exit code $code). See the output above and $Dir\logs\latest.log." }
    if (-not (Test-Path -LiteralPath $PropsFile -PathType Leaf)) { Stop-Setup "server.properties was not created in $Dir." }
}

# ---------------------------------------------------------------- 4. server.properties

Write-Step 'server.properties'
$merge = Merge-Properties $PropsFile $TemplateFile
if ($merge.Changes.Count -eq 0) {
    Write-Info 'Already matches server.properties.template.'
} else {
    foreach ($change in $merge.Changes) { if ($DryRun) { Write-Plan $change } else { Write-Info $change } }
    if (-not $DryRun) { [IO.File]::WriteAllLines($PropsFile, [string[]]$merge.Lines, $Utf8NoBom) }
}

# ---------------------------------------------------------------- 5. EULA

Write-Step 'Minecraft EULA'
$eulaText = ''
if (Test-Path -LiteralPath $EulaFile -PathType Leaf) { $eulaText = [IO.File]::ReadAllText($EulaFile) }
$EulaAccepted = $eulaText -match '(?m)^[ \t]*eula[ \t]*=[ \t]*true[ \t]*\r?$'
if ($EulaAccepted) {
    Write-Info 'Already accepted in eula.txt.'
} elseif ($AcceptEula) {
    if ($DryRun) {
        Write-Plan 'set eula=true in eula.txt'
    } else {
        if ($eulaText -match '(?m)^[ \t]*eula[ \t]*=') {
            $eulaText = [regex]::Replace($eulaText, '(?m)^[ \t]*eula[ \t]*=[^\r\n]*', 'eula=true')
        } else {
            $eulaText = "#Accepted with setup-server.ps1 -AcceptEula ($EulaUrl)`r`neula=true`r`n"
        }
        [IO.File]::WriteAllText($EulaFile, $eulaText, $Utf8NoBom)
        Write-Info "eula=true (you accepted $EulaUrl with -AcceptEula)."
    }
    $EulaAccepted = $true
} else {
    Write-Warn "The server will not start until you accept the Minecraft EULA: $EulaUrl"
    Write-Info 'Read it, then run this script again with -AcceptEula (or set eula=true in eula.txt yourself).'
}

# ---------------------------------------------------------------- 6. mods

$ModsDir = Join-Path $Dir 'mods'
Write-Step "Server mods ($ModsDir)"
$Wanted = New-Object System.Collections.ArrayList
$byFile = @{}
foreach ($e in @($Lock.entries)) {
    if ($e.group -ne 'server' -or @('server', 'both') -notcontains $e.side) { continue }
    if ($e.optional) {
        $picked = $false
        foreach ($r in @($e.roots)) { if ($Included -contains $r) { $picked = $true } }
        if (-not $picked) { continue }
    }
    if (-not (Test-PlainJarName $e.filename) -or $e.url -notmatch '^https://cdn\.modrinth\.com/' -or $e.sha1 -notmatch '^[0-9a-f]{40}$') {
        Stop-Setup "mods.lock.json has a bad entry ($($e.group)/$($e.slug)); run: python tools/modpack.py check"
    }
    if ($byFile.ContainsKey($e.filename)) { continue }
    $byFile[$e.filename] = $e
    [void]$Wanted.Add($e)
}
foreach ($u in @($Lock.unresolved)) {
    if ($u -and $u.group -eq 'server') { Write-Warn "$($u.slug) is not available: $($u.reason)" }
}
$notIncluded = @($OptionalChoices | Where-Object { $Included -notcontains $_ })
if ($notIncluded.Count -gt 0) { Write-Info "Optional, not included (add with -Include): $($notIncluded -join ', ')" }
if (-not $DryRun) { [void][IO.Directory]::CreateDirectory($ModsDir) }

$ManifestPath = Join-Path $ModsDir $ManifestName
$OldManaged = @{}
if (Test-Path -LiteralPath $ManifestPath -PathType Leaf) {
    try {
        foreach ($f in @(([IO.File]::ReadAllText($ManifestPath) | ConvertFrom-Json).files)) {
            if ($f -and (Test-PlainJarName ([string]$f.file))) { $OldManaged[[string]$f.file] = [string]$f.sha1 }
        }
    } catch { Write-Warn "Ignoring unreadable $ManifestName ($($_.Exception.Message))" }
}
$NewManaged = [ordered]@{}
$Counts = @{ ok = 0; installed = 0; removed = 0 }

foreach ($e in $Wanted) {
    $dest = Join-Path $ModsDir $e.filename
    $label = "$($e.slug) $($e.version_number)"
    if ($e.prerelease) { $label += " ($($e.version_type))" }
    if ((Test-Path -LiteralPath $dest -PathType Leaf) -and (Get-Sha1 $dest) -eq $e.sha1) {
        Write-Info "ok         $label"
        $NewManaged[$e.filename] = @{ sha1 = $e.sha1; slug = $e.slug }
        $Counts.ok++
        continue
    }
    if ($DryRun) {
        Write-Plan "download   $label  $($e.filename)  ($([math]::Ceiling($e.size / 1KB)) KB)"
        $NewManaged[$e.filename] = @{ sha1 = $e.sha1; slug = $e.slug }
        continue
    }
    try {
        Save-Download $e.url $dest $e.sha1
        Write-Info "installed  $label"
        $NewManaged[$e.filename] = @{ sha1 = $e.sha1; slug = $e.slug }
        $Counts.installed++
    } catch {
        Write-Warn "$label failed: $($_.Exception.Message)"
        [void]$Failures.Add($label)
    }
}

$ourDest = Join-Path $ModsDir $ModJarName
$ourSha1 = Get-Sha1 $ModJar
if ((Test-Path -LiteralPath $ourDest -PathType Leaf) -and (Get-Sha1 $ourDest) -eq $ourSha1) {
    Write-Info "ok         $ModJarName (Voidhome)"
    $Counts.ok++
} elseif ($DryRun) {
    Write-Plan "copy       $ModJarName (Voidhome) from $ModJar"
} else {
    $part = Get-PartPath $ourDest
    [IO.File]::Copy($ModJar, $part, $true)
    if ((Get-Sha1 $part) -ne $ourSha1) { Remove-Item -LiteralPath $part -Force; Stop-Setup "Copying $ModJarName failed (sha1 changed)." }
    Move-Into $part $ourDest
    Write-Info "installed  $ModJarName (Voidhome)"
    $Counts.installed++
}
$NewManaged[$ModJarName] = @{ sha1 = $ourSha1; slug = $OurModId }

foreach ($name in @($OldManaged.Keys)) {
    if ($NewManaged.Contains($name)) { continue }
    $path = Join-Path $ModsDir $name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    if ((Get-Sha1 $path) -ne $OldManaged[$name]) {
        Write-Warn "$name was installed by this script but has changed since, so it is left alone and no longer managed."
        continue
    }
    if ($Failures.Count -gt 0) {
        Write-Info "kept       $name (some downloads failed, so nothing is removed this time)"
        $NewManaged[$name] = @{ sha1 = $OldManaged[$name]; slug = '' }
        continue
    }
    if ($DryRun) { Write-Plan "remove     $name (an older version, or no longer included)"; continue }
    Remove-Item -LiteralPath $path -Force
    Write-Info "removed    $name"
    $Counts.removed++
}

if (-not $DryRun) {
    $files = @(foreach ($k in $NewManaged.Keys) { [pscustomobject]@{ file = $k; sha1 = $NewManaged[$k].sha1; slug = $NewManaged[$k].slug } })
    $manifest = [pscustomobject]@{
        managed_by = 'server/setup-server.ps1 (Voidhome)'
        note = 'Jars listed here are replaced or removed by the setup script. Jars not listed here are yours and are never touched.'
        updated = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", $Invariant)
        included = @($Included)
        files = $files
    }
    [IO.File]::WriteAllText($ManifestPath, ($manifest | ConvertTo-Json -Depth 5), $Utf8NoBom)

    $ids = @{}
    foreach ($jar in Get-ChildItem -LiteralPath $ModsDir -Filter '*.jar' -File) {
        $id = Get-JarModId $jar.FullName
        if (-not $id) { continue }
        if (-not $ids.ContainsKey($id)) { $ids[$id] = New-Object System.Collections.ArrayList }
        [void]$ids[$id].Add($jar.Name)
    }
    foreach ($id in $ids.Keys) {
        if ($ids[$id].Count -gt 1) {
            Write-Warn "mod '$id' is in more than one jar: $($ids[$id] -join ', '). Fabric will not start until you delete the one you added yourself."
        }
    }
}

# ---------------------------------------------------------------- 7. start scripts

Write-Step 'Start scripts'
foreach ($f in @('start.ps1', 'start.bat')) {
    $src = Join-Path $PSScriptRoot $f
    $dst = Join-Path $Dir $f
    if ((Resolve-FullPath $src) -eq (Resolve-FullPath $dst)) { Write-Info "$f is already here."; continue }
    if ($DryRun) { Write-Plan "copy $f to $Dir" }
    else { [IO.File]::Copy($src, $dst, $true); Write-Info "Copied $f." }
}

# ---------------------------------------------------------------- summary

Write-Step 'Summary'
if ($DryRun) {
    Write-Info "Would manage $($NewManaged.Count) jars in mods\ ($($Counts.ok) already in place)."
} else {
    Write-Info "Mods: $($Counts.ok) already in place, $($Counts.installed) installed, $($Counts.removed) removed, $($Failures.Count) failed."
}
if ($Failures.Count -gt 0) {
    Write-Host ''
    Write-Host "Some mods failed: $($Failures -join ', '). Check your connection and run this again." -ForegroundColor Red
    exit 1
}
Write-Host ''
if ($DryRun) { Write-Host 'DRY RUN finished: nothing was downloaded or written.' -ForegroundColor Yellow }
if (-not $EulaAccepted) { Write-Host "Next: read $EulaUrl, then run this again with -AcceptEula." -ForegroundColor Yellow }
Write-Host 'Then:'
Write-Host "  1. Start the server: $Dir\start.bat   (add -RestartOnCrash to restart it after a crash)"
Write-Host '  2. In the server console: op <your name>, then whitelist add <friend> for each friend'
Write-Host '  3. Join from this PC at 127.0.0.1, and share a playit.gg tunnel with friends: see docs\HOSTING.md'
