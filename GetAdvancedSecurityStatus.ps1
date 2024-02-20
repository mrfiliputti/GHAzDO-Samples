<# 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
#>

$PAT = "xxxx"
$Organization = "Contoso"

# Set up the URLs
$ServerUrl = "https://dev.azure.com"
$AdvancedSecurityUrl = "https://advsec.dev.azure.com"

# Empty list to store the output
$ReposAdvSec = @()

# Set up the authentication header
$AzureDevOpsAuthenicationHeader = @{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
}

#Get all repos from organization
$Repos = Invoke-RestMethod -Uri "$ServerUrl/$Organization/_apis/git/repositories?api-version=7.0" -Method Get -Headers $AzureDevOpsAuthenicationHeader

# For each repo, get the advanced security status
foreach($Repo in $Repos.value){
    $RepoId = $Repo.id
    $RepoName = $Repo.name
    $ProjectName = $Repo.project.name

    $AdvancedSecurity = Invoke-RestMethod -Uri "$AdvancedSecurityUrl/$Organization/$ProjectName/_apis/management/repositories/$RepoId/enablement?api-version=7.2-preview.1" -Method Get -Headers $AzureDevOpsAuthenicationHeader
    $AdvancedSecurityEnabled = $AdvancedSecurity.advSecEnabled
    
    $ReposAdvSec+= [PSCustomObject]@{
        ProjectName = $ProjectName
        RepoName = $RepoName
        AdvancedSecurity = $AdvancedSecurityEnabled 
    }
}

# Export the list to a CSV file in the same directory as the script
$ReposAdvSec | Export-Csv -Path ".\advancedsecuritystatus.csv" -NoTypeInformation


Exit



