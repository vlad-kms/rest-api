#t.mrovo.ru
#id=9ab289ff-d101-4d6a-8227-9adcf9fc9d83
$vb=$false

$r=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{'dns_selectel'=@{'version'='v2';"config_v2"=@{"token_use_env"="0"}}};
                '_domain'="t.mrovo.ru"; "_Service" = "791376";
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

$r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{'dns_selectel'=@{'version'='v2';"config_v2"=@{"token_use_env"="0"}}};
                '_domain'="9ab289ff-d101-4d6a-8227-9adcf9fc9d83"; "Service" = "9ab289ff-d101-4d6a-8227-9adcf9fc9d83";
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
#Start-Sleep 2

$r2=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{'dns_selectel'=@{'version'='v2';"config_v2"=@{"token_use_env"="0"}}};
                'domain'="9ab289ff-d101-4d6a-8227-9adcf9fc9d83"; "_Service" = "9ab289ff-d101-4d6a-8227-9adcf9fc9d83";
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

Write-Host "=============================================================================================================="
Write-Host "https://api.selectel.ru/domains/v2/zones"
($r.result | ConvertTo-Json -Depth 4)

Write-Host "=============================================================================================================="
Write-Host "https://api.selectel.ru/domains/v2/zones/{id_domain}"
Write-Host "id_domain - берется ExtParams.Service"
$r1.result


Write-Host "=============================================================================================================="
Write-Host "https://api.selectel.ru/domains/v2/zones/{id_domain}"
Write-Host "id_domain - берется ExtParams.domain"
$r2.result
