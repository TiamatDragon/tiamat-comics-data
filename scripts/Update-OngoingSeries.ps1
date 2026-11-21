# Updates every ongoing series reading order. Add a line per series you follow.
$series = @(
    @{ SeriesName = 'Venom'; SeriesId = 16923; OrderId = 'venom-2026'; Title = 'Venom (2026)' }
    @{ SeriesName = 'Gambit'; SeriesId = 16281; OrderId = 'gambit-2026'; Title = 'Gambit: Wanted (2026)' }
    @{ SeriesName = 'Daredevil'; SeriesId = 5558; OrderId = 'daredevil-2023'; Title = 'Daredevil (2023)' }
    @{ SeriesName = 'Daredevil'; SeriesId = 15328; OrderId = 'daredevil-2026'; Title = 'Daredevil (2026)' }
    @{ SeriesName = 'Iron Man'; SeriesId = 14660; OrderId = 'ironman-2026'; Title = 'Iron Man (2026)' }
    @{ SeriesName = 'Captain America'; SeriesId = 12309; OrderId = 'captainamerica-2025'; Title = 'Captain America (2025)' }
    @{ SeriesName = 'Hulk'; SeriesId = 13913; OrderId = 'infernalhulk-2026'; Title = 'Infernal Hulk (2026)' }
    @{ SeriesName = 'Spider-Man'; SeriesId = 10958; OrderId = 'spider-man-2025'; Title = 'The AmazingSpider-Man (2025)' }
    @{ SeriesName = 'Thor'; SeriesId = 12881; OrderId = 'thor-2025'; Title = 'The Mortal Thor (2025)' }
    @{ SeriesName = 'Moon Knight'; SeriesId = 14960; OrderId = 'moonknight-2026'; Title = 'Mark Spectre:Moon Knight (2026)' }
    @{ SeriesName = 'Black Panther'; SeriesId = 14118; OrderId = 'blackpanther-2026'; Title = 'Black Panther: Intergalactic (2026)' }
    @{ SeriesName = 'Miles Morales'; SeriesId = 4984; OrderId = 'avengers-2023'; Title = 'The Avengers (2023)' }
    @{ SeriesName = 'Avengers'; SeriesId = 17270; OrderId = 'avengers-2027'; Title = 'Avengers (2027)' }
    @{ SeriesName = 'Deadpool'; SeriesId = 14961; OrderId = 'deadpool-2026'; Title = 'Wade Wilson: Deadpool (2026)' }
    @{ SeriesName = 'Punisher'; SeriesId = 15229; OrderId = 'punisher-2026'; Title = 'Punisher (2026)' }
    @{ SeriesName = 'Rogue'; SeriesId = 14433; OrderId = 'rogue-2026'; Title = 'Rogue (2026)' }
    @{ SeriesName = 'Cyclops'; SeriesId = 14958; OrderId = 'cyclops-2026'; Title = 'Cyclops (2026)' }
    @{ SeriesName = 'Storm'; SeriesId = 14849; OrderId = 'storm-2026'; Title = 'Storm: Earths Mighest Mutant (2026)' }
)

foreach ($s in $series) {
    Write-Host "== $($s.Title) =="
    & "$PSScriptRoot/New-ReadingOrderFromSeries.ps1" @s
    Start-Sleep -Seconds 5   # stay under Metron's rate limit between series
}
