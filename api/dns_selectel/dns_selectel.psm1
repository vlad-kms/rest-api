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
        $s = "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: =============================================++++++++++++++++++++++++++++"
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
        Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $resultAPI
}

<############################################################################################################>
<###  v1 and v2 #############################################################################################>
<###  Получить домены                                                                                     ###>
<############################################################################################################>
function DomainInArray(){
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Domain,
        [Parameter(Mandatory=$true, Position=1)]
        $ListDomains,
        [Int]$LogLevel=1
    )
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Domain: $($Domain)"
    Write-Verbose "List domains: $($ListDomains)"

    # версия API
    $VerAPI = (GetVersionAPI -Params $Params)
    $res = $null
    $Domain = ([String]$Domain).ToLower()
    $isName = $domain.Contains('.')
    if ($isName -and ($VerAPI -eq 'v2') -and (-not $Domain.EndsWith('.')) ) {
        $Domain += '.'
    }
    foreach ($item in $ListDomains) {
        if ( $isName ) {
            # было передано имя домена
            if ($item.Name.ToLower() -eq $Domain) {
                $res = $item
                break
            }
        } else {
            # был передан ID домена
            if (([String]($item.ID)).ToLower() -eq $Domain) {
                $res = $item
                break
            }
        }
    }
    if ($null -ne $res) {
        Write-Verbose "Домен $($Domain) есть в списке доменов"
    }
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

function ParseQueryParams(){
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        $Query,
        [Int]$LogLevel=1
    )
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Строка запроса: $($Query)"
    $res=@{}

    if ($null -ne $Query) {
        if ($Query -is [String]) {
            # строку параметров в массив строк вида name=value
            [String[]]$Query=$Query.trim().split(@('&', '?'), [System.StringSplitOptions]::RemoveEmptyEntries)
        }

        if ($Query -is [String[]]) {
            # массив строк вида name=value
            # преобразовать этот массив в Hastable @{name=value}
            foreach ($param in $Query){
                $Pattern='(?ins)^(?<name>.*)=(?<value>.*)$'
                if ($param -match $Pattern) {
                    $res += @{$Matches.name.trim()=$Matches.value.trim()}
                }
            }
        } elseif ($Query -is [System.Collections.IDictionary]) {
            $res = $Query
        }
    }
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<#
.DESCRIPTION
Попробовать идентифицировать Value является ID или нет
Для leagcy (v1) ID - целое число
Для actual (v2) ID - GUID
.OUTPUTS
Name: res
BaseType: Boolean
    true   - скорее всего ID
    false  - скорее всего имя домена
.PARAMETER Value
Значение, которое надо идентифицировать
.PARAMETER VerAPI
Версия API
.PARAMETER ErrorAsException
Если TRUE, то неудавшееся преобразование порождает Exception.
Иначе возвращает FALSE
#>
function IsID(){
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        $Value,
        [Parameter(Position=1)]
        [String] $VerAPI='v2',
        [Parameter(Position=2)]
        [bool] $ErrorAsException=$true,
        [Parameter(Position=3)]
        [bool] $OnlyID4v1=$true,
        [string] $WhatId='',
        [Int] $LogLevel=1
    )
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    if ($VerAPI -eq 'v1') {
        #v1
        if ($OnlyID4v1) {
            # пробуем преобразовать в тип [Int]
            try {
                $res = [Int]$Value -is [Int]
            }
            catch {
                $res = $false
                if ($ErrorAsException) {throw "$($Value) не может являться ID$($WhatId). Тип не [Int]"}
            }
        } else {
            # в любом случае это ID 
            $res=$true
        }
    } elseif ($VerAPI -eq 'v2') {
        #v2
        try {
            # пробуем преобразовать в тип [Guid]
            $res = [guid]$Value -is [guid]
        }
        catch {
            $res = $false
            if ($ErrorAsException) {throw "$($Value) не может являться ID$($WhatId). Тип не [Guid]"}
        }
    } else {
        $res = $false
        if ($ErrorAsException) {throw "Неподерживаемая версия API: $($VerAPI)"}
    }
    Write-Verbose "$($Value) может являться ID домена"
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<#
.DESCRIPTION
Получить записи о доменах. Учитываются limit и offset из строки запроса
v1: GET /; https://api.selectel.ru/domains/v1/
v2: GET /zones; https://api.selectel.ru/domains/v2/zones
.OUTPUTS
Name: res
BaseType: Hashtable
    'raw'   - оригинальный ответ от Invoke-WebRequest
    'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
    "resDomains" массив записей о доменах
.PARAMETER Params
Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        нет
    Необязательные ключи в HASHTABLE:
        Params.Params.domain  - имя или id домена, будет выбираться данные только о нем.
                                Имя или ID определяется через функцию IsID
                                ДЛЯ legacy (v1):
                                Если передан ID, то выбор осуществляется через API https://api.selectel.ru/domains/v1/<id-domain>
                                Если передано имя домена, то поиск ведется через параметр запрос &filter=<name-domain> https://api.selectel.ru/domains/v1/?filter=<name-domain>.
                                    Если Params.params.query уже есть &filter=<value>, то значение <name-domain> заменит <value> 
                                Для actual (v2):
                                Если передан ID, то выбор осуществляется через API https://api.selectel.ru/domains/v2/zones/<id-domain>
                                Если передано имя домена, то поиск ведется через параметр запрос &filter=<name-domain> https://api.selectel.ru/domains/v2/zones?filter=<name-domain>.
                                    Если Params.params.query уже есть &filter=<value>, то значение <name-domain> заменит <value> 
        Params.params.query   - аргументы для строки запроса (?arg=1&arg2=qwe&arg3=3...).
                                Может быть строкой, первый '?' не обязателен.
                                Может быть массивом @('arg=1', 'arg2=qwe', 'arg3=3', ...)
                                Может быть hashtable @{'arg'=1; 'arg2'='qwe'; 'arg3'=3, ...)
        Params.Params.UseInitialOffset -наличие (значение не обязательно) указывает использовать начальное значение offset из параметра запроса,
                                        иначе offset обнуляется
#>
function Get-Domains() {
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры:"
    Write-Verbose "Params.params.domain: $(([String]$Params.params.Domain).Trim())"
    Write-Verbose "Params.params.UseInitialOffset  (не обязательный): $($Params.Params.ContainsKey('UseInitialOffset'))"
    Write-Verbose "Params.params.query (не обязательный): $(`
            if ($Params.Params.query -is [String]) {([String]$Params.Params.query).Trim()}`
            elseif ($Params.Params.query -is [Object[]]) {$Params.Params.query -join ', '}`
            elseif ($Params.Params.query -is [System.Collections.IDictionary]) {$Params.Params.query|ConvertTo-Json -Depth $LogLevel}`
        )"

    # версия API
    $VerAPI = (GetVersionAPI -Params $Params)
    # разбор Params.params.query, как параметров запроса
    # преобразовать строку (p1=v1&p2=v2&...) или массив строк (@('p1=v1', 'p2=v2', ...)) в hastable @{'p1'=v1; 'p2'=v2;...}
    #
    if ($null -ne $Params.Params.Query) {
        $queryNormalize = ($Params.Params.Query | ParseQueryParams)
    } else {
        $queryNormalize=@{}
    }
    # если в Query нет limit, то проинициализировать значением по-умолчанию
    if (-not $queryNormalize.ContainsKey('limit')) {
        $queryNormalize.limit=1000
    }
    # offset по-умолчанию
    if (-not $queryNormalize.ContainsKey('offset')) {
        $queryNormalize.offset=0
    } else {
        if ( -not $Params.Params.ContainsKey('UseInitialOffset') )  {
            $queryNormalize.offset=0
        }
    }
    $par=@{'query'=$queryNormalize}
    # домен в параметрах $Params.Params.domain:
    #   'mrovo.ru' - есть '.', значит передали имя домена и поиск будет осуществляться через Query &filter=<name>
    #   'sdsad'    - нет '.', значит передали ID домена и поиск будет осуществляться через id_domain в строке v1/{id_domain} (v2/zones/{id_domain})
    $domain = ([String]$Params.params.Domain).Trim()
    if ($domain) {
        # проверить, что значение подходит под ID (для v1 [Int]; для v2 [Guid]), или это имя домена
        if (IsID -Value $domain -VerAPI $VerAPI -ErrorAsException $false){
            # в domain передали ID домена
            $par += @{'idDomain'="$($domain)"}
        } else {
            # в domain передали имя домена
            $par.query.filter=$domain
        }
    }
    $par += @{'Headers'=$Params.Headers}
    # удалить лишние параметры
    $par.Remove('service')
    Write-Verbose "Параметры для запроса:"
    Write-Verbose "$($par|ConvertTo-Json -Depth $LogLevel)"

    # сделать копию $Params
    $Params4Invoke=@{}
    $Params4Invoke += $Params
    $Params4Invoke += @{'paramsQuery'=$par}

    $requestParams = @{
        "Params" = $Params4Invoke;
        "Method" = "Get";
        "logLevel" = $LogLevel;
    }

    # Читать домены частями до конца
    # вернуть часть доменов
    $full_res = @()
    do {
        # вызов API
        $resultAPI = (Invoke-Request @requestParams)
        # обработка результата
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
        if ($VerAPI -eq 'v1') {
            #legacy
            $full_res += $res.resDomains
            if ($res.raw.Headers.ContainsKey('x-total-count')) {
                $h_count = [int]($res.raw.Headers."x-total-count")
            } else {
                $h_count = 0
            }
            if ($res.raw.Headers.ContainsKey('x-offset')) {
                $h_offset = [int]($res.raw.Headers.'x-offset')
            } else {
                $h_offset = 0
            }
            $new_offset=$h_offset + $Params4Invoke.paramsQuery.query.limit
            $_break_ = $new_offset -lt $h_count
            $requestParams.Params.paramsQuery.query.offset=$new_offset
        } else {
            # actual
            if (HasProperty -Value $res.resDomains -Property 'next_offset') {
                # содержится информация о offset
                $full_res += $res.resDomains.result
                $_break_ = ($res.resDomains.next_offset -ne 0)
                $requestParams.Params.paramsQuery.query.offset=$res.resDomains.next_offset
            } else {
                $full_res = ,$res.resDomains
                $_break_ = $false
            }
        }
    }
    while ($_break_)
    $res.resDomains = $full_res
    Write-Verbose "content TO object: $($resultAPI.resDomains)"
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

function Find-Domain() {
<#
Поиск домена по имени.
.OUTPUTS
Name: res
BaseType: Hashtable
    'raw'   - оригинальный ответ от Invoke-WebRequest
    'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
    "resDomains" массив с одним элементом - записью домена. Пустой массив, если такого домена нет
.PARAMETER Params
Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain  - имя домена, который надо найти
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры:"
    Write-Verbose "Params.params.domain: $(([String]$Params.params.Domain).Trim())"

    $VerAPI = (GetVersionAPI -Params $Params)
    # domain
    $domain = ([string]$Params.Params.Domain).Trim(' .').ToLower()
    if ($domain) {
        if (IsID -Value $domain -VerAPI $VerAPI -ErrorAsException $false -OnlyID4v1 $false){
            # это ID
            $paramQuery = @{
                'Params'=@{
                    'Params'=@{
                    }
                'paramsQuery'=@{
                    'Query'='';
                    'idDomain'=$domain;
                    'Headers'=$Params.Params.Headers;
                    'Body'=$Params.Params.Body;
                }
                'sectionData'=$Params.sectionData;
                }
                'Method'='GET';
                'LogLevel'=$LogLevel
            }
            #$res = Get-Domains -Params $params -LogLevel $LogLevel
            $resultAPI = Invoke-Request @paramQuery
            # обработка результата
            $res = @{
                'raw'  = $resultAPI;
                'code' = $resultAPI.StatusCode;
            }
            if ($res.Code -eq 200) { # OK
                $res += @{
                    "resDomains" = ,($resultAPI.Content | ConvertFrom-Json)
                }
            } else {
                throw $resultAPI.StatusDescription
            }
        } else {
            # передано имя домена
            # пробуем найти домен с именем $domain
            $paramsTemp = @{}
            $paramsTemp += $Params
            $paramsTemp.Params.Query=''
        
            $res = Get-Domains -Params $paramsTemp -LogLevel $LogLevel
            if ($res.Code -eq 200) { # OK
                $domTemp=@()
                foreach ($d in $res.resDomains) {
                    $dn = $d.Name.Trim(' .').ToLower()
                    if ($dn -eq $domain) {
                        # нашли домен по имени
                        $domTemp += $d
                        break
                    }
                }
                $res.resDomains = $domTemp
            #} else {
            #    throw $resultAPI.StatusDescription
            }
        }
        #$Params += @{'additionalUri' = ([String]$Params.Params.Domain).Trim()}
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен, который надо найти."
        throw $mess
    }
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  v1 and v2 #############################################################################################>
<###  Получить ресурсные записи домена                                                                    ###>
<############################################################################################################>
function Get-Records() {
<#
.DESCRIPTION
Получить все ресурсные записи домена с учетом параметров запроса &ofsset &limit
v1: GET /; https://api.selectel.ru/domains/v1/{id_domain}/records
v2: GET /zones; https://api.selectel.ru/domains/v2/zones/{id_domain}/rrset
.OUTPUTS
Name: res
BaseType: Hashtable
    'raw'   - ответ от Invoke-WebRequest
    'code'  - Invoke-WebRequest.StatusCode, т.е. результат возврата HTTP code
    "resDomains" массив записей rrset домена
.PARAMETER Params
Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
    Обязательные ключи в HASHTABLE:
        Params.Params.domain  - имя  или id домена
            ДЛЯ legacy (v1):
                Если передан ID, то выбор осуществляется через API https://api.selectel.ru/domains/v1/<id-domain>/records
                Если передано имя домена, то выбор осуществляется через API https://api.selectel.ru/domains/v1/<name-domain>/records
            Для actual (v2):
                Если передан ID, то выбор осуществляется через API https://api.selectel.ru/domains/v2/zones/<id-domain>/rrset
                Если передано имя домена, сначала надо найти ID домена, используя GetIdDomain, затем https://api.selectel.ru/domains/v2/zones/<id-domain>/rrset
    Необязательные ключи в HASHTABLE:
        $Params.Params.record_id - id записи, будет выбрана только конкретная запись с этим id
        Params.Params.UseInitialOffset -наличие (значение не обязательно) указывает использовать начальное значение offset из параметра запроса,
                                        или начинать чтение с 0
#>
    #Requires -Version 3
    [OutputType([Hashtable])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры:"
    Write-Verbose "Params.params.domain: $(([String]$Params.params.Domain).Trim())"
    Write-Verbose "Params.params.record_id (не обязательный): $(([String]$Params.Params.record_id).Trim())"
    Write-Verbose "Params.params.UseInitialOffset  (не обязательный): $($Params.Params.ContainsKey('UseInitialOffset'))"

    # версия API
    $VerAPI = (GetVersionAPI -Params $Params)
    # разбор Params.params.query, как параметров запроса
    # преобразовать строку (p1=v1&p2=v2&...) или массив строк (@('p1=v1', 'p2=v2', ...)) в hastable @{'p1'=v1; 'p2'=v2;...}
    #
    if ($null -ne $Params.Params.Query) {
        $queryNormalize = ($Params.Params.Query | ParseQueryParams)
    } else {
        $queryNormalize=@{}
    }
    # если в Query нет limit, то проинициализировать значением по-умолчанию
    if (-not $queryNormalize.ContainsKey('limit')) {
        $queryNormalize.limit=1000
    }
    # offset по-умолчанию
    if (-not $queryNormalize.ContainsKey('offset')) {
        $queryNormalize.offset=0
    } else {
        if ( -not $Params.Params.ContainsKey('UseInitialOffset') )  {
            $queryNormalize.offset=0
        }
    }
    $par=@{'query'=$queryNormalize}
    # домен в параметрах $Params.Params.domain ОБЯЗАТЕЛЕН:
    #   для legacy (v1) можно использовать и имя домена, и  ID
    #   для actual (v2) можно использовать только ID домена, если передали имя, то сначала получить ID по имени домена (GetIdDomain)
    $domain = ([String]$Params.params.Domain).Trim()
    if ($domain) {
        if (IsID -Value $domain -VerAPI $VerAPI -ErrorAsException $false -OnlyID4v1 $false) {
            # в domain передали ID домена
            $par += @{'idDomain'="$($domain)"}
        } else {
            # в domain передали имя домена
            $fd = Find-Domain -Params $Params -LogLevel $LogLevel
            if ($fd.Code -eq 200) {
                # нет ошибок при поиске
                if ($fd.resDomains.Count -ne 1) {
                    throw "Не смогли найти домен $($domain) ::: $($MyInvocation.InvocationName)"
                }
                $par += @{'idDomain'="$($fd.resDomains[0].id)"}
            } else {
                throw "Ошибка при поиске домена $($domain) ::: $($MyInvocation.InvocationName)"
            }

        }
    }
    # record ID
    $record_id=([String]$Params.Params.record_id).Trim()
    if ($record_id) {
        if (IsID -Value $record_id -VerAPI $VerAPI) {
            $par += @{'record_id'=$record_id}
        }
    }
    # service
    $par += @{'service'=if($VerAPI -eq 'v1'){'records'}else{'rrset'}}
    Write-Verbose "Начальное значение &limit: $($h_limit)"
    Write-Verbose "Начальное значение &offset: $($h_limit)"
    # параметры запроса подготовили
    Write-Verbose "Параметры для запроса:"
    Write-Verbose "$($par|ConvertTo-Json -Depth $LogLevel)"

    # сделать копию $Params
    $Params4Invoke=@{}
    $Params4Invoke += $Params
    $Params4Invoke += @{'paramsQuery'=$par}
    $requestParams = @{
        "Params" = $Params4Invoke;
        "Method" = "Get";
        "logLevel" = $LogLevel;
    }

    # Читать домены частями до конца
    # вернуть часть доменов
    $full_res = @()
    do {
        $resultAPI = (Invoke-Request @requestParams)
        # обработка результата
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

        if ($VerAPI -eq 'v1') {
            #legacy
            $full_res += $res.resDomains
            if ($res.raw.Headers.ContainsKey('x-total-count')) {
                $h_count = [int]($res.raw.Headers."x-total-count")
            } else {
                $h_count = 0
            }
            if ($res.raw.Headers.ContainsKey('x-offset')) {
                $h_offset = [int]($res.raw.Headers.'x-offset')
            } else {
                $h_offset = 0
            }
            $new_offset=$h_offset + $Params4Invoke.paramsQuery.query.limit
            $_break_ = $new_offset -lt $h_count
            $requestParams.Params.paramsQuery.query.offset=$new_offset
        } else {
            # actual
            if (HasProperty -Value $res.resDomains -Property 'next_offset') {
                # содержится информация о offset
                $full_res += $res.resDomains.result
                $_break_ = ($res.resDomains.next_offset -ne 0)
                $requestParams.Params.paramsQuery.query.offset=$res.resDomains.next_offset
            } else {
                $full_res = ,$res.resDomains
                $_break_ = $false
            }
        }
    } while ($_break_)

    # результат работы
    $res.resDomains = $full_res
    Write-Verbose "content TO object: $($resultAPI.resDomains)"
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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
    Params.Params.domain  - имя  или id домена. Т.к. поддерживается только leagcy (v1), то $domain передается без всяких преобразований (As-Is)
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры:"
    Write-Verbose "Params.params.domain: $(([String]$Params.params.Domain).Trim())"

    # версия API
    $VerAPI = (GetVersionAPI -Params $Params)
    if ($VerAPI -ne 'v1') {
        # поддерживается только для v1
        throw "$($MyInvocation.InvocationName) не поддерживается версией $($VerAPI)"
    }
    # подготовить параметры запроса
    $par=@{}
    $domain = ([String]$Params.params.Domain).Trim()
    if ($domain) {
        $par += @{'idDomain'="$($domain)"}
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо сделать экспорт ресурсных записей."
        throw $mess
    }
    # сделать копию $Params
    $Params4Invoke=@{}
    $Params4Invoke += $Params
    $Params4Invoke += @{'paramsQuery'=$par}
    $requestParams = @{
        "Params" = $Params4Invoke;
        "Method" = "Get";
        "Service" = "export";
        "logLevel" = $LogLevel;
    }
    # вызов API
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<###  v1 and v2  #############################################################################################>
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
        Params.Params.domain  - id или имя домена.
                                legacy (v1):
                                что передали в $domain, то и считается ID
                                actual (v2):
                                если в $domain передали GUID, то это ID,
                                иначе передали имя домена, и сначала через Find-Domain находим ID для имени домена
    #>
    #Requires -Version 3
    [OutputType([String])]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params,
        [Int] $LogLevel=1
    )

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры:"
    Write-Verbose "Params.params.domain: $(([String]$Params.params.Domain).Trim())"

    $VerAPI = (GetVersionAPI -Params $Params)
    $par=@{}
    # домен в параметрах $Params.Params.domain ОБЯЗАТЕЛЕН:
    #   для legacy (v1) можно использовать и имя домена, и  ID
    #   для actual (v2) можно использовать только ID домена, если передали имя, то сначала получить ID по имени домена (GetIdDomain)
    $domain = ([String]$Params.params.Domain).Trim()
    if ($domain) {
        if (IsID -Value $domain -VerAPI $VerAPI -ErrorAsException $false -OnlyID4v1 $false) {
            # в domain передали ID домена
            $par += @{'idDomain'="$($domain)"}
        } else {
            # в domain передали имя домена
            $fd = Find-Domain -Params $Params -LogLevel $LogLevel
            if ($fd.Code -eq 200) {
                # нет ошибок при поиске
                if ($fd.resDomains.Count -ne 1) {
                    throw "Не смогли найти домен $($domain) ::: $($MyInvocation.InvocationName)"
                }
                $par += @{'idDomain'="$($fd.resDomains[0].id)"}
            } else {
                throw "Ошибка при поиске домена $($domain) ::: $($MyInvocation.InvocationName)"
            }

        }
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен(зона) для которого(ой) надо вернуть статус."
        throw $mess
    }
    # параметры запроса
    # сделать копию $Params
    $Params4Invoke=@{}
    $Params4Invoke += $Params
    $Params4Invoke += @{'paramsQuery'=$par}
    if ($VerAPI -eq 'v1') {
        # вызов API
        $requestParams = @{
            "Params" = $Params4Invoke;
            "Method" = "Get";
            "Service" = "state";
            "logLevel" = $LogLevel;
        }
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
        $res = (Find-Domain -Params $Params -LogLevel $LogLevel)
        if ($res.Code -eq 200) { # OK
            if ($res.resDomains.Count -eq 1) {
                $res.resDomains = [PSCustomObject]@{"disabled"=$res.resDomains[0].disabled};
            }
        } else {
            throw $res.StatusDescription
        }
    } else {
        throw "$($MyInvocation.InvocationName): Версия $($VerAPI) не поддерживается"
    }

    Write-Verbose "Data return: "
    Write-Verbose "$($res.resDomains)"
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    $VerAPI = (GetVersionAPI -Params $Params)
    $par=@{}
    # домен в параметрах $Params.Params.domain ОБЯЗАТЕЛЕН:
    #   для legacy (v1) можно использовать и имя домена, и  ID
    #   для actual (v2) можно использовать только ID домена, если передали имя, то сначала получить ID по имени домена (GetIdDomain)
    $domain = ([String]$Params.params.Domain).Trim()
    if ($domain) {
        if (IsID -Value $domain -VerAPI $VerAPI -ErrorAsException $false -OnlyID4v1 $false) {
            # в domain передали ID домена
            $par += @{'idDomain'="$($domain)"}
        } else {
            # в domain передали имя домена
            $fd = Find-Domain -Params $Params -LogLevel $LogLevel
            if ($fd.Code -eq 200) {
                # нет ошибок при поиске
                if ($fd.resDomains.Count -ne 1) {
                    throw "Не смогли найти домен $($domain) ::: $($MyInvocation.InvocationName)"
                }
                $par += @{'idDomain'="$($fd.resDomains[0].id)"}
            } else {
                throw "Ошибка при поиске домена $($domain) ::: $($MyInvocation.InvocationName)"
            }

        }
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен(зона) для которого(ой) надо отключить обслуживание."
        throw $mess
    }
    $Body = @{"disabled" = [bool]$Params.params.disabled}
    # параметры запроса
    # сделать копию $Params
    $Params4Invoke=@{}
    $Params4Invoke += $Params
    $Params4Invoke += @{'paramsQuery'=$par}
    $requestParams = @{
        "Params" = $Params4Invoke;
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Переданные параметры:"
    Write-Verbose "Params.params.domain: $(([String]$Params.params.Domain).Trim())"
    Write-Verbose "Params.params.record (не обязательный): $($Params.Params.record | ConvertTo-Json -Depth $LogLevel)"

    $VerAPI = (GetVersionAPI -Params $Params)

    # домен в параметрах $Params.Params.domain ОБЯЗАТЕЛЕН:
    #   для legacy (v1) можно использовать и имя домена, и  ID
    #   для actual (v2) можно использовать только ID домена, если передали имя, то сначала получить ID по имени домена (GetIdDomain)
    $domain = ([String]$Params.params.Domain).Trim()
    if ($domain) {
        if (IsID -Value $domain -VerAPI $VerAPI -ErrorAsException $false -OnlyID4v1 $false) {
            # в domain передали ID домена
            $par += @{'idDomain'="$($domain)"}
        } else {
            # в domain передали имя домена
            $fd = Find-Domain -Params $Params -LogLevel $LogLevel
            if ($fd.Code -eq 200) {
                # нет ошибок при поиске
                if ($fd.resDomains.Count -ne 1) {
                    throw "Не смогли найти домен $($domain) ::: $($MyInvocation.InvocationName)"
                }
                $par += @{'idDomain'="$($fd.resDomains[0].id)"}
            } else {
                throw "Ошибка при поиске домена $($domain) ::: $($MyInvocation.InvocationName)"
            }
        }
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо добавить ресурсную запись."
        throw $mess
    }
    $Params += @{'paramsQuery'=$par}
    # Service
    if ($VerAPI.ToLower() -eq 'v1' ) {
        $svcstr="records"
    } elseif ($VerAPI.ToLower() -eq 'v2') {
        $svcstr="rrset"
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    #Write-Verbose "Переданные параметры: $($Params | ConvertTo-Json -Depth $LogLevel)"

    $VerAPI = (GetVersionAPI -Params $Params)

    # домен в параметрах $Params.Params.domain ОБЯЗАТЕЛЕН:
    #   для legacy (v1) можно использовать и имя домена, и  ID
    #   для actual (v2) можно использовать только ID домена, если передали имя, то сначала получить ID по имени домена (GetIdDomain)
    $domain = ([String]$Params.params.Domain).Trim()
    if ($domain) {
        if (IsID -Value $domain -VerAPI $VerAPI -ErrorAsException $false -OnlyID4v1 $false) {
            # в domain передали ID домена
            $par += @{'idDomain'="$($domain)"}
        } else {
            # в domain передали имя домена
            $fd = Find-Domain -Params $Params -LogLevel $LogLevel
            if ($fd.Code -eq 200) {
                # нет ошибок при поиске
                if ($fd.resDomains.Count -ne 1) {
                    throw "Не смогли найти домен $($domain) ::: $($MyInvocation.InvocationName)"
                }
                $par += @{'idDomain'="$($fd.resDomains[0].id)"}
            } else {
                throw "Ошибка при поиске домена $($domain) ::: $($MyInvocation.InvocationName)"
            }
        }
    } else {
        $mess = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.domain> - домен для которого надо добавить ресурсную запись."
        throw $mess
    }
    # record ID
    $record_id=([String]$Params.Params.record_id).Trim()
    if ($record_id) {
        if (IsID -Value $record_id -VerAPI $VerAPI) {
            $par += @{'record_id'=$record_id}
        }
    } else {
        $messError = "Запрос не может быть выполнен. Не указан обязательный параметр <Params.params.record_id> - id ресурсной записи для удаления."
        throw $messError
    }
    # Service
    $svcstr=''
    if ($VerAPI.ToLower() -eq 'v1' ) {
        $svcstr="records"
    } elseif ($VerAPI.ToLower() -eq 'v2') {
        $svcstr="rrset"
    } else {
        throw "Версия API $($VerAPI) не поддерживается. $($MyInvocation.InvocationName)"
    }
    $par += @{'service'=$svcstr}
    $Params += @{'paramsQuery'=$par}

    #
    $requestParams = @{
        "Params" = $Params;
        "Method" = "DELete";
        #"Service" = "$($svcstr)$($record_id)";
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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
        - Params.sectionData [HASHTABLE]    - секция из файла cfg с настройками провайдера: части URI, пароли ...
            параметры для формирования структур для API и вызов API.
            Получили ее из INI-файла с помощью [FileCFG]::getSectionValues
            - sectionData.BaseUri: "https://api.selectel.ru"    , ОБЯЗАТЕЛЬНЫЙ
            - sectionData.ServiceUri: "/domains/v1/"            , ОБЯЗАТЕЛЬНЫЙ
                Используются для формирования строки запроса:
                Params.sectionData.BaseUri+Params.sectionData.ServiceUri+Params.additionalUri+Service+params.queryGet
        - Params.paramsQuery [HASHTABLE]    - параметры для запроса
            - .query [HASHTABLE]            - параметры в для строке запроса (limit, offset, filter и т.д.)
            - .idDomain                     - ID домена
            - .service                      - часть URI (records, rrset, state...), используется если не передали параметр -Service
            - .record_id                    - ID записи RRSET, использется при формрровании строки запроса после service
            - .headers[Hashtable]           - HEADERS  к HTTP запросу
            - sectionData   [Hashtable]
        Необязательные ключи в HASHTABLE:
        - Params.params - [hashtable], здесь то, что было передано скрипту в -ExtParams
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
    
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
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
    $uri = $uri.trimEnd('/')
    $svcUri = $p.ServiceUri
    $svcUri = $svcUri.trim('/')
    $uri = "$($uri)/$($svcUri)/"
    # формирование URI без параметров запроса
    if ($Params.paramsQuery.ContainsKey("idDomain") -and $Params.paramsQuery.idDomain -and $Params.paramsQuery.idDomain.Trim()) {
        $additionalUri = $Params.paramsQuery.idDomain.Trim()
        $additionalUri = $additionalUri.Trim('/')
        $uri = "$($uri)$($additionalUri)/"
    }
    # Service
    if (-not $Service) {
        # не передали параметр -Service
        # берем из Params.paramsQuery.service
        $Service = ([string]$Params.paramsQuery.service).Trim()
    }
    if ($Service) {
        $uri = "$($uri)$($Service)/"
    }
    # строка после service (record_id, ...)
    $record_id = ([string]$Params.paramsQuery.record_id).Trim()
    if ($record_id) {
        $uri = "$($uri)$($record_id)/"
    }
    # формируем параметры к строке запроса (GET например: ?p1=v1&p2=v2&p3=v3)
    $queryGet=''
    if ($Params.paramsQuery.ContainsKey("query") -and ($Method.ToLower() -eq "get") -and 
            $Params.paramsQuery.query -and ($Params.paramsQuery.query.Count -gt 0) )
    {
        $Params.paramsQuery.query.GetEnumerator().foreach({
            $queryGet += "&$($_.name)=$($_.value)"
        })
        # убрать начальные '&'
        $queryGet = $queryGet.TrimStart('&')
        # добавить в начало '?'
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
        "$AuthHeader" = "$(Get-TokenDNSSelectel -section $p -verAPI $verAPI -LogLevel $LogLevel)";
        'Content-Type' = 'application/json'
    }
    # Дополнительно Headers из параметров
    if ($Params.paramsQuery.ContainsKey("Headers") -and ($Params.paramQuery.Headers -is [hashtable])) {
        $Params.paramQuery.Headers.GetEnumerator().foreach({
            $h += @{"$($_.Key)"="$($_.Value)"}
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
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
            # TODO пока не готово. Может и не надо. Думать надо... (с)
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="

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

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}

<############################################################################################################>
<############################################################################################################>
<############################################################################################################>
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
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="

    $VerAPI = (GetVersionAPI -Params $Params)

    if ( (-not $Params.ContainsKey('params')) -or (-not $Params.params.ContainsKey('domain')) ) {
        throw("Не передан обязательный параметр Params.params.domain")
    }
    $params_temp = @{}
    $params_temp += $Params
    $params_temp.Params.Query=''
    $params_temp.Params.Remove('UseInitialOffset')
    $params_temp.AllDomains = $true

    $domain = $params_temp.params.domain
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
    if ($domain.Contains('.')) {
        # в Params.params.domain было передано имя и надо для него получить ID для actual (v1)
        # для legacy (v1) ID получать не надо, т.к. API одинаково работает и с ID, и с именем
        if ($VerAPI -eq 'v2') {
            $res = (Get-DomainsNew -Params $params_temp -LogLevel $LogLevel)
            if ( ($null -ne $res) -and ($res.resDomains.count -eq 1) ) {
                $res = $res.resDomains[0].id
            }
        } else {
            $res = $domain
        }
    } else {
        # в Params.params.domain был передан ID, его и возвращаем
        $res = $domain
    }
    # результат
    Write-Verbose "Возвращаемое значение (res): $($res)"
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}


######################################################################################################
#                                    PRIVATE FUNCTION 
#
######################################################################################################
function GetVersionAPI() {
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [hashtable] $Params
    )
    $listSupportedVersions=@('v1', 'v2')
    $res =([string]$Params.sectionData.result.version).Trim().ToLower()
    if ($res -in $listSupportedVersions ) {
        return ([string]$Params.sectionData.result.version).Trim().ToLower()
    } else {
        throw "Неподерживаемая версия API: $($res)"
    }
}

function HasProperty() {
    #Requires -Version 3
    [OutputType([String])]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        $Value,
        [Parameter(Mandatory=$true, Position=1)]
        [String]$Property
    )

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    if ($value -is [System.Collections.IDictionary]){
        # объект имеет тип HASHTABLE
        $res = $Value.ContainsKey("$($Property)")
    } elseif ($Value -is [PSCustomObject]) {
        # объект имеет тип PSCustomObject или Object
        $res = [bool]($Value.psobject.properties.match("$Property").Count)
    }
    Write-Verbose "Объект содержит свойство $($Property): $($res)"
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $res
}


#===========================================================================
#===========================================================================
#===========================================================================

if ( ($null -eq (Get-Variable Token_Current -ErrorAction SilentlyContinue)) -or ($Token_Current -isnot [hashtable])) {
    $global:Token_Current=@{
        Username='';
        UserID='';
        ProjectName='';
        TokenKeystone='';
        DateToken=[datetime](Get-Date -Date "1.1.0 0:0:0")
    }
}

#Set-Alias -Value Get-Domains -Name domains
Export-ModuleMember -Function @('Invoke-API') #, <#'Get-Domains',#> 'Get-Records')
#Export-ModuleMember -Function Invoke-API
#Export-ModuleMember -Function *
