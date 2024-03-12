[CmdletBinding()]
Param (
    [Parameter(ValueFromPipeline=$True, Position=0)]
    $Provider='selectel'
)


begin {
    Write-Verbose "script begin: ====================================================="
    Write-Host "input: $input"
    Write-Host "Provider: $Provider"
    $result = 1
    Write-Host "PSBoundParameters:"
    Write-Host "$($PSBoundParameters | ConvertTo-Json -Depth 100)"
    $global:t=[ordered]@{}
    $t.add('z-b','z-b')
}
process {
    Write-Verbose "script process: ==================================================="
    Write-Host "_: $_"
    Write-Host "Provider: $Provider"
    $t.Add("q$($result)", 'v')
    $result += 2
    Write-Host "PSBoundParameters:"
    Write-Host "$($PSBoundParameters | ConvertTo-Json -Depth 100)"

}
end {
    Write-Verbose "script end: ======================================================="
    Write-Verbose "result: $result"
    Write-Host "PSBoundParameters:"
    Write-Host "$($PSBoundParameters | ConvertTo-Json -Depth 100)"
    $t.add('z-e','z-e')
    $t
    Write-Host "-----------------------------"
    return $result
}

