<# 
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree: 
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded; 
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
#>

$PAT = "#PAT#"
$Organization = "#Organization#"
$Project = "#Project#"

# Definir a URL do Azure DevOps
$ServerUrl = "https://dev.azure.com"

# Lista vazia para armazenar os nomes dos commiters
$Commiters = @()

# Header de autenticação
$AzureDevOpsAuthenicationHeader = @{
    Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)"))
}

#Obter Repos e commiters de cada Repo
$Repos = Invoke-RestMethod -Uri "$ServerUrl/$Organization/$Project/_apis/git/repositories?api-version=7.0" -Method Get -Headers $AzureDevOpsAuthenicationHeader
foreach($Repo in $Repos.value){
    $RepoId = $Repo.id
    $Commits = Invoke-RestMethod -Uri "$ServerUrl/$Organization/$Project/_apis/git/repositories/$RepoId/commits?searchCriteria.fromDate=1/12/2024 00:00:00&searchCriteria.toDate=1/12/2024 23:59:59&api-version=7.1-preview.1" -Method Get -Headers $AzureDevOpsAuthenicationHeader
    foreach ($Commit in $Commits.value) {
        $Commiter = $Commit.committer.name
        if ($Commiter -notin $Commiters) {
            $Commiters += $Commiter
        }
    }
    
}
#Objeto commiters
$Output = $Commiters | Select-Object @{Name="Commiter";Expression={$_}}

# Exportar o objeto para arquivo CSV chamado "commiters.csv" no mesmo diretório
$Output | Export-Csv -Path ".\commiters3.csv" -NoTypeInformation

# Sair do PowerShell
Exit
