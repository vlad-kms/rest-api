<#
Миграция домена из legacy в actual
#>

[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String[]]$domains,
    [int]$LL=1,
    [switch]$Force
)

begin {
    Write-Host "$(get-date -Format "yyyyMMdd HH:mm:ss") ::: Миграция доменов Selectel(legacy) --> Selectel(actual) (v1 --> v2)" -ForegroundColor Green
    $s = "$(Get-Date):::$($MyInvocation.InvocationName) ENTER: ============================================="
    Write-Verbose $s
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
    )
    if ($domains_legacy.retCode -ne 200) {
        throw "Ошибка получения доменов legacy (v1)"
    } else {
        $domains_legacy = $domains_legacy.result
    }
    if ($PSBoundParameters.Debug) {
        $domains_legacy
    }
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
    )
    if ($domains_actual.retCode -ne 200) {
        throw "Ошибка получения доменов actual (v2)"
    } else {
        $domains_actual = $domains_actual.result.result
    }
    if ($PSBoundParameters.Debug.IsPresent) {
        $domains_actual
    }
    $result=@{'source'=@{'actual'=$domains_actual; "legacy"=$domains_legacy}; "dest"=@{}; "raw"=@{"legacy"=@{'domains'=$domains_legacy}; "actual"=@{'domains'=$domains_actual}}}
}
process {
    # проверить существование домена в legacy
    # Сначала считаем все записи из домена legacy
    foreach ($e in $domains) {
        Write-Progress -Id 0 "домен $($e)"
        Write-Verbose "Элемент массива (домен): $e"
        $result.dest += @{$e=@{'result'=0}}
        $result.dest."$e".IsPresent=[bool]($domains_legacy | Where-Object -Property Name -EQ "$e")
        if ($result.dest."$e".IsPresent)
        {
            # в legacy есть, пробуем мигрировать в actual

            # флаг, что домен уже существует в actual
            $result.dest."$e".ExistsInActual = [bool](($domains_actual | Where-Object -Property Name -EQ "$($e)."))
            if ( $result.dest."$e".ExistsInActual ) {
                # есть такой домен в приемнике actual (v2)
                # если нет ключа -Force, то не выполнять миграцию
                $result.dest."$e".mess += ,"Домен $($e) уже существует в actual (v2)."
                if ( -not $Force) {
                    $result.dest."$e".mess += ,"Мигрировать не будем."
                    $result.dest."$e".IsMigrate = $false
                    # INFO_RESULT=20, такой домен уже существует в actual (v2)
                    $result.dest."$e".result = 20;
                } else {
                    $result.dest."$e".mess += ,"Будем мигрировать принудительно, объединяя два домена."
                }
            }
            if ($result.dest."$e".result -eq 0) {
                $result.dest."$e".mess += ,"Мигрируем $($e) из legacy -> actual"
                <#####################################
                # Тут будут актуальны следующие условия:
                # $result.dest."$e".ExistsInActual - существует ли домен в actual
                # $Force - мигрировать ли принудительно
                ######################################>
                # считать все ресурсные записи домена source (legacy)
                $rrset_legacy = (.\rest-api.ps1 `
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
                )
                if ($rrset_legacy.retCode -eq 200) {
                    # нет ошибок при чтении legacy rrset
                    $result.dest."$e".rrset_legacy = $rrset_legacy.result
                    $result.raw.legacy += @{"$e"=@{"rrset" = $rrset_legacy}}
                } else {
                    $result.dest."$e".mess += ,"Не считали rrset legacy домена. HTTP code: $($rrset_legacy.retCode); $($rrset_legacy.result)"
                    $result.dest."$e".IsMigrate=$false
                }
                if ($result.dest."$e".ExistsInActual -and $Force) {
                    # т.к. домен уже есть в actual (v2) и установлен флаг $Force, то считать rrset и из домена actual (v2)
                    $rrset_actual = (.\rest-api.ps1 `
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
                    )
                    if ($rrset_actual.retCode -eq 200) {
                        # нет ошибок при чтении actual rrset
                        $result.dest."$e".rrset_actual = $rrset_actual.result
                        $result.raw.actual += @{"$e"=@{"rrset" = $rrset_actual}}
                    } else {
                        $result.dest."$e".mess += ,"Не считали rrset actual домена. HTTP code: $($rrset_actual.retCode); $($rrset_actual.result)"
                        $result.dest."$e".IsMigrate=$false
                    }
                }


            }
        } else {
            # нет домена в legacy
            $result.dest."$e".mess += ,"Домен $($e) не существует в legacy (v1). Мигрировать нечего, пропускаем."
            $result.dest."$e".IsMigrate = $false
            # INFO_RESULT=10, домен для миграции не существует в legacy (v1)
            $result.dest."$e".result = 10;
        }
        Start-Sleep -Milliseconds 200
    }


    # Теперь запишем их в actual
}
end {
    $s = "$(Get-Date):::$($MyInvocation.InvocationName) LEAVE: ============================================="
    Write-Verbose $s
    Write-Host "$(get-date -Format "yyyyMMdd HH:mm:ss") ::: Миграция доменов Selectel(legacy) --> Selectel(actual) (v1 --> v2)" -ForegroundColor Green

    #return @{'actual'=$domains_actual; 'legacy'=$domains_legacy}
    return $result
}




















