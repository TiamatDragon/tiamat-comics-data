# Combines every reading order into reading-orders.json, the single file the app downloads.
$root   = Split-Path $PSScriptRoot -Parent
$orders = Get-ChildItem "$root/ReadingOrders" -Recurse -Filter *.json |
          Sort-Object FullName |
          ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json }

[ordered]@{ orders = @($orders) } | ConvertTo-Json -Depth 6 | Set-Content "$root/reading-orders.json"
Write-Host "reading-orders.json: $(@($orders).Count) reading orders"
