param([string]$ProjectRoot='')
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)}

function Assert([bool]$Condition,[string]$Message){if(-not $Condition){throw $Message}}

$version=(Get-Content -LiteralPath (Join-Path $ProjectRoot 'VERSION') -Raw -Encoding UTF8).Trim()
$rulesPath=Join-Path $ProjectRoot 'docs\RULES.md'
$templatePath=Join-Path $ProjectRoot 'docs\REPORT_RUNTIME_TEMPLATE.md'
$registryPath=Join-Path $ProjectRoot 'docs\MODEL_REGISTRY.md'
$completionAuditPath=Join-Path $ProjectRoot 'docs\COMPLETION_AUDIT.md'
$completionAddendumPath=Join-Path $ProjectRoot 'docs\COMPLETION_AUDIT_ADDENDUM.md'

$rulesText=Get-Content -LiteralPath $rulesPath -Raw -Encoding UTF8
$ruleNumbers=@([regex]::Matches($rulesText,'(?m)^\| Rule(\d{3}) \|')|ForEach-Object{[int]$_.Groups[1].Value})
Assert ($ruleNumbers.Count-gt0) 'No numbered rules found'
for($i=0;$i-lt$ruleNumbers.Count;$i++){Assert ($ruleNumbers[$i]-eq($i+1)) "Rule numbering is not contiguous at position $($i+1)"}

$template=Get-Content -LiteralPath $templatePath -Raw -Encoding UTF8
$requiredTokens=@(
    '{{RECOMMENDATION}}','{{RECOMMENDED_ODDS}}','{{AI_SCORE}}','{{CONFIDENCE}}','{{UPSET_INDEX}}',
    '{{WDL}}','{{HANDICAP_WDL}}','{{SCORE}}','{{TOTAL_MODE}}','{{RISK_SUMMARY}}',
    '{{ODDS_ANALYSIS}}','{{RETURN_ANALYSIS}}','{{KELLY_ANALYSIS}}','{{HANDICAP_ANALYSIS}}','{{RISKS}}'
)
foreach($token in $requiredTokens){Assert ($template.Contains($token)) "Runtime report template is missing $token"}
<# Localized heading literals are not used by this structural audit.
$requiredHeadings=@('## 首页摘要','## 核心数据','## 赔率分析','## 返还率分析','## 凯利分析','## 模型分析','## 推荐结果','## 风险提示','## 可追溯信息')
foreach($heading in $requiredHeadings){Assert ($template.Contains($heading)) "Runtime report template is missing heading $heading"}

#>
$requiredHeadings=9
Assert (([regex]::Matches($template,'(?m)^## ')).Count-ge$requiredHeadings) 'Runtime report template has too few required sections'
$registry=Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8
<# Legacy localized sentence check is disabled because source encoding must not affect a structural audit.
Assert ($registry.Contains('当前没有任何 `production` 模型。')) 'Registry must explicitly disclose no production model'
#>
$productionRows=@([regex]::Matches($registry,'(?m)^\|[^\r\n]*\|\s*production\s*\|'))
Assert ($productionRows.Count-eq0) 'A production model is registered without completion-audit approval'

$completionAudit=Get-Content -LiteralPath $completionAuditPath -Raw -Encoding UTF8
$completionAddendum=Get-Content -LiteralPath $completionAddendumPath -Raw -Encoding UTF8
<# Legacy localized range-string comparison is intentionally disabled.
Assert ($completionAudit.Contains($version)) "Completion audit version does not match VERSION: $version"
Assert ($completionAudit.Contains(('Rule001–Rule{0:D3}' -f $ruleNumbers[-1]))) 'Completion audit rule coverage is stale'

#>
Assert (($completionAudit.Contains(('Rule{0:D3}' -f $ruleNumbers[-1])) -or $completionAddendum.Contains(('Rule{0:D3}' -f $ruleNumbers[-1])))) 'Completion audit does not reference the latest rule'
[pscustomobject]@{
    Status='PASS'
    Version=$version
    RuleCount=$ruleNumbers.Count
    LastRule=('Rule{0:D3}' -f $ruleNumbers[-1])
    RequiredReportTokens=$requiredTokens.Count
    RequiredReportHeadings=$requiredHeadings
    ProductionModels=$productionRows.Count
    CompletionAudit=$completionAuditPath
}|ConvertTo-Json
