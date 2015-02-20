function Set-TrustAllCertsPolicy { 
    <#
    .SYNOPSIS
        Set CertificatePolicy to trust all certs.  This will remain in effect for this session.
    .Functionality
        Web
    .NOTES
        Not sure where this originated.  A few references:
            http://connect.microsoft.com/PowerShell/feedback/details/419466/new-webserviceproxy-needs-force-parameter-to-ignore-ssl-errors
            http://stackoverflow.com/questions/11696944/powershell-v3-invoke-webrequest-https-error
    #>
    [cmdletbinding()]
    param()
    
    if([System.Net.ServicePointManager]::CertificatePolicy.ToString() -eq "TrustAllCertsPolicy")
    {
        Write-Verbose "Current policy is already set to TrustAllCertsPolicy"
    }
    else
    {
        add-type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@
    
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }
 }