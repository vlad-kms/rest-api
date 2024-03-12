<#
function Invoke-API () {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [int] $LogLevel=1
    )
    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    $result = [ordered]@{
        "code" = 0;
        "message" = "";
        "logs" = [System.Collections.Generic.List[string]]@();
        "resAPI" = [ordered]@{};
        "error" = $null
    }

    Write-Verbose "$($Params | ConvertTo-Json -depth 2)"
    Write-Verbose "$($Params | ConvertTo-Json -depth 2)"

    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $result
}
#>

function Get-SupportedFeatures() {
    <#
    .DESCRIPTION
    Обязательная функция, возвращающая список-словарь поддерживаемых модулем (Action: Function)
    #>
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param()

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="

    $result = @{
        "Test"="Get-Test";
    }
    $result.GetEnumerator().Name | ForEach-Object {
        if ( -not $result.$_ ) {
            $result."$($_)" = $_
        }
    }
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $result
}

function Get-Test() {
    <#
    .DESCRIPTION
    Обязательная функция, возвращающая список-словарь поддерживаемых модулем (Action: Function)
    #>
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="

    Write-Verbose "TESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTEST"
    Write-Verbose "$($Params|ConvertTo-Json -Depth $LogLevel)"

    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
}
