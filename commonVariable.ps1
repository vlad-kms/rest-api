enum ActionWithModule {
    dotSourcing = 1
    Import      = 2
}

class CommonVariable {
    [string]$scriptPath="";
    [string]$DS=[System.IO.Path]::DirectorySeparatorChar;
    #[bool]$IsImportModule=$False;
    #[bool]$isDotSourcing=$False

    CommonVariable([String]$scPath)
    {
        $this.scriptPath=$scPath;
    }

   [String] ToJson()
    {
        return $this.ToJson(1);
    }
    
    [String] ToJson([Int]$Depth)
    {
        return ($this | ConvertTo-Json -Depth $Depth);
    }
    
    [void] addProperties([string[]]$Names, [object[]]$Values){
        $i=0
        $Names.ForEach({
            if ( $i -lt $Values.Count) {
                $v=$Values[$i]
            } else {
                $v=$null
            }
            $this.addProperty($_, $v)
            $i+=1
        })
    }

    [void] addProperties([hashtable]$Values){
        $Values.GetEnumerator() | ForEach-Object{
            $this.addProperty($_.Key, $_.Value)
        }
    }

    [void] addProperty([string]$Name, $Value){
        if ( $global:PSVersionTable.PSVersion.Major -ge 3 ) {
            $this | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
        } else {
            $this | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
        }
    }

    [bool] existsProperty([string]$Name) {
        return [bool]($this | Get-Member -Name $Name -MemberType Properties)
    }
}

