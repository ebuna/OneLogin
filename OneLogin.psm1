# Make all errors terminating for try/catch exception handling
$ErrorActionPreference = "Stop"

# Static variables
Set-Variable -Name "baseURI" -Value "https://api.us.onelogin.com/api/1"


<#
    .SYNOPSIS
        Generates an access token for use with the OneLogin API.

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
            [string] $accessToken: The access token obtained.
        ELSE:
            $null. Will also display the error in the console.

    .EXAMPLE
        $token = GetAuthToken -ClientId "abcde12345" -ClientSecret "54321edcba"

        Generates an access token and saves it to $token.

    .LINK
        https://developers.onelogin.com/api-docs/1/oauth20-tokens/generate-tokens-2

#>
Function GetAuthToken {

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
        return $null
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

        return $response.data.access_token
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

Export-ModuleMember GetAuthToken