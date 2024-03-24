[CmdletBinding()]
Param(
    [String]$domain='f68e88b1-aaf6-43d0-9a3d-5bd70aba2f55',
    [String]$ver='v1'
)

$vb=$false
$dt=(get-date)

$r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{
                    'dns_selectel'=@{
                        'version'="$($ver)"}
                    };
                'domain'="$($domain)";
                "Body"='test';
                '_Query'='offset=2&limit=2&show_ips=true';
                '_record_id'=11264554 `
    } `
    -Action 'export' `
    -debug `
    -verbose:$vb `
    -LogLevel 1`
);

$dd=(Get-Date)-$dt
Write-Host -ForegroundColor DarkGreen "$("Начали".PadRight(12,'-')): $($dt)"
Write-Host -ForegroundColor DarkGreen "$("Закончили".PadRight(12,'-')): $(Get-Date)"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalSeconds) сек"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalMilliseconds) мс"
$r1
