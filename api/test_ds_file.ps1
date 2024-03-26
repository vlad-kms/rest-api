function Invoke-API () {
    <#
    .SYNOPSIS
    Маршрутизация методов API
    .DESCRIPTION
    Маршрутизация методов API
    .OUTPUTS
    Name: result
    BaseType: Hashtable
        см. return-codes.md Invoke-API output:
    .PARAMETER Params
    Все параметры.
        - [String]          cmd     : Action (функция) для выполнения
        - [CommonVariable]  vars    : общие переменные скрипта
        - [Hashtable]       params  : параметры для функции
    #>
    #- [System.Collections.Stack]logs      - [STACK] LIFO объект сообщений

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [int] $LogLevel=1
    )
    $s = "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "$($s)"
    #Write-Verbose "$($Params | ConvertTo-Json -depth 2)"
    $result = [ordered]@{
        "code" = 0;
        "message" = "";
        "logs" = [System.Collections.Generic.List[string]]@();
        "resAPI" = [ordered]@{};
        "error" = $null
    }

    $Action = $Params.cmd
    Write-Verbose "Action:   $($Action)"
    if ($Action.ToUpper() -eq "_ISPRESENT_") {
        $result.message = "Метод Invoke-API присутствует в $($MyInvocation.InvocationName)";
        $result.code = 1000;
    } elseif ($Params.cmd.ToUpper() -eq "TEST") {
        Write-Verbose "cmd: $($Params.cmd.ToUpper())"
    } else {
        $Provider = $Params.Provider
        Write-Verbose "Provider: $($Provider)"
        # список поддерживаемых функций
        try {
            $suppFunc = Get-SupportedFeatures
            $result.resAPI += @{"AllFunc" = $suppFunc}
            $result.Message = "Test is successfull $($MyInvocation.InvocationName)"
            # HACKTEST убрать комментарий для проверки на throw
            #1/0
        }
        catch {
            $result.code = -1;
            $result.message = "Ошибка получения поддерживаемых функций";
            $result.error = $PSItem
            $result.resAPI = @{}
        }
    
    }
<#
    if ( $Action -and ($Action.ToUpper() -ne "getSupportedFunction".ToUpper()) ) {
        try {
            # HACKTEST убрать комментарий для проверки на throw
            #1 /0
        }
        catch {
            $result.code = -2;
            $result.Message = "Ошибка обработки $($Provider::$Action)"
            $result.Error = $PSItem
        }
    }
#>
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $result
}

function Get-SupportedFeatures() {
    <#
    .DESCRIPTION
    Обязательная функция, возвращающая список-словарь поддерживаемых модулем @{Action1=Func;Action2=Func2;...}
    #>
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
    )

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    $result = @{
        "test"="Get-Test";
        "GetRecords"="Get-Records";
        "grs"="Get-Records";
        "Get-Domains"="";
        "gds"="Get-Domains";
    }
    $result.GetEnumerator().Name | ForEach-Object {
        if ( -not $result.$_ ) {
            $result."$($_)" = $_
        }
    }
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="

    Write-Verbose "TESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTESTTEST"
    Write-Verbose "$($Params|ConvertTo-Json -Depth $LogLevel)"

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
}
