[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $Organization,

    [Parameter(Mandatory)]
    [string]
    $Project
)

if(-not(az extension show --name 'azure-devops')) {
    az extension add --name 'azure-devops'
}

$repos = az repos list --organization $Organization --project $Project | ConvertFrom-Json

foreach ($Repo in $Repos) {
    if (-not (Test-Path -Path $Repo.name -PathType Container)) {
        Write-Warning -Message "Cloning repo $Proj\$($Repo.Name)"
        git clone $Repo.webUrl
    } else {
        Write-Verbose "Folder already exists: $($Repo.name)"
    }
}