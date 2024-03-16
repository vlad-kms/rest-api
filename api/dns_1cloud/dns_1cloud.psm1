<# ############################################################################################## #>
<# ############################################################################################## #>
<# ############################################################################################## #>
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
                    #$command = "$(if (-not $fileIsDotSourcing) {""$($Provider)\""})$($suppFunc.""$($Action)"")  $(if ($PSBoundParameters.Verbose) {"-Verbose"}) -LogLevel $($LogLevel) -Params " + '$($Params)'
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

<# ############################################################################################## #>
<# ############################################################################################## #>
<# ############################################################################################## #>
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
    $result.GetEnumerator().Name | ForEach-Object {
        if ( -not $result.$_.Trim() ) {
            $result."$($_)" = $_
        }
    }
    Write-Verbose "result: $($result | ConvertTo-Json)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $result
}

<# ############################################################################################## #>
<# ############################################################################################## #>
<# ############################################################################################## #>
function Get-Domains() {
    <#
    .DESCRIPTION
    Список доменов (зон) со списком всех ресурсных записей домена
    GET ::: https://api.1cloud.ru/dns
    GET ::: https://api.1cloud.ru/dns/<id_domain>
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
                ID          number  Уникальный идентификатор домена
                Name        string  Наименование домена
                TechName    string  Техническое наименование домена
                State       string  Статус домена на момент обработки запроса. Может содержать следующие значения:
                                    New:    создание домена на DNS 1cloud
                                    Active: домен активен
                DateCreate  DateTime    Дата создания домена
                IsDelegate  string  Состояние делегирования доменного имени под управление dns серверами 1cloud
                                    true: домен делегирован
                                    false: домен не делегирован
                                    null: нет информации о делегировании
                LinkedRecords   list    Список записей, которые ассоциированы с данным доменом. Содержит список объектов, каждый из которых имеет следующие атрибуты:
                                        ID: уникальный идентификатор записи
                                        TypeRecord: тип записи, может содержать следующие значения: A, AAAA, MX, CNAME, TXT, NS, SRV
                                        IP: IP адрес
                                        HostName: @ - если запись создана для домена, или наименование поддомена, если запись создана для него
                                        Priority: приоритет записи, актуально только для MX и SRV записей
                                        Text: текст записи, актуально только для TXT записей
                                        MnemonicName: мнемоническое имя, актуально только для CNAME записей
                                        ExtHostName: наименование внешнего к 1cloud хоста, актуально для MX или NS записей
                                        Weight: относительный вес для записей с одинаковым приоритетом, актуально для SRV записей
                                        Port: порт на котором работает сервис, актуально для SRV записей
                                        Target: канонические имя машины, предоставляющей сервис, актуально для SRV записей
                                        Proto: транспортный протокол используемый сервисом, актуально для SRV записей
                                        Service: символьное имя сервиса, предоставляющей сервис, актуально для SRV записей
                                        TTL: Длительность кэширования записи, в секундах
                                        State:
                                            New: создание записи на DNS 1cloud
                                            Active: запись активна
                                        Дата создания записи
                                        CanonicalDescription: каноническое описание dns записи
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
        Обязательные ключи в HASHTABLE:
    нет
        Необязательные ключи в HASHTABLE:
    Params.Params.domain  - имя  или id домена, будет выбираться данные только о нем
    Params.Params.Service - имя  или id домена, будет выбираться данные только о нем. Может использоваться или domain, или Service.
                            Два одновременно не могут использоваться, будет ошибка
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
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        $Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
    }
    $requestParams = @{
        "Params" = $Params;
        "Method" = "Get";
        "logLevel" = $LogLevel;
    }
    if ($Params.Params.Service) {
        $requestParams += @{"Service" = $Params.Params.Service}
    }
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

<# ############################################################################################## #>
<# ############################################################################################## #>
<# ############################################################################################## #>
function Get-Record() {
    <#
    .DESCRIPTION
    Получить ресурсную запись домена
    GET ::: https://api.1cloud.ru/dns/record/<id_record>
    .OUTPUTS
    Name: res
    BaseType: Hashtable
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject
            Данные ресурсной записи
                ID: уникальный идентификатор записи
                TypeRecord: тип записи, может содержать следующие значения: A, AAAA, MX, CNAME, TXT, NS, SRV
                IP: IP адрес
                HostName: @ - если запись создана для домена, или наименование поддомена, если запись создана для него
                Priority: приоритет записи, актуально только для MX и SRV записей
                Text: текст записи, актуально только для TXT записей
                MnemonicName: мнемоническое имя, актуально только для CNAME записей
                ExtHostName: наименование внешнего к 1cloud хоста, актуально для MX или NS записей
                Weight: относительный вес для записей с одинаковым приоритетом, актуально для SRV записей
                Port: порт на котором работает сервис, актуально для SRV записей
                Target: канонические имя машины, предоставляющей сервис, актуально для SRV записей
                Proto: транспортный протокол используемый сервисом, актуально для SRV записей
                Service: символьное имя сервиса, предоставляющей сервис, актуально для SRV записей
                TTL: Длительность кэширования записи, в секундах
                State:
                    New: создание записи на DNS 1cloud
                    Active: запись активна
                Дата создания записи
                CanonicalDescription: каноническое описание dns записи
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
        Обязательные ключи в HASHTABLE:
    $Params.Params.record_id - id записи,  по которой нгадо вернуть данные
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
    # record_id
    if ($Params.Params.ContainsKey("record_id") -and $Params.Params.record_id -and ([String]$Params.Params.record_id).Trim()) {
        $record_id = "/$($Params.Params.record_id)"
    } else {
        $messError = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.record_id> - id ресурсной записи для поиска."
        throw $messError
    }

    $requestParams = @{
        "Params" = $Params;
        "Method" = "Get";
        "Service" = "record$($record_id)";
        "logLevel" = $LogLevel;
    }

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

<# ############################################################################################## #>
<# ############################################################################################## #>
<# ############################################################################################## #>
function Add-Records() {
    <#
    .DESCRIPTION
    Создать ресурсную запись для заданного домена
    .OUTPUTS
    Name: res
    BaseType: [Array[Hashtable]]
        {
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject, если ответ был успешный, иначе отсутствует
        },...
    Ответ содержит добавленные данные (или ошибку) для каждой записи
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.records  - массив структур ресурсных записей для создания
            @(
                @{
                    domainId = <id_domain>  - id домена в котором наджо создать запись
                                            если отсутствует, то будем брать из Params.Params.domain,
                                            если отсутствует, то будем брать из Params.Params.Service
                    type = 'A';
                    Content = <ipv4_ADDRESS>;
                    name = <name>;
                    ttl = <n>;
                },
                @{
                    domainId = <id_domain>
                    type = 'CNAME';
                    Content = <name>;
                    name = <mnemonic_name>;
                    ttl = <n>;
                }
            )
    Необязательные ключи в HASHTABLE:
        Params.Params.service - имя  или id домена по-умолчанию, если в элементе массива отстутствует DomainId, то используется это значение. Самый низкий приоритет"
        Params.Params.domain  - имя  или id домена по-умолчанию, если в элементе массива отстутствует DomainId, то используется это значение. 2-й приоритет
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

    # вычисляем domain по-умолчанию, который будем дополнять в ресурсную запись при отсутствии домена в данных
    $DomainDef = ""
    if ($Params.Params.ContainsKey("Service") -and $Params.Params.Service -and ([String]$Params.Params.Service).Trim()) {
        $DomainDef = ([String]$Params.Params.Service).Trim()
    }
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        $DomainDef = ([String]$Params.Params.Domain).Trim()
    }
    Write-Verbose "Domain по-умолчанию: $($DomainDef)"

    $resArray = @()

    # цикл для каждой переданной ресурсной записи
    $Params.params.records.foreach({
        Write-Verbose "$($_|ConvertTo-Json -Depth $LogLevel)"
        if ($_.Type.ToUpper() -eq "A") {
            $Service = 'recorda'
            $_.IP = $_.Content
        } elseif ($_.Type.ToUpper() -eq "AAAA") {
            $Service = 'recordaaaa'
            $_.IP = $_.Content
        } elseif ($_.Type.ToUpper() -eq "CNAME") {
            $Service = 'recordcname'
            $_.MnemonicName = $_.Name
            $_.Name = $_.Content
        } elseif ($_.Type.ToUpper() -eq "NS") {
            $Service = 'recordns'
            $_.HostName = $_.Name
            $_.Name = $_.Content
        } elseif ($_.Type.ToUpper() -eq "TXT") {
            $Service = 'recordtxt'
            $_.Text = $_.Content
        } else {
            $messError = "Запрос не может быть выполнен. Не указан (неверно задан) - $($_.Type.ToUpper()) - обязательный параметр <Params.params.records.type> - тип ресурсной записи, может быть одним из 'A', 'AAAA', 'CNAME', 'NS', 'TXT'."
            throw $messError
        }
        if ( -not $_.ContainsKey('DomainId')) {
            $_.DomainId = $DomainDef
        }
        $requestParams = @{
            "Params" = $Params;
            "Method" = "POST";
            "Service" = "$($Service)";
            "Body" = $_;
            "logLevel" = $LogLevel;
        }
        #Write-Verbose "$($requestParams|ConvertTo-Json -Depth $LogLevel)"
        # вызов API
        <##>
        $res = @{}
        $resultAPI = (Invoke-Request @requestParams)
        $res += @{
            'raw'  = $resultAPI;
            'code' = $resultAPI.StatusCode;
        }
        if ($res.Code -eq 200) { # OK
            $res += @{'resDomains' = $resultAPI.Content | ConvertFrom-Json;}
            $resArray += $res;
        } else {
            $resArray += $res;
            #throw $resultAPI.StatusDescription
        }
        <##>
    })
   
    Write-Verbose "Data return: "
    Write-Verbose "$($resArray.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $resArray
}

<# ############################################################################################## #>
<# ############################################################################################## #>
<# ############################################################################################## #>
function Remove-Records() {
    <#
    .DESCRIPTION
    Удалить ресурсную запись для заданного домена
    .OUTPUTS
    Name: res
    BaseType: [Array[Hashtable]]
        {
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject, если ответ был успешный, иначе отсутствует
        },...
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.records - массив словарей ресурсных записей, которые надо удалить
            @(
                @{
                    "domainId"=<domainId>, если этого ключа нет, то используем Params.Params.Service или Params.Params.Domain
                    "recordId"=<recordId>
                },...
            )
    Необязательные ключи в HASHTABLE:
        Params.Params.service - имя  или id домена по-умолчанию, если в элементе массива отстутствует DomainId, то используется это значение. Самый низкий приоритет"
        Params.Params.domain  - имя  или id домена по-умолчанию, если в элементе массива отстутствует DomainId, то используется это значение. 2-й приоритет
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

    # domain
    $domainDef_id = '';
    if ($Params.Params.ContainsKey("Service") -and $Params.Params.Service -and ([String]$Params.Params.Service).Trim()) {
        $domainDef_id = ([String]$Params.Params.Service).Trim()
    }
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        $domainDef_id = ([String]$Params.Params.Domain).Trim()
    }
    <#
    if ($domain_id -eq "") {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо добавить ресурсную запись."
        throw $mess
    }
    #>
    $resArray = @()
    # цикл по записям для удаления
    $Params.params.records.foreach({
        #
        if (-not $_.ContainsKey('domainId')) {$_.DomainId = $domainDef_id}
        if ( -not ([string]$_.DomainId).Trim() ) {
            $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> (<Params.params.records[recordId]>) - домен для которого надо удалить ресурсную запись."
            throw $mess
        }
        if ( -not ([string]$_.recordId).Trim() ) {
            $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.records[recordId]> - id записи для удаления."
            throw $mess
        }
        #
        $requestParams = @{
            "Params" = $Params;
            "Method" = "Delete";
            "Service" = "$($_.domainId)/$($_.recordId)";
            "logLevel" = $LogLevel;
        }
        Write-Verbose "$($requestParams|ConvertTo-Json -Depth $LogLevel)"
        # вызов API
        <##>
        $res = @{}
        $resultAPI = (Invoke-Request @requestParams)
        $res += @{
            'raw'  = $resultAPI;
            'code' = $resultAPI.StatusCode;
        }
        if ($res.Code -eq 200) { # OK
            $res += @{'resDomains' = $resultAPI.Content | ConvertFrom-Json;}
            $resArray += $res;
        } else {
            $resArray += $res;
            #throw $resultAPI.StatusDescription
        }
        <##>
    })

    Write-Verbose "Data return: "
    Write-Verbose "$($resArray.code)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $resArray
}

<# ############################################################################################## #>
<# ############################################################################################## #>
<# ############################################################################################## #>
function Set-Records() {
    <#
    .DESCRIPTION
    Обновить ресурсную запись для заданного домена
    .OUTPUTS
    Name: res
    BaseType: [Array[Hashtable]]
        {
        'raw'   - ответ от Invoke-WebRequest
        'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
        "resDomains" (Invoke-WebRequest.Content | ConvertFrom-Json), конвертированный Content в PSCustomObject, если ответ был успешный, иначе отсутствует
        },...
    .PARAMETER Params
    Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.records - массив словарей ресурсных записей, которые надо обновить
            @(
                @{
                    recordId = <id_record>  - id запсис, которую надо обновить
                    domainId = <id_domain>  - id домена в котором надо обновить запись
                                            если отсутствует, то будем брать из Params.Params.domain,
                                            если отсутствует, то будем брать из Params.Params.Service
                    type = 'A';
                    Content = <ipv4_ADDRESS>;
                    name = <name>;
                    ttl = <n>;
                },
                @{
                    domainId = <id_domain>
                    type = 'CNAME';
                    Content = <name>;
                    name = <mnemonic_name>;
                    ttl = <n>;
                }
            )
    Необязательные ключи в HASHTABLE:
        Params.Params.service - имя  или id домена по-умолчанию, если в элементе массива отстутствует DomainId, то используется это значение. Самый низкий приоритет"
        Params.Params.domain  - имя  или id домена по-умолчанию, если в элементе массива отстутствует DomainId, то используется это значение. 2-й приоритет
    #>
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

    # domain
    $domainDef_id = '';
    if ($Params.Params.ContainsKey("Service") -and $Params.Params.Service -and ([String]$Params.Params.Service).Trim()) {
        $domainDef_id = ([String]$Params.Params.Service).Trim()
    }
    if ($Params.Params.ContainsKey("Domain") -and $Params.Params.Domain -and ([String]$Params.Params.Domain).Trim()) {
        $domainDef_id = ([String]$Params.Params.Domain).Trim()
    }
    $resArray = @()
    # цикл по записям для удаления
    $Params.params.records.foreach({
        #Write-Verbose "$($_|ConvertTo-Json -Depth $LogLevel)"
        if ($_.Type.ToUpper() -eq "A") {
            $Service = 'recorda'
            $_.IP = $_.Content
        } elseif ($_.Type.ToUpper() -eq "AAAA") {
            $Service = 'recordaaaa'
            $_.IP = $_.Content
        } elseif ($_.Type.ToUpper() -eq "CNAME") {
            $Service = 'recordcname'
            $_.MnemonicName = $_.Name
            $_.Name = $_.Content
        } elseif ($_.Type.ToUpper() -eq "NS") {
            $Service = 'recordns'
            $_.HostName = $_.Name
            $_.Name = $_.Content
        } elseif ($_.Type.ToUpper() -eq "TXT") {
            $Service = 'recordtxt'
            $_.Text = $_.Content
        } else {
            $messError = "Запрос не может быть выполнен. Не указан (неверно задан) - $($_.Type.ToUpper()) - обязательный параметр <Params.params.records.type> - тип ресурсной записи, может быть одним из 'A', 'AAAA', 'CNAME', 'NS', 'TXT'."
            throw $messError
        }
        $_.Remove('Type')
        if ( -not $_.ContainsKey('DomainId')) {
            $_.DomainId = $DomainDef_id
        }
        if ($_.ContainsKey('recordId')) {
            $requestParams = @{
                "Params" = $Params;
                "Method" = "PUT";
                "Service" = "$($Service)/$($_.recordId)";
                "Body" = $_;
                "logLevel" = $LogLevel;
            }
            Write-Verbose "$($requestParams|ConvertTo-Json -Depth $LogLevel)"
            # вызов API
            <##>
            $res = @{}
            $resultAPI = (Invoke-Request @requestParams)
            $res += @{
                'raw'  = $resultAPI;
                'code' = $resultAPI.StatusCode;
            }
            if ($res.Code -eq 200) { # OK
                $res += @{'resDomains' = $resultAPI.Content | ConvertFrom-Json;}
                $resArray += $res;
            } else {
                $resArray += $res;
                #throw $resultAPI.StatusDescription
            }
        }
        <##>
    })
    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $resArray
}

<# ############################################################################################## #>
<# ############################################################################################## #>
<# ############################################################################################## #>
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

    $verAPI = $Params.sectionData.result.version.Trim()
    $p = @{}
    $p += $Params.sectionData.result."config$(if ($verAPI) {""$(_$verAPI)""})";
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
    $h = @{
        'Authorization' = "$($p.Token)";
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
        # пропустить для -Method GET
        if ( ($Body -is [hashtable] -or $Body -is [psobject] -or $Bosy -is [PSCustomObject]) -and ($null -ne $Body) ) {
            $Body = ($Body | ConvertTo-Json -Depth 4)
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
        if (-not $s) {
            $s = $PSItem.Exception.Message
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

#Set-Alias -Value Get-Domains -Name domains
    
#Export-ModuleMember -Function Invoke-API -Alias domains
#Export-ModuleMember -Function Invoke-API
#Export-ModuleMember -Function *
