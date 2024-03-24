[CmdletBinding()]
Param(
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [String]$ver='v2',
    [bool]$state=$true
)

$vb=$false
$dt=(get-date)

$r1=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
        "sectionName"="dns_selectel";
        'CFG'=@{
            'dns_selectel'=@{
                'version'="$($ver)"}
            };
        'domain'="$($domain)";
        "Service" = "";
        "DiSaBlEd"=$($state);
        "Body"='test';
        'Query'='offset=0&limit=22&show_ips=true';
        '_record_id'=11264554
    } `
    -Action 'stateSet' `
    -debug `
    -verbose:$vb `
    -LogLevel 1 `
);
$dd=(Get-Date)-$dt
Write-Host -ForegroundColor DarkGreen "$("Начали".PadRight(12,'-')): $($dt)"
Write-Host -ForegroundColor DarkGreen "$("Закончили".PadRight(12,'-')): $(Get-Date)"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalSeconds) сек"
Write-Host -ForegroundColor DarkGreen "$("Выполнено за".PadRight(12,'-')): $($dd.TotalMilliseconds) мс"
$r1
