﻿
[CmdletBinding()]
Param(
    [String]$domain='9ab289ff-d101-4d6a-8227-9adcf9fc9d83',
    [P]
    [String]$record='',
    [String]$ver='v2'
)
$vb=$false

$global:r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{
                    'dns_selectel'=@{
                        'version'="$($ver)"
                    }
                };
                'domain'="$($domain)";
                "_Service" = "$($domain)";
                "Body"='test';
                '_Query'='offset=2&limit=2&show_ips=true';
                'record_id'="$($record)" `
    } `
    -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'grs' `
    -debug `
    -verbose:$vb `
    -LogLevel 1 `
);

<#
$global:r2=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{
                    'dns_selectel'=@{
                        'version'="$($ver)"
                    }
                };
                'domain'="$($domain)";
                "_Service" = "$($domain)";
                "Body"='test';
                '_Query'='offset=2&limit=2&show_ips=true';
                'record_id'="$($record)" `
    } `
    -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'grs' `
    -debug `
    -verbose:$vb `
    -LogLevel 1 `
);
#>
Write-Output "=============================================================================================================="
Write-Output "Version API: $($ver)"
Write-Output "domain: $($domain)"
Write-Output "record: $($record)"
$r1.result

<#
Write-Output "=============================================================================================================="
Write-Output "Version API: $($ver)"
Write-Output "domain: $($domain)"
Write-Output "record: $($record)"
$r2.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains
#>

Write-Output 'GLOBAL VAR $r1'