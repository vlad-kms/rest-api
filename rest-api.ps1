<#
    .SYNOPSIS
    Обертка для обращений к API DNS провайдеров
    .\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{'config'=@{'p1'='v1'; 'p2'='v2'};'s1'=@{}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; 'test1'=123} -TypeConfig INI  -Debug -Verbose;    .DESCRIPTION
    .DESCRIPTION
    Обертка для обращений к API DNS провайдеров
    .PARAMETER Provider
    Провайдер API
    .PARAMETER FileIni
    Файл настроек для провайдера(ов) в формате или INI, или JSON
    .PARAMETER Action
    Действие для выполнения через API
    .PARAMETER TypeConfig
    Тип файла настроек:
    Принимаемые значения:
        - INI   - в формате INI.
        - JSON  - в формате JSON.**
    Используется если у файла настроек расширение не .ini или не json, т.е. не может определить тип файла по расширению
    .PARAMETER LogLevel=1,
    Уровень логирования скрипта. Чем больше значение, тем больше логов
    .PARAMETER LogFilename
    Имя файла логов
    .PARAMETER ExtParams
    Расширенные параметры типа HASHTABLE.
    Могут заменять параметры из FileInin.
    Служит для передачи других различных параметров скрипту.
    Пример:
    .\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{'config'=@{'p1'='v1'; 'p2'='v2'};'s1'=@{}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; 'test1'=123} -TypeConfig INI  -Debug -Verbose;
    .PARAMETER PathIncludes
    Массив путей для поиска включаемых (dot sourcing) модулей
    .PARAMETER Module
    Имя модуля для импорта. Пример: D:\Tools\~scripts.ps\avvClasses, он должен быть организован по требованиям модулей Powershell
    .OUTPUTS
    Name: result
    BaseType: Hashtable
        - [ErrorRecord[]]Errors = @()  : записи Exception, возвращаемая из API
        - [hashtable] raw = @{}     :
        - [int] retCode             : числовой код возврата.
                0   - нет ошибок
                < 0 - критические ошибки
                > 0:
                    0-1999 - правильные кода возврата
                    1000-2999 - предупреждения
                    4000-4999 - коды возврата http+4000 (yfghbvth 4200 - Ok; 4400 Authority error и т.д.)
        - [String] message      : сообщение, поясняющее код возврата
        - [Hashtable] resAPI    : структура для возврата из вызываемой функции, соответствующей cmd(Action)
        - [System.Collections.Generic.List[String]]
            logs                : массив сообщений
        - [ErrorRecord] error   : запись Exception, возвращаемая из API
#>
[CmdletBinding()]
[OutputType([Hashtable])]
Param (
    [Parameter(ValueFromPipeline=$True, Position=0)]
    [string] $Provider='selectel',
    [Parameter(Position=1)]
    [string] $FileIni='',
    [Parameter(Position=2)]
    [string] $Action='getInfo',
    [ValidateSet('INI', 'JSON')]
    [String] $TypeConfig="JSON",
    [int] $LogLevel=1,
    [string] $LogFilename="",
    [hashtable] $ExtParams=@{},
    [string[]] $PathIncludes=@(),
    [string] $Module='avvClasses'
)

#Requires -Version 5

$deliveryToProd = $True

Write-Verbose "$($MyInvocation.InvocationName) ENTER: ==================================================================="

Write-Verbose "Provider: $($Provider)"
Write-Verbose "FileIni: $($FileIni)"
Write-Verbose "Action: $($Action)"
Write-Verbose "TypeConfig: $($TypeConfig)"
Write-Verbose "LogFilename: $($LogFilename)"
Write-Verbose "LogLevel: $($LogLevel)"
Write-Verbose "ExtParams: $($ExtParams|ConvertTo-Json -Depth 5)"
Write-Verbose "PathIncludes: $($PathIncludes)"
Write-Verbose "Module: $($Module)"
Write-Verbose "PSBoundParameters.Debug: $($PSBoundParameters.Debug)"
Write-Verbose "PSBoundParameters.Debug.IsPresent: $($PSBoundParameters.Debug.IsPresent)"
Write-Verbose "PSBoundParameters.Verbose: $($PSBoundParameters.Verbose)"
Write-Verbose "PSBoundParameters.Verbose.IsPresent: $($PSBoundParameters.Verbose.IsPresent)"

<###### Проверить переданные параметры ######>
# каталог откуда запускается скрипт
if ($global:PSVersionTable.BuildVersion.Major -gt 3) {
    $sr = $PSScriptRoot

} else {
    $sr = ($PSCommandPath | Split-Path -Parent)
}
#echo $sr
#echo ($MyInvocation.MyCommand.Path)
#$sr = (Get-PathScript)

# Exception и выход, если ошибка подключения локальных модулей
try {
    . (Join-Path -Path $sr -ChildPath commonVariable.ps1)
    . (Join-Path -Path $sr -ChildPath .\commonFunc.ps1)
}
catch {
    throw "Ошибка подключения модулей: commonVariable.ps1, commonFunc.ps1";
}
Write-Verbose "Версия Powershell: $($PSVersionTable.PSVersion)"
# Прервать скрипт, если версия Powershell (AND):
#   младше 5-ой
#   версия Powershell major = 5 и minor < 1
if (
        ($PSVersionTable.PSVersion.Major -lt 5) -or
        ( ($PSVersionTable.PSVersion.Major -eq 5) -and ($PSVersionTable.PSVersion.Minor -lt 1) )
) {
    #consoleError("Версия major powershell должна быть не младше 5-й")
    Write-Error "Версия major powershell должна быть не младше 5-й"
    return 1;
}

$isDebug = [bool]$PSBoundParameters.Debug.IsPresent
# путь к выполняемому скрипту
$cv = [CommonVariable]::new($sr)

$argsP = @{}
$argsP['Provider']    = $Provider
$argsP['FileIni']     = $FileIni
$argsP['Action']      = $Action
$argsP['TypeConfig']  = $TypeConfig
$argsP['LogLevel']    = $LogLevel
$argsP['LogFilename'] = $LogFilename
$argsP['ExtParams']   = $ExtParams
$argsP['PathIncludes']= $PathIncludes
$argsP['Module']      = $Module

$cv.addProperties(@('IsImportModule', 'isDotSourcing', 'isDeb', 'typeConfigFile'), @($False, $False, $isDebug, $TypeConfig))
$cv.addProperties(@{
    'args'  = $MyInvocation.BoundParameters
    'argsAll'  = $argsP
    'ini'   = $null
})

# Файл конфигурации задан в параметрах, но если его не существует (или он не является обычным файлом), то ошибка и выход из скрипта
if ($FileIni -and !(Test-Path -Path $FileIni -PathType Leaf)) {
    #consoleError("В параметрах задан файл настроек $($FileIni), но он не существует")
    Write-Error "В параметрах задан файл настроек $($FileIni), но он не существует"
    return;
}
# тип конфига INI или JSON
$ext = "";
if ($FileIni -and (Test-Path -Path $FileIni)) {
    # Получить расширение файла с настройками, если он передан
    # Оно должно быть или .ini или .json. Если не эти расширения,
    # то ошибка и прервать скрипт
    $ext = (Get-ChildItem -Path $FileIni).Extension.Trim().Substring(1).ToUpper()
    if ( ($ext -eq 'JSON') -or ($ext -eq 'INI') ) {
        $cv.typeConfigFile = $ext
    } else {
        $cv.typeConfigFile = $TypeConfig.ToUpper()
    }
} elseif ($FileIni -and !(Test-Path -Path $FileIni)) {
    #consoleError("В параметрах задан файл настроек $($FileIni), но он не существует")
    Write-Error "В параметрах задан файл настроек $($FileIni), но он не существует"
    return 1;
}

# Импорт модуля $Module. Если их нет или ошибка при импорте, то dotsourcing модулей
try {
    # ИМПОРТ
    $fullNameModule = $Module;
    $nameModule = Split-Path -Path $fullNameModule -Leaf
    # проверить существование модуля $nameModule
    try {
        $m=(Get-Module -ListAvailable -Name "$($fullNameModule)" -ErrorAction SilentlyContinue)
    }
    catch {
        $m=$null
    }
    if ($null -ne $m) {
        # модуль есть, импортируем его. Сначала выгрузим, затем заново загрузим
        if ((Get-Module -Name "$($nameModule)")) { Remove-Module "$($nameModule)" }
        Import-Module "$($fullNameModule)" -Force -ErrorAction Stop
        $cv.IsImportModule=$True
    }
} catch {
    $cv.IsImportModule=$False
}

if ( ! $cv.IsImportModule) {
    # DOTSOURCING
    # Здесь если ранее не смогли импротировать модуль $Module. Пробуем провести dotsourcing требуемых модулей:
    # пробуем dotsourcing avvBase.ps1 и classCFG.ps1', сначала из каталога запуска скрипта, если нет, то .\.classes, затем .\classes
    # Если не смогли, то ошибка
    #$pathModules = @('.\', '.classes','classes')

    $nameModules = @(@{"Name"='avvBase.ps1'; "Required"=$True;}, @{"Name"='classCFG.ps1'; "Required"=$True; "Action"=[ActionWithModule]::dotSourcing}, @{"Name"="ddd"; "Required"=$false})
    $listModules=($nameModules | Get-ArrayModules -Path $PathIncludes -Vars $cv -IncludeCommon)
    $listModules.Keys.ForEach({
        $item=$listModules[$_]
        # Проверить, что требуемые модули найдены в путях поиска.
        # Если хотя бы один не найден, то прервать выполнение скрипта
        if ($item.Required -and -not ($item.isFound -and $item.Fullname.Trim())) {
            throw "Не найден требуемый модуль $($_)"
        }
        if ($item.isFound) {
            # модуль нашли, теперь загрузим его
            Write-Verbose "Модуль найден: $($item.Fullname.Trim()). Будем его загружать через $(if ($item.Action -eq [ActionWithModule]::dotSourcing) {"dot sourcing"} else {"import"})"
            if ($item.Action -eq [ActionWithModule]::dotSourcing) {
                # dot sourcing module
                . $item.Fullname
            } elseif ($item.Action -eq [ActionWithModule]::Import) {
                # import module
                Import-Module -Force -Name $item.Fullname
            } else {
                throw "Не верный способ $($item.Action) загрузки модуля $($_)"
            }
        } else {
            # модуль не нашли и здесь он не может быть обязательным
            Write-Verbose "Модуль $($_) не является обязательным к загрузке и его не нашли. Пропустим его загрузку."
        }
    })
    $cv.isDotSourcing = $True
}

# загрузить другие модули
$nameModules = @(@{"Name"='dispatсher.ps1'; "Required"=$True; "Action"=[ActionWithModule]::dotSourcing})
#$listModules=($nameModules | Get-ArrayModules -Path ($PathIncludes + ".classes") -Vars $cv)
$listModules=($nameModules | Get-ArrayModules -Path 'api' -Vars $cv)
$listModules.Keys.ForEach({
    $item=$listModules[$_]
    # Проверить, что требуемые модули найдены в путях поиска.
    # Если хотя бы один не найден, то прервать выполнение скрипта
    if ($item.Required -and -not ($item.isFound -and $item.Fullname.Trim())) {
        throw "Не найден требуемый модуль $($_)"
    }
    if ($item.isFound) {
        # модуль нашли, теперь загрузим его
        Write-Verbose "Модуль найден: $($item.Fullname.Trim()). Будем его загружать через $(if ($item.Action -eq [ActionWithModule]::dotSourcing) {"dot sourcing"} else {"import"})"
        if ($item.Action -eq [ActionWithModule]::dotSourcing) {
            # dot sourcing module
            . $item.Fullname
        } elseif ($item.Action -eq [ActionWithModule]::Import) {
            # import module
            Import-Module -Force -Name $item.Fullname
        } else {
            throw "Не верный способ $($item.Action) загрузки модуля $($_)"
        }
    } else {
        # модуль не нашли и здесь он не может быть обязательным
        Write-Verbose "Модуль $($_) не является обязательным к загрузке и его не нашли. Пропустим его загрузку."
    }
})

# добавить в hashtable для констуктора данные для объекта
#$ExtParams.Add('_new_', $ExtParams)
$ExtParams._obj_ += @{filename=$FileIni; errorAsException=$True}

if ($cv.IsImportModule) {
    # были импортированы модули
    if ($cv.typeConfigFile -eq 'INI') {
        # INI
        $className='IniCFG'
    } elseif ($cv.typeConfigFile -eq 'JSON') {
        # JSON
        $className='JsonCFG'
    } else {
        # не передан файл конфигурации или не смогли вычислить тип по расширению файла
        throw "Неверный формат файла с конфигурацией"
    }
    $cv.addProperty('className', $className)
    # создали объет для файла конфигурации
    $cv.ini=(Get-AvvClass -ClassName $className -Params $ExtParams -Verbose:($PSBoundParameters.Verbose))
} elseif ($cv.isDotSourcing) {
    # были dotsourcing модули
    if ($cv.typeConfigFile -eq 'INI') {
        # INI
        $cv.ini=[IniCFG]::New($ExtParams)
    } elseif ($cv.typeConfigFile -eq 'JSON') {
        # JSON
        $cv.ini=[JsonCFG]::New($ExtParams)
    } else {
        # не передан файл конфигурации или не смогли вычислить тип по расширению файла
        throw "Неверный формат файла с конфигурацией"
    }
} else {
    # не смогли ни подключить модули, ни dotsourcing
    throw "Ошибка при импорте $($nameModule) или dot-sourcing $($nameModules)"
}

# считали секцию для провайдера
#$cv.addProperty('sectionData', ($cv.ini.getSectionValues($Provider)))

$result=@{}
if (-not $deliveryToProd) {
    $result.Vars = $cv
}
$result.Errors = [System.Management.Automation.ErrorRecord[]]@()
$result.raw = @{}
$result.raw += @{"Providers" = @{}}
$result.retCode=0

if ($Action.ToUpper() -eq '_TEST_') {
    Write-Verbose "Testing... =========================================="
    
    #$result.raw.Providers += ("test_file"    | Get-FileProvider -Vars $cv -Verbose:$PSBoundParameters.Verbose -LogLevel $LogLevel)
    #$result.raw.Providers += ("test_ds_file" | Get-FileProvider -Vars $cv -Verbose:$PSBoundParameters.Verbose -LogLevel $LogLevel -IsDotSourcing)
    $result.raw.Providers += ("test_mod"     | Get-FileProvider -Vars $cv -Verbose:$PSBoundParameters.Verbose -LogLevel $LogLevel)
    $result.raw.Providers.Keys.ForEach({
        Write-Verbose $_
        $p = @{
            "cmd"="test";
            "provider"="$($_)";
            "provider_file"=$result.raw.Providers."$($_)";
            "vars"=$cv;
            "params" = $ExtParams;
        }
        #Write-Verbose "параметры для передачи в маршрутизацию:`n$($p|ConvertTo-Json -Depth 2)"
        if ($_ -eq 'test_mod') {
            $p += @{'sectionName'='dns_selectel'}
            #$p.cmd = "ttt"
        }
        $command = "Get-Invoke-API -Params " + '$($p)' + " $(if ($PSBoundParameters.Verbose) { "-Verbose" }) -LogLevel $($LogLevel)"
        Write-Verbose "command: $($command)"
        $rm = (Invoke-Expression -Command $command)
        $result.raw.Providers.$_.res += $rm
        if ($rm.code -lt 0) {
            Write-Verbose "$($rm | ConvertTo-Json)"
            throw $rm.Message
            #throw $rm.Error.Exception.Message
            #Write-Verbose "===================== $($rm.code -lt 0) ========================================"
            #Write-Verbose "===================== $($rm.code.gettype()) ========================================"
        }
    })
} else {
    Write-Verbose "Working... =========================================="
    $p = @{"cmd" = $Action; "provider"="$($Provider)"; "vars"=$cv; "params"=$ExtParams}
    Write-Verbose "параметры для передачи в маршрутизацию:`n$($p|ConvertTo-Json -Depth $LogLevel)"
    $result.raw.Providers += ("$($Provider)" | Get-FileProvider -Vars $cv -Verbose:$PSBoundParameters.Verbose -LogLevel $LogLevel)
    $command = "Get-Invoke-API $(if ($PSBoundParameters.Verbose) { "-Verbose" }) -LogLevel $($LogLevel) -Params " + '$($p)'
    Write-Verbose "command: $($command)"
    $rm = (Invoke-Expression -Command $command)
    $result.raw.Providers.$Provider.res += $rm
}
#(get-module -all).path
if ($PSBoundParameters.Debug) {
    $global:cvar=$cv
}

return $result

#man ExistsFilesModules -Full
#man getArrayModules -Full
