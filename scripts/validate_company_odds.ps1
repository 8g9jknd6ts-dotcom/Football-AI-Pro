[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'
$rows = @(Import-Csv -LiteralPath $Path -Encoding UTF8)
$required = @('MatchID','Market','Company','SnapshotTime','InitialLine','CurrentLine','InitialHomePrice','InitialAwayPrice','CurrentHomePrice','CurrentAwayPrice')
$headers = @($rows[0].PSObject.Properties.Name)
$missingHeaders = @($required | Where-Object { $_ -notin $headers })
if ($missingHeaders.Count -gt 0) { throw "Missing required columns: $($missingHeaders -join ', ')" }

$issues = @()
foreach ($r in $rows) {
    foreach ($f in $required) {
        if ([string]::IsNullOrWhiteSpace([string]$r.$f)) {
            $issues += [pscustomobject]@{Type='MISSING_FIELD';MatchID=$r.MatchID;Company=$r.Company;Field=$f}
        }
    }
    foreach ($f in @('InitialHomePrice','InitialAwayPrice','CurrentHomePrice','CurrentAwayPrice')) {
        $v = 0.0
        if (-not [double]::TryParse([string]$r.$f,[Globalization.NumberStyles]::Float,[Globalization.CultureInfo]::InvariantCulture,[ref]$v) -or $v -le 1.0) {
            $issues += [pscustomobject]@{Type='INVALID_PRICE';MatchID=$r.MatchID;Company=$r.Company;Field=$f}
        }
    }
}

$duplicateGroups = @($rows | Group-Object MatchID,Market,Company | Where-Object Count -gt 1)
foreach ($g in $duplicateGroups) {
    $issues += [pscustomobject]@{Type='DUPLICATE_COMPANY_ROW';MatchID=($g.Group[0].MatchID);Company=($g.Group[0].Company);Field=($g.Group[0].Market)}
}

[pscustomobject]@{
    Path=$Path
    Rows=$rows.Count
    UniqueCompanies=@($rows | Select-Object -ExpandProperty Company -Unique).Count
    UniqueMatches=@($rows | Select-Object -ExpandProperty MatchID -Unique).Count
    DuplicateGroups=$duplicateGroups.Count
    Issues=$issues.Count
    Status=$(if ($issues.Count -eq 0) {'PASS'} else {'REVIEW'})
    IssueDetails=$issues
} | ConvertTo-Json -Depth 5
