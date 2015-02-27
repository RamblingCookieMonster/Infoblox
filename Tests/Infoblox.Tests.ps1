#A few basic tests, will add more, contributions would be appreciated!

#Variables used in the tests
    $ModuleRoot = "$PSScriptRoot\..\Infoblox"
    $IBXml = "$PSScriptRoot\..\InfoBlox\Infoblox.xml"
    
    $ReferenceConfig = @{
        Uri = "grid.contoso.com"
        IBVersion = 999
        IBSession = "ThisMakesNoSense!"
    }

    $Credential = New-Object -TypeName PSCredential -ArgumentList user, $(ConvertTo-SecureString -asPlainText -Force -String "jdhfia@$*7")

Import-Module $ModuleRoot -ErrorAction Stop -force

Describe 'Import-Module InfoBlox' {
    Context 'Strict mode' { 
        Set-StrictMode -Version latest

        It 'Should create a persistent configuration file' {
                                    
            #It should have the right properties
                $Properties = ( Import-Clixml -Path $IBXml -ErrorAction Stop ).PSObject.Properties.Name
                $Comparison = Compare-Object -ReferenceObject Uri, IBVersion -DifferenceObject $Properties -IncludeEqual
            
                $Properties.Count | Should Be 2
                ($Comparison | Where-Object {$_.SideIndicator -eq "=="} ).Count | Should Be 2
        }
    }
}

Describe 'Set-IBConfig' {
    
    Context 'Strict mode' { 

        Set-StrictMode -Version latest

        It 'Should change Infoblox.xml' {
            
            Set-IBConfig @ReferenceConfig
            $Config = Import-Clixml -Path $IBXml
            $Config.Uri | Should Be $ReferenceConfig.Uri
            $Config.IBVersion | Should Be $ReferenceConfig.IBVersion
            $Config.PSObject.Properties.Name -Contains 'IBSession' | Should Be $False
            
            Set-IBConfig -Uri "" -IBVersion ""
            $Config = Import-Clixml -Path $IBXml
            $Config.Uri | Should BeNullOrEmpty
            $Config.IBVersion | Should BeNullOrEmpty
            $Config.PSObject.Properties.Name -Contains 'IBSession' | Should Be $False

        }
        It 'Should change $Script:IBConfig' {

            Set-IBConfig @ReferenceConfig
            $Config = Get-IBConfig -Source IBConfig
            $Config.Uri | Should Be $ReferenceConfig.Uri
            $Config.IBVersion | Should Be $ReferenceConfig.IBVersion
            $Config.IBSession | Should Be $ReferenceConfig.IBSession

            Set-IBConfig -Uri "" -IBVersion "" -IBSession ""
            $Config = Get-IBConfig -Source IBConfig
            $Config.Uri | Should BeNullOrEmpty
            $Config.IBVersion | Should BeNullOrEmpty
            $Config.IBSession | Should BeNullOrEmpty
        }
    }
}

Describe 'Get-IBConfig' {
    
    Context 'Strict mode' { 

        Set-StrictMode -Version latest

        It 'Should retrieve data from Infoblox.xml' {
            
            Set-IBConfig @ReferenceConfig
            $Config = Get-IBConfig -Source Infoblox.xml
            $Config.Uri | Should Be $ReferenceConfig.Uri
            $Config.IBVersion | Should Be $ReferenceConfig.IBVersion
            
            Set-IBConfig -Uri "" -IBVersion ""
            $Config = Get-IBConfig -Source Infoblox.xml
            $Config.Uri | Should BeNullOrEmpty
            $Config.IBVersion | Should BeNullOrEmpty

        }
        It 'Should retrieve data from $Script:IBConfig' {
            
            Set-IBConfig @ReferenceConfig
            $Config = Get-IBConfig -Source IBConfig
            $Config.Uri | Should Be $ReferenceConfig.Uri
            $Config.IBVersion | Should Be $ReferenceConfig.IBVersion
            $Config.IBSession | Should Be $ReferenceConfig.IBSession

            Set-IBConfig -Uri "" -IBVersion "" -IBSession ""
            $Config = Get-IBConfig -Source IBConfig
            $Config.Uri | Should BeNullOrEmpty
            $Config.IBVersion | Should BeNullOrEmpty
            $Config.IBSession | Should BeNullOrEmpty

        }
    }
}

#TODO We set IBSession as a string above.  That's a no-no we should handle in module later.  Reset the XML...
Remove-Item $IBXml -Force
Import-Module $ModuleRoot -Force

Describe 'Get-IBObject' {

    Mock -ModuleName Infoblox -CommandName Invoke-RestMethod {}

    Context 'Strict mode' { 

        Set-StrictMode -Version latest
        
        It 'Should not error out' {

            Get-IBObject -Object IPv4Address -Credential $Credential
        
        }
    }
}