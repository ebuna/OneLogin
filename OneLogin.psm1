# Make all errors terminating for try/catch exception handling
$ErrorActionPreference = "Stop"

# Static variables
Set-Variable -Name "baseURI" -Value "https://api.us.onelogin.com/api/1"


#region Public Functions

<#
    .SYNOPSIS
        Generates and stores in memory an access token for use with the OneLogin API.

    .DESCRIPTION
        OneLogin uses OAuth2.0 for API authentication. This function uses the
        Generate Tokens call to exchange a ClientID and ClientSecret for 
        an access token that can be use to perform subsequent calls to the
        API.

    .PARAMETER ClientId
        The Client ID from the OneLogin Developer API credential.

    .PARAMETER ClientSecret
        The Client Secret from the OneLogin Developer API credential.

    .OUTPUTS
        IF successful:
            $true
        ELSE:
            $false. Will also display the error in the console.

    .EXAMPLE
        New-OLAuthToken -ClientId "abcde12345" -ClientSecret "54321edcba"

        Generates a new access token and saves it in memory.

    .LINK
        https://developers.onelogin.com/api-docs/1/oauth20-tokens/generate-tokens-2

#>
Function New-OLAuthToken {

    [CmdletBinding()]
    Param (

        # The Client ID from the OneLogin Developer API credential
        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 0)]
        [String]
        $ClientId,

        # The Client Secret from the OneLogin Developer API credential
        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 1)]
        [String]
        $ClientSecret
    )

    # Authorization URI used to generate an access token
    $authURI = "https://api.us.onelogin.com/auth/oauth2/token"

    # Convert ClientID and ClientSecret to base64 string
    $b64 = Convertto-Base64String -ClientId $ClientId -ClientSecret $ClientSecret

    # Create the headers for the auth token request
    $headers = @{}
    $headers.Add("Authorization","Basic $b64")
    $headers.Add("Content-Type","application/json")

    # Create the body of the auth token request and convert to JSON
    $body = @{

        grant_type='client_credentials'
    }
    $jsonBody = $body | convertto-json

    # Post the request to obtain a token
    try {

        $response = Invoke-RestMethod -Method Post -Headers $headers -Body $jsonBody -Uri $authURI
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {

        # The response returned an exception
        Write-Verbose $_.Exception.Message
        $response = $_.Exception.Response
    }
    catch {

        # Something else happened
        Write-Host "An unknown exception occurred: $($_.Exception.Message)"
        return $false
    }

    # Check the response status code
    if ($response.StatusCode) {

        switch ($response.StatusCode) {

            "Unauthorized" {
    
                Write-Host "The credentials provided are not valid." -ForegroundColor Red
                break
            }
    
            default {
    
                # TODO: cleanup response status codes
                return $response
            }
        }
    }
    else {

        # Save token in memory
        # Not converting to securestring yet due to pscore limitaions
        # See here fore more info: https://github.com/PowerShell/PowerShell/issues/1654

        New-Variable -Name "OLAPIToken" -Value $response.data -Visibility Private -Option ReadOnly -Scope Global

        return $true
    }
}



Function Get-OLEvents {

    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 0)]
        [String]
        $EventID,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 1)]
        [int]
        $Hours
    )

    # Check for existing access token and use or refresh it
    if (ValidateToken) {

        # Token is valid
        Write-Verbose "Token is valid."

        # Set start date for the API call
        $startDate = (get-date).AddHours(-$Hours)
        $startString = $startDate.ToString("o")

        # URI
	    $URI = "$baseURI/events?event_type_id=$EventID&since=$startString"
	
        # Headers
        $headers = @{}
        $headers.Add("Authorization","bearer:$($OLAPIToken.access_token)")

        try {

            $response = Invoke-RestMethod -URI $URI -Headers $headers -Method Get -SkipHeaderValidation
        }
        catch {

            $response = $_.Exception.Response
        }

        # Check for errors
        switch ($response.status.code) {

            400 {

                # Bad request
                Write-Host "Received http 400 error.`nType: $($response.status.type).`nMessage:$($response.status.message)." -ForegroundColor Red
                break
            }

            401 {

                # TODO: Unauthorized
            }

            200 {

                # Success
                return $response.data
            }

            default {

                Write-Host "An exception occurred: $($_.Exception.Message)" -ForegroundColor Red
            }
        }

        return $response
    }
    else {

        # Token is not valid
        Write-Verbose "token not valid"
    }
}


#endregion


#region Private Functions
Function GetAllPaginationData {

	[CmdletBinding()]
    Param (

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 0)]
        [String]
        $Headers,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 1)]
        [int]
        $Response
    )
	
	$tempData = $Response
	$allData = $Response.data
	
	while ($tempData.pagination.next_link) {
	
		$tmpIRM = Invoke-RestMethod -URI $tempData.pagination.next_link -Method Get -Headers $Headers
		
		$allData += $tmpIRM.data
		$tempData = $tmpIRM
	}
	
	return $allData
}


Function ValidateToken {

    # Check for existing access token and use or refresh it
    if ($OLAPIToken) {

        $now = Get-Date
        $tokenExpiry = $OLAPIToken.created_at.AddSeconds($OLAPIToken.expires_in)

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


Function Convertto-Base64String {

    [CmdletBinding()]
    Param (

        # The Client ID from the OneLogin Developer API credential
        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 0)]
        [String]
        $ClientId,

        # The Client Secret from the OneLogin Developer API credential
        [Parameter(Mandatory = $true,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 1)]
        [String]
        $ClientSecret
    )


    $baseString = $ClientId + ":" + $ClientSecret
    $utfEncodedString = [System.Text.Encoding]::UTF8.GetBytes($baseString)
    return [System.Convert]::ToBase64String($utfEncodedString)
}
#endregion


Export-ModuleMember New-OLAuthToken, Get-OLEvents