[CmdletBinding()]
Param(
    [String]$domain='34124'
)

$vb=$false

$r1=(.\rest-api.ps1 -Provider 'dns_1cloud' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{ `
        'domain'="$($domain)"; `
        "Body"='test'; `
        "records"=@( `
            @{ `
                'type'='A'; `
                'Name'='tt2'; `
                'conTent'='1.1.2.1'; `
            }, `
            @{ `
                'type'='CNAme'; `
                'Name'='tt3'; `
                'conTent'='tt1.mrovo.ru.'; `
            }, `
            @{ `
                "tYpe"='TXT'; `
                'Name'='tt4'; `
                'conTent'='CONTENT TXT'; `
            }, `
            @{ `
                "tYpe"='NS'; `
                'Name'='t.mrovo.ru'; `
                'conTent'='ns4.selectel.ru'; `
            } `
        ) `
    } `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'rDel' `
    -debug `
    -verbose:$vb `
    -LogLevel 3 `
);
$r1.result

################### add record TXT
$global:r2=(.\rest-api.ps1 `
    -Provider 'dns_1cloud' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{ `
        'domain'="$($domain)"; `
        "records"=@( `
            @{ `
                "tYpe"='TXT'; `
                'Name'='tt4.t1.mrovo.ru'; `
                'conTent'='CONTENT TXT'; `
            } `
        ) `
    } `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'recordsDel' `
    -debug `
    -verbose:$true `
    -LogLevel 3);
$r2.result

