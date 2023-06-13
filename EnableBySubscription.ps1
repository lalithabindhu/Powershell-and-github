Param
(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [Guid[]]$SubscriptionList
);

#Array of objects for storing failure subscriptionIds and failure reasons.
$FailedRegistrations = @();

# Register subscriptionIds to Automatic Registraion.
# https://docs.microsoft.com/th-th/powershell/azure/install-az-ps?view=azps-3.8.0#install-the-azure-powershell-module.
# Check if AzureRm is already installed and use that module if it is already available.
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Host "AzureRM is already installed. Registering using AzureRm commands";

    Write-Host "Please login to your account which have access to the listed subscriptions";
    $Output = Connect-AzureRmAccount -ErrorAction Stop;
    
    If (!$SubscriptionList) {
        [Guid[]]$SubscriptionList = $null
        Get-AzureRmSubscription | ForEach-Object -Process {$SubscriptionList += $_.Id}
    }

    foreach ($SubscriptionId in $SubscriptionList) {
        Write-host "`n`n--------------------$SubscriptionId----------------------------`n`n";

        try {
            Write-Host "Setting powershell context to subscriptionid: $SubscriptionId";
            $Output = Set-AzureRmContext  -SubscriptionId $SubscriptionId -ErrorAction Stop;

            Write-Host "Registering subscription($SubscriptionId) to Microsoft.SqlVirtualMachine Resource provider";
            $Output = Register-AzureRmResourceProvider -ProviderNamespace Microsoft.SqlVirtualMachine -ErrorAction Stop;

            Write-Host "Registering subscription($SubscriptionId) to AFEC";
            $Output = Register-AzureRmProviderFeature -FeatureName BulkRegistration -ProviderNamespace Microsoft.SqlVirtualMachine -ErrorAction Stop;
        }
        Catch {
            $message = $_.Exception.Message;
            Write-Error "We failed due to complete $SubscriptionId operation because of the following reason: $message";

            # Store failed subscriptionId and failure reason.
            $FailedRegistration = @{ };
            $FailedRegistration.Add("SubscriptionId", $SubscriptionId);
            $FailedRegistration.Add("Errormessage", $message);
            $FailedRegistrations += New-Object -TypeName psobject -Property $FailedSubscriptionId;
        }
    };
    
} 
else {
    # Since AzureRm module is not availavle, we will use Az module.
    Write-Host "Installing Az powershell module if not installed already."
  # Install-Module -Name Az -AllowClobber -Scope CurrentUser;
  # Install-Module -Name Az -AllowClobber -Verbose -AcceptLicense -Force -Repository PSGallery;
    Install-Module -Name Az -AllowClobber -Scope CurrentUser -Repository PSGallery -Force;
  # Set-PSRepository -Name PSGallery -SourceLocation https://www.powershellgallery.com/api/v2/ -InstallationPolicy Trusted;

    Write-Host "Please login to your account which have access to the listed subscriptions";
    $Output = Connect-AzAccount -ErrorAction Stop;
    
    If (!$SubscriptionList) {
        [Guid[]]$SubscriptionList = $null
        Get-AzSubscription | ForEach-Object -Process {$SubscriptionList += $_.Id}
    }

    foreach ($SubscriptionId in $SubscriptionList) {
        Write-host "`n`n--------------------$SubscriptionId----------------------------`n`n"

        try {
            Write-Host "Setting powershell context to subscriptionid: $SubscriptionId";
            $Output = Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop;

            Write-Host "Registering subscription($SubscriptionId) to Microsoft.SqlVirtualMachine Resource provider";
            $Output = Register-AzResourceProvider -ProviderNamespace Microsoft.SqlVirtualMachine -ErrorAction Stop;

            Write-Host "Registering subscription($SubscriptionId) to AFEC";
            $Output = Register-AzProviderFeature -FeatureName BulkRegistration -ProviderNamespace Microsoft.SqlVirtualMachine -ErrorAction Stop;
        }
        Catch {
            $message = $_.Exception.Message;
            Write-Error "We failed due to complete $SubscriptionId operation because of the following reason: $message";

            # Store failed subscriptionId and failure reason.
            $FailedRegistration = @{ };
            $FailedRegistration.Add("SubscriptionId", $SubscriptionId);
            $FailedRegistration.Add("Errormessage", $message);
            $FailedRegistrations += New-Object -TypeName psobject -Property $FailedSubscriptionId;
        }
    };
}

# Failed subscription registration and its reason will be stored in a csv file(RegistrationErrors.csv) for easy analysis.
# The file should be available in current directory where this .ps1 is executed
$FailedRegistrations | Export-Csv -Path RegistrationErrors.csv -NoTypeInformation
