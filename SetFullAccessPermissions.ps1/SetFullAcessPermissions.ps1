[CmdletBinding()]
param (
    # Organization Name for establishing Exchange Online Connection
    [Parameter()]
    [string]
    $orgName = $(Get-AutomationVariable 'orgName'),

    # Account to assign full mailbox access permissions to.
    [Parameter()]
    [string]
    $serviceAccount = $(Get-AutomationVariable 'ServiceAccountName'),

    # resultSize for querying mailboxes, can be either the string "unlimited" or an integer
    [Parameter()]
    $resultSize = $(Get-AutomationVariable 'exchangeOnlineResultSize')
)
#Requires -Modules @{ ModuleName="ExchangeOnlineManagement"; ModuleVersion="2.0.3" }

Write-Verbose "orgName: $orgName"
Write-Verbose "serviceAccount: $serviceAccount"
Write-Verbose "resultSize: $resultSize"

$stopWatch = [system.diagnostics.stopwatch]::startNew()

Write-Verbose "Importing pwsh module"
Import-Module ExchangeOnlineManagement 

Write-Verbose "Connecting to Exchange Online"
$runAsConnection = Get-AutomationConnection -Name 'AzureRunAsConnection'
$ConnectParams = @{
    Organization = $orgName
    AppId = $runAsConnection.ApplicationId
    CertificateThumbprint = $runAsConnection.CertificateThumbprint
    ShowBanner = $false
}
Connect-ExchangeOnline @ConnectParams
Write-Verbose "Minutes elapsed: $($stopWatch.Elapsed.TotalMinutes)"

try {
    $processedMailboxes = 0
    Write-Verbose "Getting mailboxes"
    Get-EXOMailbox -ResultSize $resultSize -Filter {(RecipientTypeDetails -eq 'UserMailbox')} | ForEach-Object {
        Write-Verbose "Minutes elapsed: $($stopWatch.Elapsed.TotalMinutes)"

        Write-Verbose "Setting Mailbox permission for: $($_.SAMAccountName)"
        Add-MailboxPermission -Identity $_.SAMAccountName -User $serviceAccount -AccessRights FullAccess -InheritanceType all -WarningAction SilentlyContinue

        $processedMailboxes++
        Write-Verbose "Processed mailboxes: $processedMailboxes"
    }
}
catch {
    Write-Host "An unhandled exception occured:"
    Write-Host $_.Exception.Message
    Write-Host "Stack Trace:"
    Write-Host $_.Exception.StackTrace
}
finally {
    Write-Verbose "Finished execution"
    Disconnect-ExchangeOnline -Confirm:$false
    Write-Verbose "Minutes elapsed: $($stopWatch.Elapsed.TotalMinutes)"
}
