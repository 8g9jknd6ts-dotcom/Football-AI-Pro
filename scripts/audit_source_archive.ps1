param(
    [string]$ArchiveRoot = (Join-Path $PSScriptRoot '..\data\source_archive'),
    [string]$OutputRoot = (Join-Path $PSScriptRoot '..\data\quality')
)
$ErrorActionPreference='Stop'
if(-not(Test-Path -LiteralPath $ArchiveRoot)){throw "Archive root not found: $ArchiveRoot"}
New-Item -ItemType Directory -Force -Path $OutputRoot|Out-Null

$files=@(Get-ChildItem -LiteralPath $ArchiveRoot -File -Recurse|Sort-Object FullName)
if($files.Count-eq0){throw 'Source archive has no files'}
$records=foreach($file in $files){
    $relative=$file.FullName.Substring((Resolve-Path -LiteralPath $ArchiveRoot).Path.Length).TrimStart('\','/')
    $extension=$file.Extension.TrimStart('.').ToLowerInvariant()
    $hash=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject]@{
        RelativePath=$relative
        Extension=$extension
        Bytes=$file.Length
        LastWriteUtc=$file.LastWriteTimeUtc.ToString('o')
        Sha256=$hash
        ArchiveStatus='RETAINED_RAW_NOT_TRAINING_BY_DEFAULT'
    }
}
$manifestPath=Join-Path $OutputRoot 'source_archive_manifest.csv'
$records|Export-Csv -LiteralPath $manifestPath -NoTypeInformation -Encoding UTF8
$extensionCounts=@{}
foreach($record in $records){if(-not$extensionCounts.ContainsKey($record.Extension)){$extensionCounts[$record.Extension]=0};$extensionCounts[$record.Extension]++}
$duplicateHashes=@($records|Group-Object Sha256|Where-Object{$_.Count-gt1})
$summary=[ordered]@{
    Status='PASS'
    ArchiveRoot=(Resolve-Path -LiteralPath $ArchiveRoot).Path
    FileCount=$records.Count
    ByteCount=($records|Measure-Object Bytes -Sum).Sum
    UniqueHashes=@($records.Sha256|Select-Object -Unique).Count
    DuplicateHashGroups=$duplicateHashes.Count
    ExtensionCounts=$extensionCounts
    ManifestPath=$manifestPath
    Policy='Raw retention inventory only; does not approve training or backtesting use.'
}
$summaryPath=Join-Path $OutputRoot 'source_archive_manifest_summary.json'
$summary|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $summaryPath -Encoding UTF8
$summary|ConvertTo-Json -Depth 5
