param(
    [string]$ArchiveRoot = (Join-Path $PSScriptRoot '..\data\source_archive\2026-07-15'),
    [string]$OutputRoot = (Join-Path $PSScriptRoot '..\data\quality')
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutputRoot | Out-Null

function Csv([string]$s) { '"' + ($s -replace '"','""') + '"' }
function ValidDateSuffix([string]$id) {
    if($id -notmatch '(\d{8})$'){return $false}; $d=[datetime]::MinValue
    [datetime]::TryParseExact($Matches[1],'yyyyMMdd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d)
}
function Write-AuditRow($writer,[string]$dataset,[string]$id,[string[]]$reasons) {
    $status=if($reasons.Count){'QUARANTINED'}else{'REVIEWABLE'}; $why=if($reasons.Count){$reasons -join '|'}else{'NONE'}
    $writer.WriteLine("$(Csv $dataset),$(Csv $id),$(Csv $status),$(Csv $why)")
}

$coreRows=0; $coreReviewable=0; $coreQuarantined=0
$coreOut=Join-Path $OutputRoot 'match_history_core_audit.csv'
$w=[IO.StreamWriter]::new($coreOut,$false,[Text.UTF8Encoding]::new($true))
try {
    $w.WriteLine('"Dataset","SourceMatchID","Status","Reasons"')
    Import-Csv (Join-Path $ArchiveRoot 'match_history_core.csv') | ForEach-Object {
        $r=@(); if(-not (ValidDateSuffix $_.match_id)){$r+='MISSING_VALID_MATCH_DATE'}
        if([string]::IsNullOrWhiteSpace($_.home_team_id)-or[string]::IsNullOrWhiteSpace($_.away_team_id)){$r+='MISSING_TEAM'}
        if($_.home_team_id-eq$_.away_team_id){$r+='SAME_HOME_AWAY'}; if([string]::IsNullOrWhiteSpace($_.league_id)){$r+='MISSING_LEAGUE'}
        $hg=0;$ag=0;$oh=0.0;$od=0.0;$oa=0.0
        if(-not[int]::TryParse($_.home_goals,[ref]$hg)-or$hg-lt0-or$hg-gt30){$r+='INVALID_HOME_GOALS'}
        if(-not[int]::TryParse($_.away_goals,[ref]$ag)-or$ag-lt0-or$ag-gt30){$r+='INVALID_AWAY_GOALS'}
        if(-not[double]::TryParse($_.b365_home,[ref]$oh)-or$oh-le1){$r+='INVALID_HOME_ODDS'}
        if(-not[double]::TryParse($_.b365_draw,[ref]$od)-or$od-le1){$r+='INVALID_DRAW_ODDS'}
        if(-not[double]::TryParse($_.b365_away,[ref]$oa)-or$oa-le1){$r+='INVALID_AWAY_ODDS'}
        Write-AuditRow $w 'match_history_core' $_.match_id $r; $coreRows++; if($r.Count){$coreQuarantined++}else{$coreReviewable++}
    }
} finally {$w.Dispose()}

$intRows=0; $intReviewable=0; $intQuarantined=0
$intOut=Join-Path $OutputRoot 'international_matches_audit.csv'
$w=[IO.StreamWriter]::new($intOut,$false,[Text.UTF8Encoding]::new($true))
try {
    $w.WriteLine('"Dataset","SourceMatchID","Status","Reasons"')
    Import-Csv (Join-Path $ArchiveRoot 'international_matches.csv') | ForEach-Object {
        $r=@(); $d=[datetime]::MinValue
        if(-not[datetime]::TryParseExact($_.date,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$d)){$r+='INVALID_DATE'}
        if([string]::IsNullOrWhiteSpace($_.home_team)-or[string]::IsNullOrWhiteSpace($_.away_team)){$r+='MISSING_TEAM'}; if($_.home_team-eq$_.away_team){$r+='SAME_HOME_AWAY'}
        $hg=0;$ag=0;$hs=0;$as=0;$hx=0.0;$ax=0.0;$hp=0.0;$ap=0.0
        $score=[int]::TryParse($_.home_goals,[ref]$hg)-and[int]::TryParse($_.away_goals,[ref]$ag)-and$hg-ge0-and$ag-ge0
        if(-not$score){$r+='INVALID_SCORE'}else{$expected=if($hg-gt$ag){'H'}elseif($hg-eq$ag){'D'}else{'A'};if($_.result-ne$expected){$r+='RESULT_SCORE_MISMATCH'}}
        if(-not[int]::TryParse($_.home_shots,[ref]$hs)-or-not[int]::TryParse($_.away_shots,[ref]$as)-or$hs-lt0-or$as-lt0-or$hs-gt60-or$as-gt60){$r+='IMPLAUSIBLE_SHOTS'}
        if(-not[double]::TryParse($_.home_xg,[ref]$hx)-or-not[double]::TryParse($_.away_xg,[ref]$ax)-or$hx-lt0-or$ax-lt0-or$hx-gt10-or$ax-gt10){$r+='IMPLAUSIBLE_XG'}
        if(-not[double]::TryParse($_.home_possession,[ref]$hp)-or-not[double]::TryParse($_.away_possession,[ref]$ap)-or$hp-lt0-or$ap-lt0-or$hp-gt100-or$ap-gt100-or[math]::Abs($hp+$ap-100)-gt1){$r+='INVALID_POSSESSION'}
        if($_.source-notin @('official_fifa','official_uefa','official_federation')){$r+='UNVERIFIABLE_SOURCE'}
        Write-AuditRow $w 'international_matches' $_.match_id $r; $intRows++; if($r.Count){$intQuarantined++}else{$intReviewable++}
    }
} finally {$w.Dispose()}

$parts=@(Get-ChildItem $ArchiveRoot -Filter 'match_history_core_part*.csv'); $partRows=0
foreach($p in $parts){$partRows += (@([IO.File]::ReadLines($p.FullName)).Count - 1)}
$summary=@(
 [pscustomobject]@{Dataset='match_history_core';Rows=$coreRows;Reviewable=$coreReviewable;Quarantined=$coreQuarantined;Note="$($parts.Count) partition files / $partRows distribution-copy rows"},
 [pscustomobject]@{Dataset='international_matches';Rows=$intRows;Reviewable=$intReviewable;Quarantined=$intQuarantined;Note='Authoritative row-level sources required before formal import'}
)
$summary|Export-Csv (Join-Path $OutputRoot 'low_trust_history_summary.csv') -NoTypeInformation -Encoding UTF8
$summary|Format-Table -AutoSize
