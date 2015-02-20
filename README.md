Infoblox PowerShell Module
=============

This is a PowerShell module for working with the Infoblox Web API.

This is a quick and dirty implementation based on my environment's configuration, with limited functionality.  Contributions to improve this would be more than welcome!

Some caveats:

 * A number of shortcuts have been taken given that this is a fast publish.  This is more of a demo module; I have no plans to address these, but contributions are welcome!
   * Limited testing, limited validation of edge case scenarios
   * Limited error handling
   * Limited comment based help and examples (some may be outdated)

#Functionality

Search Infoblox DHCP leases:
  * ![Search for Infoblox DHCP leases](/Media/Get-IBLease.png)

Search for Infoblox networks
  * ![Search for Infoblox networks](/Media/Get-IBObject.png)

Search for Infoblox for IPAM IPv4 addresses between two IPs
  * ![Search for Infoblox DHCP leases](/Media/Get-IBObjectFilter.png)

#Prerequisites
    
 * You must be using Windows PowerShell 3 or later on the system running this module
 * You must have your Infoblox configured to allow access to the Web API
 * You must have access to query the Infoblox Web API
 * We serialize a default Uri Infoblox.xml in the module path - you must have access to that path for this functionality
 * Module folder downloaded, unblocked, extracted, available to import

#Instructions

    # One time setup
        # Download the repository
        # Unblock the zip
        # Extract the Infoblox folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    # Import the module.
        Import-Module Infoblox    #Alternatively, Import-Module \\Path\To\Infoblox

    # Get commands in the module
        Get-Command -Module Infoblox

    # Get help for a command or two
        Get-Help Set-IBConfig -Full
        Get-Help New-IBSession -Full

    # Optional persistent default config setup
    # This configures Infoblox.xml in your module folder, will load each time you import the module
        Set-IBConfig -Uri "https://grid.contoso.com" -IBVersion "v1.6"

    # View the current config settings
        Get-IBConfig

    # Establish a new session.  This uses the IBConfig Uri and IBVersion
        New-IBSession -Credential (Get-Credential)

        # Note! if you don't have certificates set up correctly, you may see the following error.  Set-TrustAllCertsPolicy is a temporary solution
        # Error retrieving session: The underlying connection was closed: Could not establish trust relationship for the SSL/TLS secure channel.
        # Set-TrustAllCertsPolicy

    # Get all leases 
        Get-IBLease

    # Get leases for any address in 192.168.0., with a free binding state
        Get-IBLease -Address 192.168.0. | Where {$_.binding_state -like "FREE"}

    # Get a list of all networks defined on the InfoBlox.  Get-IBObject is a generic wrapper to pull random object types
        Get-IBObject -Object Network

    # Maybe you want to go from an IP address to a network:

        # Get network from IPAM for a single IP
            $filter = [pscustomobject]@{
                        Object="ip_address"
                        Operator="="
                        Filter="192.168.0.54"
                    }

            $Network = Get-IBObject -Filters $filter -Object IPV4Address | Select -ExpandProperty network


        # Get the corresponding network object
            $filter = [pscustomobject]@{
                        Object="network"
                        Operator="="
                        Filter=$Network
                    }

            Get-IBObject -Filters $filter -Object Network 

    # Find all IPAM IPv4 Addresses between two IPs
        $filters = [pscustomobject]@{
            Object="ip_address"
            Operator=">="
            Filter="192.168.0.10"
        },
        [pscustomobject]@{
            Object="ip_address"
            Operator="<="
            Filter="19.168.0.100"
        }

        Get-IBObject -Filters $filters -Object IPV4Address
        
  #NOTES

  Publishing this as a reference to a blog post.  Infoblox' Web API highlights [the need for vendors to provide PowerShell modules](https://ramblingcookiemonster.wordpress.com/2015/02/07/rest-powershell-and-infoblox/) layered on top of their APIs, rather than offloading this to their customers.

  * The API documentation this used was 962 pages (most of which you can skip, thankfully)
  * Unique syntax and formatting that you must read up on and implement, including features like paging and filters
  * I'm not too familiar with the Infoblox.  I'm a consumer of a few services, and happen to like using PowerShell.  Someone more familiar with the technology (the vendor) should be writing a PowerShell module.
  * I'm only going to spend as much time as needed to get a result that meets my needs for reliability, functionality, and configuration.
