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
    [switch]$AddDatetimeLogging
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
        $domains_actual = $domains_actual.result.result
    }
    Write-Verbose (levelMessage "Все домены actual:" -Indent ($indentOneElement - 1))
    Write-Verbose (levelMessage ($domains_actual|ConvertTo-Json -Depth 4) -Indent $indentOneElement)
    $result=@{"$sourceKey"=@{'actual'=$domains_actual; "legacy"=$domains_legacy}; "$processingKey"=@{}; "raw"=@{"actual"=@{'domains'=$domains_actual}; "legacy"=@{'domains'=$domains_legacy};}}
}
process {
    # проверить существование домена в legacy
    # Сначала считаем все записи из домена legacy
    foreach ($e in $domains) {
        Write-Progress -Id 0 "домен $($e)"
        Write-Verbose (levelMessage "Элемент массива (домен): ""$e""" -Indent 1)
        $result."$processingKey" += @{$e=@{'result'=0}}
        $domain_legacy = ($domains_legacy | Where-Object -Property Name -EQ "$e")
        $result."$processingKey"."$e".legacy_id = $domain_legacy.id
        $result."$processingKey"."$e".IsPresent=[bool]$domain_legacy
        if ($result."$processingKey"."$e".IsPresent)
        {
            # в legacy есть, пробуем мигрировать в actual
            Write-Verbose (levelMessage """$($e)"" существует в legacy, пробуем мигрировать в actual" -Indent 2)

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
                    return $result
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
                        $result."$processingKey"."$e".actual_rrset = $actual_rrset.result.result
                        $result.raw.actual += @{"$e"=@{"rrset" = $actual_rrset}}
                    } else {
                        $strMess="Не считали rrset actual домена. HTTP code: $($actual_rrset.retCode); $($actual_rrset.result)"
                        $result."$processingKey"."$e".mess += ,$strMess
                        $result."$processingKey"."$e".IsMigrate=$false
                        # INFO_RESULT=100, ошибка чтения RRSET в actual (v2)
                        $result."$processingKey"."$e".result = 100;
                        return $result
                        throw $strMess
                    }
                } else {
                    # домен не существует в actual, надо добавить его в actual
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
                    if ($domain_added_actual.retCode -eq 200) {
                        # нет ошибок при чтении actual rrset
                        $result."$processingKey"."$e".actual_id = $domain_added_actual.result.id
                        $result.raw.actual += @{"$e"=@{"domain" = $domain_added_actual.result.id}}
                    } else {
                        $strMess="Не смогли добавить домен $($e) в  actual. HTTP code: $($actual_rrset.retCode); $($actual_rrset.result)"
                        $result."$processingKey"."$e".mess += ,$strMess
                        $result."$processingKey"."$e".IsMigrate=$false
                        d# INFO_RESULT=102, ошибка добавления нового домена в actual (v2)
                        $result."$processingKey"."$e".result = 102;
                        return $result
                        throw $strMess
                    }
                }
                # подготовили записи, начинаем процесс
                #
                foreach ($record in $result."$processingKey"."$e".legacy_rrset) {
                    #
                    Write-Progress -Id 1 "RRSET record $($record.Name)"
                    $strMess = "Начинаем обработку записи ""$($record.name)"""
                    Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+1))
                    #$result."$processingKey"."$e".mess += ,$strMess
                    $type=$record.type.ToUpper()
                    if ( ($type -eq 'SOA') -or (($type -eq 'NS') -and ($record.name.ToLower() -eq $e.ToLower())) ) {
                        # пропускаем записи SOA, NS самого домена
                        $strMess = "Пропускаем запись ""$record"": тип $($type); name $($record.name)"
                        Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+1))
                        continue
                    }
                    $strMess = """$($record.name)"""
                    Write-Verbose (levelMessage $strMess -Indent ($indentOneElement+1))
                }
            }
        } else {
            # нет домена в legacy
            $strMess="Домен $($e) не существует в legacy (v1). Мигрировать нечего, пропускаем."
            Write-Verbose (levelMessage $strMess -Indent 2)
            $result."$processingKey"."$e".mess += ,$strMess
            $result."$processingKey"."$e".IsMigrate = $false
            # INFO_RESULT=10, домен для миграции не существует в legacy (v1)
            $result."$processingKey"."$e".result = 10;
        } ### if ($result."$processingKey"."$e".IsPresent)
        Start-Sleep -Milliseconds 200
    }

    # Теперь запишем их в actual
    
}
end {
    $s = "$($MyInvocation.InvocationName) LEAVE: ============================================="
    Write-Verbose ($s | levelMessage)
    Write-Host "$(get-date -Format "yyyyMMdd HH:mm:ss") ::: Миграция доменов Selectel(legacy) --> Selectel(actual) (v1 --> v2)" -ForegroundColor Green

    #return @{'actual'=$domains_actual; 'legacy'=$domains_legacy}
    return $result
}




















