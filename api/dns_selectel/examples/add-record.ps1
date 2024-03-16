
[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [String]$ver='v2',
    [hashtable]$record=@{}
)
$vb=$false

$r=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{ `
        "sectionName"="dns_selectel"; `
        'CFG'=@{ `
            'dns_selectel'=@{ `
                'version'="$($ver)"
                "config_v2"=@{ `
                    "token_use_env"="0" `
                } `
            } `
        }; `
        'domain'="$($domain)"; `
        "Body"='test'; `
        'Query'='offset=0&limit=22&show_ips=true'; `
        '_record_id'=11264554; `
        "record"=$($record) `
    } `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'rAdd' `
    -debug -verbose:$vb `
    -LogLevel 1 `
);
#Write-Output 'GLOBAL VAR $r1'
$r

exit
