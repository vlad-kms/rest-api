[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='',
    [String]$ver='v2',
    [switch]$v,
    [hashtable]$ExP=@{},
    [string]$act='fd',
    [int]$useEnv=0
)

$dt=(get-date)
$r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams (@{
                "sectionName"="dns_selectel"; 
                'CFG'=@{
                    'dns_selectel'=@{
                        'version'="$($ver)";
                        "config_v2"=@{
                            "token_use_env"="$($useEnv)"
                        }
                    }
                };
                'domain'="$($domain)";
                "_Service" = "$($domain)";
                "Body"='test';
                '_Query'='show_ips=true&limit=2';
                '_record_id'=11264554 `
    } + $ExP)`
    -Action $act `
    -debug `
    -Verbose:$v `
    -LogLevel 1
);
$dd=(Get-Date)-$dt
Write-Host -ForegroundColor DarkGreen "$("Начали".PadRight(12,'-')): $($dt)"
Write-Host -ForegroundColor DarkGreen "$("Закончили".PadRight(12,'-')): $(Get-Date)"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalSeconds) сек"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalMilliseconds) мс"
$r1
