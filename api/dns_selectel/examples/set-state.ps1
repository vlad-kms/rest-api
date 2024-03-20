[CmdletBinding()]
Param(
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [String]$ver='v2',
    [bool]$state=$true
)

$vb=$false

$global:r=(.\rest-api.ps1 -Provider 'dns_selectel' -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
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
$r
