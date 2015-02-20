Function Get-IBRange {
    <#
    .SYNOPSIS
        Get a range from the Infoblox
    
    .DESCRIPTION
        Get a range from the Infoblox

    .PARAMETER Properties
        Extract these additional properties for the objects

    .PARAMETER IBSession
        Existing Infoblox web session generated with New-IBSession.  Defaults to $IBConfig.IBSession

    .PARAMETER Credential
        A valid PSCredential

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
        [string[]]$Properties = @("network","network_view","comment","start_addr","end_addr","lease_scavenge_time","options"),
        [string]$Uri = $Script:IBConfig.Uri,
        [string]$IBVersion = $Script:IBConfig.IBVersion,
        [Microsoft.PowerShell.Commands.WebRequestSession]$IBSession = $Script:IBConfig.IBSession,
        [System.Management.Automation.PSCredential]$Credential,
        [int]$PageSize = 1000
    )

    #Build up URI
        $Object = "range"
        $IBBaseURI = Join-Parts $Uri "/wapi/$IBVersion"
        $BaseUri = "$IBBaseURI/$object"
        $NextPageID = "NotStarted"
        
    #Build up filters
        $CGI = @()

        if($Properties)
        {
            $CGI += "_return_fields=$($Properties -join ",")"
        }

        $CGI += "_paging=1", "_max_results=$PageSize", "_return_as_object=1"
        $CGIString = $CGI -join "&"
        $uri = $BaseUri, $CGIString -join "?"

        #Build up Invoke-RestMethod parameters for splatting
        $IRMParams = @{
            Uri = $uri
            Method = 'Get'
        }

        #TODO parameterset
        if($IBSession)
        {
            $IRMParams.add('WebSession',$IBSession)
        }
        elseif($Credential)
        {
            $IRMParams.add('Credential',$Credential)
        }
        else
        {
            Throw "Please provide a valid IBSession or Credential.  Get-Help New-IBSession for more information"
        }


        Write-Verbose "Running $($MyInvocation.MyCommand).`nPSBoundParameters: $( $PSBoundParameters | Format-List | Out-String)`nInvoke-RestMethod parameters: $($IRMParams | Format-List | Out-String)"

        do
        {
            if($NextPageID -notlike "NotStarted")
            {
                $IRMParams.Uri = $BaseUri, "_page_id=$NextPageID" -join "?"
            }

            Try
            {
                $TempResult = Invoke-RestMethod @IRMParams
            }
            Catch
            {
                Throw "Error retrieving lease: $_"
            }
            $NextPageID = $TempResult.next_page_id
            
            Write-Verbose "Page $NextPageID"
            
            if($Properties)
            {
                $TempResult.result | Select -Property $(,'_ref' + $Properties)
            }
            else
            {
                $TempResult.result
            }
        }
        until (-not $TempResult.next_page_id)

}