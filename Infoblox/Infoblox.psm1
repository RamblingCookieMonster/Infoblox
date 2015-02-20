#Get public and private function definition files.
    $Public  = Get-ChildItem $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue 
    $Private = Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue 

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error "Failed to import function $($import.fullname)"
        }
    }

#Create / Read config
    if(-not (Test-Path -Path "$PSScriptRoot\Infoblox.xml" -ErrorAction SilentlyContinue))
    {
        Try
        {
            Write-Warning "Did not find config file $PSScriptRoot\Infoblox.xml, attempting to create"
            [pscustomobject]@{
                Uri = $null
                IBVersion = "v1.6"
            } | Export-Clixml -Path "$PSScriptRoot\Infoblox.xml" -Force -ErrorAction Stop
        }
        Catch
        {
            Write-Warning "Failed to create config file $PSScriptRoot\Infoblox.xml: $_"
        }
    }
    
#Initialize the config variable.  I know, I know...
    Try
    {
        #Import the config
        $IBConfig = $null
        $IBConfig = Get-IBConfig -Source Infoblox.xml -ErrorAction Stop | Select -Property Uri, IBVersion, IBSession

    }
    Catch
    {   
        Write-Warning "Error importing IBConfig: $_"
    }

#Create some aliases, export public functions
    Export-ModuleMember -Function $($Public | Select -ExpandProperty BaseName) -Alias *