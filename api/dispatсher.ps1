function Get-FileProvider {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [String] $Provider,
        #[Parameter(Mandatory=$true)]
        [CommonVariable] $Vars,
        [String] $Path="api",
        [switch] $IsDotSourcing,
        [int] $LogLevel=1
    )

    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose "Provider: $($Provider)"
    Write-Verbose "Path: $($Path)"
    Write-Verbose "Vars: $(if ($null -ne $Vars) {$Vars.ToJson(1)} else {"null"})"
    Write-Verbose "IsDotSourcing: $($IsDotSourcing)"

    # путь скрипта
    $scriptPath = (Get-PathScript -Vars $Vars)
    #$scriptPath = (Get-PathScript)
    # преобразовать $Path
    if ( -not (Split-Path $Path -IsAbsolute) ) {
        $Path = (Join-Path $scriptPath -ChildPath $Path)
    }
    if ( -not (Test-Path $Path -PathType Container) ) {
        throw "Нет каталога для поиска файлов работы с API: $($Path)"
    }
    Write-Verbose "Путь для поиска файлов работы с API: $($Path)"
    Write-Verbose "Файл для работы с API ""$($Provider)"" ""$($scriptFile)"" найден"
    $result = @{"$($Provider)"= @{"IsDotSourcing"=[bool]$IsDotSourcing}}
    # загрузить файл и проверить наличие функции Invoke-API
    if ($IsDotSourcing) {
        # подключить модуль через dotsourcing
        Write-Warning "Лучше не использовать DotSourcing с модулями API провайдеров. Если используете, то проверьте, что при работе скрипта используется только один провайдер или этот модуль один и подключается он последним в данном сеансе. Иначе результат будет непредсказуемый"
        #Write-Warning "Этот процесс очень не надежен. Используйте подключение через Import-Module (не используйте ключ IsDotSourcing)"
        $scriptFile = Join-Path -Path "$($Path)" -ChildPath "$($Provider).ps1"
        if ( -not (Test-Path $scriptFile -PathType Leaf) ) {
            throw "Нет файла-модуля для работы с API ""$($Provider)"": $($scriptFile)"
        }
        #. $scriptFile
        #$moduleProvider = (Get-Module $scriptFile -ListAvailable)
        $result."$($Provider)".module = $null
        $result."$($Provider)".path = $Path
        $result."$($Provider)".file = $scriptFile
    } else {
        # подключить модуль через Import-Module
        $scriptFile = Join-Path -Path "$($Path)" -ChildPath "$($Provider)"
        # проверить наличие каталога api\<Provider>
        if ( -not (Test-Path $scriptFile -PathType Container) ) {
            # нет каталога api\<Provider>
            # проверим наличие файла api\<Provider>.psm1
            if (Test-Path "$($scriptFile).psm1") {
                $scriptFile = "$($scriptFile).psm1"
            } else {
                throw "Нет модуля для работы с API ""$($Provider)"": $($scriptFile) и $($scriptFile).psm1"
            }
        }
        $moduleProvider = (Import-Module $scriptFile -Force -PassThru)
        #$moduleProvider = (Import-Module $scriptFile -Force -PassThru -Prefix $Provider)
        $result."$($Provider)".module = $moduleProvider
        $result."$($Provider)".path = $Path
        $result."$($Provider)".file = $scriptFile
    }

    #Write-Verbose "moduleProvider: $($moduleProvider|ConvertTo-Json -depth 1)"
    #Write-Verbose "result.$($Provider).module: $($result.$Provider.module | ConvertTo-Json -depth 1)"
    Write-Verbose "result.$($Provider).path: $($result.$Provider.path)"
    Write-Verbose "result.$($Provider).file: $($result.$Provider.file)"
    Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    return $result
}

function Get-Invoke-API () {
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
        [Int] $LogLevel=1
    )
    begin {
        $s = "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: =============================================++++++++++++++++++++++++++++"
        Write-Verbose "$($s)"
        #Write-Verbose "Параметры, переданные:`n$($Params|ConvertTo-Json -Depth $LogLevel)"
        # проверить обязательность параметров
        # TODO: потом надо реализовать

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
        $Provider = $Params.Provider
        $Action = $Params.cmd
        $fileIsDotSourcing = $params.provider_file.isDotSourcing
        Write-Verbose "Provider: $($Provider)"
        Write-Verbose "Action:   $($Action)"
        Write-Verbose "fileIsDotSourcing:   $($fileIsDotSourcing)"
        if ($fileIsDotSourcing) {
            Write-Warning "Лучше не использовать DotSourcing с модулями API провайдеров. Если используете, то проверьте, что при работе скрипта используется только один провайдер или этот модуль один и подключается он последним в данном сеансе. Иначе результат будет непредсказуемый"
        }
        # если в модуле API провайдера есть функция Invoke-API, то перевести диспетчеризацию метода API на нее,
        # иначе диспетчеризацию провести здесь
        # флаг, что используем глобальную функцию маршрутизации Action Get-Invoke-API
        $isUseGlobalInvokeAPI = $True
        try {
            # проверить в модуле провайдера наличие функции Invoke-API
            $p = @{"cmd"="_IsPresent_";}
            $command = "$(if (-not $fileIsDotSourcing) {""$($Provider)\""})Invoke-API $(if ($PSBoundParameters.Verbose) {"-Verbose"}) -LogLevel $($LogLevel) -Params" + ' $($p)'
            $test_res = (Invoke-Expression -Command "$($command)")
            Write-Verbose "test_res:`n$($test_res|ConvertTo-Json -Depth $LogLevel)"
            if ($test_res.code -ne 1000) {
                throw "Not Invoke-API for $($Provider)"
            }
            # флаг, что после этого не используем глобальную функцию маршрутизации Action Get-Invoke-API
            $isUseGlobalInvokeAPI = $False
            $command = "$(if (-not $fileIsDotSourcing) {""$($Provider)\""})Invoke-API  $(if ($PSBoundParameters.Verbose) {"-Verbose"}) -LogLevel $($LogLevel) -Params " + '$($Params)'
            Write-Verbose "command: $($command)"
            $result = (Invoke-Expression -Command "$($command)")
        }
        catch {
            if (-not $isUseGlobalInvokeAPI) {
                Write-Verbose "Ошибка в функции маршрутизации Invoke-API в модуле провайдера $($Provider)."
                throw $PSItem
            }
            Write-Verbose "Нет функции маршрутизации Invoke-API в модуле провайдера $($Provider)."
            Write-Verbose "Для дальнейшей работы используется глобальная функция маршрутизации dispatcher.ps1::Get-Invoke-API"
            Write-Verbose "Exception:"
            Write-Verbose "`tInvocationInfo.PositionMessage: $($PSItem.InvocationInfo.PositionMessage)"
            Write-Verbose "`tException.StackTrace ---------:"
            Write-Verbose "`t$($PSItem.Exception.StackTrace)"
        }
        #if ($isUseGlobalInvokeAPI -or ($result.raw.Providers.$Provider.res.)) {
        if ($isUseGlobalInvokeAPI) {
            # здесь если в модуле API провайдера нет функции маршрутизации Invoke-API, или она не удовлетворяет требованию:
            # ответ на cmd='_IsPresent_' не содержит code=1000
            Write-Verbose "Маршрутизируем вызов при помощи глобальной функции $($MyInvocation.InvocationName)"

            # считать секцию файла конфигурации для провайдера
            $ini = $Params.vars.ini
            if ( ("sectionName" -in $Params.Keys) -and $Params.sectionName) {
                $sectN = $Params.sectionName
                #$result += @{'sectionData'= $ini.getSectionValues($Params.sectionName)}
            }elseif ( ("sectionName" -in $Params.params.Keys) -and $Params.params.sectionName) {
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

            # список поддерживаемых функций
            try {
                Write-Verbose "Получаем список поддерживаемых функций"
                $command = "$(if (-not $fileIsDotSourcing) {""$($Provider)\""})Get-SupportedFeatures -sectionIni " + '$($result.sectionData.resultDefs)'
                Write-Verbose "command: $($command)"
                $suppFunc = (Invoke-Expression -Command $command)
                Write-Verbose "Получили список поддерживаемых функций: $($suppFunc|ConvertTo-Json -Depth $LogLevel)"
                $result.resAPI += @{"AllFunc" = $suppFunc}
            }
            catch {
                $message = "Не нашли функцию, возвращающую список поддерживаемых функций: $($Provider)\Get-SupportedFeatures"
                $message += "`n$(''.PadRight(80, '-'))"
                $message += "`nPARENT Exception: $($PSItem.Exception.Message)"
                $message += "`nPARENT InvocationInfo.PositionMessage: $($PSItem.InvocationInfo.PositionMessage)"
                $message += "`n$(''.PadRight(80, '-'))"
                throw $message
            }
            # в списке поддерживаемых функций ищем Action в модуле провайдера
            if ($suppFunc.ContainsKey("$($Action)")) {
                # есть среди поддерживаемых функций Action
                # ищем функцию для Action и вызываем ее
                try {
                    Write-Verbose "Получаем из списка поддерживаемых функций соответствующую функцию $($suppFunc.""$($Action)"") для $($Action)"

                    # список поддерживаемых функций
                    $result += @{"runningFunction"=$suppFunc."$($Action)"}

                    # маршрутизация метода 
                    $command = "$(if (-not $fileIsDotSourcing) {""$($Provider)\""})$($suppFunc.""$($Action)"")  $(if ($PSBoundParameters.Verbose) {"-Verbose"}) -LogLevel $($LogLevel) -Params " + '$($Params)'
                    Write-Verbose "Маршрутизируем command: $($command)"
                    $result.resAPI += @{"HttpResponse" = (Invoke-Expression -Command $command)}
                    # проверить HTTP Response на наличие ошибок
                }
                catch {
                    $message = "Не смогли выполнить функцию для $($Action) => $($suppFunc.""$($Action)"")"
                    $message += "`n$(''.PadRight(80, '-'))"
                    $message += "`nPARENT Exception: $($PSItem.Exception.Message)"
                    $message += "`nPARENT InvocationInfo.PositionMessage: $($PSItem.InvocationInfo.PositionMessage)"
                    $message += "`n$(''.PadRight(80, '-'))"
                    throw $message
                }
            } else {
                throw "Action ""$($Action)"" не поддерживается модулем $($Provider). Список Action: $($suppFunc.Keys)"
            }
        }
    }
    end {
        Write-Verbose "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
        $result += @{'result'=$result.resAPI.HttpResponse.resDomains}
        return $result
    }
}
