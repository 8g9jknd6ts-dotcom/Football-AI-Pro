Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MeanLast {
    param([Collections.ArrayList]$Values, [int]$Window = 10)
    $start = [Math]::Max(0, $Values.Count - $Window)
    $sum = 0.0
    for ($i = $start; $i -lt $Values.Count; $i++) { $sum += [double]$Values[$i] }
    return $sum / ($Values.Count - $start)
}

function Get-PoissonVector {
    param([double]$Lambda, [int]$MaxGoals = 8)
    $p = New-Object double[] ($MaxGoals + 1)
    $p[0] = [Math]::Exp(-$Lambda)
    for ($k = 1; $k -le $MaxGoals; $k++) { $p[$k] = $p[$k-1] * $Lambda / $k }
    return ,$p
}

function Get-DixonColesPrediction {
    param([double]$HomeLambda, [double]$AwayLambda, [double]$Rho = -0.12, [int]$MaxGoals = 8, [int]$Handicap = 0)
    $HomeLambda = [Math]::Max(0.15, [Math]::Min(4.5, $HomeLambda))
    $AwayLambda = [Math]::Max(0.15, [Math]::Min(4.5, $AwayLambda))
    $hp = Get-PoissonVector $HomeLambda $MaxGoals
    $ap = Get-PoissonVector $AwayLambda $MaxGoals
    $matrix = New-Object 'double[,]' ($MaxGoals + 1),($MaxGoals + 1)
    $sum=0.0; $h=0.0; $d=0.0; $a=0.0; $hh=0.0; $hd=0.0; $ha=0.0; $under25=0.0; $over25=0.0; $best=-1.0; $bestH=0; $bestA=0
    $totals=New-Object double[] (($MaxGoals*2)+1);$scores=[Collections.Generic.List[object]]::new()
    for($i=0;$i -le $MaxGoals;$i++) {
        for($j=0;$j -le $MaxGoals;$j++) {
            $tau=1.0
            if($i -eq 0 -and $j -eq 0){$tau=1.0-($HomeLambda*$AwayLambda*$Rho)}
            elseif($i -eq 0 -and $j -eq 1){$tau=1.0+($HomeLambda*$Rho)}
            elseif($i -eq 1 -and $j -eq 0){$tau=1.0+($AwayLambda*$Rho)}
            elseif($i -eq 1 -and $j -eq 1){$tau=1.0-$Rho}
            $v=[Math]::Max(0.0,$hp[$i]*$ap[$j]*$tau); $matrix[$i,$j]=$v; $sum+=$v
        }
    }
    for($i=0;$i -le $MaxGoals;$i++) {
        for($j=0;$j -le $MaxGoals;$j++) {
            $v=$matrix[$i,$j]/$sum
            if($i -gt $j){$h+=$v}elseif($i -eq $j){$d+=$v}else{$a+=$v}
            $adjusted=$i+$Handicap;if($adjusted -gt $j){$hh+=$v}elseif($adjusted -eq $j){$hd+=$v}else{$ha+=$v}
            if(($i+$j)-le2){$under25+=$v}else{$over25+=$v};$totals[$i+$j]+=$v
            if($v -gt $best){$best=$v;$bestH=$i;$bestA=$j}
            $scores.Add([pscustomobject]@{Score=($i.ToString()+'-'+$j.ToString());Probability=$v})
        }
    }
    $totalMode=0;for($k=1;$k-lt$totals.Count;$k++){if($totals[$k]-gt$totals[$totalMode]){$totalMode=$k}}
    $result = if($h -ge $d -and $h -ge $a){'H'}elseif($d -ge $a){'D'}else{'A'}
    $handicapResult=if($hh-ge$hd-and$hh-ge$ha){'H'}elseif($hd-ge$ha){'D'}else{'A'}
    return [pscustomobject]@{HomeProbability=$h;DrawProbability=$d;AwayProbability=$a;Prediction=$result;ScoreHome=$bestH;ScoreAway=$bestA;TopScores=@($scores|Sort-Object Probability -Descending|Select-Object -First 3);HomeLambda=$HomeLambda;AwayLambda=$AwayLambda;Under25Probability=$under25;Over25Probability=$over25;TotalGoalsMode=$totalMode;Handicap=$Handicap;HandicapHomeProbability=$hh;HandicapDrawProbability=$hd;HandicapAwayProbability=$ha;HandicapPrediction=$handicapResult}
}

function Get-DeVigProbabilities {
    param([double]$HomeOdds,[double]$DrawOdds,[double]$AwayOdds)
    if($HomeOdds -le 1 -or $DrawOdds -le 1 -or $AwayOdds -le 1){return $null}
    $rh=1.0/$HomeOdds;$rd=1.0/$DrawOdds;$ra=1.0/$AwayOdds;$s=$rh+$rd+$ra
    return [pscustomobject]@{HomeProbability=$rh/$s;DrawProbability=$rd/$s;AwayProbability=$ra/$s;ReturnRate=1.0/$s}
}

function Get-OutcomeMetrics {
    param([double]$PH,[double]$PD,[double]$PA,[string]$Result)
    $eps=1e-15; $yh=if($Result -eq 'H'){1.0}else{0.0};$yd=if($Result -eq 'D'){1.0}else{0.0};$ya=if($Result -eq 'A'){1.0}else{0.0}
    $picked=if($Result -eq 'H'){$PH}elseif($Result -eq 'D'){$PD}else{$PA}
    return [pscustomobject]@{Brier=(($PH-$yh)*($PH-$yh)+($PD-$yd)*($PD-$yd)+($PA-$ya)*($PA-$ya));LogLoss=-[Math]::Log([Math]::Max($eps,$picked))}
}

function Get-LeagueProfile {
    param([Parameter(Mandatory=$true)][string]$LeagueCode)
    $code=$LeagueCode.Trim().ToUpperInvariant()
    $profiles=@{
        'E0'=@{HomeAdvantage=1.12;GoalWeight=1.00;MarketWeight=0.68;MinimumHistory=80}
        'FD_B1'=@{HomeAdvantage=1.10;GoalWeight=0.98;MarketWeight=0.70;MinimumHistory=60}
        'FD_D1'=@{HomeAdvantage=1.14;GoalWeight=1.02;MarketWeight=0.68;MinimumHistory=60}
        'FD_E0'=@{HomeAdvantage=1.12;GoalWeight=1.00;MarketWeight=0.68;MinimumHistory=60}
        'FD_F1'=@{HomeAdvantage=1.10;GoalWeight=0.96;MarketWeight=0.70;MinimumHistory=60}
        'FD_I1'=@{HomeAdvantage=1.08;GoalWeight=0.94;MarketWeight=0.72;MinimumHistory=60}
        'JPN'=@{HomeAdvantage=1.08;GoalWeight=0.92;MarketWeight=0.72;MinimumHistory=80}
        'SWE'=@{HomeAdvantage=1.11;GoalWeight=1.05;MarketWeight=0.70;MinimumHistory=80}
    }
    $p=if($profiles.ContainsKey($code)){$profiles[$code]}else{@{HomeAdvantage=1.10;GoalWeight=1.00;MarketWeight=0.70;MinimumHistory=80}}
    return [pscustomobject]@{LeagueCode=$code;ProfileSource=if($profiles.ContainsKey($code)){'CANDIDATE_LEAGUE_PROFILE'}else{'GENERIC_FALLBACK'};HomeAdvantage=[double]$p.HomeAdvantage;GoalWeight=[double]$p.GoalWeight;MarketWeight=[double]$p.MarketWeight;ModelWeight=(1.0-[double]$p.MarketWeight);MinimumHistory=[int]$p.MinimumHistory;ProductionEligible=$false}
}

function Get-AbstentionDecision {
    param([double]$TopProbability,[double]$SecondProbability,[int]$SampleSize,[bool]$DataComplete=$true,[bool]$SignalConflict=$false,[double]$MinimumTopProbability=0.45,[int]$MinimumSampleSize=50)
    $reasons=[Collections.Generic.List[string]]::new()
    if(-not $DataComplete){$reasons.Add('INCOMPLETE_DATA')}
    if($SampleSize -lt $MinimumSampleSize){$reasons.Add('INSUFFICIENT_SAMPLE')}
    if($TopProbability -lt $MinimumTopProbability){$reasons.Add('LOW_TOP_PROBABILITY')}
    if(($TopProbability-$SecondProbability) -lt 0.05){$reasons.Add('LOW_SEPARATION')}
    if($SignalConflict){$reasons.Add('MARKET_MODEL_CONFLICT')}
    return [pscustomobject]@{Eligible=($reasons.Count -eq 0);Reasons=@($reasons);TopProbability=$TopProbability;SecondProbability=$SecondProbability;SampleSize=$SampleSize;DataComplete=$DataComplete;SignalConflict=$SignalConflict;Policy='RESEARCH_ONLY_UNTIL_BACKTEST_GATE'}
}

function Get-UpsetRiskProfile {
    param(
        [Parameter(Mandatory=$true)][ValidateSet('H','D','A')][string]$MarketFavorite,
        [Parameter(Mandatory=$true)][double]$MarketFavoriteProbability,
        [Parameter(Mandatory=$true)][double]$MarketDrawProbability,
        [Parameter(Mandatory=$true)][double]$MarketOpponentProbability,
        [double]$ModelFavoriteProbability=0.0,
        [int]$CompanyCount=0,
        [double]$AgreementRatio=0.0,
        [bool]$MovementAgainstFavorite=$false,
        [double]$LineupUncertainty=0.0,
        [bool]$DataComplete=$true
    )
    $base=[Math]::Max(0.0,[Math]::Min(100.0,(1.0-$MarketFavoriteProbability)*100.0))
    $modelGap=if($ModelFavoriteProbability -gt 0){[Math]::Max(0.0,($MarketFavoriteProbability-$ModelFavoriteProbability)*100.0)}else{0.0}
    $consensusBonus=if($MovementAgainstFavorite -and $CompanyCount -ge 3 -and $AgreementRatio -ge 0.60){12.0}elseif($MovementAgainstFavorite){5.0}else{0.0}
    $lineupBonus=[Math]::Max(0.0,[Math]::Min(12.0,$LineupUncertainty*12.0))
    $overall=[Math]::Min(100.0,$base+$modelGap+$consensusBonus+$lineupBonus)
    $draw=[Math]::Min(100.0,$MarketDrawProbability*100.0+$consensusBonus*0.35+$lineupBonus*0.40)
    $opponent=[Math]::Min(100.0,$MarketOpponentProbability*100.0+$consensusBonus*0.65+$modelGap*0.50)
    $type=if($draw-ge$opponent){'FAVORITE_NONWIN_DRAW_RISK'}else{'FAVORITE_LOSS_OPPONENT_RISK'}
    $quality=if(-not$DataComplete){'INCOMPLETE_DATA'}elseif($CompanyCount-lt3-or$AgreementRatio-lt0.60){'LOW_MARKET_CONSENSUS'}else{'MULTI_SOURCE_CANDIDATE'}
    return [pscustomobject]@{Model='ColdHunter';Version='1.1.0-candidate';MarketFavorite=$MarketFavorite;HotTeamNonWinScore=[Math]::Round($overall,1);DrawRiskScore=[Math]::Round($draw,1);OpponentWinRiskScore=[Math]::Round($opponent,1);RiskType=$type;CompanyCount=$CompanyCount;AgreementRatio=$AgreementRatio;MovementAgainstFavorite=$MovementAgainstFavorite;LineupUncertainty=$LineupUncertainty;DataQuality=$quality;FormalRecommendation=$false}
}

function Get-AsianComponents {
    param([double]$Line)
    $q=[Math]::Round($Line*4)/4.0;$scaled=[int][Math]::Round($q*4)
    if(([Math]::Abs($scaled)%2)-eq1){return @(($q-0.25),($q+0.25))}
    return @($q)
}

function Convert-TitanHandicapToHomeLine {
    param([Parameter(Mandatory=$true)][string]$TitanLine)
    <# Legacy encoding-damaged parsing line retained below for traceability.
    $rawText=$TitanLine.Trim().Replace('球','').Replace(' ','')
    #>
    $rawText=($TitanLine.Trim() -replace '[^0-9./-]','')
    if([string]::IsNullOrWhiteSpace($rawText)){throw 'Titan handicap line is required'}
    $isAwayGiving=$rawText.StartsWith('-')
    $unsigned=if($isAwayGiving){$rawText.Substring(1)}else{$rawText}
    $tokens=@($unsigned.Split('/'))
    if($tokens.Count-lt1-or$tokens.Count-gt2){throw "Invalid Titan handicap line: $TitanLine"}
    $sum=0.0
    foreach($token in $tokens){
        $value=0.0
        if(-not[double]::TryParse($token,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$value)-or$value-lt0){throw "Invalid Titan handicap component: $TitanLine"}
        $sum+=$value
    }
    $rawLine=$sum/[double]$tokens.Count
    if($isAwayGiving){$rawLine=-$rawLine}
    $homeLine=-$rawLine
    $favoured=if($homeLine-lt0){'HOME'}elseif($homeLine-gt0){'AWAY'}else{'LEVEL'}
    return [pscustomobject]@{Source='TITAN007';RawText=$TitanLine;RawLine=[double]$rawLine;HomeLine=[double]$homeLine;FavouredSide=$favoured}
}

function Test-TitanHandicapDirection {
    param([Parameter(Mandatory=$true)][string]$TitanLine,[double]$HomeOdds,[double]$AwayOdds,[double]$Tolerance=0.02)
    if($HomeOdds-le1-or$AwayOdds-le1){throw '1X2 odds must be greater than one'}
    $line=Convert-TitanHandicapToHomeLine $TitanLine
    $marketFavoured=if($HomeOdds-lt($AwayOdds-$Tolerance)){'HOME'}elseif($AwayOdds-lt($HomeOdds-$Tolerance)){'AWAY'}else{'LEVEL'}
    $pass=($line.FavouredSide-eq'LEVEL'-or$marketFavoured-eq'LEVEL'-or$line.FavouredSide-eq$marketFavoured)
    $reason=if($pass){'CONSISTENT'}else{"CONTRADICTION: Titan line favours $($line.FavouredSide), 1X2 favours $marketFavoured"}
    return [pscustomobject]@{Passed=$pass;Reason=$reason;TitanLine=$line.RawText;HomeLine=$line.HomeLine;TitanFavouredSide=$line.FavouredSide;MarketFavouredSide=$marketFavoured;HomeOdds=$HomeOdds;AwayOdds=$AwayOdds}
}

function Get-AsianSettlement {
    param([int]$HomeGoals,[int]$AwayGoals,[double]$HomeLine,[ValidateSet('HOME','AWAY')][string]$Side,[double]$Odds)
    if($Odds-le1){throw 'Asian odds must be greater than one'}
    $components=@(Get-AsianComponents $HomeLine);$returns=@();$parts=@()
    foreach($line in $components){$margin=$HomeGoals-$AwayGoals+$line;if($Side-eq'AWAY'){$margin=-$margin};if($margin-gt0){$returns+=$Odds;$parts+='W'}elseif($margin-eq0){$returns+=1.0;$parts+='P'}else{$returns+=0.0;$parts+='L'}}
    $mult=($returns|Measure-Object -Average).Average;$label=if($parts.Count-eq1){if($parts[0]-eq'W'){'WIN'}elseif($parts[0]-eq'P'){'PUSH'}else{'LOSS'}}elseif($parts-contains'W'-and$parts-contains'P'){'HALF_WIN'}elseif($parts-contains'L'-and$parts-contains'P'){'HALF_LOSS'}elseif($parts-notcontains'L'){'WIN'}else{'LOSS'}
    return [pscustomobject]@{Side=$Side;HomeLine=$HomeLine;Components=($components-join'/');Outcome=$label;ReturnMultiplier=[double]$mult;NetReturn=([double]$mult-1.0)}
}

function Get-AsianExpectedReturn {
    param([double]$HomeLambda,[double]$AwayLambda,[double]$Rho=-0.12,[double]$HomeLine,[double]$HomeOdds,[double]$AwayOdds,[int]$MaxGoals=8)
    $hp=Get-PoissonVector $HomeLambda $MaxGoals;$ap=Get-PoissonVector $AwayLambda $MaxGoals;$sum=0.0;$homeReturn=0.0;$awayReturn=0.0;$components=@(Get-AsianComponents $HomeLine);$componentCount=[double]$components.Count
    for($i=0;$i-le$MaxGoals;$i++){for($j=0;$j-le$MaxGoals;$j++){$tau=1.0;if($i-eq0-and$j-eq0){$tau=1.0-($HomeLambda*$AwayLambda*$Rho)}elseif($i-eq0-and$j-eq1){$tau=1.0+($HomeLambda*$Rho)}elseif($i-eq1-and$j-eq0){$tau=1.0+($AwayLambda*$Rho)}elseif($i-eq1-and$j-eq1){$tau=1.0-$Rho};$v=[Math]::Max(0.0,$hp[$i]*$ap[$j]*$tau);$sum+=$v;$hr=0.0;$ar=0.0;foreach($line in $components){$margin=$i-$j+$line;if($margin-gt0){$hr+=$HomeOdds}elseif($margin-eq0){$hr+=1.0;$ar+=1.0}else{$ar+=$AwayOdds}};$homeReturn+=$v*($hr/$componentCount);$awayReturn+=$v*($ar/$componentCount)}}
    return [pscustomobject]@{HomeExpectedReturn=($homeReturn/$sum-1.0);AwayExpectedReturn=($awayReturn/$sum-1.0);HomeLine=$HomeLine;HomeOdds=$HomeOdds;AwayOdds=$AwayOdds}
}

Export-ModuleMember -Function Get-MeanLast,Get-DixonColesPrediction,Get-DeVigProbabilities,Get-OutcomeMetrics,Get-LeagueProfile,Get-AbstentionDecision,Get-UpsetRiskProfile,Get-AsianComponents,Get-AsianSettlement,Get-AsianExpectedReturn,Convert-TitanHandicapToHomeLine,Test-TitanHandicapDirection
