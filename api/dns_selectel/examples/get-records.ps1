
[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [String]$record='',
    [String]$ver='v2',
    [Switch]$v,
    [hashtable]$ExP=@{},
    [string]$act='records',
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
                '_Query'='offset=2&limit=2&show_ips=true';
                'record_id'="$($record)" `
    } + $ExP) `
    -Action $act `
    -debug `
    -verbose:$v `
    -LogLevel 1 `
);
$dd=(Get-Date)-$dt
Write-Host -ForegroundColor DarkGreen "Начали: $($dt)"
Write-Host -ForegroundColor DarkGreen "Закончили: $(Get-Date)"
Write-Host -Foreground DarkGreen `
    "$(if ($dd.Days -ne 0){Write-Host -Foreground DarkGreen ""$($dd.Days) дн""}; `
    if ($dd.Hours -ne 0) {Write-Host -Foreground DarkGreen ""$($dd.Hours) ч""}; `
    if ($dd.Minutes -ne 0) {Write-Host -Foreground DarkGreen ""$($dd.Minutes) м""}; `
    if ($dd.Seconds -ne 0) {Write-Host -Foreground DarkGreen ""$($dd.Seconds) сек""}; `
    if ($dd.Milliseconds -ne 0) {Write-Host -Foreground DarkGreen ""$($dd.Milliseconds) мс""})"

Write-Host -ForegroundColor DarkGreen "Выполнено за: $($dd. Seconds) сек"
Write-Host -ForegroundColor DarkGreen "Выполнено за: $($dd.Milliseconds) мс"
$r1
