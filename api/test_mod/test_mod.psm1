function Invoke-API1 () {
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
    Параметры.
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
    begin {
        $s = "$($MyInvocation.InvocationName) ENTER: =============================================++++++++++++++++++++++++++++"
        Write-Verbose "$($s)"
        Write-Verbose "$($Params|ConvertTo-Json -Depth $LogLevel)"
        $result = [ordered]@{
            "code" = 0;
            "message" = "";
            "logs" = [System.Collections.Generic.List[string]]@();
            "resAPI" = [ordered]@{};
            "error" = $null
        }
    }
    process {
        $Action = $Params.cmd
        if ($Action.ToUpper() -eq "_ISPRESENT_") {
            $result.message = "Метод Invoke-API присутствует в $($MyInvocation.InvocationName)";
            $result.code = 1000;
        } elseif ($Action.ToUpper() -eq "_TEST_") {
            Write-Verbose "cmd: $($Params.cmd.ToUpper())"
            $result.Message = "Action '$($Action)' running is successfull $($MyInvocation.InvocationName)"
            $result.code = 1001;
        } else {
            $Provider = $Params.Provider
            Write-Verbose "Provider: $($Provider)"
            Write-Verbose "Action:   $($Action)"

            # список поддерживаемых функций
            $suppFunc = Get-SupportedFeatures
            $result.resAPI += @{"AllFunc" = $suppFunc}
            Write-Verbose "$($Params.vars.ini.ToJson($LogLevel))"
            # HACKTEST убрать комментарий для проверки на throw
            #1/0

            # считать секцию файла конфигурации
            $ini = $Params.vars.ini
            if ( ("sectionName" -in $Params.Keys) -and $Params.sectionName) {
                $result += @{'sectionData'= $ini.getSectionValues($Params.sectionName)}
            }elseif ( ("sectionName" -in $Params.params.Keys) -and $Params.params.sectionName) {
                $result += @{'sectionData'= $ini.getSectionValues($Params.params.sectionName)}
            } else {
                $result += @{'sectionData'= $ini.getSectionValues($Provider)}
            }

            # пробуем найти Action в списке поддерживаемых cmd
            if ($suppFunc.ContainsKey($Action)) {
                # есть среди поддерживаемых функций Action
                # найти функцию для Action и вызвать ее
                try {
                    Write-Verbose "Получаем из списка поддерживаемых функций соответствующую функцию $($suppFunc."$($Action)") для $($Action)"
                    $result += @{"runningFunction"=$suppFunc."$($Action)"}
                    #$command = "$(if (-not $fileIsDotSourcing) {""$($Provider)\""})$($suppFunc.""$($Action)"")  $(if ($PSBoundParameters.Verbose) {"-Verbose"}) -LogLevel $($LogLevel) -Params " + '$($Params)'
                    $command = "$($suppFunc.""$($Action)"")  $(if ($PSBoundParameters.Verbose) {"-Verbose"}) -LogLevel $($LogLevel) -Params " + '$($Params)'
                    Write-Verbose "command: $($command)"
                    $result.resAPI += @{"result"=(Invoke-Expression -Command $command)}
                }
                catch {
                    throw "Не нашли функцию для $($Action) => $($suppFunc.""$($Action)"")"
                }

            } else {
                throw "Action ""$($Action)"" не поддерживается модулем $($Provider). Список Action: $($suppFunc.Keys)"
            }

            #Нужно для организации истории
            $result += @{"Input"=$Params}
        }
    }
    end {
        Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
        return $result
    }
}

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
        "test"="Get-Test";
        "tEst1"="Get-Test";
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
    #1/0
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $result
}

function Get-Test() {
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    $resultAPI = [ordered]@{
        "code" = 0;
        "message" = "";
        "logs" = [System.Collections.Generic.List[string]]@();
        "error" = $null
    }
    
    $s = "cmd: $($Params.cmd.ToUpper())"
    Write-Verbose "$((($s).PadRight($s.Length+1, ' ')).PadRight(80, [char]94))"
    $resultAPI.code = 1001;

    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $resultAPI
}

#Set-Alias Invoke-API Invoke-API-dns_selectel
#Export-ModuleMember -Function "*"
