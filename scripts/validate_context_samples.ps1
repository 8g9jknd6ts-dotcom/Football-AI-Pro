param([string]$ProjectRoot='')
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)}
$path=Join-Path $ProjectRoot 'data\standardized\wc2026_pre_semifinal_team_samples.csv'
if(-not(Test-Path -LiteralPath $path)){throw 'World Cup context sample file missing'}
$rows=@(Import-Csv -LiteralPath $path -Encoding UTF8)
if($rows.Count-ne12){throw "Unexpected context sample count: $($rows.Count)"}
$required=@('MatchID','MatchDate','Team','Opponent','Stage','ScoreFor','ScoreAgainst','ExtraTime','Result','SourceUrl','DataStatus')
foreach($column in $required){if($column-notin$rows[0].PSObject.Properties.Name){throw "Context sample missing column: $column"}}
$ids=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($row in $rows){
 if(-not$ids.Add($row.MatchID)){throw "Duplicate context MatchID: $($row.MatchID)"}
 if($row.MatchID-notmatch'^FAI-[a-f0-9]{24}$'){throw "Invalid context MatchID: $($row.MatchID)"}
 $date=[datetime]::MinValue;if(-not[datetime]::TryParseExact($row.MatchDate,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$date)){throw "Invalid context MatchDate: $($row.MatchDate)"}
 $gf=0;$ga=0;if(-not[int]::TryParse($row.ScoreFor,[ref]$gf)-or-not[int]::TryParse($row.ScoreAgainst,[ref]$ga)-or$gf-lt0-or$ga-lt0){throw "Invalid context score: $($row.MatchID)"}
 $expected=if($gf-gt$ga){'W'}elseif($gf-eq$ga){'D'}else{'L'};if($row.Result-ne$expected){throw "Context result mismatch: $($row.MatchID)"}
 if($row.ExtraTime-notin@('true','false')){throw "Invalid ExtraTime value: $($row.MatchID)"}
 if($row.DataStatus-ne'CONTEXT_ONLY_NOT_TRAINING'){throw "Context isolation flag missing: $($row.MatchID)"}
 if($row.SourceUrl-notmatch'^https://'){throw "Invalid context source URL: $($row.MatchID)"}
}
$teams=$rows|Group-Object Team|ForEach-Object{[pscustomobject]@{Team=$_.Name;Matches=$_.Count;GoalsFor=(($_.Group|Measure-Object ScoreFor -Sum).Sum);GoalsAgainst=(($_.Group|Measure-Object ScoreAgainst -Sum).Sum)}}
[pscustomobject]@{Status='PASS';Rows=$rows.Count;UniqueMatchIDs=$ids.Count;DataStatus='CONTEXT_ONLY_NOT_TRAINING';Teams=$teams}|ConvertTo-Json -Depth 4
