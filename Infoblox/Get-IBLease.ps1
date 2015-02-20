Function Get-IBLease {
    <#
    .SYNOPSIS
        Get leases from the Infoblox
    
    .DESCRIPTION
        Get leases from the Infoblox

    .PARAMETER Address
        Address filter.  Uses Infoblox regular expressions (e.g. 192.168.0 would pick up anything matching that)

    .PARAMETER Client_Hostname
        Client_Hostname filter.   Uses Infoblox regular expressions (e.g. RMDY would pick up anything matching that).  Case sensitive.

    .PARAMETER last_discovered
        If specified, look for servers with discovered_data.last_discovered after this date

    .PARAMETER OS
        If specified, look for servers with discovered_data.os matching this Infoblox regular expression (e.g. Windows would match any OS 

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

    .PARAMETER PageSize
        Maximum records to retrieve in a single query.  Default is 1000.  Multiple queries performed if more results exist.

    .EXAMPLE
        #Authenticate with the Infoblox. $IBConfig.IBSession and $IBConfig.Uri will now be populated
        New-IBSession -Credential $Cred

        #Get leases with an address matching 192.168.0.
        Get-IBLease -Address 192.168.0.

        #Get free leases in the 192.168.0.0/24 subnet
        Get-IBLease -Address 192.168.0. | ?{$_.binding_state -like "FREE"}

    .FUNCTIONALITY
        Infoblox
    #>
    [cmdletbinding()]
    param(
        [string]$Address = $null,
        [string]$Client_Hostname = $null,
        [datetime]$last_discovered,
        [string]$OS = $null,
        [string[]]$Properties = @( "network","address", "binding_state", "client_hostname","hardware", "starts","ends", "discovered_data" , "protocol") ,
        [string]$Uri = $Script:IBConfig.Uri,
        [string]$IBVersion = $Script:IBConfig.IBVersion,
        [Microsoft.PowerShell.Commands.WebRequestSession]$IBSession = $Script:IBConfig.IBSession,
        [System.Management.Automation.PSCredential]$Credential,
        [int]$PageSize = 1000
    )

    #Build up URI
        $Object = "lease"
        $IBBaseURI = Join-Parts "$Uri" "wapi/$IBVersion"
        $BaseUri = "$IBBaseURI/$object"
        $NextPageID = "NotStarted"
        
    #Build up filters
        $CGI = @()
        if($os)
        {
            New-Variable -Name "discovered_data.os" -Value $os
        }
        $Filters = echo address client_hostname discovered_data.os
        foreach($filter in $filters)
        {
            if($v = Get-Variable -Name $filter -ValueOnly -ErrorAction SilentlyContinue )
            {
                $CGI += "$filter~=$v"
            }
        }
            
        #If we got a last_discovered, convert it, add to CGI
            if($last_discovered){
                $unixEpochStart = New-Object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
                [int]$last_discovered = ($last_discovered - $unixEpochStart).TotalSeconds
                $CGI += "discovered_data.last_discovered>=$last_discovered"
            }


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