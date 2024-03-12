[CmdletBinding()]
Param(
    [String]$domain='9ab289ff-d101-4d6a-8227-9adcf9fc9d83',
    [String]$ver='v2'
)

$vb=$false
$global:r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{
                    'dns_selectel'=@{
                        'version'="$($ver)"}
                    };
                'domain'="$($domain)";
                "Body"='test';
                '_Query'='offset=2&limit=2&show_ips=true';
                '_record_id'=11264554 `
    } `
    -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'state' `
    -debug `
    -verbose:$vb `
    -LogLevel 1);

Write-Host "domain: $($domain)"

Write-Output "======================================Get-State"
Write-Output "Version API: $($ver)`nDomain: $($domain)"
Write-Output $r1
