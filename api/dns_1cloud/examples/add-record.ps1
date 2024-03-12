$r=(.\rest-api.ps1 -Provider 'dns_1cloud' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
-ExtParams @{'domain'="34124"; "_Service" = "123"; "Body"='test'; 'record_id'=11264554; `
"record"=@(@{ `
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
)} `
-PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'recordsAdd'  -debug -verbose:$true -LogLevel 3); `
$r.raw.Providers.dns_1cloud.res.resapi.HttpResponse.resDomains


################### add record TXT
$r=(.\rest-api.ps1 -Provider 'dns_1cloud' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
-ExtParams @{'domain'="34124"; "_Service" = "123"; "Body"='test'; 'record_id'=11264554; `
"record"=@( `
    @{ `
        "tYpe"='TXT'; `
        'Name'='tt4.t1.mrovo.ru'; `
        'conTent'='CONTENT TXT'; `
    } `
)} `
-PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'recordsAdd'  -debug -verbose:$true -LogLevel 3); `
$r.raw.Providers.dns_1cloud.res.resapi.HttpResponse.resDomains

