
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