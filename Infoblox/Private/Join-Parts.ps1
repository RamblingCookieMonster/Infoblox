#Function used to join URL.
#Credit to http://stackoverflow.com/questions/9593535/best-way-to-join-parts-with-a-separator-in-powershell
function Join-Parts
{
    param
    (
    [parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Parts = $null
    )
    $Separator = "/"
    ($Parts | Where { $_ } | Foreach { ([string]$_).trim($Separator) } | ? { $_ } ) -join $Separator
}