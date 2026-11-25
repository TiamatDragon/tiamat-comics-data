# Builds a reading-order JSON from a Metron story arc.
#   Step 1 (find the arc):  ./New-ReadingOrderFromArc.ps1 -ArcName "Civil War"
#   Step 2 (build file):    ./New-ReadingOrderFromArc.ps1 -ArcName "Civil War" -ArcId 123 -OrderId civil-war-2006-full -Title "Civil War (2006) - Complete"
param(
    [Parameter(Mandatory)] [string] $ArcName,
    [int]    $ArcId,
    [string] $OrderId,
    [string] $Title
)
git -C (Split-Path $PSScriptRoot -Parent) pull --rebase --autostash --quiet

$cred    = Get-Credential -Message "Metron login"
$pair    = "$($cred.UserName):$($cred.GetNetworkCredential().Password)"
$auth    = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
$headers = @{ Authorization = "Basic $auth"; "User-Agent" = "TiamatComics/0.1" }
$base    = "https://metron.cloud/api"

# Step 1: no ArcId yet, so list matching arcs and stop
if (-not $ArcId) {
    $r = Invoke-RestMethod -Headers $headers -Uri "$base/arc/?name=$([uri]::EscapeDataString($ArcName))"
    Write-Host "Arcs matching '$ArcName' - rerun with -ArcId <id>:"
    $r.results | Format-Table -AutoSize
    return
}

# Step 2: pull every issue in the arc (pausing to respect Metron's rate limit)
$uri  = "$base/arc/$ArcId/issue_list/"
$all  = [System.Collections.Generic.List[object]]::new()
$page = 0
while ($uri -and $page -lt 20) {
    $r = Invoke-RestMethod -Headers $headers -Uri $uri
    $all.AddRange([object[]]$r.results)
    $uri = $r.next
    $page++
    Write-Host "Page $page - $($all.Count) issues so far"
    if ($uri) { Start-Sleep -Seconds 3 }
}

# Publication order: cover date, then in-store date
$sorted = $all | Sort-Object cover_date, store_date

$entries = foreach ($i in $sorted) {
    [ordered]@{
        metronId = $i.id
        label    = $i.issue
        note     = $(if ($i.series.name -eq $ArcName) { "Main event" } else { $null })
    }
}

$order = [ordered]@{
    id      = $OrderId
    title   = $Title
    category = "event"
    summary = "Built from Metron's '$ArcName' story arc in publication order. Reorder entries as needed."
    entries = @($entries)
}

$src  = (Get-ChildItem (Split-Path $PSScriptRoot -Parent) -Recurse -Directory -Filter ReadingOrders |
         Select-Object -First 1).Parent.FullName
$dir = "$src/ReadingOrders/Events"
New-Item -ItemType Directory $dir -Force | Out-Null
$path = "$dir/$OrderId.json"
$order | ConvertTo-Json -Depth 5 | Set-Content $path
Write-Host "Wrote $($entries.Count) entries to $path"
