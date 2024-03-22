[CmdletBinding()]
Param(
    [String]$domain='f68e88b1-aaf6-43d0-9a3d-5bd70aba2f55',
    [String]$ver='v2'
)

$vb=$false
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
    -Action 'state' `
    -debug `
    -verbose:$vb `
    -LogLevel 1);

Write-Host "domain: $($domain)"


$r1

exit

Write-Output "======================================Get-State"
Write-Output "Version API: $($ver)`nDomain: $($domain)"
Write-Output $r1
