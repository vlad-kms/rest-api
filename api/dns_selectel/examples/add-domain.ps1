<# USE
.\api\dns_selectel\examples\add-domain.ps1  -domain t33.mrovo.ru
 #>
 
[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [String]$ver='v2'
)

$dt=(get-date)

$r=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{ `
                "sectionName"="dns_selectel"; `
                'CFG'=@{ `
                    'dns_selectel'=@{ `
                        'version'="v2"; `
                        "config_v2"=@{ `
                            "token_use_env"="0" `
                        } `
                    } `
                }; `
                'domain'="$($domain)"; `
                "_Service" = "$($domain)"; `
                "Body"='test'; `
                '_Query'='offset=2&limit=2&show_ips=true'; `
                '_record_id'=11264554 `
    } `
    -Action 'dAdd' `
    -LogLevel 1 `
);

$dd=(Get-Date)-$dt
Write-Host -ForegroundColor DarkGreen "$("Начали".PadRight(12,'-')): $($dt)"
Write-Host -ForegroundColor DarkGreen "$("Закончили".PadRight(12,'-')): $(Get-Date)"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalSeconds) сек"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalMilliseconds) мс"
$r
