# Builds or updates a reading-order JSON from a Metron series.
#   Step 1 (find the series): ./New-ReadingOrderFromSeries.ps1 -SeriesName "Venom"
#   Step 2 (build/update):    ./New-ReadingOrderFromSeries.ps1 -SeriesName "Venom" -SeriesId 123 -OrderId venom-2025 -Title "Venom (2025)"
#   Optional: -Category ongoing|limited|oneShot  (otherwise detected from Metron)
param(
    [Parameter(Mandatory)] [string] $SeriesName,
    [int]    $SeriesId,
    [string] $OrderId,
    [string] $Title,
    [ValidateSet('ongoing', 'limited', 'oneShot')] [string] $Category
)

# Login: GitHub secrets when running in the Action, otherwise ask
if ($env:METRON_USERNAME -and $env:METRON_PASSWORD) {
    $user = $env:METRON_USERNAME
    $pass = $env:METRON_PASSWORD
} else {
    $cred = Get-Credential -Message "Metron login"
    $user = $cred.UserName
    $pass = $cred.GetNetworkCredential().Password
}
$pair    = "${user}:$pass"
$auth    = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
$headers = @{ Authorization = "Basic $auth"; "User-Agent" = "TiamatComics/0.1" }
$base    = "https://metron.cloud/api"

# Step 1: no SeriesId yet, so list matching series (newest first) and stop
if (-not $SeriesId) {
    $r = Invoke-RestMethod -Headers $headers -Uri "$base/series/?name=$([uri]::EscapeDataString($SeriesName))"
    Write-Host "Series matching '$SeriesName' - rerun with -SeriesId <id>:"
    $r.results | Sort-Object year_began -Descending |
        Select-Object id, series, year_began, issue_count,
                      @{ n = 'type';      e = { $_.series_type.name } },
                      @{ n = 'publisher'; e = { $_.publisher.name } } |
        Format-Table -AutoSize
    return
}
if (-not $OrderId -or -not $Title) {
    throw "Also pass -OrderId and -Title, e.g. -OrderId venom-2025 -Title 'Venom (2025)'"
}

# Category: from -Category if given, otherwise from Metron's series type
if (-not $Category) {
    $info = Invoke-RestMethod -Headers $headers -Uri "$base/series/$SeriesId/"
    $type = "$($info.series_type.name)"
    $Category = switch -Regex ($type) {
        'one.?shot'    { 'oneShot'; break }
        'limited|mini' { 'limited'; break }
        default        { 'ongoing' }
    }
    Write-Host "Metron series type '$type' -> category '$Category'"
    Start-Sleep -Seconds 3
}
if (-not $Category) { $Category = 'ongoing' }   # safety net

# Pull every issue in the series (pausing to respect Metron's rate limit)
$uri  = "$base/series/$SeriesId/issue_list/"
$all  = [System.Collections.Generic.List[object]]::new()
$page = 0
while ($uri -and $page -lt 40) {
    $r = Invoke-RestMethod -Headers $headers -Uri $uri
    $all.AddRange([object[]]$r.results)
    $uri = $r.next
    $page++
    Write-Host "Page $page - $($all.Count) issues so far"
    if ($uri) { Start-Sleep -Seconds 3 }
}

# Order by issue number, then cover date
$sorted = $all | Sort-Object @{ e = { $n = $_.number -replace '[^0-9.]', ''; if ($n) { [double]$n } else { 0 } } }, cover_date

$entries = foreach ($i in $sorted) {
    [ordered]@{
        metronId = $i.id
        label    = $i.issue
        note     = $(if ($i.store_date) { "In stores $($i.store_date)" } else { $null })
    }
}

# Find the app's ReadingOrders folder (works on your Mac and on GitHub)
$src = (Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Recurse -Directory -Filter ReadingOrders |
        Select-Object -First 1).Parent.FullName
if (-not $src) { throw "Couldn't find a ReadingOrders folder in the repo." }

# Update the file wherever it lives, or create it in its category folder
$folders  = @{ ongoing = 'Ongoing Series'; limited = 'Limited Series'; oneShot = 'One-Shots' }
$existing = Get-ChildItem "$src/ReadingOrders" -Recurse -Filter "$OrderId.json" | Select-Object -First 1
if ($existing) {
    $path = $existing.FullName
} else {
    $dir = Join-Path "$src/ReadingOrders" $folders[$Category]
    New-Item -ItemType Directory $dir -Force | Out-Null
    $path = Join-Path $dir "$OrderId.json"
}

if ($existing) {
    # Update: keep existing entries and their order, append only new issues
    $order = Get-Content $path -Raw | ConvertFrom-Json
    if (-not $order.category) {
        $order | Add-Member -NotePropertyName category -NotePropertyValue $Category -Force
    }
    $known = @($order.entries | ForEach-Object { $_.metronId })
    $new   = @($entries | Where-Object { $_.metronId -notin $known })
    $order.entries = @($order.entries) + @($new | ForEach-Object { [pscustomobject]$_ })
    Write-Host "Added $($new.Count) new issue(s); kept your $($known.Count) existing entries."
} else {
    $order = [ordered]@{
        id       = $OrderId
        title    = $Title
        category = $Category
        summary  = "From Metron. Rerun the script to add new issues."
        entries  = @($entries)
    }
    Write-Host "Created with $($entries.Count) entries."
}

$order | ConvertTo-Json -Depth 5 | Set-Content $path
Write-Host "Saved $path"
