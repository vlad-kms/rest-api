#using module .\commonVariable.ps1
function Get-DefaultColor() {
    [CmdletBinding()]
    Param
    (
        [parameter(ValueFromPipeline=$True, Position=0)]
        [System.Management.Automation.Host.PSHost]$HostVar=$null
    )
    if ($null -eq $HostVar) { $HostVar = $Global:Host}
    $BColor = [System.ConsoleColor]'DarkBlue';
    $FColor = [System.ConsoleColor]"White";
    switch ($HostVar.Name) {
        'ConsoleHost' {
            $BColor = $HostVar.ui.rawui.backgroundcolor;
            $FColor = $HostVar.ui.rawui.Foregroundcolor;
            $BColorErr = $HostVar.PrivateData.ErrorBackgroundColor;
            $FColorErr = $HostVar.PrivateData.ErrorForegroundColor;
            break;
        }
        'Visual Studio Code Host' {
            $BColor = $HostVar.ui.rawui.backgroundcolor;
            $FColor = $HostVar.ui.rawui.Foregroundcolor;
            $BColorErr = $HostVar.PrivateData.ErrorBackgroundColor;
            $FColorErr = $HostVar.PrivateData.ErrorForegroundColor;
            break;
        }
        'Windows PowerShell ISE Host'{
            $BColor = $HostVar.PrivateData.ConsolePaneBackgroundColor;
            $FColor = $HostVar.PrivateData.ConsolePaneForegroundColor;
            $BColorErr = $HostVar.PrivateData.ErrorBackgroundColor;
            $FColorErr = $HostVar.PrivateData.ErrorForegroundColor;
            break;
        }
        default {
            $BColor = [System.ConsoleColor]'DarkBlue';
            $FColor = [System.ConsoleColor]"White";
            $BColorErr = [System.ConsoleColor]"Red";;
            $FColorErr = [System.ConsoleColor]"White";
        }
    }
    return @{'Foreground'=$FColor; 'Background'=$BColor; 'ForegroundErr'=$FColorErr; 'BackgroundErr'=$BColorErr}
}

function Console() {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$True, Position=0, Mandatory=$True)]
        [string]$Msg,
        $FGColor="",
        $BGColor=""
    )
    begin{
        if ( ($FGColor -eq "") -or ($BGColor -eq "") ) {
            $defaultColor=Get-DefaultColor
        }
        if ($FGColor -eq "") {$FGColor = $defaultColor.Foreground}
        else {$FGColor = [ConsoleColor]$FGColor}
        if ($BGColor -eq "") {$BGColor = $defaultColor.Background}
        else {$BGColor = [ConsoleColor]$BGColor}
    }
    process {

        $msg | Write-Host -ForegroundColor $FGColor -BackgroundColor $BGColor
    }
}
function consoleError(){
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$True, Position=0, Mandatory=$True)]
        [string]$Msg,
        $FGColor="",
        $BGColor=""
    )
    if ( ($FGColor -eq "") -or ($BGColor -eq "") ) {
        $defaultColor=Get-DefaultColor
    }
    if ($FGColor -eq "") {$FGColor = $defaultColor.ForegroundErr}
    if ($BGColor -eq "") {$BGColor = $defaultColor.BackgroundErr}
    $Msg | Console -FGColor $FGColor -BGColor $BGColor
}

function Get-ArrayModules() {
    <#
    .SYNOPSIS
    Подготовить массив модулей для загрузки
    .DESCRIPTION
    Подготовить массив c модулями для загрузки через sourcing
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Hashtable[]] $Modules,
        [Parameter(Position=1)]
        [String[]] $Path=@(),
        [Parameter(Mandatory=$true, Position=2)]
        [CommonVariable] $Vars,
        [switch] $IncludeCommon
    )
    begin{
        Write-Verbose "$($MyInvocation.InvocationName) ENTER: ======================================================="
        Write-Verbose "$($MyInvocation.InvocationName) begin: ======================================================="
        $Result=[ordered]@{}
        $useCommonDir = $IncludeCommon.IsPresent
        # выяснить импортировали ли модуль $Module (аргумент скрипта) или нет
        if ($Vars.existsProperty("IsImportModule")) {
            $IsImp = $vars.IsImportModule
        } else {
            $IsImp = $false
        }
        <#
        if ($Vars.existsProperty("ScriptPath")) {
            $scriptPath = $vars.ScriptPath
        } else {
            if ($global:PSVersionTable.BuildVersion.Major -gt 3) {
                $scriptPath = $PSScriptRoot
            } else {
                $scriptPath = ($PSCommandPath | Split-Path -Parent)
            }
        }
        #>
        $scriptPath = Get-PathScript -Vars $Vars
        $mod = $Module
        #if ( ($Vars.existsProperty("argsAll")) -and ($Vars.argsAll -is [hashtable]) -and ($Vars.args.ContainsKey("Module")) ) {
        #    $mod = $Vars.args.Module
        #}
        Write-Verbose "Модуль ""$($mod)"" $(if ($IsImp) {"импортирован"} else {"не импортирован"})"
        Write-Verbose "Путь скрипта: $($scriptPath)"
        Write-Verbose "Использовать ли пути скрипта и импортированного модуля avvClasses (.\, .\classes, .\.classes, classes в каталоге модуля): $($useCommonDir)"
        if ( ($null -eq $Path) -or
            #($Path.GetType() -ne @().getType()) -or
            #( ($Path.GetType() -eq @().getType()) -and ($Path.Length -eq 0))
            ($Path -isnot [array]) -or
            ( ($Path -is [array]) -and ($Path.Length -eq 0) )
        ) {
            # Если $Path не массив, $null или пустой массив, то проинициализировать массив: @('<ScriptPath>', '<ScriptPath>\classes', '<ScriptPath>\.classes', '<ModulePath>\classes')
            # 1-й - '<ScriptPath>', каталог скрипта
            # Если передан IncludeCommon, то еще добавляются:
            #   1) '<ScriptPath>\classes', '<ScriptPath>\.classes'
            #   2) '<ModulePath>\classes', если вдобавок был импортирован модуль avvClasses
            Write-Verbose "Массив путей для поиска модулей передан пустым"
            Clear-Variable Path
            $Path+=$scriptPath
        } else {
            # добавить к путям поиска <ScriptPath>, <ScriptPath>\classes, <ScriptPath>\.classes и <ModulePath>\classes,
            # если только передан параметр IncludeCommon, причем 4-й путь добавить только, если при этом импортировали модуль avvClasses
            Write-Verbose "Массив путей для поиска модулей передан не пустым"
            if ($useCommonDir -and ($Path -notcontains $scriptPath) ) {
                $Path+=$scriptPath
            }
        }
        if ($useCommonDir) {
            if ( ($Path -notcontains 'classes') -and ($Path -notcontains '.\classes') ) {
                $Path+=(Join-Path -Path $scriptPath -ChildPath 'classes')
            }
            if ( ($Path -notcontains '.classes') -and ($Path -notcontains '.\.classes') ) {
                $Path+=(Join-Path -Path $scriptPath -ChildPath '.classes')
            }
            #$Path+=@("$(Join-Path -Path $scriptPath -ChildPath 'classes')", "$(Join-Path -Path $scriptPath -ChildPath '.classes')")
            if ($isImp) {
                $Path += (Get-InfoModule).PathModules
            }
        }
        Write-Verbose "Modules.Count: $($Modules.Count)"
        Write-Verbose "Пути для поиска модулей: $($Path)"
    }
    process{
        Write-Verbose "$($MyInvocation.InvocationName) process: ======================================================="
        <#
        if ($null -ne $_) {
            Write-Verbose "_:"
            Write-Verbose $_
        }
        if ($null -ne $PSItem) {
            Write-Verbose "PSItem:"
            Write-Verbose $PSItem
        }
        Write-Verbose "Modules.getType():$($Modules.getType())"
        Write-Verbose "Modules.length:$($Modules.Length)"
        #>
        $Modules.ForEach({
            Write-Verbose "Текущий модуль: $(($_|ConvertTo-Json -Depth 2))"
            $Result.Add("$($_.Name)", @{
                "Fullname"  = '';
                "Action"    = $(if ($_.ContainsKey("Action")) {$_.Action} else {[ActionWithModule]::dotSourcing})
                "isFound"   = $false;
                "Required"  = $(if ($_.ContainsKey("Required")) {$_.Required} else {$true})
            })
            #Write-Verbose "Текущий результат: $(($Result|ConvertTo-Json -Depth 2))"
            # Теперь проверить наличие модуля в путях из маасива. Проверять до первого наличия
            foreach($item in $Path) {
                # если не абсолютный путь, то дополнить слева $PathScript'ом
                if ( -not (Split-Path $item -IsAbsolute) ) {
                    $fn = (Join-Path $scriptPath -ChildPath $item)
                } else {
                    $fn = $item
                }
                Write-Verbose "Проверим наличие файла ""$($_.Name)"" по пути ""$($item)"" (""$($fn)"")"
                $fn = Join-Path -Path $fn -ChildPath $_.Name
                if (Test-Path -Path $fn -PathType Leaf) {
                    $Result["$($_.Name)"].Fullname = $fn
                    $Result["$($_.Name)"].isFound = $true
                    Write-Verbose "Нашли файл $($_.Name) по пути $($item)"
                    break
                }
            }
        })

    }
    end{
        Write-Verbose "$($MyInvocation.InvocationName) end: ======================================================="
        Write-Verbose "Result: $($result | ConvertTo-Json -Depth 10)"
        Write-Verbose "$($MyInvocation.InvocationName) EXIT: ======================================================="
        return $result
    }
}

function Get-PathScript() {
    <#
    .SYNOPSIS
    Вернуть путь скрипта
    .DESCRIPTION
    Вернуть путь запущенного скрипта
    #>
    [CmdletBinding()]
    param (
        [CommonVariable] $Vars=$null
    )
    Write-Verbose "$($MyInvocation.InvocationName) ENTER: ======================================================="
    if ( ($null -ne $Vars) -and ($Vars -is [CommonVariable]) -and ($Vars.existsProperty('scriptPath')) ) {
        $result = $Vars.scriptPath
        Write-Verbose "Взять путь из [CommonVariable]: $($result)"
    }
    else {
        if ($global:PSVersionTable.BuildVersion.Major -gt 3) {
            $result = $PSScriptRoot
        } else {
            $result = ($PSCommandPath | Split-Path -Parent)
        }
        Write-Verbose "Взять путь из системных автопеременных: $($result)"
    }
    Write-Verbose "return: $($result)"
    Write-Verbose "$($MyInvocation.InvocationName) LEAVE: ======================================================="
    return $result
}

<#
.SYNOPSIS
Пока не работает

.DESCRIPTION
Long description

.PARAMETER InputObject
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function ConvertPSObjectToHashtable
{
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    process
    {
        if ($null -eq $InputObject) { return $null }

        if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string])
        {
            $collection = @(
                foreach ($object in $InputObject) { ConvertPSObjectToHashtable $object }
            )

            Write-Output -NoEnumerate $collection
        }
        elseif ($InputObject -is [psobject])
        {
            $hash = @{}

            foreach ($property in $InputObject.PSObject.Properties)
            {
                $hash[$property.Name] = ConvertPSObjectToHashtable $property.Value
            }

            $hash
        }
        else
        {
            $InputObject
        }
    }
}

<#
.SYNOPSIS
HasProperty -Value Object -Property "Name"
HasProperty Object "Name"

.DESCRIPTION
Содержит ли Hashtable, PSCustomObject или Object свойство Name

.PARAMETER InputObject
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>

