<#
USE
v2 ONLY
.\api\dns_selectel\examples\del-domain.ps1 -domain t33.mrovo.ru
.\api\dns_selectel\examples\del-domain.ps1 -domain t33.mrovo.ru
.\api\dns_selectel\examples\del-domain.ps1 -domain <id-domain>
#>

[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='tt3.mrovo.ru'
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
                '_Query'='offset=2&limit=2&show_ips=true'; `
                '_record_id'=11264554 `
    } `
    -Action 'dDEL' `
    -LogLevel 1 `
);

$r1
