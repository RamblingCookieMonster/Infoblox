Function Get-IBConfig {
    <#
    .SYNOPSIS
        Get Infoblox module configuration

    .DESCRIPTION
        Get Infoblox module configuration

    .PARAMETER Source
        Config source:
        IBConfig to view module variable
        Infoblox.xml to view Infoblox.xml

    .FUNCTIONALITY
        Infoblox
    #>
    [cmdletbinding()]
    param(
        [ValidateSet('IBConfig','Infoblox.xml')]
        [string]$Source = "IBConfig"
    )

    if($Source -eq "IBConfig")
    {
        $Script:IBConfig
    }
    else
    {
        Import-Clixml -Path "$PSScriptRoot\Infoblox.xml"
    }

}