param(
    [Parameter(Mandatory=$true)][string]$LeagueCode,
    [Parameter(Mandatory=$true)][string]$HomeTeam,
    [Parameter(Mandatory=$true)][string]$AwayTeam,
    [Parameter(Mandatory=$true)][int]$HomeHandicap,
    [Parameter(Mandatory=$true)][double]$HandicapWinOdds,
    [Parameter(Mandatory=$true)][double]$HandicapDrawOdds,
    [Parameter(Mandatory=$true)][double]$HandicapLossOdds,
    [Parameter(Mandatory=$true)][string]$CutoffDate,
    [string]$ProjectRoot='',
    [string]$HistoryPath='',
    [string]$OutputPath='',
    [int]$Window=10,
    [double]$HomeAdvantage=1.15,
    [double]$Rho=-.12,
    [bool]$MarketConflict=$false,
    [bool]$HistoricalGatePassed=$false
)

Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

if([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

$cutoff=[datetime]::MinValue
if(-not [datetime]::TryParseExact($CutoffDate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$cutoff)) {
    throw 'CutoffDate must be yyyy-MM-dd. A dated pre-match cutoff is mandatory.'
}

Import-Module (Join-Path $ProjectRoot 'src\HandicapModel.psm1') -Force

function Write-Forecast($Forecast) {
    $out=if([string]::IsNullOrWhiteSpace($OutputPath)) { Join-Path $ProjectRoot 'reports\handicap_forecast.json' } else { $OutputPath }
    $Forecast | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $out -Encoding UTF8
    $Forecast | ConvertTo-Json -Depth 8
}

function New-SkipForecast([string[]]$Reasons, [int]$LeagueRowsBeforeCutoff=0, [int]$HomeHistory=0, [int]$AwayHistory=0) {
    [ordered]@{
        Status='SKIP'
        LeagueCode=$LeagueCode
        MatchDate=$CutoffDate
        HomeTeam=$HomeTeam
        AwayTeam=$AwayTeam
        HomeHandicap=$HomeHandicap
        GoalMarginDistribution=$null
        GoalMarginDistributionStatus='UNAVAILABLE'
        ModelProbability=$null
        MarketImpliedProbability=$null
        Edge=$null
        Confidence=$null
        HANDICAP_DECISION='SKIP'
        TriggeredReasons=@()
        RejectedReasons=@($Reasons)
        DataCoverage=[ordered]@{
            LeagueRowsBeforeCutoff=$LeagueRowsBeforeCutoff
            HomeTeamHistory=$HomeHistory
            AwayTeamHistory=$AwayHistory
            MinimumTeamHistory=5
            HistoricalGatePassed=$HistoricalGatePassed
        }
        FormalRecommendation=$false
    }
}

$path=if([string]::IsNullOrWhiteSpace($HistoryPath)) { Join-Path $ProjectRoot 'data\standardized\matches_all.csv' } else { $HistoryPath }
if(-not (Test-Path -LiteralPath $path)) { throw "Missing standardized history: $path" }

$allLeagueRows=@(Import-Csv -LiteralPath $path -Encoding UTF8 | Where-Object { $_.LeagueCode -eq $LeagueCode })
$datedRows=[Collections.Generic.List[object]]::new()
$invalidDateRows=0
foreach($row in $allLeagueRows) {
    $date=[datetime]::MinValue
    if(-not [datetime]::TryParseExact([string]$row.MatchDate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$date)) {
        $invalidDateRows++
        continue
    }
    if($date -lt $cutoff) { $datedRows.Add($row) }
}

# Rows without a verifiable date are never used as a fallback.  This prevents a
# target match or later result being silently included in the training history.
if($datedRows.Count -eq 0) {
    $reasons=@('NO_DATED_PREMATCH_HISTORY')
    if($invalidDateRows -gt 0) { $reasons += 'UNDATED_LEAGUE_HISTORY_EXCLUDED' }
    Write-Forecast (New-SkipForecast $reasons 0 0 0)
    exit
}

$rows=@($datedRows | Sort-Object MatchDate,MatchTime,SourceRow)
$homeRows=@($rows | Where-Object { $_.HomeTeam -eq $HomeTeam -or $_.AwayTeam -eq $HomeTeam } | Select-Object -Last $Window)
$awayRows=@($rows | Where-Object { $_.HomeTeam -eq $AwayTeam -or $_.AwayTeam -eq $AwayTeam } | Select-Object -Last $Window)

if($homeRows.Count -lt 5 -or $awayRows.Count -lt 5) {
    $reasons=@('INSUFFICIENT_DATED_TEAM_HISTORY')
    if($invalidDateRows -gt 0) { $reasons += 'UNDATED_LEAGUE_HISTORY_EXCLUDED' }
    Write-Forecast (New-SkipForecast $reasons $rows.Count $homeRows.Count $awayRows.Count)
    exit
}

function Get-GoalsFor($Row, [string]$Team) {
    if($Row.HomeTeam -eq $Team) { return [double]$Row.HomeGoals }
    return [double]$Row.AwayGoals
}
function Get-GoalsAgainst($Row, [string]$Team) {
    if($Row.HomeTeam -eq $Team) { return [double]$Row.AwayGoals }
    return [double]$Row.HomeGoals
}

$homeLambda=((($homeRows | ForEach-Object { Get-GoalsFor $_ $HomeTeam } | Measure-Object -Average).Average) + (($awayRows | ForEach-Object { Get-GoalsAgainst $_ $AwayTeam } | Measure-Object -Average).Average)) / 2 * $HomeAdvantage
$awayLambda=((($awayRows | ForEach-Object { Get-GoalsFor $_ $AwayTeam } | Measure-Object -Average).Average) + (($homeRows | ForEach-Object { Get-GoalsAgainst $_ $HomeTeam } | Measure-Object -Average).Average)) / 2
$prediction=Get-JczqHandicapPrediction $homeLambda $awayLambda $HomeHandicap $Rho
$market=Get-HandicapMarketProbabilities $HandicapWinOdds $HandicapDrawOdds $HandicapLossOdds
if($null -eq $market) { throw 'Invalid JCZQ handicap odds' }

$dataComplete=($invalidDateRows -eq 0)
$decision=Get-HandicapDecision $prediction $market ([Math]::Min($homeRows.Count,$awayRows.Count)) $dataComplete $MarketConflict $HistoricalGatePassed
$reasons=@($decision.RejectedReasons)
if($invalidDateRows -gt 0) { $reasons += 'UNDATED_LEAGUE_HISTORY_EXCLUDED' }

$forecast=[ordered]@{
    Status='OK'
    LeagueCode=$LeagueCode
    MatchDate=$CutoffDate
    HomeTeam=$HomeTeam
    AwayTeam=$AwayTeam
    HomeHandicap=$HomeHandicap
    GoalMarginDistribution=[ordered]@{
        HomeWin1=$prediction.HomeWin1Probability
        HomeWin2=$prediction.HomeWin2Probability
        HomeWin3Plus=$prediction.HomeWin3PlusProbability
        Draw=$prediction.DrawProbability
        AwayWin=$prediction.AwayWinProbability
    }
    GoalMarginDistributionStatus='AVAILABLE'
    ModelProbability=$decision.ModelProbability
    MarketImpliedProbability=$decision.MarketImpliedProbability
    Edge=$decision.Edge
    Confidence=$decision.Confidence
    HANDICAP_DECISION=$decision.HANDICAP_DECISION
    SelectedOutcome=$decision.SelectedOutcome
    TriggeredReasons=@($decision.TriggeredReasons)
    RejectedReasons=$reasons
    DataCoverage=[ordered]@{
        LeagueRowsBeforeCutoff=$rows.Count
        UndatedLeagueRowsExcluded=$invalidDateRows
        HomeTeamHistory=$homeRows.Count
        AwayTeamHistory=$awayRows.Count
        MinimumTeamHistory=5
        HistoricalGatePassed=$HistoricalGatePassed
    }
    FormalRecommendation=$false
}

Write-Forecast $forecast
