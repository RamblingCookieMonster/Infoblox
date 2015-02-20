Function Set-IBConfig {
    <#
    .SYNOPSIS
        Set Infoblox module configuration.

    .DESCRIPTION
        Set Infoblox module configuration, and module $IBConfig variable.

        This data is used as the default for most commands.

    .PARAMETER Uri
        Specify a Uri to use

    .PARAMETER IBVersion
        Specify an Infoblox version (v1.6 is the default)

    .PARAMETER IBSession
        Specify an Infoblox session.  This is not written to the XML, it is used in $IBConfig only.

    .Example
        Set-IBConfig -Uri "https://grid.contoso.com"

    .FUNCTIONALITY
        Infoblox
    #>
    [cmdletbinding()]
    param(
        [string]$Uri,
        [string]$IBVersion,
        $IBSession
    )

    if($IBVersion)
    {
        $Script:IBConfig.IBVersion = $IBVersion
    }
    If($Uri)
    {
        $Script:IBConfig.Uri = $Uri
    }
    If($IBSession)
    {
        $Script:IBConfig.IBSession = $IBSession
    }

    $Script:IBConfig | Select -Property * -ExcludeProperty IBSession | Export-Clixml -Path "$PSScriptRoot\Infoblox.xml" -force

}