Function Get-IBObject {
    <#
    .SYNOPSIS
        Get a specified object from the Infoblox
    
    .DESCRIPTION
        Get a specified object from the Infoblox

        Note:  Error 400 generally refers to a syntax error.  For example:
                   Case sensitivity issues
                   Invalid operator issues.  API describes which properties accept specific operators.

    .PARAMETER Object
        Type of object to query for.  Example: 'network'

    .PARAMETER Properties
        If specified, extract these additional properties for the objects

    .PARAMETER Filters
        Array of objects containing Filter Information.  Objects must be formatted as follows:
            Object   = What to filter on.  Example: "address"
            Operator = Filter operator.    Example: "~=".  See API for details.
            Filter   = Value for filter.   Example: "192.168.0"

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

        #Get network objects
        Get-IBObject -Object network

    .EXAMPLE

        #Authenticate with the Infoblox. $IBConfig.IBSession and $IBConfig.Uri will now be populated
        New-IBSession -Credential $Cred

        
        #Filters argument must be an array.  This simplified way works in PS3 only...
            $filter = [pscustomobject]@{
                Object="ip_address"
                Operator="="
                Filter="192.168.0.231"
            }

        #Get a specific ipv4 address
            Get-IBObject -Object ipv4address -filters $filter

    .EXAMPLE

    .FUNCTIONALITY
        Infoblox
    #>
    [cmdletbinding()]
    param(    
        [string]$Object = "network",
        [string[]]$Properties = $null,
        [string]$Uri = $Script:IBConfig.Uri,
        [string]$IBVersion = $Script:IBConfig.IBVersion,
        [psobject[]]$Filters = @(),
        [Microsoft.PowerShell.Commands.WebRequestSession]$IBSession = $Script:IBConfig.IBSession,
        [System.Management.Automation.PSCredential]$Credential,
        [int]$PageSize = 1000
    )

    #Build up URI
        $IBBaseURI = Join-Parts $Uri "/wapi/$IBVersion"
        $BaseUri = "$IBBaseURI/$($object.ToLower())"
        $NextPageID = "NotStarted"

        #Build up filters
            $CGI = @()

            if($Filters.count -gt 0)
            {
                $ValidOperators = "=","!=","<=",">=","~=", ":="
                foreach($Filter in $Filters)
                {
                    if($ValidOperators -contains $Filter.Operator)
                    {
                        $CGI += "{0}{1}{2}" -f $Filter.Object, $Filter.Operator, $Filter.Filter
                    }
                    else
                    {
                        Write-Warning "Discarding Filter, invalid Operator $($Filter | Format-List | Out-String)`n.  Use $($ValidOperators -join ", ")"
                    }
                }
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
                Throw "Error retrieving record: $_"
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