
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
