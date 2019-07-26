
Function Get-OLEvents {
    <#
        .SYNOPSIS
            Returns events of the specified ID.

        .DESCRIPTION
            Generates an array of events of the provided ID. By default,
            this function returns a maximum of 50 results. You can use the
            -All switch to return all event found.

        .PARAMETER EventID
            Required. The ID of the event to return data for.

        .PARAMETER Hours
            Optional. Specify the number of hours to look back
            from the current time.

        .PARAMETER All
            Optional. Set this switch to return all events that match
            the criteria.

        .OUTPUTS
            ArrayList of objects.

        .EXAMPLE
            Get-OLEvents -EventID 113 -Hours 5

            Returns a list of events for eventID 113 over the last 5 hours. A maximum of 50 events will be returned.

        .EXAMPLE
            Get-OLEvents -EventID 110 -Hours 48 -All

            Returns a list of events for eventID 110 over the last 48 hours. There is no limit to the amount of events returned.

        .LINK
            https://developers.onelogin.com/api-docs/1/events/get-events

    #>
    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true,
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
        $Hours = 0,

        [Parameter(Mandatory = $false,
        ValueFromPipelineByPropertyName,
        ValueFromPipeline,
        Position = 1)]
        [switch]
        $All
    )

    # Check for existing access token and use or refresh it
    if (ValidateToken -Token $OLAPIToken) {

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
                if ($All) {

                    $allData = GetAllPaginationData -Headers $headers -Response $response
                    return $allData
                }
                else {

                    return $response.data
                }
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