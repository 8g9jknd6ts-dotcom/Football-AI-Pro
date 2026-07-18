param(
    [Parameter(Mandatory=$true)][string]$SourceDirectory,
    [string]$ProjectRoot = ''
)

$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectRoot = Split-Path -Parent $scriptDirectory
}
$leagueCodes = @('ARG','AUT','BRA','CHN','FIN','IRL','ISL','JPN','K1','MEX','NOR','POL','ROU','RUS','SWE','SWZ','USA')
$rawDir = Join-Path $ProjectRoot 'data\raw'
$outDir = Join-Path $ProjectRoot 'data\standardized'
New-Item -ItemType Directory -Force -Path $rawDir,$outDir | Out-Null

function Clean([object]$value) {
    if ($null -eq $value) { return '' }
    return ([string]$value).Trim()
}

function IsoDate([string]$value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return '' }
    $formats = @('dd/MM/yyyy','d/M/yyyy','yyyy-MM-dd','dd/MM/yy','d/M/yy')
    foreach ($format in $formats) {
        $parsed = [datetime]::MinValue
        if ([datetime]::TryParseExact($value.Trim(), $format, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$parsed)) {
            return $parsed.ToString('yyyy-MM-dd')
        }
    }
    throw "Unparseable date: $value"
}

function MatchId([string]$identity) {
    $bytes = [Text.Encoding]::UTF8.GetBytes($identity.ToUpperInvariant())
    $hex = [BitConverter]::ToString($script:sha.ComputeHash($bytes)).Replace('-','').ToLowerInvariant()
    return 'FAI-' + $hex.Substring(0,24)
}

function ValidOdds([string]$h,[string]$d,[string]$a) {
    $x=0.0; $y=0.0; $z=0.0
    return [double]::TryParse($h,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$x) -and
           [double]::TryParse($d,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$y) -and
           [double]::TryParse($a,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$z) -and
           $x -gt 1 -and $y -gt 1 -and $z -gt 1
}

$matches = [Collections.Generic.List[object]]::new()
$odds = [Collections.Generic.List[object]]::new()
$manifest = [Collections.Generic.List[object]]::new()
$rejects = [Collections.Generic.List[object]]::new()
$ids = @{}
$script:sha = [Security.Cryptography.SHA256]::Create()

foreach ($code in $leagueCodes) {
    $source = Join-Path $SourceDirectory ($code + '.csv')
    if (-not (Test-Path -LiteralPath $source)) { throw "Missing source file: $source" }
    Copy-Item -LiteralPath $source -Destination (Join-Path $rawDir ($code + '.csv')) -Force
    $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    $rows = @(Import-Csv -LiteralPath $source -Encoding UTF8)
    $dateMissing = 0
    for ($i=0; $i -lt $rows.Count; $i++) {
        $r = $rows[$i]; $rowNo = $i + 1
        if ($code -eq 'ISL') {
            $season=Clean $r.Season; $date=''; $time=''; $stage="ROW-$rowNo"
            $homeTeam=Clean $r.HomeTeam; $awayTeam=Clean $r.AwayTeam; $hg=Clean $r.FTHG; $ag=Clean $r.FTAG; $res=(Clean $r.Res).ToUpperInvariant()
            $country='Iceland'; $league='ISL'
        } elseif ($code -eq 'K1') {
            $season=Clean $r.season; $date=''; $time=''; $stage=(Clean $r.stage) + "-ROW-$rowNo"
            $homeTeam=Clean $r.home_team; $awayTeam=Clean $r.away_team; $hg=Clean $r.home_goals; $ag=Clean $r.away_goals; $res=(Clean $r.result).ToUpperInvariant()
            $country='South Korea'; $league='K League 1'
        } else {
            $season=Clean $r.Season; $date=IsoDate (Clean $r.Date); $time=Clean $r.Time; $stage=''
            $homeTeam=Clean $r.Home; $awayTeam=Clean $r.Away; $hg=Clean $r.HG; $ag=Clean $r.AG; $res=(Clean $r.Res).ToUpperInvariant()
            $country=Clean $r.Country; $league=Clean $r.League
        }
        if ($date -eq '') { $dateMissing++ }
        $hgi=0; $agi=0
        if (-not [int]::TryParse($hg,[ref]$hgi) -or -not [int]::TryParse($ag,[ref]$agi) -or $hgi -lt 0 -or $agi -lt 0) {
            $rejects.Add([pscustomobject]@{LeagueCode=$code;SourceFile=($code+'.csv');SourceRow=$rowNo;Reason='INVALID_OR_MISSING_SCORE'})
            continue
        }
        $expected = if ($hgi -gt $agi) {'H'} elseif ($hgi -eq $agi) {'D'} else {'A'}
        if ($res -ne $expected) { throw "$code row $rowNo result $res disagrees with score $hgi-$agi" }
        if ($season -eq '' -or $homeTeam -eq '' -or $awayTeam -eq '' -or $homeTeam -eq $awayTeam) { throw "$code row $rowNo has invalid identity fields" }
        $identity = @($code,$season,$date,$stage,$homeTeam,$awayTeam) -join '|'
        $id = MatchId $identity
        if ($ids.ContainsKey($id)) { throw "MatchID collision: $id ($identity / $($ids[$id]))" }
        $ids[$id] = $identity
        $matches.Add([pscustomobject]@{MatchID=$id;Country=$country;LeagueCode=$code;League=$league;Season=$season;MatchDate=$date;MatchTime=$time;Stage=$stage;HomeTeam=$homeTeam;AwayTeam=$awayTeam;HomeGoals=$hgi;AwayGoals=$agi;Result=$res;SourceFile=($code+'.csv');SourceRow=$rowNo})

        if ($code -notin @('ISL','K1')) {
            $providers = @(
                @('Pinnacle','PSCH','PSCD','PSCA'), @('MarketMax','MaxCH','MaxCD','MaxCA'),
                @('MarketAverage','AvgCH','AvgCD','AvgCA'), @('Betfair','BFECH','BFECD','BFECA'),
                @('Bet365','B365CH','B365CD','B365CA')
            )
            foreach ($p in $providers) {
                $oh=Clean $r.($p[1]); $od=Clean $r.($p[2]); $oa=Clean $r.($p[3])
                if ($code -eq 'JPN' -and $p[0] -eq 'Bet365' -and $oa -eq '') { $oa=Clean $r.B36CA }
                if (ValidOdds $oh $od $oa) { $odds.Add([pscustomobject]@{MatchID=$id;Provider=$p[0];Market='1X2_CLOSE';HomeOdds=$oh;DrawOdds=$od;AwayOdds=$oa}) }
            }
        }
    }
    $manifest.Add([pscustomobject]@{LeagueCode=$code;Rows=$rows.Count;Sha256=$hash;MissingDateRows=$dateMissing;SourceFile=($code+'.csv')})
}

$matches | Export-Csv -LiteralPath (Join-Path $outDir 'matches.csv') -NoTypeInformation -Encoding UTF8
$odds | Export-Csv -LiteralPath (Join-Path $outDir 'odds_1x2_close.csv') -NoTypeInformation -Encoding UTF8
$rejects | Export-Csv -LiteralPath (Join-Path $outDir 'rejected_rows.csv') -NoTypeInformation -Encoding UTF8
$manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $outDir 'manifest.json') -Encoding UTF8

[pscustomobject]@{Leagues=$leagueCodes.Count;SourceRows=($manifest | Measure-Object -Property Rows -Sum).Sum;Matches=$matches.Count;RejectedRows=$rejects.Count;OddsRows=$odds.Count;UniqueMatchIDs=$ids.Count} | ConvertTo-Json
$script:sha.Dispose()
