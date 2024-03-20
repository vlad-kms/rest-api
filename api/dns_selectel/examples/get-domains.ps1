﻿[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='',
    [String]$ver='v2',
    [switch]$v,
    [hashtable]$ExP=@{}
)

$r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams (@{
                "sectionName"="dns_selectel"; 
                'CFG'=@{
                    'dns_selectel'=@{
                        'version'="$($ver)";
                        "config_v2"=@{
                            "token_use_env"="0"
                        }
                    }
                };
                'domain'="$($domain)";
                "_Service" = "$($domain)";
                "Body"='test';
                '_Query'='show_ips=true&limit=2';
                '_record_id'=11264554 `
    } + $ExP)`
    -Action 'gds' `
    -debug `
    -Verbose:$v `
    -LogLevel 1
);

$r1
