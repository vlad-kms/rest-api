[CmdletBinding()]
Param(
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [String]$ver='v2'
)

$vb=$false
$global:r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
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

Write-Output "======================================Get-State"
Write-Output "Version API: $($ver)`nDomain: $($domain)"
Write-Output $r1
