[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String]$record,
    [Parameter(Position=1)]
    [String]$domain='295579'
)

$vb=$false

$r1=(.\rest-api.ps1 -Provider 'dns_1cloud' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{ `
        'domain'="$($domain)"; `
        "_Service" = "123"; `
        "Body"='test'; `
        'record_id'=$record; `
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
    -Action 'gr' `
    -debug `
    -verbose:$vb `
    -LogLevel 3 `
); `
$r1

