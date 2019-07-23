# Make all errors terminating for try/catch exception handling
$ErrorActionPreference = "Stop"

# Static variables
Set-Variable -Name "baseURI" -Value "https://api.us.onelogin.com/api/1"



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