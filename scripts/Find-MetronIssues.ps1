# Lists Metron issue IDs for one series, e.g.:
#   ./Find-MetronIssues.ps1 -Series "Civil War" -YearBegan 2006
param(
    [Parameter(Mandatory)] [string] $Series,
    [Parameter(Mandatory)] [int]    $YearBegan
)

$cred    = Get-Credential -Message "Metron login"
$pair    = "$($cred.UserName):$($cred.GetNetworkCredential().Password)"
$auth    = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($pair))
$headers = @{ Authorization = "Basic $auth"; "User-Agent" = "TiamatComics/0.1" }

$uri  = "https://metron.cloud/api/issue/?series_name=$([uri]::EscapeDataString($Series))"
$all  = [System.Collections.Generic.List[object]]::new()
$page = 0
while ($uri -and $page -lt 15) {
    $r = Invoke-RestMethod -Uri $uri -Headers $headers
    $all.AddRange([object[]]$r.results)
    $uri = $r.next
    $page++
    Write-Host "Page $page - $($all.Count) issues so far"
    if ($uri) { Start-Sleep -Seconds 3 }   # stay under Metron's 20 requests/minute
}

$found = $all | Where-Object { $_.series.name -eq $Series -and $_.series.year_began -eq $YearBegan }
if ($found) {
    $found |
        Sort-Object { $n = $_.number -replace '[^0-9.]', ''; if ($n) { [double]$n } else { 0 } } |
        Select-Object id, number, issue, cover_date |
        Format-Table -AutoSize
} else {
    Write-Host "No exact match. Series names Metron returned:"
    $all | ForEach-Object { "$($_.series.name) ($($_.series.year_began))" } | Sort-Object -Unique
}
