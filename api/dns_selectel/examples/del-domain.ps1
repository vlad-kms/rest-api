[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='tt3.mrovo.ru',
    [hashtable]$comment=@{'comment'=''},
    [String]$ver='v2'
)

$r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{ `
                "sectionName"="dns_selectel"; `
                'CFG'=@{ `
                    'dns_selectel'=@{ `
                        'version'="v2"; `
                        "config_v2"=@{ `
                            "token_use_env"="0" `
                        } `
                    } `
                }; `
                'domain'="$($domain)"; `
                "_Service" = "$($domain)"; `
                "Body"='test'; `
                "domain_data"=$comment; `
                '_Query'='offset=2&limit=2&show_ips=true'; `
                '_record_id'=11264554 `
    } `
    -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'dDEL' `
    -LogLevel 1 `
);

$r1
