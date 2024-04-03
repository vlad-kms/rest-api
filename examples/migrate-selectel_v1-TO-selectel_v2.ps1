<#
Миграция домена из legacy в actual
#>

[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String[]]$domains,
    [int]$LL=1,
    [switch]$Force,
    [switch]$VerboseLib,
    [Alias('adt')]
    [switch]$AddDatetimeLogging,
    [switch]$WhatIf
)
<#
function levelMessage($mess, $beginLevel, $widthSpaceLevel){
    foreach ($s in $mess){
        $result = ' '.PadRight($beginLevel+$widthSpaceLevel)+$s
    }
    return $result
}
#>
begin {
    #function levelMessage([string[]]$mess, [int]$beginLevel, [int]$widthSpaceLevel){
    function levelMessage(){
        Param(
            [Parameter(ValueFromPipeline=$true, Position=0, Mandatory=$true)]
            [String[]]$mess,
            [Parameter(Position=1)]
            [Alias('idt')]
            [int]$Indent=0,
            [Parameter(Position=2)]
            [Alias('spcSub')]
            [int]$SpacesSubstitution=4
        )
        $lstr=' '.PadRight($Indent*$SpacesSubstitution)
        $result = $mess -replace "(?m)^", "$lstr"
        if ([bool]$AddDatetimeLogging) {
            $result = $result -replace "(?m)^", "$(Get-Date)  "
        }
        return $result
    }

    # INIT common variable
    [int]$indentOneElement=2
    $vbl=[bool]$VerboseLib
    $sourceKey='source'
    $processingKey='process'
    #
    Write-Host "$(get-date -Format "yyyyMMdd HH:mm:ss") ::: Миграция доменов Selectel(legacy) --> Selectel(actual) (v1 --> v2)" -ForegroundColor Green
    $s = "$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose ($s | levelMessage)
    # список всех доменов legacy (v1)
    Write-Progress -Id 0 "Вызов API: получение доменов"
    $domains_legacy=(.\rest-api.ps1 `
        -Provider 'dns_selectel' `
        -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
        -ExtParams @{ `
            'CFG'=@{ `
                'dns_selectel'=@{ `
                    'version'="v1"; `
                    "config_v2"=@{ `
                        "token_use_env"="0" `
                    } `
                } `
            }; `
        } `
        -Action 'gds' `
        -LogLevel $LL `
        -vb:$vbl `
    )
    if ($domains_legacy.retCode -ne 200) {
        throw "Ошибка получения доменов legacy (v1)"
    } else {
        $domains_legacy = $domains_legacy.result
    }
    Write-Verbose (levelMessage -Mess "Все домены legacy:" -Indent ($indentOneElement - 1))
    Write-Verbose (levelMessage -Mess ($domains_legacy|ConvertTo-Json -Depth 4) -Indent $indentOneElement)
    # список всех доменов actual (v2)
    $domains_actual=(.\rest-api.ps1 `
        -Provider 'dns_selectel' `
        -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
        -ExtParams @{ `
            'CFG'=@{ `
                'dns_selectel'=@{ `
                    'version'="v2"; `
                    "config_v2"=@{ `
                        "token_use_env"="0" `
                    } `
                } `
            }; `
        } `
        -Action 'gds' `
        -LogLevel $LL `
        -vb:$vbl `
    )
    if ($domains_actual.retCode -ne 200) {
        throw "Ошибка получения доменов actual (v2)"
    } else {
        $domains_actual = $domains_actual.result
    }
    Write-Verbose (levelMessage "Все домены actual:" -Indent ($indentOneElement - 1))
    Write-Verbose (levelMessage ($domains_actual|ConvertTo-Json -Depth 4) -Indent $indentOneElement)
    $result=@{"$sourceKey"=@{'actual'=$domains_actual; "legacy"=$domains_legacy}; "$processingKey"=@{}; "raw"=@{"actual"=@{'domains'=$domains_actual}; "legacy"=@{'domains'=$domains_legacy};}}
}
process {
    # проверить существование домена в legacy
    # Сначала считаем все записи из домена legacy
    foreach ($e in $domains) {
        Write-Progress -Id 0 "Читаем домен $($e) legacy (v1)"
        Write-Verbose (levelMessage "Элемент массива (домен): ""$e""" -Indent ($indentOneElement-1))
        $result."$processingKey" += @{$e=@{'result'=0}}
        $domain_legacy = ($domains_legacy | Where-Object -Property Name -EQ "$e")
        $result."$processingKey"."$e".legacy_id = $domain_legacy.id
        $result."$processingKey"."$e".IsPresent=[bool]$domain_legacy
        if ($result."$processingKey"."$e".IsPresent)
        {
            # в legacy есть, пробуем мигрировать в actual
            Write-Verbose (levelMessage """$($e)"" существует в legacy, пробуем мигрировать в actual" -Indent $indentOneElement)

            # флаг, что домен уже существует в actual
            $domain_actual = ($domains_actual | Where-Object -Property Name -EQ "$($e).")
            $result."$processingKey"."$e".ExistsInActual = [bool]($domain_actual)
            if ( $result."$processingKey"."$e".ExistsInActual ) {
                # есть такой домен в приемнике actual (v2)
                # если нет ключа -Force, то не выполнять миграцию
                $strMess = "Домен ""$($e)"" уже существует в actual (v2)."
                Write-Verbose (levelMessage $strMess -Indent $indentOneElement)
                $result."$processingKey"."$e".mess += ,$strMess
                if ( -not $Force) {
                    $strMess = "Ключ -Force не передан в командлет, ""$($e)"" мигрировать не будем"
                    Write-Verbose (levelMessage $strMess -Indent $indentOneElement)
                    $result."$processingKey"."$e".mess += ,$strMess
                    $result."$processingKey"."$e".IsMigrate = $false
                    # INFO_RESULT=20, такой домен уже существует в actual (v2)
                    $result."$processingKey"."$e".result = 20;
                } else {
                    $strMess = "Будем мигрировать принудительно, объединяя два домена (legacy и actual)."
                    Write-Verbose (levelMessage $strMess -Indent $indentOneElement)
                    $result."$processingKey"."$e".actual_id = $domain_actual.id
                    $result."$processingKey"."$e".mess += , $strMess
                }
            }
            if ($result."$processingKey"."$e".result -eq 0) {
                $strMess="Начинаем миграцию ""$($e)"" из legacy -> actual........................"
                Write-Verbose (levelMessage $strMess -Indent $indentOneElement)
                $result."$processingKey"."$e".IsMigrate = $true
                $result."$processingKey"."$e".mess += ,$strMess
                <#####################################
                # Здесь окажемся только в двух случаях:
                #   1) домен существует только в legacy
                #   2) домен существует и в legacy, и в actual, и установлен флаг -Force
                ######################################>
                # считать все ресурсные записи домена source (legacy)
                $strMess="Читаем ресурсные записи legacy домена ""$($e)"""
                Write-Verbose (levelMessage $strMess -Indent $indentOneElement)
                $result."$processingKey"."$e".mess += ,$strMess
                $legacy_rrset = (.\rest-api.ps1 `
                    -Provider 'dns_selectel' `
                    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
                    -ExtParams @{ `
                        'CFG'=@{ `
                            'dns_selectel'=@{ `
                                'version'="v1"; `
                                "config_v2"=@{ `
                                    "token_use_env"="0" `
                                } `
                            } `
                        }; `
                        'domain'="$($e)"
                    } `
                    -Action 'grs' `
                    -LogLevel $LL `
                    -vb:$vbl `
                    )
                if ($legacy_rrset.retCode -eq 200) {
                    # нет ошибок при чтении legacy rrset
                    $result."$processingKey"."$e".legacy_rrset = $legacy_rrset.result
                    $result.raw.legacy += @{"$e"=@{"rrset" = $legacy_rrset}}
                } else {
                    $strMess = "Не считали rrset legacy домена ""$($e)"". HTTP code: $($legacy_rrset.retCode); $($legacy_rrset.result)"
                    $result."$processingKey"."$e".mess += ,$strMess
                    $result."$processingKey"."$e".IsMigrate=$false
                    # INFO_RESULT=101, ошибка чтения RRSET в legacy (v1)
                    $result."$processingKey"."$e".result = 101;
                    #return $result
                    throw $strMess
                }
                if ($result."$processingKey"."$e".ExistsInActual -and $Force) { # условие (-and $Force) вообще-то избыточно, но пусть будет
                    # т.к. домен уже есть в actual (v2) и установлен флаг $Force, то считать rrset и из домена actual (v2)
                    $strMess="Читаем ресурсные записи actual домена ""$($e)"""
                    Write-Verbose (levelMessage $strMess -Indent $indentOneElement)
                    $result."$processingKey"."$e".mess += ,$strMess
                    $actual_rrset = (.\rest-api.ps1 `
                        -Provider 'dns_selectel' `
                        -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
                        -ExtParams @{ `
                            'CFG'=@{ `
                                'dns_selectel'=@{ `
                                    'version'="v2"; `
                                    "config_v2"=@{ `
                                        "token_use_env"="0" `
                                    } `
                                } `
                            }; `
                            'domain'="$($e)"
                        } `
                        -Action 'grs' `
                        -LogLevel $LL `
                        -vb:$vbl `
                    )
                    if ($actual_rrset.retCode -eq 200) {
                        # нет ошибок при чтении actual rrset
                        $aar = [PSCustomObject]$actual_rrset.result
                        $result.raw.actual += @{"$e"=@{"rrset" = $actual_rrset}}
                    } else {
                        $strMess="Не считали rrset actual домена. HTTP code: $($actual_rrset.retCode); $($actual_rrset.result)"
                        $result."$processingKey"."$e".mess += ,$strMess
                        $result."$processingKey"."$e".IsMigrate=$false
                        # INFO_RESULT=100, ошибка чтения RRSET в actual (v2)
                        $result."$processingKey"."$e".result = 100;
                        #return $result
                        throw $strMess
                    }
                    # сгруппировать считанные записи actual по типам записей
                    if (-not $result."$processingKey"."$e".ContainsKey("actual_rrset") -or ($null -eq $result."$processingKey"."$e".actual_rrset) ) {
                        $result."$processingKey"."$e".actual_rrset = @{}
                    }
                    foreach ($record in $aar) {
                        #
                        $type = $record.type.ToUpper()
                        if (-not $result."$processingKey"."$e".actual_rrset.ContainsKey($type)) {
                            # нет такого свойства $type RRSET
                            $result."$processingKey"."$e".actual_rrset.$type = @()
                        }
                        $result."$processingKey"."$e".actual_rrset.$type += $record
                    }
                } else {
                    # домен не существует в actual, надо добавить его в actual
                    <##>
                    if (-not $WhatIf) {
                        $domain_added_actual = (.\rest-api.ps1 `
                            -Provider 'dns_selectel' `
                            -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
                            -ExtParams @{ `
                                'CFG'=@{ `
                                    'dns_selectel'=@{ `
                                        'version'="v2"; `
                                        "config_v2"=@{ `
                                            "token_use_env"="0" `
                                        } `
                                    } `
                                }; `
                                'domain'="$($e)" `
                            } `
                            -Action 'domainAdd' `
                            -LogLevel $LL `
                            -vb:$vbl `
                        )
                        <##>
                        if ($domain_added_actual.retCode -eq 200) {
                            # нет ошибок при чтении actual rrset
                            $result."$processingKey"."$e".actual_id = $domain_added_actual.result.id
                            $result.raw.actual += @{"$e"=@{"domain" = $domain_added_actual.result.id}}
                        } else {
                            $strMess="Не смогли добавить домен $($e) в  actual. HTTP code: $($domain_added_actual.retCode); $($domain_added_actual.result)"
                            $result."$processingKey"."$e".mess += ,$strMess
                            $result."$processingKey"."$e".IsMigrate=$false
                            # INFO_RESULT=102, ошибка добавления нового домена в actual (v2)
                            $result."$processingKey"."$e".result = 102;
                            #return $result
                            throw $strMess
                        }
                    } else {
                        Write-Host "What If: добавили домен $($e) а actual (v2)" -ForegroundColor DarkCyan
                    }
                }
                # подготовили записи, начинаем процесс
                #
                if (-not $result."$processingKey"."$e".ContainsKey("actual_rrset")) {
                    $result."$processingKey"."$e".actual_rrset = @{}
                }
                foreach ($record in $result."$processingKey"."$e".legacy_rrset) {
                    #
                    Write-Progress -Id 1 " Готовим RRSET record $($record.Name)"
                    $strMess = "Начинаем обработку записи и подготовку структур для миграции ""$($record.name)"""
                    Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+1))
                    #$result."$processingKey"."$e".mess += ,$strMess
                    $type=$record.type.ToUpper()
                    if ( ($type -eq 'SOA') -or (($type -eq 'NS') -and ($record.name.ToLower() -eq $e.ToLower())) ) {
                        # пропускаем записи SOA, NS самого домена
                        $strMess = "Пропускаем запись ""$record"": тип $($type); name $($record.name)"
                        Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+1))
                        continue
                    }
                    <#
                        если    в actual_rrset нет записи с таким именем,
                        то      добавить запись с таким именем в actual
                        иначе   если в actual уже есть запись таким именем и типом
                                то   добавить к ней доп.запись данных
                                иначе добавить запись
                    #>
                    if ( ($null -eq $result."$processingKey"."$e".actual_rrset.$type.name) -or ($result."$processingKey"."$e".actual_rrset.$type.name.IndexOf("$($record.name.ToLower()).") -lt 0) ) {
                        # нет в actual записей с именем $record.name
                        $result."$processingKey"."$e".actual_rrset.$type += ,[PSCustomObject]@{
                            'name'="$($record.name).";
                            'type'=$record.type;
                            'ttl'=$record.ttl;
                            'comment'='migrate from legacy:';
                            'records'=@(
                                [PSCustomObject]@{
                                    'content'=$record.content;
                                }
                            );
                            'IsChanged'=$false
                        }
                        $idx = $result."$processingKey"."$e".actual_rrset.$type.Count - 1
                    } else {
                        # есть в actual запись с именем $record.name
                        $idx= $result."$processingKey"."$e".actual_rrset."$type".name.IndexOf("$($record.name.ToLower()).")
                        $result."$processingKey"."$e".actual_rrset."$type"[$idx].records += [PSCustomObject]@{'content'=$record.content}
                        if ($result."$processingKey"."$e".actual_rrset."$type"[$idx].psobject.Properties.match('IsChanged').Count -gt 0) {
                            $result."$processingKey"."$e".actual_rrset."$type"[$idx].IsChanged = ($true -and ($result."$processingKey"."$e".actual_rrset."$type"[$idx].psobject.Properties.match('ID').Count -gt 0))
                        } else {
                            $result."$processingKey"."$e".actual_rrset."$type"[$idx] | Add-Member -MemberType NoteProperty -Name IsChanged -Value ($true -and ($result."$processingKey"."$e".actual_rrset."$type"[$idx].psobject.Properties.match('ID').Count -gt 0))
                        }
                    }
                    $strMess = "Подготовили для миграции ""$($record.name)"""
                    Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+1))
                    Write-Verbose (levelMessage ($result."$processingKey"."$e".actual_rrset."$type"[$idx] | ConvertTo-Json -Depth 4) -Indent ($indentOneElement+1))
                } ### foreach ($record in $result."$processingKey"."$e".legacy_rrset) {
            } ### if ($result."$processingKey"."$e".result -eq 0) {
        } else {
            # нет домена в legacy
            $strMess="Домен $($e) не существует в legacy (v1). Мигрировать нечего, пропускаем."
            Write-Verbose (levelMessage $strMess -Indent $indentOneElement)
            $result."$processingKey"."$e".mess += ,$strMess
            $result."$processingKey"."$e".IsMigrate = $false
            # INFO_RESULT=10, домен для миграции не существует в legacy (v1)
            $result."$processingKey"."$e".result = 10;
        } ### if ($result."$processingKey"."$e".IsPresent)
        #Start-Sleep -Milliseconds 200
    } ### foreach ($e in $domains) {
    # Теперь запишем их в actual
    $strMess = "Приступаем к записи RRSET записей на сервер"
    Write-Verbose (levelMessage $strMess -Indent ($indentOneElement-1))
    $result."$processingKey"."$e".mess += ,$strMess
    foreach ($domain in $result."$processingKey".GetEnumerator()) {
        Write-Progress -Id 2 "Записываем подготовленные данные домена $($domain.Name)"
        if (($domain.Value).IsMigrate) {
            # домен надо мигрировать
            $strMess="Записываем домен $($domain.Name) в actual (v2)."
            Write-Verbose (levelMessage $strMess -Indent $indentOneElement)
            $result."$processingKey".($domain.Name).mess += ,$strMess
            #$_.Value.actual_rrset.GetEnumerator().foreach({
            foreach ($type in $domain.Value.actual_rrset.GetEnumerator()) {
                # группируем по типам записей:
                #   пропускаем SOA
                #   пропускаем NS записи с именем домена
                #   пропускаем записи имеющие ID и (у которых нет свойства IsChanged или оно равно $False)
                #       это будут записи, которые уже существуют в домене actual (v2) и они не поменялсь относительно legacy (v1)
                #   остальные пишем в домен actual (v2)
                #       если свойство ID не существует, то это новая запись и используем addRecord
                #       если свойство ID существует и IsChanged, то это существующая запись и используем updRecord
                Write-Progress -Id 3 "Разбираем записи типа $($type.Name) домена $($domain.Name)"
                $strMess="Начинаем записывать записи типа $($type.Name)"
                Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+1))
                $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                if ($type.Name.ToUpper() -eq 'SOA') {
                    # пропускаем записи SOA
                    $strMess="Пропускаем записи типа $($type.Name)"
                    Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+1))
                    continue
                }
                $type.Value.foreach({
                    Write-Progress -Id 4 "Обрабатываем запись $($_.Name)"
                    $strMess="Обрабатываем запись $($_.Name)"
                    Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+2))
                    $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                    if ($type.Name.ToUpper() -eq 'NS'){
                        # пропускаем NS записи с именем домена
                        if ($_.Name.ToLower().trim('.') -eq $domain.Name.ToLower().trim('.')) {
                            $strMess="Пропускаем запись типа $($type.Name) с именем $($_.Name)"
                            Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+3))
                            Continue
                        }
                    }
                    if ($_.psobject.properties.match('ID').count -eq 0) {
                        # нет записи в actual, т.е новая запись добавить через addRecord
                        $strMess="Мигрируем новую запись $($_.Name)"
                        Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+3))
                        $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                        # add over API
                        if (-not [bool]$WhatIf){
                            # реально добавить запись
                            $rec_added = (./rest-api.ps1 `
                                -Provider 'dns_selectel' `
                                -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
                                -ExtParams @{ `
                                    'CFG'=@{ `
                                        'dns_selectel'=@{ `
                                            'version'="v2"; `
                                            "config_v2"=@{ `
                                                "token_use_env"="0" `
                                            } `
                                        } `
                                    }; `
                                    'domain'="$($result."$($processingKey)"."$($domain.Name)".actual_id)"; `
                                    "record"=$_; `
                                } `
                                -Action 'recordAdd' `
                                -LogLevel $LL `
                                -vb:$vbl `
                            )
                            if ($rec_added.retCode -eq 200) {
                                # нет ошибок при добавлении rrset
                                $strMess = "Миграция завершена успешно"
                            } else {
                                $strMess = "Миграция завершена с ошибкой: HTTP code: $($rec_added.retCode); $($rec_added.result)"
                            }
                            $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                            Write-Verbose (levelMessage -mess $strMess -Indent ($indentOneElement+3))
                        } else {
                            $strMess = "What If: добавили запись $($_.Name) в домене $($domain.Name) actual (v2)"
                            Write-Host -Object $strMess -ForegroundColor DarkCyan
                            Write-Verbose (levelMessage -mess $strMess -Indent ($indentOneElement+3))
                            $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                        }
                    }
                    if ($_.psobject.properties.match('ID').count -gt 0) {
                        # уже есть такая запись в actual
                        if ($_.IsChanged) {
                            # если установлен флаг IsChanged,
                            # то обновить запись с новыми данными через updRecord
                            $strMess="Мигрируем существующую запись $($_.Name), т.к. она менялась"
                            Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+3))
                            $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                            # update over API
                            if (-not [bool]$WhatIf){
                                # реально обновить запись
                                $rec_updated = (./rest-api.ps1 `
                                    -Provider 'dns_selectel' `
                                    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
                                    -ExtParams @{ `
                                        'CFG'=@{ `
                                            'dns_selectel'=@{ `
                                                'version'="v2"; `
                                                "config_v2"=@{ `
                                                    "token_use_env"="0" `
                                                } `
                                            } `
                                        }; `
                                        'domain'="$($result."$($processingKey)"."$($domain.Name)".actual_id)"; `
                                        "record_id"=$_.id
                                        "record"=$_; `
                                    } `
                                    -Action 'recordUpd' `
                                    -LogLevel $LL `
                                    -vb:$vbl `
                                )
                                if ($rec_updated.retCode -eq 204) {
                                    # нет ошибок при добавлении rrset
                                    $strMess = "Миграция завершена успешно"
                                } else {
                                    $strMess = "Миграция завершена с ошибкой: HTTP code: $($rec_updated.retCode); $($rec_updated.result)"
                                }
                                $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                                Write-Verbose (levelMessage -mess $strMess -Indent ($indentOneElement+3))
                            } else {
                                $strMess = "What If: обновили запись $($_.Name) в домене $($domain.Name) actual (v2)"
                                Write-Host -Object $strMess -ForegroundColor DarkCyan
                                Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+3))
                                $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                            }
                        } else {
                            # запись не менялась, пропускаем
                            $strMess="Пропускаем существующую запись $($_.Name), т.к. она не менялась"
                            Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+3))
                            $result."$processingKey"."$($domain.Name)".mess += ,$strMess
                        }
                    }
                    #Start-Sleep -Milliseconds 1000
                }) ### $type.Value.foreach({
            } ### foreach ($type in $domain.Value.actual_rrset.GetEnumerator()) {
        } ### if (($domain.Value).IsMigrate) {
        #Start-Sleep -Milliseconds 2000
    } ### foreach ($domain in $result."$processingKey".GetEnumerator()) {
}
end {
    $s = "$($MyInvocation.InvocationName) LEAVE: ============================================="
    Write-Verbose ($s | levelMessage)
    Write-Host "$(get-date -Format "yyyyMMdd HH:mm:ss") ::: Миграция доменов Selectel(legacy) --> Selectel(actual) (v1 --> v2)" -ForegroundColor Green

    #return @{'actual'=$domains_actual; 'legacy'=$domains_legacy}
    return $result
}




















