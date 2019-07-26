
Function ValidateToken {

    Param (

        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 0)]
        $Token
    )
    # Check for existing access token and use or refresh it
    if ($Token) {

        $now = Get-Date
        $tokenExpiry = $Token.created_at.AddSeconds($Token.expires_in)

        if ($now -ge $tokenExpiry) {

            # TODO: Token is expired
            # Should refresh the token using the Refresh Token call
            Write-Verbose "Token is expired."
            return $false
        }
        else {

            # Token exists and is valid
            return $true
        }
    }
    else {

        # Token does not exist
        Write-Verbose "Token does not exist. Did you forget to authenticate with New-OLAuthToken?"
        return $false
    }
}
