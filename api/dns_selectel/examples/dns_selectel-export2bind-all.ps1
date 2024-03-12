$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{'_domain'="791977"; 'Query'=@('show_ips=true');} -Module D:\Tools\~scripts.ps\avvClasses1 `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'gds'  -debug -verbose:$false -LogLevel 1)
#;$r.raw.Providers.dns_selectel.res.resapi.httpresponse.resDomains
$res = @{}
$r.raw.Providers.dns_selectel.res.resapi.HttpResponse.resDomains.foreach({
    $s = (.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{'domain'="$($_.Name)";} -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'export'  -debug -verbose:$false -LogLevel 1).raw.Providers.dns_selectel.res.resapi.httpresponse.resDomains
    $res += @{"$($_.Name)" = $s}
})

return $res


exit
$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{"p4"=$null;'config'=@{'p1'='v1'; 'p3'='v2'};'s1'=@{"p3"='v-p3'}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; 'domain'="791977"; "_service"="mrovo.ru"; "Body"='test'; 'Query'=@('offset=2', 'limit=2', 'show_ips=true');} -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'gds'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.httpresponse.resDomains

$r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" -ExtParams @{"sectionName"="dns_selectel"; CFG=@{dns_1cloud1=@{p1='v1'};dns_cli=@{"p4"=$null;'config'=@{'p1'='v1'; 'p3'='v2'};'s1'=@{"p3"='v-p3'}}; 'dns_1cloud'=@{'config'=@{'p33'='v_p33';'p5'=@{'p5_2'=@{'p2_2_2'='1234';'p2_2_3'='333'}}}}}; 'domain'=""; "Body"='test'; 'Query'='offset=2&limit=2&show_ips=true'} -Module D:\Tools\~scripts.ps\avvClasses1 -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' -Action 'gds'  -debug -verbose:$true -LogLevel 1);$r.raw.Providers.dns_selectel.res.resapi.httpresponse.resDomains





