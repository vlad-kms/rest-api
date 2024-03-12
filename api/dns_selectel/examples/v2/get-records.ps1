
[CmdletBinding()]
Param(
    [String]$id_record='bcb74475-5be8-46f3-a415-a83d2344524c',
    [String]$id_domain='9ab289ff-d101-4d6a-8227-9adcf9fc9d83'
)
$vb=$false
Write-Host "id_domain: $($id_domain)"
Write-Host "id_record: $($id_record)"

Write-Host "=============================================================================================================="
Write-Host "https://api.selectel.ru/domains/v2/zones/{id_domain}/rrset"
Write-Host "https://api.selectel.ru/domains/v2/zones/9ab289ff-d101-4d6a-8227-9adcf9fc9d83/rrset/"
$r=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{'dns_selectel'=@{'version'='v2'}};
                'domain'="$($id_domain)"; "_Service" = "$($id_domain)";
                "Body"='test';
                '_Query'='offset=2&limit=2&show_ips=true';
                '_record_id'=11264554 `
    } `
    -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'grs' `
    -debug `
    -verbose:$vb `
    -LogLevel 1);
$r.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains.result


Write-Host "=============================================================================================================="
Write-Host "https://api.selectel.ru/domains/v2/zones/{id_domain}/rrset/{id_record}"
Write-Host "https://api.selectel.ru/domains/v2/zones/9ab289ff-d101-4d6a-8227-9adcf9fc9d83/rrset/bcb74475-5be8-46f3-a415-a83d2344524c"
$r=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{'dns_selectel'=@{'version'='v2'}};
                'domain'="$($id_domain)"; "_Service" = "$($id_domain)";
                "Body"='test';
                '_Query'='offset=2&limit=2&show_ips=true';
                'record_id'="$($id_record)" `
    } `
    -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'grs' `
    -debug `
    -verbose:$vb `
    -LogLevel 1);
$r.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains
