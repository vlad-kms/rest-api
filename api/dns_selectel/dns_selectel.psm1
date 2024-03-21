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
        #Нужно для организации истории
        $result += @{"Input"=$Params}
    }
    process {
        $Action = $Params.cmd
        if ($Action.ToUpper() -eq "_ISPRESENT_") {
            $result.message = "Метод Invoke-API присутствует в $($MyInvocation.InvocationName)";
            $result.code = 1000;
        } elseif ($Action.ToUpper() -eq "_TEST_") {
            $s = "cmd: $($Params.cmd.ToUpper())"
            Write-Verbose "$((($s).PadRight($s.Length+1, ' ')).PadRight(80, [char]94))"
            $result.Message = "Action '$($Action)' running is successfull $($MyInvocation.InvocationName)"
            $result.code = 1001;
        } else {
            $Provider = $Params.Provider
            Write-Verbose "Provider: $($Provider)"
            Write-Verbose "Action:   $($Action)"

            # считать секцию файла конфигурации
            $ini = $Params.vars.ini
            if ( ("sectionName" -in $Params.Keys) -and $Params.sectionName) {
                $sectN = $Params.sectionName
                #$result += @{'sectionData'= $ini.getSectionValues($Params.sectionName)}
            } elseif ( ("sectionName" -in $Params.params.Keys) -and $Params.params.sectionName) {
                $sectN = $Params.params.sectionName
                #$result += @{'sectionData'= $ini.getSectionValues($Params.params.sectionName)}
            } else {
                $sectN = $Provider
                #$result += @{'sectionData'= $ini.getSectionValues($Provider)}
            }
            $r = $ini.getSectionValues($sectN)
            if ($r.code -ne 0) {
                # не смогли считать секцию с настройками
                #Write-Verbose "Не смогли считать секцию с настройками $($sectN) для провайдера $($Provider)"
                throw "Не смогли считать секцию с настройками $($sectN) для провайдера $($Provider)"
            }
            $result += @{'sectionData'=$r}
            $Params += @{'sectionData'=$r}
            #Write-Verbose "$($Params.vars.ini.ToJson($LogLevel))"

            # список поддерживаемых функций
            $suppFunc = (Get-SupportedFeatures -sectionIni $result.sectionData.resultDefs)
            $result.resAPI += @{"AllFunc" = $suppFunc}
            # HACKTEST убрать комментарий для проверки на throw
            #1/0
            Write-Verbose "Supported function: $($suppFunc | ConvertTo-Json)"

            # пробуем найти Action в списке поддерживаемых cmd
            if ($suppFunc.ContainsKey($Action)) {
                # есть среди поддерживаемых функций Action
                # найти функцию для Action и вызвать ее
                try {
                    Write-Verbose "Получаем из списка поддерживаемых функций соответствующую функцию $($suppFunc."$($Action)") для $($Action)"
                    $result += @{"runningFunction"=$suppFunc."$($Action)"}
                    $command = "$($suppFunc.""$($Action)"")  $(if ($PSBoundParameters.Verbose) {"-Verbose"}) -LogLevel $($LogLevel) -Params " + '$($Params)'
                    Write-Verbose "Маршрутизируем command: $($command)"
                    $result.resAPI += @{"HttpResponse"=(Invoke-Expression -Command $command)}
                }
                catch {
                    #throw "Не нашли функцию для $($Action) => $($suppFunc.""$($Action)"")"
                    throw $PSItem
                }

            } else {
                throw "Action ""$($Action)"" не поддерживается модулем $($Provider). Список Action: $($suppFunc.Keys)"
            }
        }
    } ### process {
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
    Param(
        [Parameter(Position=0, ValueFromPipeline=$true)]
        [hashtable] $sectionIni = @{}
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    $result = @{}
    if ($sectionIni.ContainsKey("actions")) {
        $result += $sectionIni.actions
    }
    <#
    $result = @{
        "test"="Get-Test";
        "GetRecords"="Get-Records";
        "grs"="Get-Records";
        "domains"="Get-Domains";
        "gds"="Get-Domains";
    }
    #>
    $result.GetEnumerator().Name | ForEach-Object {
        if ( -not $result.$_.Trim() ) {
            $result."$($_)" = $_
        }
    }
    Write-Verbose "result: $($result | ConvertTo-Json)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $result
}

function Get-Test() {
    #Requires -Version 3
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

<############################################################################################################>
<###  v1 and v2 #############################################################################################>
<###  Получить домены                                                                                     ###>
<############################################################################################################>
function Get-DomainsAll
{
    <#
    .DESCRIPTION
    Получить все ресурсные записи домена.
    v1: GET /; https://api.selectel.ru/domains/v1/
    v2: GET /zones; https://api.selectel.ru/domains/v2/zones
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" массив записей о доменах
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
        Обязательные ключи в HASHTABLE:
    нет
        Необязательные ключи в HASHTABLE:
    Params.Params.domain  - имя или id домена, будет выбираться данные только о нем
    Params.params.query   - аргументы для строки запроса (?arg=1&arg2=qwe&arg3=3...).
                            Может быть строкой, первый '?' не обязателен.
                            Может быть массивом @('arg=1', 'arg2=qwe', 'arg3=3', ...), будет преобразован в строку запроса
    Params.Params.UseInitialOffset -наличие (значение не обязательно) указывает использовать начальное значение offset из параметра запроса,
                                    иначе offset обнуляется
    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )
    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="

    [Int]$Limit=1000
    [Int]$Offset=0
# версия API
    $VerAPI = (GetVersionAPI -Params $Params)
    # если есть Query, то в нем убрать аргументы limit и
    # linit, offset по-умолчанию
    $h_limit=$Limit
    if ($Params.Params.ContainsKey('Query') -and $Params.Params.Query -and $Params.Params.Query.trim() ) {
        if ($Params.Params.Query -match '(?ins)(?<fc>\?|&|^)(?<lm>limit=)(?<dg>\d+)(?<lc>&|$)') {
            # есть limit в запросе, получить значение в переменную
            $h_limit = [int]$Matches.dg
        } else {
            # нет limit среди параметров запроса
            $Params.Params.Query += "&limit=$($Limit)"
        }
        $Pattern='(?ins)(?<fc>\?|&|^)(?<lm>offset=)(?<dg>\d+)(?<lc>&|$)'
        if ($Params.Params.Query -match $Pattern) {
            if ( -not $Params.Params.ContainsKey('UseInitialOffset') )  {
                # есть offset среди параметров запроса, установить значение в 0
                $Params.params.Query = ($Params.params.Query -replace $Pattern, '${fc}${lm}0${lc}')
            }
        } else {
            # нет offset среди параметров запроса
            $Params.Params.Query += "&offset=$($Offset)"
        }
    } else {
        # пустой или $null Query
        $Params.Params.Query = "limit=$($Limit)&offset=$($Offset)"
    }
    # Читать домены частями до конца
    # вернуть часть доменов
    $full_res = @()
    if ($VerAPI -eq 'v1') {
        do {
            $res_tmp = (Get-Domains -Params $Params -LogLevel $LogLevel)
            $full_res += $res_tmp.resDomains
            if ($res_tmp.raw.Headers.ContainsKey('x-total-count')) {
                $count = [int]($res_tmp.raw.Headers."x-total-count")
            } else {
                $count = 0
            }
            <#
            if ($res_tmp.raw.Headers.ContainsKey('x-limit')) {
                $h_limit = [int]($res_tmp.raw.Headers.'x-limit')
            }
            else {
                $h_limit = 0
            }
            #>
            if ($res_tmp.raw.Headers.ContainsKey('x-offset')) {
                $h_offset = [int]($res_tmp.raw.Headers.'x-offset')
            } else {
                $h_offset = 0
            }
            # заменить значения для аргументов &limit= и &offset=
            #$Params.params.Query = ($Params.params.Query -replace '(?ins)(?<fc>\?|&|^)(?<lm>limit=)(?<dg>\d+)(?<lc>&|$)', "`${fc}`${lm}$($h_limit)`${lc}")
            $Params.params.Query = ($Params.params.Query -replace '(?ins)(?<fc>\?|&|^)(?<lm>offset=)(?<dg>\d+)(?<lc>&|$)', "`${fc}`${lm}$($h_offset+$h_limit)`${lc}")
        } while ( $count -gt ($h_limit + $h_offset) )

    } elseif  ($VerAPI -eq 'v2') {
        # version API v2
        do {
            $res_tmp = (Get-Domains -Params $Params -LogLevel $LogLevel)
            $full_res += $res_tmp.resDomains.result
            # заменить значения для аргументов &limit= и &offset=
            #$h_limit=[int]$res_tmp.resDomains.next_offset
            $Params.params.Query = ($Params.params.Query -replace '(?ins)(?<fc>\?|&|^)(?<lm>offset=)(?<dg>\d+)(?<lc>&|$)', "`${fc}`${lm}$([int]$res_tmp.resDomains.next_offset)`${lc}")
        } while ($res_tmp.resDomains.next_offset -ne 0)
    } else {
        throw "Непподерживаемая версия API: $($VerAPI)"
    }

    $res_tmp.resDomains = $full_res
    Write-Verbose "content TO object: $($resultAPI.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res_tmp
}

function Get-Domains() {
    <#
    .DESCRIPTION
    Получить ресурсные записи домена.
    v1: GET /; https://api.selectel.ru/domains/v1/
    v2: GET /zones; https://api.selectel.ru/domains/v2/zones
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
        Обязательные ключи в HASHTABLE:
    нет
        Необязательные ключи в HASHTABLE:
    Params.Params.domain  - имя или id домена, будет выбираться данные только о нем
    Params.params.query   - аргументы для строки запроса (?arg=1&arg2=qwe&arg3=3...).
                            Может быть строкой, первый '?' не обязателен.
                            Может быть массивом @('arg=1', 'arg2=qwe', 'arg3=3', ...), будет преобразован в строку запроса
    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )
    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    # дополнительно для строки запроса и ее параметров
    # имя или ID домена, если есть в Params.AllDomains=$true , то принудительно вернуть весь список доменов для этого логина, игнорируя
    if ( -not [bool]$Params.AllDomains) {
        if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
            #$Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
            $id_dom = GetIdDomain -Params $Params -LogLevel $LogLevel
            $Params += @{'additionalUri' = "$($id_dom)"}
        }
    }
    #
    $Params += @{'queryGet' = ""}
    #$Params.queryGet += 'limit=1''&'''
    if ($Params.params.ContainsKey("query")) {
        $query = $Params.params.query
        if ($null -ne $query) {
            if ($query -is [string]) {
                # тип строка
                $Params.queryGet += $query
            } elseif ($query -is [Array]) {
                # тип массив строк
                $Params.queryGet += [String]::Join('&', $query)

            }
        }
    }

    $requestParams = @{
        "Params" = $Params;
        "Method" = "Get";
        "logLevel" = $LogLevel;
    }
    <#
    if ($Params.Params.Service) {
        $requestParams += @{"Service" = $Params.Params.Service}
    }
    #>
    $resultAPI = (Invoke-Request @requestParams)
    $res = @{
        'raw'  = $resultAPI;
        'code' = $resultAPI.StatusCode;
    }
    if ($res.Code -eq 200) { # OK
        $res += @{
            "resDomains" = ($resultAPI.Content | ConvertFrom-Json)
        }
    } else {
        throw $resultAPI.StatusDescription
    }
    Write-Verbose "content TO object: $($resultAPI.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  v1 and v2 #############################################################################################>
<###  Получить ресурсные записи домена                                                                    ###>
<############################################################################################################>
function Get-Records() {
    <#
    .DESCRIPTION
    Получить ресурсные записи домена
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
        Обязательные ключи в HASHTABLE:
    Params.Params.domain  - имя  или id домена
        Необязательные ключи в HASHTABLE:
    $Params.Params.record_id - id записи, будет выбрана только конкретная запись с этим id

    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    # дополнительно для строки запроса и ее параметров
    $VerAPI = (GetVersionAPI -Params $Params)
    # domain
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        #$Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
        $id_dom = GetIdDomain -Params $Params -LogLevel $LogLevel
        $Params += @{'additionalUri' = "$($id_dom)"}

    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо выбрать ресурсные записи."
        throw $mess
    }
    # record ID
    if ($Params.Params.ContainsKey("record_id") -and $Params.Params.record_id -and ([String]$Params.Params.record_id).Trim()) {
        $record_id = "/$($Params.Params.record_id)"
    } else {
        $record_id = ""
    }
    # параметры в строку запроса
    $Params += @{'queryGet' = ""}
    if ($Params.params.ContainsKey("query")) {
        $query = $Params.params.query
        if ($null -ne $query) {
            if ($query -is [string]) {
                # тип строка
                $Params.queryGet += $query
            } elseif ($query -is [Array]) {
                # тип массив строк
                $Params.queryGet += [String]::Join('&', $query)
            }
        }
    }
    # модификация url под версию API
    if ($VerAPI.ToLower() -eq 'v1') {
        $svcstr="records"
    } elseif ($VerAPI.ToLower() -eq 'v2') {
        $svcstr="rrset"
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
    }
    # параметры запроса
    $requestParams = @{
        "Params" = $Params;
        "Method" = "Get";
        "Service" = "$($svcstr)$($record_id)";
        "logLevel" = $LogLevel;
    }
    # запрос
    $resultAPI = (Invoke-Request @requestParams)
    # подготовка резальтата
    $res = @{
        'raw'  = $resultAPI;
        'code' = $resultAPI.StatusCode;
    }
    if ($res.Code -eq 200) { # OK
        $res += @{
            "resDomains" = ($resultAPI.Content | ConvertFrom-Json)
        }
    } else {
        throw $resultAPI.StatusDescription
    }
    # результат работы
    Write-Verbose "content TO object: $($resultAPI.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  ONLY v1     ###########################################################################################>
<###  v2 не поддерживается       ############################################################################>
<###  Экспорт данные о записях в формате ZONE BIND                                                        ###>
<############################################################################################################>
function Export-ToBind() {
    <#
    .DESCRIPTION
    Экспорт данных о ресурсных записях домена в формате zone Bind
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" Invoke-WebRequest.Content, текст в формате файла zone Bind для домена
    .PARAMETER Params
        Обязательные ключи в HASHTABLE:
    Params.Params.domain  - имя  или id домена
        Необязательные ключи в HASHTABLE:
    нет

    #>
    #Requires -Version 3
    [OutputType([String])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"
    
    $VerAPI = (GetVersionAPI -Params $Params)
    if ($VerAPI -ne 'v1') {
        throw "$($MyInvocation.InvocationName) не поддерживается версией $($VerAPI)"
    }

    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        $Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо сделать экспорт ресурсных записей."
        throw $mess
    }

    $requestParams = @{
        "Params" = $Params;
        "Method" = "Get";
        "Service" = "export";
        "logLevel" = $LogLevel;
    }

    $resultAPI = (Invoke-Request @requestParams)
    $res = @{
        'raw'  = $resultAPI;
        'code' = $resultAPI.StatusCode;
    }
    if ($res.Code -eq 200) { # OK
        $res += @{
            'resDomains' = $resultAPI.Content;
        }
    } else {
        throw $resultAPI.StatusDescription
    }

    Write-Verbose "Data to export: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  ONLY v1   #############################################################################################>
<###  Получить статус зоны на NS серверах Selectel: свойство disabled                                     ###>
<############################################################################################################>
function Get-State() {
    <#
    .DESCRIPTION
    Получить статус зоны на NS серверах Selectel
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" Статус зоны в json формате {"disabled": false (or true)}
    .PARAMETER Params
    Обязательные ключи в HASHTABLE:
        Params.Params.domain  - id домена
    Необязательные ключи в HASHTABLE:
        нет
    #>
    #Requires -Version 3
    [OutputType([String])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    $VerAPI = (GetVersionAPI -Params $Params)
    if ($VerAPI -eq 'v1') {
        # domain
        if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
            $Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
            #$id_dom = GetIdDomain -Params $Params -LogLevel $LogLevel
            #$Params += @{'additionalUri' = "$($id_dom)"}
        } else {
            $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо сделать экспорт ресурсных записей."
            throw $mess
        }
        # параметры запроса
        $requestParams = @{
            "Params" = $Params;
            "Method" = "Get";
            "Service" = "state";
            "logLevel" = $LogLevel;
        }
        # запрос
        $resultAPI = (Invoke-Request @requestParams)
        # обработка результата
        $res = @{
            'raw'  = $resultAPI;
            'code' = $resultAPI.StatusCode;
        }
        if ($res.Code -eq 200) { # OK
            $res += @{
                'resDomains' = ($resultAPI.Content | ConvertFrom-Json);
            }
        } else {
            throw $resultAPI.StatusDescription
        }
    } elseif ($VerAPI -eq 'v2') {
        #throw "$($MyInvocation.InvocationName) не поддерживается версией $($VerAPI)"
        $res = (Get-Domains -Params $Params -LogLevel $LogLevel)
        if ($res.Code -eq 200) { # OK
            $res.resDomains = @{"disabled"=$res.resDomains.disabled};
        } else {
            throw $res.StatusDescription
        }
    } else {
        throw "$($MyInvocation.InvocationName): Версия $($VerAPI) не поддерживается"
    }

    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  v1 and v2 #############################################################################################>
<############################################################################################################>
function Set-State() {
    <#
    .DESCRIPTION
    Изменить статус зоны на NS серверах Selectel
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" Статус зоны в json формате {"disabled": false (or true)}
    .PARAMETER Params
        Обязательные ключи в HASHTABLE:
    Params.Params.domain  - имя  или id домена
    Params.Params.state   - значение для статуса зоны true (disabled) или false (enabled). По-умолчанию: false 
        Необязательные ключи в HASHTABLE:
    нет
    #>
    #Requires -Version 3
    [OutputType([String])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"
    
    $VerAPI = (GetVersionAPI -Params $Params)

    # domain
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        #$Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
        $id_dom = GetIdDomain -Params $Params -LogLevel $LogLevel
        $Params += @{'additionalUri' = "$($id_dom)"}
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен, для которого надо отключить обслуживание."
        throw $mess
    }
    # state value
    $Body = @{"disabled" = [bool]$Params.params.disabled}
    $requestParams = @{
        "Params" = $Params;
        "Method" = "Patch";
        "Service" = "state";
        "Body" = $Body;
        "logLevel" = $LogLevel;
    }

    $resultAPI = (Invoke-Request @requestParams)
    $res = @{
        'raw'  = $resultAPI;
        'code' = $resultAPI.StatusCode;
    }
    if ($res.Code -eq 204) { # OK
        $res += @{
            'resDomains' = $resultAPI.Content;
        }
    } else {
        throw $resultAPI.StatusDescription
    }

    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  v1 and v2 #############################################################################################>
<############################################################################################################>
function Add-Record() {
    <#
    .DESCRIPTION
    Создать ресурсную запись для заданного домена
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain  - имя  или id домена
        Params.Params.record  - Словарь данных для описания ресурсной записи
        v1
            @{
                type = @('A');
                name = <имя>;
                ttl = <n>;
                Content = <ipv4_ADDRESS>;
            }
            @{
                type = @('CNAME');
                name = <имя>;
                ttl = <n>;
                Content = <имяREF>;
            }
        v2
            Из документации:
                RRSetCreateForm{
                    comment	string
                        maxLength: 255
                        title: Comment
                    name*	string
                        title: Name
                    records*	Records[
                        maxItems: 100
                        title: Records
                        Records{
                            content*	string
                                title: Content
                            disabled	boolean
                                default: false
                                title: Disabled
                        }
                    ]
                    ttl*	integer
                        maximum: 604800
                        minimum: 60
                        title: Ttl
                    type*   AllowedRecordTypes  string
                        title: AllowedRecordTypes
                        An enumeration.
                        Enum: [ A, AAAA, ALIAS, CAA, CNAME, DNAME, HTTPS, MX, NS, SOA, SRV, SVCB, SSHFP, TXT ]
                }
            @{
                type=<[ A, AAAA, ALIAS, CAA, CNAME, DNAME, HTTPS, MX, NS, SOA, SRV, SVCB, SSHFP, TXT ]>;
                name=<имя>;
                ttl=<n>;
                records=@(
                    {content=<IP>},
                    {disabled=false}
                )
                comment="Text comment";
            }

        Необязательные ключи в HASHTABLE:

    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    $VerAPI = (GetVersionAPI -Params $Params)

    # domain
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        #$Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
        $id_dom = GetIdDomain -Params $Params -LogLevel $LogLevel
        $Params += @{'additionalUri' = "$($id_dom)"}
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо добавить ресурсную запись."
        throw $mess
    }
    # готовим Body для ресурсной записи
    $record = @{};
    $messError = ""
    $record = $Params.params.record
    if ($null -ne $record -and ($record -is [hashtable]) -or ($record -is [PSCustomObject]) -or ($record -is [psobject])  ) {
        $Body = $record
    } else {
        $messError = "Запрос не может быть выполнен. Не определены или неверно заданы параметры ресурсной записи для домена $($Params.Params.record)."
    }
    if ($messError) {
        throw $messError
    }
    # Service
    if ($VerAPI.ToLower() -eq 'v1' ) {
        $svcstr="records"
    } elseif ($VerAPI.ToLower() -eq 'v2') {
        $svcstr="rrset"
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
    }
    #
    $requestParams = @{
        "Params" = $Params;
        "Method" = "POST";
        "Service" = "$($svcstr)";
        "Body" = $Body;
        "logLevel" = $LogLevel;
    }

    $resultAPI = (Invoke-Request @requestParams)
    $res = @{
        'raw'  = $resultAPI;
        'code' = $resultAPI.StatusCode;
    }
    if ($res.Code -eq 200) { # OK
        $res += @{
            'resDomains' = $resultAPI.Content;
        }
    } else {
        throw $resultAPI.StatusDescription
    }

    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  v1 and v2 #############################################################################################>
<############################################################################################################>
function Remove-Record() {
    <#
    .DESCRIPTION
    Удалить ресурсную запись для заданного домена
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain    - имя  или id домена
        Params.Params.record_id - id ресурсной записи, которую надо удалить
    Необязательные ключи в HASHTABLE:

    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    $VerAPI = (GetVersionAPI -Params $Params)

    # domain
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        #$Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
        $id_dom = GetIdDomain -Params $Params -LogLevel $LogLevel
        $Params += @{'additionalUri' = "$($id_dom)"}
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо добавить ресурсную запись."
        throw $mess
    }
    # record_id
    if ($Params.Params.ContainsKey("record_id") -and $Params.Params.record_id -and ([String]$Params.Params.record_id).Trim()) {
        $record_id = "/$($Params.Params.record_id)"
    } else {
        $messError = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.record_id> - id ресурсной записи для удаления."
        throw $messError
    }
    # Service
    if ($VerAPI.ToLower() -eq 'v1' ) {
        $svcstr="records"
    } elseif ($VerAPI.ToLower() -eq 'v2') {
        $svcstr="rrset"
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
    }
    #
    $requestParams = @{
        "Params" = $Params;
        "Method" = "DELete";
        "Service" = "$($svcstr)$($record_id)";
        "logLevel" = $LogLevel;
    }

    $resultAPI = (Invoke-Request @requestParams)
    $res = @{
        'raw'  = $resultAPI;
        'code' = $resultAPI.StatusCode;
    }
    if ($res.Code -eq 204) { # OK
        $res += @{
            'resDomains' = $resultAPI.Content;
        }
    } else {
        throw $resultAPI.StatusDescription
    }

    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  v1 and v2 #############################################################################################>
<############################################################################################################>
function Set-Record() {
    <#
    .DESCRIPTION
    Обновить ресурсную запись для заданного домена
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain    - имя  или id домена
        Params.Params.record_id - id ресурсной записи, которую надо обновить
    Необязательные ключи в HASHTABLE:
    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    $VerAPI = (GetVersionAPI -Params $Params)

    # domain
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        #$Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
        $id_dom = GetIdDomain -Params $Params -LogLevel $LogLevel
        $Params += @{'additionalUri' = "$($id_dom)"}
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо добавить ресурсную запись."
        throw $mess
    }
    # record_id
    if ($Params.Params.ContainsKey("record_id") -and $Params.Params.record_id -and ([String]$Params.Params.record_id).Trim()) {
        $record_id = "/$($Params.Params.record_id)"
    } else {
        $messError = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.record_id> - id ресурсной записи для обновления."
        throw $messError
    }
    # готовим Body для ресурсной записи
    $record = @{};
    $messError = ""
    $record = $Params.params.record
    if ($null -ne $record -and ($record -is [hashtable]) -or ($record -is [PSCustomObject]) -or ($record -is [psobject])  ) {
        $Body = $record
    } else {
        $messError = "Запрос не может быть выполнен. Не определены или неверно заданы параметры ресурсной записи для домена $($Params.Params.record)."
    }
    if ($messError) {
        throw $messError
    }
    #
    # Service
    if ($VerAPI.ToLower() -eq 'v1' ) {
        $Method='Put'
        $svcstr="records"
    } elseif ($VerAPI.ToLower() -eq 'v2') {
        $Method='Patch'
        $svcstr="rrset"
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
    }
    $requestParams = @{
        "Params" = $Params;
        "Method" = $Method;
        "Service" = "$($svcstr)$($record_id)";
        "Body" = $Body;
        "logLevel" = $LogLevel;
    }

    $resultAPI = (Invoke-Request @requestParams)
    $res = @{
        'raw'  = $resultAPI;
        'code' = $resultAPI.StatusCode;
    }
    if ( ($res.Code -eq 200) -or ($res.Code -eq 204) ) { # OK
        $res += @{
            'resDomains' = $resultAPI.Content;
        }
    } else {
        throw $resultAPI.StatusDescription
    }

    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  ONLY v2 ###############################################################################################>
<############################################################################################################>
function Set-Domain() {
    <#
    .DESCRIPTION
    Обновить данные для заданного домена
    Поддерживается только API v2
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain        - имя  или id домена
        Params.Params.domain_data   - Hashtable, данные для домена:
                                    {
                                        "comment"=<String>
                                    }
    Необязательные ключи в HASHTABLE:
    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"
    # версия API
    $VerAPI = (GetVersionAPI -Params $Params)
    if ($VerAPI.ToLower() -eq 'v2' ) {
        # domain
        if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
            #$Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
            $d_id = GetIdDomain -Params $Params -LogLevel $LogLevel
            $Params += @{'additionalUri' = "$($d_id)"}
        } else {
            $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо обновить данные."
            throw $mess
        }
        # готовим Body, данные для записи, для домена
        $domain_data = @{};
        $messError = ""
        $domain_data = $Params.params.domain_data
        if ($null -ne $domain_data -and ($domain_data -is [hashtable]) -or ($domain_data -is [PSCustomObject]) -or ($domain_data -is [psobject])  ) {
            $Body = $domain_data
        } else {
            $messError = "Запрос не может быть выполнен. Не определены или неверно заданы параметры ресурсной записи для домена $($Params.Params.domain_data)."
        }
        if ($messError) {
            throw $messError
        }
        #
        # Method
        $Method='Patch'
        # параметры запроса
        $requestParams = @{
            "Params" = $Params;
            "Method" = $Method;
            "Service" = "";
            "Body" = $Body;
            "logLevel" = $LogLevel;
        }
        $resultAPI = (Invoke-Request @requestParams)
        $res = @{
            'raw'  = $resultAPI;
            'code' = $resultAPI.StatusCode;
        }
        if ( ($res.Code -eq 200) -or ($res.Code -eq 204) ) { # OK
            $res += @{
                'resDomains' = $resultAPI.Content;
            }
        } else {
            throw $resultAPI.StatusDescription
        }
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
    }
    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  ONLY v2 ###############################################################################################>
<############################################################################################################>
function Add-Domain() {
    <#
    .DESCRIPTION
    Добавить заданный домен
    Поддерживается только API v2
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain        - имя домена, который надо создать
    Необязательные ключи в HASHTABLE:
    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"
    # версия API
    $VerAPI = (GetVersionAPI -Params $Params)
    if ($VerAPI.ToLower() -eq 'v2' ) {
        # domain
        if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim() -and [String]$Params.Params.Domain.Contains('.') ) {
            $Body=@{"name"="$(([String]$Params.Params.Domain).Trim())"}
        } else {
            $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен который надо создать."
            throw $mess
        }
        # Method
        $Method='Post'
        # параметры запроса
        $requestParams = @{
            "Params" = $Params;
            "Method" = $Method;
            "Service" = "";
            "Body" = $Body;
            "logLevel" = $LogLevel;
        }
        $resultAPI = (Invoke-Request @requestParams)
        $res = @{
            'raw'  = $resultAPI;
            'code' = $resultAPI.StatusCode;
        }
        if ( ($res.Code -eq 200) -or ($res.Code -eq 204) ) { # OK
            $res += @{
                'resDomains' = $resultAPI.Content;
            }
        } else {
            throw $resultAPI.StatusDescription
        }
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
    }
    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  ONLY v2 ###############################################################################################>
<############################################################################################################>
function Remove-Domain() {
    <#
    .DESCRIPTION
    Удалить заданный домен
    Поддерживается только API v2
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain        - имя домена или ID, который надо удалить
    Необязательные ключи в HASHTABLE:
    #>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"
    # версия API
    $VerAPI = (GetVersionAPI -Params $Params)
    if ($VerAPI.ToLower() -eq 'v2' ) {
        # domain
        if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim() -and [String]$Params.Params.Domain.Contains('.') ) {
            $d_id = GetIdDomain -Params $Params -LogLevel $LogLevel
            $Params += @{'additionalUri' = "$($d_id)"}
        } else {
            $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен который надо удалить."
            throw $mess
        }
        # Service
        $Method='Delete'
        $requestParams = @{
            "Params" = $Params;
            "Method" = $Method;
            "Service" = "";
            "logLevel" = $LogLevel;
        }
        $resultAPI = (Invoke-Request @requestParams)
        $res = @{
            'raw'  = $resultAPI;
            'code' = $resultAPI.StatusCode;
        }
        if ( $res.Code -eq 204 ) { # OK
            $res += @{
                'resDomains' = $resultAPI.Content;
            }
        } else {
            throw $resultAPI.StatusDescription
        }
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
    }
    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

function Invoke-Request() {
    <#
    .DESCRIPTION
    Выполнить HTTP запрос
    .OUTPUTS
    Name: res
    BaseType: [Microsoft.PowerShell.Commands.HtmlWebResponseObject]
    .PARAMETER Params
        - Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
            Ключи в Params.params:
            - sectionData   [Hashtable]

            Params.Params.domain    - имя  или id домена
            Params.Params.record_id - id ресурсной записи, которую надо обновить
        Необязательные ключи в HASHTABLE:
        - Params.sectionData [HASHTABLE]
            параметры для формирования структур для API и вызов API.
            Получили ее из INI-файла с помощью [FileCFG]::getSectionValues
            - sectionData.BaseUri: "https://api.selectel.ru"    , ОБЯЗАТЕЛЬНЫЙ
            - sectionData.ServiceUri: "/domains/v1/"            , ОБЯЗАТЕЛЬНЫЙ
                Используются для формирования строки запроса:
                Params.sectionData.BaseUri+Params.sectionData.ServiceUri+Params.additionalUri+Service+params.queryGet
            - params.additionalUri  [String]                    , НЕОБЯЗАТЕЛЬНЫЙ
                Используются для формирования строки запроса:
                Params.sectionData.BaseUri+Params.sectionData.ServiceUri+Params.additionalUri+Service+params.queryGet
            - params.queryGet       [String]                    , НЕОБЯЗАТЕЛЬНЫЙ
                Параметры для строки запроса (?arg=1&arg2=qwe&arg3=3...).
                Может быть строкой, первый '?' не обязателен.
                Может быть массивом @('arg=1', 'arg2=qwe', 'arg3=3', ...), будет преобразован в строку запроса
                Используются для формирования строки запроса:
                Params.sectionData.BaseUri+Params.sectionData.ServiceUri+Params.additionalUri+Service+params.queryGet
            - params.Headers       [HASHTABLE]                    , НЕОБЯЗАТЕЛЬНЫЙ
                Содержит заголовки для запроса
    .PARAMETER Method
    Метод HTTP для вызова API
    .PARAMETER Service
    Используются для формирования строки запроса:
        Params.sectionData.BaseUri+Params.sectionData.ServiceUri+Params.additionalUri+Service+params.queryGet

    #>
    #Requires -Version 3
    [OutputType([Microsoft.PowerShell.Commands.HtmlWebResponseObject])]
    [CmdletBinding(DefaultParameterSetName='UseCredential')]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Parameter(Position=1)]
        [ValidateSet('Get','Post','Put','Delete', 'Patch')]
        [String] $Method="Get",
        [Parameter(Position=2)]
        [string] $Service,
        $Body=$null,
        [Int] $LogLevel=1
    )    
    
    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры:"
    Write-Verbose "Params: $($Params | ConvertTo-Json -Depth $LogLevel)"
    Write-Verbose "Method: $($Method)"
    Write-Verbose "Service: $($Service)"
    Write-Verbose "Body: $($Body)"
    Write-Verbose "LogLevel: $($LogLevel)"

    #$verAPI = ([string]$Params.sectionData.result.version).Trim()
    $verAPI = GetVersionAPI($Params)
    $p = @{}
    #$p += $Params.sectionData.result."config_$($verAPI)";
    $p += $Params.sectionData.result."config$(if ($verAPI) {""_$($verAPI)""})"

    # подготовка строки запроса
    $uri = $p.baseUri
    while ($uri.EndsWith("/")) {
        $uri = $uri.Remove($uri.length-1)
    }
    $svcUri = $p.ServiceUri
    while ($svcUri.StartsWith("/")) {
        $svcUri = $svcUri.Remove(0, 1)
    }
    while ($svcUri.EndsWith("/")) {
        $svcUri = $svcUri.Remove($svcUri.length-1)
    }
    $uri = "$($uri)/$($svcUri)/"
    # доп. строки к URI
    if ($Params.ContainsKey("additionalUri") -and $Params.additionalUri -and $Params.additionalUri.Trim()) {
        $additionalUri = $Params.additionalUri.Trim()
        while ($additionalUri.StartsWith("/")) {
            $additionalUri = $additionalUri.Remove(0, 1)
        }
        while ($additionalUri.EndsWith("/")) {
            $additionalUri = $additionalUri.Remove($additionalUri.length-1)
        }
        $uri = "$($uri)$($additionalUri)/"
    }
    if ($Service) {
        $uri = "$($uri)$($Service)/"
    }
    # параметры к строке запроса (GET например: ?p1=v1&p2=v2&p3=v3)
    if ($Params.ContainsKey("queryGet") -and ($Method.ToLower() -eq "get") -and $Params.queryGet -and $Params.queryGet.Trim()) {
        $queryGet = $Params.queryGet.Trim()
        while ($queryGet.StartsWith("/")) {
            $queryGet = $queryGet.Remove(0, 1)
        }
        while ($queryGet.EndsWith("/")) {
            $queryGet = $queryGet.Remove($queryGet.length-1)
        }
        if (-not $queryGet.StartsWith("?")) {
            $queryGet = "?$($queryGet)"
        }
        $uri = "$($uri)$($queryGet)"
    }
    Write-Verbose "Подготовленный URI для запроса: $($uri)"

    # подготовка HEADERS
    if ($verAPI.ToLower() -eq 'v1') {
        $AuthHeader = 'X-Token'
    } elseif ($verAPI.ToLower() -eq 'v2') {
        $AuthHeader = 'X-Auth-Token'
    } else {
        $AuthHeader = 'X-Token'
    }
    $h = @{
        #'X-Token' = "$($p.Token)";
        "$AuthHeader" = "$(Get-TokenDNSSelectel -section $p -verAPI $verAPI -LogLevel $LogLevel)";
        'Content-Type' = 'application/json'
    }
    # Дополнительно Headers из параметров
    if ($Params.ContainsKey("Headers") -and ($Params.Headers -is [hashtable])) {
        $Params.Headers.Keys.foreach({
            $h += @{"$($_)"=$($Params.Headers."$($_)")}
        })
    }

    $splatParam = @{
        "Method"  = $Method;
        "Headers" = $h;
        "Uri"     = $uri;
    }

    # подготовка тела запроса Body
    if ($Method.ToLower() -notin @('get', 'delete')) {
        # пропустить для -Method GET, DELETE
        if ( ($Body -is [hashtable] -or $Body -is [psobject] -or $Bosy -is [PSCustomObject]) -and ($null -ne $Body) ) {
            $Body = ($Body | ConvertTo-Json)
        } elseif ($Body -is [string] -and $Body -and $Body.Trim()) {
            $Body = $Body
        } else {
            throw "Невозможно выполнить вызов REST API. Параметер -Body имеет неверный тип: $($Body.GetType())`nили неверное значение: $($Body)`nТип может быть одним из:[Hashtable], [PSObject], [PSCustomObject], [String]"
        }
    } else {
        $Body = $null
    }
    if ( -not ( ($null -eq $Body) -or ($Body.Trim() -eq "") ) ) {
        $splatParam += @{"Body" = $Body}
    }
    # вызов REST API
    try {
        $res = Invoke-WebRequest @splatParam
    }
    catch {
        if ($PSItem.ErrorDetails) {
            $s = $PSItem.ErrorDetails.Message
            #Write-Error $s
            Write-Warning $s
        }
        $res = [ordered]@{
            "StatusCode" = 0;
            "StatusDescription" = "";
            "Content" = "";
            "Headers" = @{};
            "RawContentLength" = 0;
        }
        if ($s -match '^\s*(\d+)') {
            $res.StatusCode = $Matches.1
            $res.StatusDescription = $s
            $res.Content = ""
        } else {
            $res.StatusCode = 599
            $res.StatusDescription = "Undefined error: $($s)"
            $res.Content = ""
        }
        #throw $PSItem
    }
    #Write-Verbose "res after request API: $($res|ConvertTo-Json -depth 4)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

############# Private functions
function Get-TokenDNSSelectel() {
    <#
    .DESCRIPTION
    Вернуть токен Keystone или API Selectel
    .OUTPUTS
    Name: res
    BaseType: String
    .PARAMETER Params
        - Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
            Ключи в Params.params:
            - sectionData   [Hashtable]

            Params.Params.domain    - имя  или id домена
            Params.Params.record_id - id ресурсной записи, которую надо обновить
        Необязательные ключи в HASHTABLE:
        - Params.sectionData [HASHTABLE]
            параметры для формирования структур для API и вызов API.
            Получили ее из INI-файла с помощью [FileCFG]::getSectionValues
            - sectionData.BaseUri: "https://api.selectel.ru"    , ОБЯЗАТЕЛЬНЫЙ
            - sectionData.ServiceUri: "/domains/v1/"            , ОБЯЗАТЕЛЬНЫЙ
                Используются для формирования строки запроса:
                Params.sectionData.BaseUri+Params.sectionData.ServiceUri+Params.additionalUri+Service+params.queryGet
            - params.additionalUri  [String]                    , НЕОБЯЗАТЕЛЬНЫЙ
                Используются для формирования строки запроса:
                Params.sectionData.BaseUri+Params.sectionData.ServiceUri+Params.additionalUri+Service+params.queryGet
            - params.queryGet       [String]                    , НЕОБЯЗАТЕЛЬНЫЙ
                Параметры для строки запроса (?arg=1&arg2=qwe&arg3=3...).
                Может быть строкой, первый '?' не обязателен.
                Может быть массивом @('arg=1', 'arg2=qwe', 'arg3=3', ...), будет преобразован в строку запроса
                Используются для формирования строки запроса:
                Params.sectionData.BaseUri+Params.sectionData.ServiceUri+Params.additionalUri+Service+params.queryGet
            - params.Headers       [HASHTABLE]                    , НЕОБЯЗАТЕЛЬНЫЙ
                Содержит заголовки для запроса
    #>
    #Requires -Version 3
    [OutputType([String])]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Section,
        [Parameter(Mandatory=$true, Position=1)]
        [string] $VerAPI,
        [Int] $LogLevel=1
    )
    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры:"
    Write-Verbose "section: $($Section | ConvertTo-Json -Depth $LogLevel)"
    Write-Verbose "verAPI: $($VerAPI)"
    Write-Verbose "LogLevel: $($LogLevel)"
    if ($verAPI.ToLower() -eq "v2") {
        $res = $null
        # Сначала получить Token Keystone
        $diffTime=(Get-Date) - $Token_Current.DateToken
        $getFromEnv=[bool]([int]$Section.token_use_env)
        if (
            ($Section."user_name" -eq $Token_Current.Username) -and
            ($Section."user_id" -eq $Token_Current.UserID) -and
            ($Section."project_name" -eq $Token_Current.ProjectName) -and
            # 1 day  - 5 minute
            ( $diffTime.TotalMinutes -gt 0 -and $diffTime.TotalMinutes -lt (24*60-5) )
           )
        {
            Write-Verbose "Пробуем взять ранее полученный Token Keystone"
            # взять уже полученный токен
            $res = $Token_Current.TokenKeystone
            Write-Verbose "Получили токен Keystone из переменной модуля"
        }
        if ($null -eq $res -and $getFromEnv) {
            # пробуем взять в переменных среды
            Write-Verbose "Пробуем взять Token Keystone в переменных среды"
            $tok=[System.Environment]::GetEnvironmentVariable("TokenSelectel",[System.EnvironmentVariableTarget]::User)
            if ($null -ne $tok) {
                $ats=$tok.split(';')
                $diffTime=(Get-Date) - (Get-Date $ats[4])
                if ( $ats[1].ToLower() -eq $Section.user_name.ToLower() -and
                    $ats[2] -eq $Section.user_id -and
                    $ats[3].ToLower() -eq $Section.project_name.ToLower() -and
                    ( $diffTime.TotalMinutes -gt 0 -and $diffTime.TotalMinutes -lt 24*60-5 )
                ) {
                    $res=$ats[0]
                } else {
                    [System.Environment]::SetEnvironmentVariable("TokenSelectel", $null, [System.EnvironmentVariableTarget]::User)
                }
            }
            # TODO пока не готово
        }
        if ($null -eq $res) {
            $p=@{}
            $p.UserName = $Section.user_name
            $p.UserID = $Section.user_id
            $p.ProjectName = $Section.project_name
            $p.Pswd = $Section.user_pswd
            if ( ($null -ne $Section.auth_uri) -and $Section.auth_uri.trim()) {
                $p.AuthURI = $Section.auth_uri
            }
            $res = Invoke-AuthSelectel @p
            $Token_Current.TokenKeystone = $res
            $Token_Current.Username = $Section.user_name
            $Token_Current.UserID = $Section.user_id
            $Token_Current.ProjectName = $Section.project_name
            $Token_Current.DateToken = (Get-Date)
            if ($getFromEnv) {
                [System.Environment]::SetEnvironmentVariable("TokenSelectel", "$($res);$($Section.user_name);$($Section.user_id);$($Section.project_name);$(Get-Date -Format 'dd-MM-yyyy HH:mm:ss')", [System.EnvironmentVariableTarget]::User)
            }
        }
    } elseif ($verAPI.ToLower() -eq "v1") {
        <# Action when this condition is true #>
        $res = "$($section.Token)"
    } else {
        throw "Невозможно получить токен для авторизации в REST API. Параметер -verAPI имеет неверное значение: $($verAPI)"
    }
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

function Invoke-AuthSelectel() {
    <#
    .DESCRIPTION
    Авторизоваться сервисным пользователем в проекте и получить Token Keystone для проекта
    #>
    #Requires -Version 3
    [OutputType([String])]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [String] $UserName,
        [Parameter(Mandatory=$true, Position=1)]
        [String] $UserID,
        [Parameter(Mandatory=$true, Position=2)]
        [String] $ProjectName,
        [Parameter(Mandatory=$true, Position=3)]
        [String] $Pswd,
        [String] $AuthURI="https://cloud.api.selcloud.ru/identity/v3/auth/tokens",
        [Int] $LogLevel=1
    )
    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="

    $h=@{'Content-Type'='application/json'}
    $b="{""auth"":{
            ""identity"":{
                ""methods"":[""password""],
                ""password"":{
                    ""user"":{
                        ""name"":""$($UserName)"",
                        ""domain"":{
                            ""name"":""$($UserID)""
                        },
                        ""password"":""$($Pswd)""
                    }
                }
            },
            ""scope"":{
                ""project"":{
                    ""name"":""$($ProjectName)"",
                    ""domain"":{
                        ""name"":""$($UserID)""
                    }
                }
            }
        }
    }"
    $rt=Invoke-WebRequest -Method Post -Uri $AuthURI -Headers $h -Body $b
    $res = $rt.Headers."x-subject-token"

    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<############################################################################################################>
<############################################################################################################>
function GetVersionAPI() {
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params
    )
    return ([string]$Params.sectionData.result.version).Trim().ToLower()
}


function GetIdDomain(){
    <#
    .DESCRIPTION
    Вернуть ID домена по имени. Параметр может быть или именем домена или его ID.
    .OUTPUTS
    Name: res
    BaseType: String
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain        - имя  или id домена.
                                      Если в значении есть символ '.', то это имя и требуется найти его ID,
                                      иначе считается, что это ID и надо его вернуть
    Необязательные ключи в HASHTABLE:
    #>
    #Requires -Version 3
    [OutputType([String])]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )
    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ============================================="

    $VerAPI = (GetVersionAPI -Params $Params)

    if ( (-not $Params.ContainsKey('params')) -or (-not $Params.params.ContainsKey('domain')) ) {
        throw("Не передан обязательный параметр Params.params.domain")
    }
    $domain = $Params.params.domain
    if ( $null -eq $domain) {
        throw("Обязательный параметр Params.params.domain не может быть null")
    }
    if ($domain -isnot [string]) {
        throw("Обязательный параметр Params.params.domain имеет неверный тип, должен быть String")
    } 
    $domain = $domain.trim().ToLower()
    if ($domain -eq "") {
        throw("Обязательный параметр Params.params.domain не может быть пустым")
    }
    # определить ID домена, если требуется
    if ($verAPI.ToLower() -eq 'v2') {
        # ver API v2
        if ($domain.Contains('.')) {
            # в Params.params.domain было передано имя и надо для него получть ID
            $Params.AllDomains = $true;
            if ($Params.params.ContainsKey('Service')) {
                $Params.params.service = '';
            }
            $list_domains = Get-Domains -Params $Params -LogLevel $LogLevel
            $Params.Remove('AllDomains');
            if ($VerAPI -eq 'v2') {
                if ( -not $domain.EndsWith('.')) {
                    $domain += '.'
                }
            }
            $res=''
            if ($list_domains.code -eq 200) {
                # получили список доменов без ошибок
                if ($VerAPI -eq 'v1') {
                    $ar = $list_domains.resDomains
                } elseif ($VerAPI -eq 'v2') {
                    $ar = $list_domains.resDomains.result
                } else {
                    throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
                }
                foreach ($dom in $ar) {
                    if ($domain -eq $dom.Name.ToLower()) {
                        $res = $dom.id
                        break
                    }
                }
            }
            if ($res -eq '') {
                throw ("Не нашли ID для домена $($domain), нет такой зоны в хостинге DNS $($Param.provider)")
            }
        } else {
            # в Params.params.domain был передан ID, его и возвращаем
            $res = $domain
        }
    } else {
        # ver API отличный от v2
        $res = $domain
    }
    # результат
    Write-Verbose "Возвращаемое значение (res): $($res)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

#Set-Alias -Value Get-Domains -Name domains
#Export-ModuleMember -Function Invoke-API -Alias domains
#Export-ModuleMember -Function Invoke-API
#Export-ModuleMember -Function *

if ( ($null -eq (Get-Variable Token_Current -ErrorAction SilentlyContinue)) -or ($Token_Current -isnot [hashtable])) {
    $global:Token_Current=@{
        Username='';
        UserID='';
        ProjectName='';
        TokenKeystone='';
        DateToken=[datetime](Get-Date -Date "1.1.0 0:0:0")
    }
}
