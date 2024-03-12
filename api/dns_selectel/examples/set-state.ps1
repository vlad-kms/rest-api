[CmdletBinding()]
Param(
    [String]$domain='9ab289ff-d101-4d6a-8227-9adcf9fc9d83',
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
    -PathIncludes 'D:\Tools\~scripts.ps\avvClasses\classes' `
    -Action 'stateSet' `
    -debug `
    -verbose:$vb `
    -LogLevel 1 `
);
$r
