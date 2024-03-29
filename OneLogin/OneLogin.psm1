
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )


#Dot source the files
foreach ($import in @($Public + $Private)) {
    
    try {
        . $import.fullname
    }
    catch {
        
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Private variables
Set-Variable -Name "baseURI" -Value "https://api.us.onelogin.com/api/1" -Scope Script

Export-ModuleMember -Function $Public.Basename
