$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{"p4"=$null;'config'=@{'p1'='v1'; 'p3'='v2'};'s1'=@{"p3"='v-p3'}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; '_domain'="791977"; "service"="mrovo.ru"; "Body"='test'; 'Query'=@('offset=2', 'limit=2', 'show_ips=true');} -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'gds'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.httpresponse.resDomains

$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{"p4"=$null;'config'=@{'p1'='v1'; 'p3'='v2'};'s1'=@{"p3"='v-p3'}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; 'domain'="791977"; "_service"="mrovo.ru"; "Body"='test'; 'Query'=@('offset=2', 'limit=2', 'show_ips=true');} -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'gds'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.httpresponse.resDomains

# get domains
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{"p4"=$null;'config'=@{'p1'='v1'; 'p3'='v2'};'s1'=@{"p3"='v-p3'}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; 'domain'=""; "Body"='test'; 'Query'='offset=2&limit=2&show_ips=true'} -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'gds'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.httpresponse.resDomains


# set state domain
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; 'domain'="791388"; "Service" = ""; "DiSaBlEd"=$true; "Body"='test'; 'Query'='offset=0&limit=22&show_ips=true'; '_record_id'=11264554} -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'stateSet'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.HttpResponse


# add resource record
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{"p4"=$null;'config'=@{'p1'='v1'; 'p3'='v2'};'s1'=@{"p3"='v-p3'}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; 'domain'="t.mrovo.ru"; "Service" = ""; "DiSaBlEd"=$true;"Body"='test'; 'Query'='offset=0&limit=22&show_ips=true'; '_record_id'=11264554; "record"=@{"type"='A'; "name"="t1.t.mrovo.ru";"content"="1.1.1.1"}} -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'recordAdd'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains


# delete resource record
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{"p4"=$null;'config'=@{'p1'='v1'; 'p3'='v2'};'s1'=@{"p3"='v-p3'}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; 'domain'="t.mrovo.ru"; "Service" = ""; "DiSaBlEd"=$true;"Body"='test'; 'record_id'=; } -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'recordDel'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains

# delete resource record
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{'domain'="t.mrovo.ru"; 'record_id'=1708693433; } -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'recordDel'  -debug -verbose:$true -LogLevel 1);

# delete resource record
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; 'domain'="t.mrovo.ru"; "Service" = ""; "DiSaBlEd"=$true;"Body"='test'; 'Query'='offset=0&limit=22&show_ips=true'; 'record_id'='26786728'; } -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'recordDel'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains

# get record with record_id
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; 'domain'="t.mrovo.ru"; "Service" = ""; "DiSaBlEd"=$true;"Body"='test'; 'Query'='offset=0&limit=22&show_ips=true'; 'record_id'="26786728"; "record"=@{"type"=@('A'); "name"="t1.t.mrovo.ru";"content"="1.1.1.1"}} -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'grs'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains


# update resource record
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{'domain'="t.mrovo.ru"; 'record_id'=26786802; "record"=@{"type"='A'; "name"="t1.t.mrovo.ru";"content"="1.1.1.2"}} -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'rUpd'  -debug -verbose:$true -LogLevel 1);



#ADD record Provider:dns_selectel1
$r=(.\rest-api.ps1 -Provider 'dns_selectel1' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
-ExtParams @{"sectionName"="dns_selectel"; 'domain'="t.mrovo.ru"; "Service" = ""; `
"DiSaBlEd"=$true;"Body"='test'; 'Query'='offset=0&limit=22&show_ips=true'; `
'_record_id'=11264554; "record"=@{"type"='A'; "name"="t2.t.mrovo.ru";"content"="1.1.2.1"}} `
-PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'rAdd' `
-debug -verbose:$true -LogLevel 1); `
$r.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains


#UPDATE record Provider:dns_selectel1
$r=(.\rest-api.ps1 -Provider 'dns_selectel1' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
-ExtParams @{"sectionName"="dns_selectel"; 'domain'="t.mrovo.ru"; "Service" = ""; `
'record_id'=26786832; "record"=@{"type"='A'; "name"="t2.t.mrovo.ru";"content"="1.1.2.3"}} `
-PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'rUpD' `
-debug -verbose:$true -LogLevel 1); `
$r.raw.Providers.dns_selectel1.res.resapi.HttpResponse.resDomains

#DELETE record Provider:dns_selectel1
$r=(.\rest-api.ps1 -Provider 'dns_selectel1' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
-ExtParams @{"sectionName"="dns_selectel"; 'domain'="t.mrovo.ru"; "Service" = ""; `
'record_id'=26786802; } `
-PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'rDel' `
-debug -verbose:$true -LogLevel 1); `
$r.raw.Providers.dns_selectel1.res.resapi.HttpResponse.resDomains





