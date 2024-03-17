<# USE
Обновить запись на v1
ID домена
    .\api\dns_selectel\examples\upd-record.ps1 -record @{"content"='1.2.12.14'; "type"='A'} -ver 'v1' -record_id 26851207 -domain 914366
Имя домена
    .\api\dns_selectel\examples\upd-record.ps1 -record @{"content"='1.2.12.14'; "type"='A'} -ver 'v1' -record_id 26851207 -domain t2.mrovo.ru)

Обновить запись на v2
ID домена
    .\api\dns_selectel\examples\upd-record.ps1 -record @{"type"='A'; "ttl"=36000; "name"="f68e88b1-aaf6-43d0-9a3d-5bd70aba2f55"; records=@(@{"content"='1.2.12.14'; "comment"="test"}); "comment"="test_record"} -ver 'v2' -record_id 1d14f2f0-445a-4457-ab77-1001b4d87e50 -domain f68e88b1-aaf6-43d0-9a3d-5bd70aba2f55
Имя домена
    .\api\dns_selectel\examples\upd-record.ps1 -record @{"type"='A'; "ttl"=36000; "name"="a.t3.mrovo.ru"; records=@(@{"content"='1.2.12.14'; "comment"="test"}); "comment"="test_record"} -ver 'v2' -record_id 1d14f2f0-445a-4457-ab77-1001b4d87e50 -domain f68e88b1-aaf6-43d0-9a3d-5bd70aba2f55

#>

[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [Parameter(Mandatory=$true, Position=1)]
    [String]$record_id,
    [String]$ver='v2',
    [hashtable]$record=@{}
)
$vb=$false
$r=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{ `
        "sectionName"="dns_selectel"; `
        'CFG'=@{ `
            'dns_selectel'=@{ `
                'version'="$($ver)"
                "config_v2"=@{ `
                    "token_use_env"="0" `
                } `
            } `
        }; `
        'domain'="$($domain)"; `
        "Body"='test'; `
        'Query'='offset=0&limit=22&show_ips=true'; `
        'record_id'=$($record_id); `
        "record"=$record `
    } `
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'rUpd' `
    -debug -verbose:$vb `
    -LogLevel 1 `
);

return $r

exit
