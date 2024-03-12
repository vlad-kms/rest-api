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





$r=(.\rest-api.ps1 -Provider 'dns_1cloud' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
-ExtParams @{'domain'="34124"; "Service" = "123"; "Body"='test'; 'record_id'=11264554; `
'record'=@(@{'recordId'=291564}, @{'recordId'=291565}, @{'recordId'=291566; 'domainId'=341243}, @{'recordId'=291567})} `
-PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'rdel'  -debug -verbose:$true -LogLevel 1); `
$r.raw.Providers.dns_1cloud.res.resapi.HttpResponse


$r=(.\rest-api.ps1 -Provider 'dns_1cloud' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
-ExtParams @{'domain'="34124"; "Service" = "123"; "Body"='test'; 'record_id'=11264554; `
'record'=@(@{'recordId'=291542},@{'recordId'=29154111})} `
-PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'rdel'  -debug -verbose:$true -LogLevel 1); `
$r.raw.Providers.dns_1cloud.res.resapi.HttpResponse.resDomains



$r.raw.Providers.dns_1cloud.res.resAPI.HttpResponse.resDomains.LinkedRecords|sort -Property ID|where-Object -Property hostname -like "*tt*"|Select-Object -Property id, typerecord, ip, hostname, mnemonicname



$r=(.\rest-api.ps1 -Provider 'dns_1cloud' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
-ExtParams @{'domain'="34124"; "_Service" = "123"; "Body"='test'; 'record_id'=11264554; `
"record"=@(@{ `
        'recordId'=291564; `
        'type'='A'; `
        'Name'='tt2'; `
        'conTent'='1.1.2.2'; `
    }, `
    @{ `                 
        'recordId'=291565; `
        'type'='CNAme'; `
        'Name'='tt3'; `
        'conTent'='mrovo.ru.'; `
    }, `
    @{ `
        'recordId'=291566; `
        "tYpe"='TXT'; `
        'Name'='tt4'; `
        'conTent'='CONTENT TXT UPD'; `
    }, `
    @{ `
        'recordId'=291567; `
        "tYpe"='NS'; `
        'Name'='t.mrovo.ru'; `
        'conTent'='ns3.selectel.ru'; `
    } `
)} `
-PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'recordsUpd'  -debug -verbose:$true -LogLevel 3); `
$r.raw.Providers.dns_1cloud.res.resapi.HttpResponse.resDomains

