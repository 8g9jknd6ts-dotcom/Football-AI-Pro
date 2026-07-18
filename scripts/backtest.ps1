param(
    [string[]]$LeagueCodes = @('BRA','JPN','SWE'),
    [string]$ProjectRoot = '',
    [int]$Window = 10,
    [int]$MinimumHistory = 5,
    [double]$HomeAdvantage = 1.15,
    [double]$Rho = -0.12,
    [string]$OutputName = 'baseline-v1'
)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)}
$LeagueCodes=@($LeagueCodes | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim().ToUpperInvariant() } | Where-Object { $_ -ne '' })
if($LeagueCodes.Count -eq 0){throw 'At least one league code is required'}
Import-Module (Join-Path $ProjectRoot 'src\FootballAI.psm1') -Force
$dataDir=Join-Path $ProjectRoot 'data\standardized';$outDir=Join-Path $ProjectRoot ('backtests\'+$OutputName);$matchesFile=Join-Path $dataDir 'matches_all.csv';if(-not(Test-Path $matchesFile)){$matchesFile=Join-Path $dataDir 'matches.csv'}
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$allMatches=@(Import-Csv -LiteralPath $matchesFile -Encoding UTF8 | Where-Object {$_.LeagueCode -in $LeagueCodes -and $_.MatchDate -ne ''} | Sort-Object LeagueCode,MatchDate,MatchTime,SourceRow)
$oddsMap=@{};$totalMap=@{}
Import-Csv -LiteralPath (Join-Path $dataDir 'odds_1x2_close.csv') -Encoding UTF8 | Where-Object {$_.Provider -eq 'MarketAverage'} | ForEach-Object {$oddsMap[$_.MatchID]=$_}
if(Test-Path (Join-Path $dataDir 'markets_extended.csv')){Import-Csv -LiteralPath (Join-Path $dataDir 'markets_extended.csv') -Encoding UTF8|ForEach-Object{if($_.Market-eq'1X2_CLOSE'){$oddsMap[$_.MatchID]=$_}elseif($_.Market-eq'TOTAL_CLOSE'-and$_.Line-eq'2.5'){$totalMap[$_.MatchID]=$_}}}
$predictions=[Collections.Generic.List[object]]::new();$summaries=[Collections.Generic.List[object]]::new()
foreach($league in $LeagueCodes){
  $rows=@($allMatches|Where-Object{$_.LeagueCode -eq $league});$stats=@{};$counts=@{H=0;D=0;A=0};$n=0;$correct=0;$brier=0.0;$logloss=0.0;$mn=0;$mc=0;$mb=0.0;$ml=0.0;$tn=0;$tc=0;$tb=0.0;$tmn=0;$tmc=0;$tmb=0.0
  foreach($r in $rows){
    $homeTeam=$r.HomeTeam;$awayTeam=$r.AwayTeam
    if(-not $stats.ContainsKey($homeTeam)){$stats[$homeTeam]=@{GF=[Collections.ArrayList]::new();GA=[Collections.ArrayList]::new()}}
    if(-not $stats.ContainsKey($awayTeam)){$stats[$awayTeam]=@{GF=[Collections.ArrayList]::new();GA=[Collections.ArrayList]::new()}}
    $hs=$stats[$homeTeam];$as=$stats[$awayTeam]
    if($hs.GF.Count -ge $MinimumHistory -and $as.GF.Count -ge $MinimumHistory){
      $lh=((Get-MeanLast $hs.GF $Window)+(Get-MeanLast $as.GA $Window))/2.0*$HomeAdvantage
      $la=((Get-MeanLast $as.GF $Window)+(Get-MeanLast $hs.GA $Window))/2.0
      $p=Get-DixonColesPrediction $lh $la $Rho;$met=Get-OutcomeMetrics $p.HomeProbability $p.DrawProbability $p.AwayProbability $r.Result
      $n++;if($p.Prediction -eq $r.Result){$correct++};$brier+=$met.Brier;$logloss+=$met.LogLoss
      $actualOver=(([int]$r.HomeGoals+[int]$r.AwayGoals)-gt2);$predOver=$p.Over25Probability-ge0.5;$tn++;if($actualOver-eq$predOver){$tc++};$y=if($actualOver){1.0}else{0.0};$tb+=(($p.Over25Probability-$y)*($p.Over25Probability-$y))
      $mph='';$mpd='';$mpa='';$ret=''
      if($oddsMap.ContainsKey($r.MatchID)){$o=$oddsMap[$r.MatchID];$mp=Get-DeVigProbabilities ([double]$o.HomeOdds) ([double]$o.DrawOdds) ([double]$o.AwayOdds);if($null-ne$mp){$mph=$mp.HomeProbability;$mpd=$mp.DrawProbability;$mpa=$mp.AwayProbability;$ret=$mp.ReturnRate;$mm=Get-OutcomeMetrics $mph $mpd $mpa $r.Result;$pick=if($mph-ge$mpd-and$mph-ge$mpa){'H'}elseif($mpd-ge$mpa){'D'}else{'A'};$mn++;if($pick-eq$r.Result){$mc++};$mb+=$mm.Brier;$ml+=$mm.LogLoss}}
      $marketOver='';if($totalMap.ContainsKey($r.MatchID)){$to=$totalMap[$r.MatchID];$ro=1.0/[double]$to.OverOdds;$ru=1.0/[double]$to.UnderOdds;$marketOver=$ro/($ro+$ru);$tmn++;$marketPred=$marketOver-ge0.5;if($marketPred-eq$actualOver){$tmc++};$tmb+=(($marketOver-$y)*($marketOver-$y))}
      $predictions.Add([pscustomobject]@{MatchID=$r.MatchID;LeagueCode=$league;MatchDate=$r.MatchDate;Result=$r.Result;Prediction=$p.Prediction;PH=$p.HomeProbability;PD=$p.DrawProbability;PA=$p.AwayProbability;LambdaH=$p.HomeLambda;LambdaA=$p.AwayLambda;Score=($p.ScoreHome.ToString()+'-'+$p.ScoreAway.ToString());Brier=$met.Brier;LogLoss=$met.LogLoss;Over25Probability=$p.Over25Probability;ActualOver25=$actualOver;MarketOver25Probability=$marketOver;MarketPH=$mph;MarketPD=$mpd;MarketPA=$mpa;MarketReturnRate=$ret})
    }
    $hg=[int]$r.HomeGoals;$ag=[int]$r.AwayGoals;[void]$hs.GF.Add($hg);[void]$hs.GA.Add($ag);[void]$as.GF.Add($ag);[void]$as.GA.Add($hg);$counts[$r.Result]++
  }
  if($rows.Count -eq 0){throw "No dated matches found for league $league"}
  $majority=($counts.Values|Measure-Object -Maximum).Maximum/[double]$rows.Count;$acc=if($n){$correct/$n}else{0};$bs=if($n){$brier/$n}else{0};$ll=if($n){$logloss/$n}else{0};$passed=$n-ge500-and$acc-ge($majority+0.02)-and$bs-le0.65-and$ll-le1.10
  $summaries.Add([pscustomobject]@{LeagueCode=$league;SourceMatches=$rows.Count;Evaluated=$n;Accuracy=$acc;Brier=$bs;LogLoss=$ll;MajorityBaseline=$majority;AccuracyLift=$acc-$majority;MarketEvaluated=$mn;MarketAccuracy=if($mn){$mc/$mn}else{$null};MarketBrier=if($mn){$mb/$mn}else{$null};MarketLogLoss=if($mn){$ml/$mn}else{$null};Over25Evaluated=$tn;Over25Accuracy=if($tn){$tc/$tn}else{$null};Over25Brier=if($tn){$tb/$tn}else{$null};MarketOver25Evaluated=$tmn;MarketOver25Accuracy=if($tmn){$tmc/$tmn}else{$null};MarketOver25Brier=if($tmn){$tmb/$tmn}else{$null};GatePassed=$passed})
}
$predictions|Export-Csv -LiteralPath (Join-Path $outDir 'predictions.csv') -NoTypeInformation -Encoding UTF8
$dataHash=(Get-FileHash -LiteralPath $matchesFile -Algorithm SHA256).Hash.ToLowerInvariant()
$artifact=[ordered]@{Model='FootballAI-Poisson-Baseline';Version='1.0.0-candidate';CreatedAt=(Get-Date).ToUniversalTime().ToString('o');DataSha256=$dataHash;Protocol='docs/BACKTEST_PROTOCOL.md';Parameters=[ordered]@{Window=$Window;MinimumHistory=$MinimumHistory;HomeAdvantage=$HomeAdvantage;Rho=$Rho;MaxGoals=8};Leagues=$summaries}
$artifact|ConvertTo-Json -Depth 8|Set-Content -LiteralPath (Join-Path $outDir 'summary.json') -Encoding UTF8
$artifact|ConvertTo-Json -Depth 8
