
[CmdletBinding()]
Param(
    [Parameter(ValueFromPipeline=$true, Position=0)]
    [String]$domain='ce26d823-51a7-420d-8158-08450ca3c6ab',
    [String]$record='',
    [String]$ver='v2',
    [Switch]$v
)

$r1=(.\rest-api.ps1 -Provider 'dns_selectel' `
    -FileIni "E:\!my-configs\configs\src\dns-api\config.json" `
    -ExtParams @{
                "sectionName"="dns_selectel"; 
                'CFG'=@{
                    'dns_selectel'=@{
                        'version'="$($ver)"
                    }
                };
                'domain'="$($domain)";
                "_Service" = "$($domain)";
                "Body"='test';
                '_Query'='offset=2&limit=2&show_ips=true';
                'record_id'="$($record)" `
    } `
    -Action 'grs' `
    -debug `
    -verbose:$v `
    -LogLevel 1 `
);

$r1