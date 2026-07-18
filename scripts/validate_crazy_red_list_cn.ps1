param(
    [Parameter(Mandatory=$true)][string]$InputPath,
    [string]$ProjectRoot=''
)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)}
if(-not(Test-Path -LiteralPath $InputPath)){throw "Input file not found: $InputPath"}
$required=@('MatchID','LeagueCode','MatchDate','HomeTeam','AwayTeam','Market','Company','Snapshot','HandicapText','HomeWater','AwayWater','SourceType','SourceHash')
$rows=@(Import-Csv -LiteralPath $InputPath -Encoding UTF8)
$issues=New-Object System.Collections.Generic.List[string]
$seen=New-Object 'System.Collections.Generic.HashSet[string]'
$chu=[string][char]0x521d; $ji=[string][char]0x5373
$rang=[string][char]0x8ba9; $qiu=[string][char]0x7403; $zhu=[string][char]0x4e3b; $ke=[string][char]0x5ba2; $shou=[string][char]0x53d7; $ping=[string][char]0x5e73; $ban=[string][char]0x534a; $yi=[string][char]0x4e00; $liang=[string][char]0x4e24
$validSnapshots=@($chu,$ji,'OPENING','CURRENT')
$validMarkets=@(($rang+$qiu),($rang+$qiu+$zhu+$ping+$ke),'HANDICAP','ASIAN')
$labelPattern="($zhu$rang|$ke$rang|$shou$rang|$ping$shou|$ping/$ban|$ban$qiu|$ban/$yi|$yi$qiu|$yi/$qiu$ban|$qiu$ban|$qiu$ban/$liang|$liang$qiu|0|0/0.5|0.5|0.5/1|1|1/1.5|1.5)"
foreach($name in $required){if($rows.Count -gt 0 -and -not($rows[0].PSObject.Properties.Name -contains $name)){$issues.Add("MISSING_COLUMN:$name")}}
foreach($r in $rows){
    $key="$($r.MatchID)|$($r.Market)|$($r.Company)|$($r.Snapshot)"
    if(-not $seen.Add($key)){$issues.Add("DUPLICATE:$key")}
    if([string]::IsNullOrWhiteSpace($r.MatchID)-or[string]::IsNullOrWhiteSpace($r.HomeTeam)-or[string]::IsNullOrWhiteSpace($r.AwayTeam)){$issues.Add("IDENTITY_MISSING:$key")}
    if($r.HomeTeam -eq $r.AwayTeam){$issues.Add("HOME_AWAY_EQUAL:$key")}
    if($validMarkets -notcontains $r.Market){$issues.Add("MARKET_UNSUPPORTED:$key")}
    if($validSnapshots -notcontains $r.Snapshot){$issues.Add("SNAPSHOT_INVALID:$key")}
    if([string]::IsNullOrWhiteSpace($r.HandicapText)){$issues.Add("HANDICAP_MISSING:$key")}
    elseif($r.HandicapText -notmatch $labelPattern){$issues.Add("HANDICAP_UNREADABLE:$key")}
    foreach($field in @('HomeWater','AwayWater')){[double]$v=0;if(-not [double]::TryParse([string]$r.$field,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$v)-or$v -le 0){$issues.Add("WATER_INVALID:${key}:${field}")}}
    if([string]::IsNullOrWhiteSpace($r.SourceHash)){$issues.Add("SOURCE_HASH_MISSING:$key")}
}
$status=if($issues.Count -eq 0){'PASS'}else{'REVIEW'}
[pscustomobject]@{Status=$status;Rows=$rows.Count;UniqueKeys=$seen.Count;IssueCount=$issues.Count;Issues=@($issues);Protocol='CRAZY_RED_LIST_CN_PARSING_V1';RuleRefs=@('Rule055','Rule056','Rule057','Rule058','Rule059','Rule060')}|ConvertTo-Json -Depth 4
