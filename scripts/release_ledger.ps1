param(
    [ValidateSet('REGISTER','AUDIT')][string]$Action='AUDIT',
    [string]$ProjectRoot=''
)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)}
function Get-Sha256([string]$Text){$sha=[Security.Cryptography.SHA256]::Create();try{return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}}
function Get-TreeState([string]$Root){
    $relativeRoots=@('src','scripts','docs','tests','VERSION','CHANGELOG.md','data\standardized\manifest.json','data\quality\source_archive_manifest_summary.json')
    $files=@()
    foreach($relativeRoot in $relativeRoots){
        $full=Join-Path $Root $relativeRoot
        if(Test-Path -LiteralPath $full -PathType Leaf){$files+=Get-Item -LiteralPath $full}
        elseif(Test-Path -LiteralPath $full -PathType Container){$files+=Get-ChildItem -LiteralPath $full -File -Recurse}
    }
    $lines=@($files|Sort-Object FullName|ForEach-Object{$relative=$_.FullName.Substring((Resolve-Path -LiteralPath $Root).Path.Length).TrimStart('\','/').Replace('\','/');$hash=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant();"$relative|$hash"})
    return [pscustomobject]@{FileCount=$lines.Count;TreeHash=(Get-Sha256 ($lines-join"`n"));Lines=$lines}
}
$ledgerDir=Join-Path $ProjectRoot 'data\version_control';$ledgerPath=Join-Path $ledgerDir 'release_ledger.jsonl'
function Get-Entries(){if(-not(Test-Path -LiteralPath $ledgerPath)){return @()};return @(Get-Content -LiteralPath $ledgerPath -Encoding UTF8|Where-Object{$_-ne''}|ForEach-Object{$_|ConvertFrom-Json})}
$tree=Get-TreeState $ProjectRoot
if($Action-eq'REGISTER'){
    New-Item -ItemType Directory -Path $ledgerDir -Force|Out-Null
    $version=(Get-Content -LiteralPath (Join-Path $ProjectRoot 'VERSION') -Raw -Encoding UTF8).Trim();$entries=@(Get-Entries)
    if(@($entries|Where-Object{$_.Version-eq$version}).Count){throw "Version already registered: $version"}
    $parent=if($entries.Count){$entries[-1].EntryHash}else{'GENESIS'}
    $core=[ordered]@{Version=$version;CreatedAt=(Get-Date).ToUniversalTime().ToString('o');ParentEntryHash=$parent;TreeHash=$tree.TreeHash;FileCount=$tree.FileCount;Policy='HASH_CHAIN_RELEASE_LEDGER'}
    $canonical=$core|ConvertTo-Json -Compress;$entry=[ordered]@{};foreach($key in $core.Keys){$entry[$key]=$core[$key]};$entry['EntryHash']=Get-Sha256 $canonical
    ($entry|ConvertTo-Json -Compress)|Add-Content -LiteralPath $ledgerPath -Encoding UTF8
    [pscustomobject]@{Status='REGISTERED';Version=$version;EntryHash=$entry.EntryHash;TreeHash=$tree.TreeHash;FileCount=$tree.FileCount;LedgerPath=$ledgerPath}|ConvertTo-Json
    exit
}
$entries=@(Get-Entries);if($entries.Count-eq0){[pscustomobject]@{Status='UNAVAILABLE';Reason='LEDGER_MISSING'}|ConvertTo-Json;exit}
$parent='GENESIS';$valid=$true
foreach($entry in $entries){$core=[ordered]@{Version=$entry.Version;CreatedAt=$entry.CreatedAt;ParentEntryHash=$entry.ParentEntryHash;TreeHash=$entry.TreeHash;FileCount=$entry.FileCount;Policy=$entry.Policy};if($entry.ParentEntryHash-ne$parent-or$entry.EntryHash-ne(Get-Sha256 ($core|ConvertTo-Json -Compress))){$valid=$false;break};$parent=$entry.EntryHash}
$version=(Get-Content -LiteralPath (Join-Path $ProjectRoot 'VERSION') -Raw -Encoding UTF8).Trim();$last=$entries[-1]
$status=if($valid-and$last.Version-eq$version-and$last.TreeHash-eq$tree.TreeHash){'HASH_CHAIN_LEDGER'}else{'STALE_OR_INVALID'}
[pscustomobject]@{Status=$status;Version=$version;Entries=$entries.Count;LastEntryHash=$last.EntryHash;TreeHash=$tree.TreeHash;FileCount=$tree.FileCount;LedgerPath=$ledgerPath}|ConvertTo-Json
