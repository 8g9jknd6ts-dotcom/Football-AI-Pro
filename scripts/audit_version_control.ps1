param([string]$ProjectRoot='')
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)}
$gitDir=Join-Path $ProjectRoot '.git'
$gitCommand=Get-Command git -ErrorAction SilentlyContinue
$headPath=Join-Path $gitDir 'HEAD'
$objectsPath=Join-Path $gitDir 'objects'
$head=''
if(Test-Path -LiteralPath $headPath){$head=(Get-Content -LiteralPath $headPath -Raw -Encoding UTF8).Trim()}
$hasObjects=(Test-Path -LiteralPath $objectsPath)
$ledgerAudit=& (Join-Path $ProjectRoot 'scripts\release_ledger.ps1') -Action AUDIT -ProjectRoot $ProjectRoot|ConvertFrom-Json
$status=if(($null-ne$gitCommand)-and$head-ne''-and$hasObjects){'GIT_COMMIT_CHAIN'}elseif($ledgerAudit.Status-eq'HASH_CHAIN_LEDGER'){'HASH_CHAIN_LEDGER'}else{'UNAVAILABLE'}
$reasons=@()
if($null-eq$gitCommand){$reasons+='GIT_EXECUTABLE_MISSING'}
if(-not(Test-Path -LiteralPath $gitDir)){$reasons+='GIT_DIRECTORY_MISSING'}elseif($head-eq''){$reasons+='GIT_HEAD_MISSING'}
if(-not$hasObjects){$reasons+='GIT_OBJECT_DATABASE_MISSING'}
[pscustomobject]@{
    Status=$status
    GitExecutableAvailable=($null-ne$gitCommand)
    GitDirectoryPresent=(Test-Path -LiteralPath $gitDir)
    HeadPresent=($head-ne'')
    ObjectDatabasePresent=$hasObjects
    Reasons=($reasons -join ';')
    LedgerStatus=$ledgerAudit.Status
    Policy='Git is preferred. A verified hash-chain release ledger is an auditable fallback when Git is unavailable.'
}|ConvertTo-Json
