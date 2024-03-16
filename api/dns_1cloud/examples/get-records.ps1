[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String]$domain
)

$vb=$false

$d=(.\rest-api.ps1 -Provider 'dns_1cloud' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{ `
        'domain'="$($domain)"; `
        "_Service" = "123"; `
        "Body"='test'; `
        'record_id'=11264554; `
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
    -Action 'gds' `
    -debug `
    -verbose:$vb `
    -LogLevel 3 `
);
#
$d
if ($d.retCode -eq 200) {
    $global:r1 = $d.result[0].LinkedRecords
}

Write-Output 'GLOBAL VAR $r1'