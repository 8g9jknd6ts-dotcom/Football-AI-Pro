param(
    [Parameter(Mandatory=$true)][string]$EvidencePath,
    [Parameter(Mandatory=$true)][string]$CapturedAt,
    [ValidateSet('SCREENSHOT','OFFICIAL_EXPORT','OFFICIAL_API_RESPONSE')][string]$EvidenceType='SCREENSHOT',
    [string]$SourceUrl='https://m.sporttery.cn/mjc/jsq/zqspf/',
    [string]$Notes='',
    [string]$ProjectRoot='',
    [switch]$ValidateOnly
)

$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)}
if(-not(Test-Path -LiteralPath $EvidencePath)){throw "Evidence not found: $EvidencePath"}
$captured=[datetimeoffset]::MinValue
if(-not[datetimeoffset]::TryParse($CapturedAt,[Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$captured)){throw 'CapturedAt must be ISO-8601 with timezone'}
$hash=(Get-FileHash -LiteralPath $EvidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
$extension=[IO.Path]::GetExtension($EvidencePath).ToLowerInvariant()
if($EvidenceType-eq'SCREENSHOT'-and$extension-notin@('.png','.jpg','.jpeg','.webp')){throw 'SCREENSHOT evidence must be PNG, JPG, JPEG, or WEBP'}
if($EvidenceType-eq'OFFICIAL_EXPORT'-and$extension-notin@('.csv','.json','.xlsx','.xls','.pdf')){throw 'OFFICIAL_EXPORT file type is not allowed'}
if($EvidenceType-eq'OFFICIAL_API_RESPONSE'-and$extension-notin@('.json','.txt')){throw 'OFFICIAL_API_RESPONSE must be JSON or TXT'}
$evidenceId='JCZQ-EV-'+$hash.Substring(0,20).ToUpperInvariant()
$manifestDir=Join-Path $ProjectRoot 'data\raw\jczq';$manifestPath=Join-Path $manifestDir 'evidence_manifest.csv'
$storedRelativePath=('data/raw/jczq/{0}{1}' -f $evidenceId,$extension);$storedPath=Join-Path $ProjectRoot ($storedRelativePath -replace '/','\')
$existing=if(Test-Path $manifestPath){@(Import-Csv $manifestPath -Encoding UTF8)}else{@()}
$duplicate=@($existing|Where-Object{$_.EvidenceID-eq$evidenceId -or $_.Sha256-eq$hash})
$row=[pscustomobject]@{EvidenceID=$evidenceId;EvidenceType=$EvidenceType;CapturedAt=$captured.ToString('o');SourceUrl=$SourceUrl;OriginalFileName=[IO.Path]::GetFileName($EvidencePath);StoredRelativePath=$storedRelativePath;Sha256=$hash;Notes=$Notes;RegisteredAt=(Get-Date).ToUniversalTime().ToString('o')}
if(-not$ValidateOnly-and$duplicate.Count-eq0){New-Item -ItemType Directory -Force -Path $manifestDir|Out-Null;Copy-Item -LiteralPath $EvidencePath -Destination $storedPath -ErrorAction Stop; $storedHash=(Get-FileHash -LiteralPath $storedPath -Algorithm SHA256).Hash.ToLowerInvariant();if($storedHash-ne$hash){Remove-Item -LiteralPath $storedPath -Force;throw 'Stored evidence hash mismatch'};@($existing)+@($row)|Export-Csv $manifestPath -NoTypeInformation -Encoding UTF8}
if($duplicate.Count-gt0){$registered=$duplicate[0];if([string]::IsNullOrWhiteSpace($registered.StoredRelativePath)){throw 'Existing evidence lacks a stored artifact; register a new auditable snapshot'};$registeredPath=Join-Path $ProjectRoot ($registered.StoredRelativePath -replace '/','\');if(-not(Test-Path -LiteralPath $registeredPath)){throw 'Registered evidence artifact is missing'};if((Get-FileHash -LiteralPath $registeredPath -Algorithm SHA256).Hash.ToLowerInvariant()-ne$hash){throw 'Registered evidence artifact hash mismatch'}}
[pscustomobject]@{Status=if($duplicate.Count){'ALREADY_REGISTERED'}else{'VALID'};EvidenceID=$evidenceId;Sha256=$hash;StoredRelativePath=$storedRelativePath;Written=(-not$ValidateOnly-and$duplicate.Count-eq0);ManifestPath=$manifestPath}|ConvertTo-Json
