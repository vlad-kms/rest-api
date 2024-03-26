<#
USE
v2
.\api\dns_selectel\examples\add-record.ps1 -record @{"type"='A'; "ttl"=3600; "name"="d.t3.mrovo.ru"; "records"=@(@{"content"='1.2.3.4'},@{"content"='1.2.3.5'})} -domain f68e88b1-aaf6-43d0-9a3d-5bd70aba2f55
.\api\dns_selectel\examples\add-record.ps1 -record @{"type"='A'; "ttl"=3600; "name"="d.t3.mrovo.ru"; "records"=@(@{"content"='1.2.3.4'},@{"content"='1.2.3.5'})} -domain t3.mrovo.ru
v1
.\api\dns_selectel\examples\add-record.ps1 -record @{"type"='A'; "ttl"=36000; "name"="d.t2.mrovo.ru"; "content"='1.2.3.4'} -ver 'v1' -domain 914366
 .\api\dns_selectel\examples\add-record.ps1 -record @{"type"='A'; "ttl"=36000; "name"="d.t2.mrovo.ru"; "content"='1.2.3.4'} -ver 'v1' -domain t2.mrovo.ru
#>

[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [String]$ver='v2',
    [hashtable]$record=@{}
)
$vb=$false
$dt=(get-date)

$r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
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
        '_record_id'=11264554; `
        "record"=$($record) `
    } `
    -debug -verbose:$vb `
    -Action 'rAdd' `
    -LogLevel 1 `
);

$dd=(Get-Date)-$dt
Write-Host -ForegroundColor DarkGreen "$("Начали".PadRight(12,'-')): $($dt)"
Write-Host -ForegroundColor DarkGreen "$("Закончили".PadRight(12,'-')): $(Get-Date)"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalSeconds) сек"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalMilliseconds) мс"
$r1
