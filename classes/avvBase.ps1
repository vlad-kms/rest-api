enum FlagAddHashtable {
    AddOnly = 1
    Merge   = 2
}

class avvBase : Object {
#class avvBase : PSCustomObject {
    hidden [FlagAddHashtable] $AddOrMerge
    hidden [string] $id=""
    #[string] $id
    <##>
    avvBase ()
    {
        Write-Verbose "avvBase::new() ENTER: ================================================"
        $this.AddOrMerge = [FlagAddHashtable]::Merge
        Write-Verbose "Создали объект $($this.getType().Name)"
        Write-Verbose "avvBase::new() EXIT: ================================================"
    }

    <#########################################################
    входящий hashtable:
        @{
            '_obj_'=@{} - значения для свойств объекта.
                        Заменить значение ключа, если такой ключ есть в объекте
            '_obj_add_'=@{} - поля для добавления в объект
                        Добавить ключ и значение ключа с помощью Add-Member -MemberType NoteProperty
            '_obj_add_value_'=@{} - значения для добавления к текущим значениям полей объекта
        }
    #########################################################>
    avvBase ([Hashtable]$params) {
        Write-Verbose "avvBase::new(params) ENTER: =============================================="
        $this.AddOrMerge = [FlagAddHashtable]::Merge
        Write-Verbose "Создали объект $($this.getType())"
        Write-Verbose "params: $($params|ConvertTo-Json -Depth 5)"
        $this.initFromHashtable($params)
        Write-Verbose "avvBase::new(params) EXIT: =============================================="
    }


    <# MEMBERS +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #>
    <##>
    [boolean] isAvvClass () {
        return $True
    }

    <##>
    [void]initFromHashtable([Hashtable]$params) {
        Write-Verbose "avvBase::initFromHashtable(params) ENTER: ============================================="
        Write-Verbose "params: $($params|ConvertTo-Json -Depth 5)"
        $keyObj = '_obj_';
        if ( $params.Contains($keyObj))
        {
            Write-Verbose "В $params есть key '_obj_'"
            foreach ($key in ($this | Get-Member -Force -MemberType Properties | Select-Object -ExpandProperty Name))
            {
                if ($params.$keyObj.Contains($key)) {
                    Write-Verbose "Заменим значение this.$($key) на $($params.$keyObj.$key)"
                    $this.$key = $params.$keyObj.$key;
                }
            }
        }
        $keyObj = '_obj_add_';
        if ( $params.Contains($keyObj))
        {
            Write-Verbose "В $params есть key '_obj_add_'"
            $params.$keyObj.Keys.foreach({
                #$this[$_] = $params.$keyObj[$_];
                #Write-Host "$($_) === $($params.$keyObj[$_]))"
                #$this | Add-Member -MemberType NoteProperty -Name $_ -Value $params.$keyObj[$_]
                Write-Verbose "Добавим в this NotePropertyName $($_) NotePropertyValue $($params.$keyObj[$_])"
                $this | Add-Member -NotePropertyName "$($_)" -NotePropertyValue $params.$keyObj[$_]
            })
        }
        $keyObj = '_obj_add_value_';
        if ( $params.Contains($keyObj))
        {
            Write-Verbose "В $params есть key '_obj_add_value_'"
            foreach ($key in ($this | Get-Member -Force -MemberType Properties | Select-Object -ExpandProperty Name))
            {
                if ($params.$keyObj.Contains($key)) {
                    $this.$key += $params.$keyObj.$key;
                }
            }
        }
        $keyObj = '_new_';
        if ( $params.Contains($keyObj)) {
            Write-Verbose "В $params есть key '_new_'"
            $this.addHashtable($params.$keyObj, $this, $this.AddOrMerge)
        }
        Write-Verbose "avvBase::initFromHashtable(params) EXIT: ============================================="
    }

    <##>
    [bool] ExistsProperty($Obj, $Key) {
        $result = $false
        try {
            if ($this.isHashtable($Obj)) {
                $result = $Obj.ContainsKey($Key)
            } else {
                $result = ($null -ne ($Obj|Get-Member $Key))
            }
        }
        catch {
            $result = $False
        }
        return $result
    }

    <##>
    [bool] addHashtable([hashtable]$Source) {
        return $this.addHashtable($Source, $this, $this.AddOrMerge)
    }
    [bool] addHashtable([hashtable]$Source, $Dest) {
        return $this.addHashtable($Source, $Dest, $this.AddOrMerge)
    }
    [bool] addHashtable([hashtable]$Source, [FlagAddHashtable]$Action) {
        return $this.addHashtable($Source, $this, $Action)
    }

    <##>
    [bool] addHashtable([hashtable]$Source, $Dest, [FlagAddHashtable]$Action) {
        Write-Verbose "avvBase::addHashtable(Source, Dest, Action) ENTER: ============================================="
        try {
            $result = $false
            if ($null -eq $Dest) {throw "Объект назначения не может быть null"}
            Write-Verbose "Source: $($Source)"
            Write-Verbose "Dest: $($Dest)"
            Write-Verbose "Action: $($Action)"
            foreach($Key in $Source.Keys) {
                if ($this.ExistsProperty($Dest, $Key)) {
                    # ключ есть в объекте назначения
                    Write-Verbose "Ключ $($Key) ЕСТЬ в Dest"
                    switch ($Action) {
                        ([FlagAddHashtable]::AddOnly) {
                            Write-Verbose "В объекте Dest есть ключ $Key. Флаг Action = $Action. Тип значения ключа: $($Dest.$Key.GetType())"
                            if ($this.isCompositeType($Dest.$Key) -and $this.isCompositeType($Source.$Key)) {
                                # Dest.Key и Source.Key имеют тип Hashtable или avvBase
                                Write-Verbose "Рекурсивный вызов с Source.$($Key),  Dest.$($Key), $Action"
                                $this.addHashtable($Source.$Key, $Dest.$Key, $Action)
                            }
                        }
                        ([FlagAddHashtable]::Merge) {
                            Write-Verbose "В объекте Dest есть ключ $Key. Флаг Action = $Action. Тип значения ключа: $($Dest.$Key.GetType())"
                            if ($this.isCompositeType($Dest.$Key) -and $this.isCompositeType($Source.$Key)) {
                                # Dest.Key и Source.Key имеют тип Hashtable или avvBase
                                Write-Verbose "Рекурсивный вызов с Source.$($Key),  Dest.$($Key), $Action"
                                $this.addHashtable($Source.$Key, $Dest.$Key, $Action)
                            } else {
                                Write-Verbose "Записали в                                          : Dest.$($Key) = $($Source.$Key)"
                                $Dest.$Key = $Source.$Key
                            }
                        }
                        Default {
                            throw "Неверное значения $($Action)"
                        }
                    } ### switch ($Action) {
                } else {
                    # ключа нет в объекте назначения
                    Write-Verbose "Ключа $($key) нет в Dest"
                    if ( $this.isHashtable($Dest)) {
                        # добавить к Hashtable
                        Write-Verbose "Добавить к Hashtable                                : Dest.$($Key) = $($Source.$key)"
                        $Dest.Add($key, $Source.$key)
                    #} elseif ( ($Dest -is [Object]) -or ($Dest -is [PSObject]) -or ($Dest -is [PSCustomObject]) ) {
                    } elseif ( $this.isObject($Dest) ) {
                        Write-Verbose "Add-Member к типам Object, PSObject, PSCustomObject : Dest.$($Key) = $($Source.$Key)"
                        $Dest | Add-Member -NotePropertyName $key -NotePropertyValue $Source.$key
                    } else {
                        Write-Verbose "Не можем добавить $($Key) к Dest типа $($Dest.GetType())"
                    }
                }
            }
            $result=$True
        }
        catch {
            $result = $false
        }
        Write-Verbose "avvBase::addHashtable(Source, Dest, Action) EXIT: ============================================="
        return $result
    }

    <#
    [String] ObjectToJson($Source, [bool]$HiddenSecret) {
        Write-Verbose "avvBase::ObjectToJson(Source, HiddenSecret) ============================================="
        Write-Verbose "Source: $($Source)"
        Write-Verbose "HiddenSecret: $($HiddenSecret)"
        Write-Verbose "this.getType(): $($this.getType())"
        $result = ($Source| ConvertTo-Json -Depth 100);

        return $result
    }
    #>
    <##>
     [String] ToJson()
    {
        Write-Verbose "avvBase::ToJson() ENTER: ============================================="
        #Write-Verbose "$($this) ============================================="
        #return  ObjectToJson($this, $true);
        Write-Verbose "avvBase::ToJson() EXIT: ============================================="
        return ($this | ConvertTo-Json -Depth 100);
    }

    [String] ToJson([int]$depth)
    {
        Write-Verbose "avvBase::ToJson([int]Depth) ENTER: ============================================="
        Write-Verbose "Глубина раскрытия: $($depth)"
        #return  ObjectToJson($this, $true);
        Write-Verbose "avvBase::ToJson([int]Depth) EXIT: ============================================="
        return ($this | ConvertTo-Json -Depth $depth);
    }

<##>
    ################## isHashtable ###########################
    [bool] isHashtable($value)
    {
        <#
        #return ($value -is [Hashtable]) -or ($value -is [System.Collections.Specialized.OrderedDictionary]);
        $result = ($value -is [System.Collections.IDictionary]);
        return $result
        #>
        return [avvBase]::isHashtableStatic($value)
    }

    static [bool] isHashtableStatic($value)
    {
        return ($value -is [System.Collections.IDictionary]);
    }

    <##>
    [bool] isObject($Value) {
        #return ($value -is [Hashtable]) -or ($value -is [System.Collections.Specialized.OrderedDictionary]);
        #$result= ($Value -is [System.Object] -or $Value -is [PSObject] -or $Value -is [PSCustomObject])
        #$result = ($Value -is [avvBase]) -or ($Value -is [PSCustomObject])
        $result = [avvBase]::isObjectStatic($Value)
        return $result
    }
    static [bool] isObjectStatic($Value) {
        return ($Value -is [avvBase]) -or ($Value -is [PSCustomObject])
    }

    <##>
    [bool] isCompositeType($Value) {
        <#
        $result= ($this.isHashtable($Value) -or 
                $this.isObject($Value))
        return $result
        #>
        return [avvBase]::isCompositeTypeStatic($Value)
    }
    static [bool] isCompositeTypeStatic($Value) {
        return ([avvBase]::isHashtableStatic($Value) -or 
                [avvBase]::isObjectStatic($Value))
    }

    <# Клонировать текущий объект #>
    [avvBase] clone() {
        Write-Verbose "avvBase::clone () ENTER: ============================================="
        <#
        $typeObj = $this.getType()
        $res = [System.Management.Automation.PSSerializer]::Serialize($this,999)
        $result=([System.Management.Automation.PSSerializer]::Deserialize($res) -as $typeObj)
        return $result
        #>
        Write-Verbose "avvBase::clone () EXIT: ============================================="
        return [avvBase]::copyFrom($this)
    }

    [avvBase] copy() {
        Write-Verbose "avvBase::copy () ENTER: ============================================="
        Write-Verbose "avvBase::copy () EXIT: ============================================="
        return $this.clone()
    }

    <# Клонировать любой объект #>
    static [System.Object] copyFrom([Object] $Source) {
        Write-Verbose "avvBase::copyFrom (Source) ENTER: ============================================="
        Write-Verbose "$($Source) ============================================="
        #Write-Verbose "Source: $($Source|ConvertTo-Json -Depth 5)"
        $typeObj = $Source.getType()
        $res = [System.Management.Automation.PSSerializer]::Serialize($Source,999)
        $result=([System.Management.Automation.PSSerializer]::Deserialize($res) -as $typeObj)
        Write-Verbose "avvBase::copyFrom (Source) EXIT: ============================================="
        return $result
    }

    static [Hashtable] ConvertPSCustomObjectToHashtable([PSCustomObject]$root){
        Write-Verbose "Class avvBase::ConvertPSCustomObjectToHashtable(root) ENTER: ============================================="
        Write-Verbose "root ::: $(($root | ConvertTo-Json -Depth 1))"
        $hash = [ordered]@{};
        $keys = $root | Get-Member -MemberType NoteProperty | Select-Object -exp Name;
        if ($null -ne $keys) {
            Write-Verbose "keys.gettype() ::: $($keys.gettype().Name)"
        }
        Write-Verbose "keys.gettype() ::: $($keys)"
        #$keys | %{
        $keys | ForEach-Object{
            Write-Verbose "Текущий элемент из keys ::: $($_)"
            $obj=$root.$($_);
            Write-Verbose "Тип текущего элемента из keys ::: $($obj.getType().Name)"
            Write-Verbose "Значение текущего элемента ::: $($obj)"
            if($obj -is [PSCustomObject])
            {
                #Write-Verbose "Тип текущего элемента из keys ::: [PSCustomObject]"
                $nesthash=[avvBase]::ConvertPSCustomObjectToHashtable($obj);
                $hash.add($_,$nesthash);
            }
            else
            {
                Write-Verbose "Добавить в hash ::: ($($_), $($obj))"
                $hash.add($_,$obj);
            }
        }
        Write-Verbose "return hash ::: $($hash)"
        Write-Verbose "Class avvBase::ConvertPSCustomObjectToHashtable(root) EXIT: ============================================="
        return $hash
    }

}