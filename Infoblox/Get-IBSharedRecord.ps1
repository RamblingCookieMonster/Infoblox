Function Get-IBSharedRecord {
    <#
    .SYNOPSIS
        Get a shared record from the Infoblox
    
    .DESCRIPTION
        Get a shared record from the Infoblox

    ,PARAMETER RecordType
        Type of shared record to retrieve (e.g. A, AAAA, SRV)

    .PARAMETER IBSession
        Existing Infoblox web session generated with New-IBSession.  Defaults to $IBConfig.IBSession

    .PARAMETER Credential
        A valid PSCredential.

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

        #Get open session
        Get-IBSharedRecord -RecordType a

    .FUNCTIONALITY
        Infoblox
    #>
    [cmdletbinding()]
    param(    
        [ValidateSet("A","AAAA","MX","SRV","TXT")]
        [string]$RecordType = "A",
        [string]$Uri = $Script:IBConfig.Uri,
        [string]$IBVersion = $Script:IBConfig.IBVersion,
        [Microsoft.PowerShell.Commands.WebRequestSession]$IBSession = $Script:IBConfig.IBSession,
        [System.Management.Automation.PSCredential]$Credential,
        [int]$PageSize = 1000
    )

    #Build up URI
        $IBBaseURI = Join-Parts $Uri "/wapi/$IBVersion"
        $BaseUri = "$IBBaseURI/sharedrecord:$($RecordType.ToLower())"
        $NextPageID = "NotStarted"

        $uri = $BaseUri, "_paging=1&_max_results=$PageSize&_return_as_object=1" -join "?"

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
                Throw "Error retrieving record: $_"
            }
            $NextPageID = $TempResult.next_page_id
            
            Write-Verbose "Page $NextPageID"
            $TempResult.result

        }
        until (-not $TempResult.next_page_id)

}