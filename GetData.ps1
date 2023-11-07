
<# 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
#>

#Configurar o PAT
$personalToken = "xxxxxxxx"

#Configurar o nome da organização
$orgName = "Contoso"

#Configurar a lista de projetos a serem analisados
$projects = @("Projeto1", "Projeto2")

$lstRepos = New-Object System.Collections.ArrayList
$lstAlerts = New-Object System.Collections.ArrayList

$headers = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($personalToken)")) }

foreach($prj in $projects)
{
    Write-Host "Project: $prj"

    # Lista os repos
    $urlRepo = "https://dev.azure.com/{0}/{1}/_apis/git/repositories?api-version=7.1-preview.1" -f $orgName, $prj
    $repos = Invoke-RestMethod -Uri $urlRepo -Headers $headers -Method Get

    foreach($repo in $repos.value)
    {
        Write-Host ""
        Write-Host "-- Repo: $($repo.name)"

        $r = New-Object System.Object
        $r | Add-Member -MemberType NoteProperty -Name "ProjectName" -Value $prj
        $r | Add-Member -MemberType NoteProperty -Name "RepoName" -Value $repo.name
        $r | Add-Member -MemberType NoteProperty -Name "RepoId" -Value $repo.id
        $lstRepos.Add($r) | Out-Null
        
        # Lista os alertas
        $url = "https://advsec.dev.azure.com/{0}/{1}/_apis/Alert/Repositories/{2}/alerts?useDatabaseProvider=true" -f $orgName, $prj, $repo.id
        $alerts = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

        foreach($alert in $alerts.value)
        {
            Write-Host "---- Alert: $($alert.title)"

            $a = New-Object System.Object
            $a | Add-Member -MemberType NoteProperty -Name "RepoId" -Value $repo.id
            $a | Add-Member -MemberType NoteProperty -Name "AlertId" -Value $alert.alertId
            $a | Add-Member -MemberType NoteProperty -Name "AlertSeverity" -Value $alert.severity
            $a | Add-Member -MemberType NoteProperty -Name "AlertTitle" -Value $alert.title
            $a | Add-Member -MemberType NoteProperty -Name "AlertType" -Value $alert.alertType
            $a | Add-Member -MemberType NoteProperty -Name "State" -Value $alert.state

            if($alert.state -eq "dismissed")
            {
                $a | Add-Member -MemberType NoteProperty -Name "DismissalType" -Value $alert.dismissal.dismissalType
            }
            else
            {
                $a | Add-Member -MemberType NoteProperty -Name "DismissalType" -Value ""
            }

            $a | Add-Member -MemberType NoteProperty -Name "FriendlyName" -Value $alert.tools[0].rules[0].friendlyName
            $lstAlerts.Add($a) | Out-Null
        }        
    }    
}

Write-Host ""
Write-Host "Exporting ..."
$lstRepos | Export-Csv -Path "C:\temp\Repos.csv" -Delimiter ";" -NoTypeInformation
$lstAlerts | Export-Csv -Path "C:\temp\Alerts.csv" -Delimiter ";" -NoTypeInformation