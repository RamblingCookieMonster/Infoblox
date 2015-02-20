Function New-IBSession {
    <#
    .SYNOPSIS
        Generate Infoblox platform API connection information
    
    .DESCRIPTION
        Generate Infoblox platform API connection information
    
            Updates $IBConfig.IBSession - Infoblox Web Session
            Updates $IBConfig.Uri       - Infoblox grid FQDN
            Updates $IBConfig.IBVersion - Infoblox WAPI version 

    .PARAMETER Credential
        A valid PSCredential

    .PARAMETER Passthru
        If specified, we return the web session

    .PARAMETER NoConfigChange
        If specified, do not update the $IBConfig module variable or Infoblox.xml file

    .PARAMETER Uri
        The base Uri for the Infoblox.  Defaults to $IBConfig.Uri
        Example: "https://grid.contoso.com"

    .PARAMETER IBVersion
        The WAPI version.  Defaults to $IBConfig.IBVersion
        Example: "v1.6" or "v1.2"

    .EXAMPLE
        #Authenticate with the Infoblox. $IBConfig.IBSession and $IBConfig.Uri will now be populated
        New-IBSession -Credential $Cred

        #Get open session
        Get-IBRange

    .FUNCTIONALITY
        Infoblox
    #>   
    [cmdletbinding()]
    param(    
        [string]$Uri = $Script:IBConfig.Uri,
        [string]$IBVersion = $Script:IBConfig.IBVersion,
        [System.Management.Automation.PSCredential]$Credential,
        [switch]$Passthru,
        [switch]$NoConfigChange
    )

    #Build up URI
    $BaseUri = Join-Parts $Uri "wapi/$IBVersion/grid"
    
    #Build up Invoke-RestMethod parameters for splatting
        $IRMParams = @{
            Uri = $BaseUri
            Method = 'Get'
            Credential = $Credential
            SessionVariable = 'TempSession'
            ErrorAction = 'Stop'
        }
   

    Write-Verbose "Running $($MyInvocation.MyCommand).`nPSBoundParameters: $( $PSBoundParameters | Format-List | Out-String)`nInvoke-RestMethod parameters: $($IRMParams | Format-List | Out-String)"

    Try
    {
        #Run the command
        $Grid = Invoke-RestMethod @IRMParams
        $GridName = ( $Grid._ref -split ":" )[-1]
        Write-Verbose "Connected to grid '$GridName'"
    }
    Catch
    {
        Throw "Error retrieving session: $_"
    }

    if($Passthru)
    {
        $TempSession
    }
    
    if(-not $NoConfigChange)
    {
        Set-IBConfig -Uri $Uri -IBVersion $IBVersion
        
        $Script:IBConfig.IBSession = $TempSession
        $Script:IBConfig.Uri = $Uri
        $Script:IBConfig.IBVersion = $IBVersion
    }

}