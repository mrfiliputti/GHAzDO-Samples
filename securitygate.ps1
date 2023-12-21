<# 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
#>

$pass = ${env:MAPPED_ADO_PAT}
$orgUri = ${env:SYSTEM_COLLECTIONURI}
$orgName = $orgUri -replace "^https://dev.azure.com/|/$"
$project = ${env:SYSTEM_TEAMPROJECT}
$repositoryId = ${env:BUILD_REPOSITORY_ID}
$pair = ":${pass}"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$basicAuthValue = "Basic $base64"
$headers = @{ Authorization = $basicAuthValue }

$url = "https://advsec.dev.azure.com/{0}/{1}/_apis/Alert/Repositories/{2}/alerts?useDatabaseProvider=true" -f $orgName, $project, $repositoryId
Write-Host $url

$alerts = Invoke-WebRequest -Uri $url -Headers $headers -Method Get
if ($alerts.StatusCode -ne 200) {
    Write-Host "##vso[task.logissue type=error] Error getting alerts from Azure DevOps Advanced Security:", $alerts.StatusCode, $alerts.StatusDescription
    exit 1
}

$parsedAlerts = $alerts.content | ConvertFrom-Json

# Policy Threshold
$severities = @("critical") #, "high", "medium", "low"
$states = @("active")
$slaDays = 10
$alertTypes = @("code", "secret", "dependency")

[System.Collections.ArrayList]$failingAlerts = @()

$failingAlerts = foreach ($alert in $parsedAlerts.value) {
    if ($alert.severity -in $severities `
            -and $alert.state -in $states `
            -and $alert.alertType -in $alertTypes) {
        @{
            "Alert Title"  = $alert.title
            "Alert Id"     = $alert.alertId
            "Alert Type"   = $alert.alertType
            "Severity"     = $alert.severity
            "Description"  = $alert.rule.description
            "First Seen"   = $alert.firstSeenDate -as [DateTime]
            "Days overdue" = [int]((Get-Date).ToUniversalTime().AddDays(-$slaDays) - ($alert.firstSeenDate -as [DateTime])).TotalDays
            "Alert Link"   = "$($alert.repositoryUrl)/alerts/$($alert.alertId)"
        }
    }
}

if ($failingAlerts.Count -gt 0) {
    $errorText = "##vso[task.logissue type=error] Found {0} failing alerts out of SLA policy:" -f $failingAlerts.Count
    Write-Host $errorText
    foreach ($alert in $failingAlerts) {
        $alert | Format-Table -AutoSize -HideTableHeaders | Out-String | Write-Host
        Write-Host $([System.Environment]::NewLine)
    }
    exit 1
}
else {
    Write-Host "##vso[task.complete result=Succeeded;]DONE"
    exit 0
}
