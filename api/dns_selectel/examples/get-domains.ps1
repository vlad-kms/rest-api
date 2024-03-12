[CmdletBinding()]
Param(
    [String]$domain='',
    [String]$ver='v2'
)


#t.mrovo.ru
#id=9ab289ff-d101-4d6a-8227-9adcf9fc9d83
$vb=$false

$r=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
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
                '_Query'='offset=2&limit=2&show_ips=true';
                '_record_id'=11264554 `
    } `
    -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'gds' `
    -debug `
    -verbose:$vb `
    -LogLevel 1
);

$global:r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{
                    'dns_selectel'=@{
                        'version'="$($ver)";
                        "config_v2"=@{
                            "token_use_env"="0"
                        }
                    }
                };
                '_domain'="$($domain)";
                "Service" = "$($domain)";
                "Body"='test';
                '_Query'='offset=2&limit=2&show_ips=true';
                '_record_id'=11264554 `
    } `
    -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'gds' `
    -debug `
    -verbose:$vb `
    -LogLevel 1
);

Write-Host "========================================= Get-Domains domain in ExtParams.domain"
Write-Host "Version API: $($ver)`nDomain: $($domain)"
($r.result | ConvertTo-Json -Depth 4)

Write-Host "========================================= Get-Domains domain in ExtParams.service"
Write-Host "Version API: $($ver)`\nDomain: $($domain)"
$r1.result
