#using module '.\avvBase.ps1';

#using module "D:\Tools\~scripts.ps\avvClasses\classes\avvBase.ps1";
#. "D:\Tools\~scripts.ps\avvClasses\classes\avvBase.ps1";

<#
# Класс FileCFG базовый класс. Сам по себе бесполезен.
# Может считывать, записывать, добавлять ключи, значения, секции.
# Для записи требуется сначала установить свойство isReadOnly в $False.
# Класс IniCFG для работы с файлами .ini. Содержимое файла загружается в Hashtable.
# Секции это ключи первого уровня, создаются из имен секций. Значения параметров секции
# пишутся как ключи и значения в Hashtable. Если имя файла переданное в конструктор = '_empty_',
# то инициализацию из файла пропустить, т.е. CFG после конструктора будет @{}
# Например:
ФАЙЛ ini
    [default]
    Token=<KEY API TELEGRAM>0
    access_token=789
    ExtVersion=ext
    ClinicVersion=2
    test=test
    test1=test1
    [_always_]
    param1=value1
    param2=value2
    [dns_cli]
    Token=$($Token)
    access_token=$($ExtParams.Token)
    ExtVersion=$($ExtParams.ExtVersion)
    ClinicVersion=$($ExtParams.ClinicVersion)
    par1="$($ExtParams.Token)"
    par1="$ExtParams"
    ke="1+3"
    kf=$(2+1*3) - будет подсчитано арифметическое выражение
    ;Token=_empty_

    [dns_cli1]
    test1=_empty_
    Hashtable
    Name                           Value
    ----                           -----
    default                        {Token, access_token, ExtVersion, ClinicVersion...}
    dns_cli                        {Token, access_token, ExtVersion, ClinicVersion}
    dns_cli1                       {test1}

    PS C:\Windows\system32> $c.CFG.default
    Name                           Value
    ----                           -----
    Token                          <KEY API TELEGRAM>0
    access_token                   789
    ExtVersion                     ext
    ClinicVersion                  2
    test                           test
    test1                          test1
# Если имеется секция [default], то значение ключа формируется по правилам
# Если в секции нет ключа, а в [default] есть, значение берется из [default].
# Если в секции есть ключ, неважно есть или нет в [default], значение берется из секции,
# кроме случая, если значение в секции = '_empty_', значение берется из [default].
# Если имеется секция [_always_], то значение ключа формируется по правилам:
# Применяются они после [default] и заменяют все что было до этого, т.е.
# секция [_always_] переопределяет все остальные параметры.
# В отличии от классического ini, есть поддержка вложенных Hashtable'ов.
# Есть конструктор для создания из Hashtable. Входной объект добавляется через (+) в CFG.
# В файле ini могут использоваться переменные. Примеры в секции [dns_cli] выше. Переменные
# высчитываются при помощи Invoke-Expression.
# Здесь и можно использовать вложенность в полной мере.
# Поле ErrorAsException если True, то при чтении если нет ключа, ошибка преобразования в тип и т.д.
# преобразуется в Exception, иначе возвращается пустая строка.
# Функции:
#   [Hashtable]readSection([string]$section) - считать секцию.
#       Выход: @{
#                   code: 0 - секция есть и ее считали
#                   result: - считанная секция, т.е. ее ключи и значения
#               }
# Следующие методы считывают ключ в заданной секции. get<Type> работают через getKeyValue,
# просто преобразуя результат в требуемый тип
#   [Object] hidden getKeyValue([string]$path, [string]$key)
#   [bool] getBool([string]$path, [string]$key){
#   [string] getString([string]$path, [string]$key){
#   [Int] getInt([string]$path, [string]$key){
#   [long] getLong([string]$path, [string]$key){
#   saveToFile([string]$filename, [bool]$isOverwrite)
#                       - записать в файл INI $filename секцию CFG. Записывается только первый уровень,
#                         не пишутся ключи, значением которых является [Hashtable]
#                         $isOverwrite показывает перезаписывать файл или нет
#   saveToFile()          - то же что и выше, но записывается в файл $this.filename. По умолчанию $isOverwrite=$False
#   saveToFile([bool]$isOverwrite)
#   [bool] hidden setKeyValue([string]$path, [string]$key, [Object]$value){
#                       - записать значение в ключ секции, значение ключа по пути.
#                         Если ключ = '', то метод проверяет есть ли путь, и создает его если его нет.
#
# ****** class JsonCFG  ************************************
# Все тоже самое, разница в файлах с которым работает класс, а именно Json.
# Остальное аналогично, толдько вложенность многоуровневая из-за структуры файлов.
#>

<######################################
    [FileCFG]
Правила именования Java
#######################################>
#. .\avvBase.ps1

Class FileCFG : avvBase {
    [string] $filename      ='';
    [Hashtable] $CFG        =[ordered]@{};
    [bool] $errorAsException=$false;
    [bool] $isReadOnly      =$true;
    [bool] $isOverwrite     =$false;
    [bool] $isDebug         =$false;
    [String]hidden $currentSection ='.';
    [System.Collections.Generic.List[String]]hidden $SecretKeys = @(
        'password',
        'pass',
        'passwd',
        'pswd',
        'pwd',
        'secret',
        'token'
    )

    <#################################################
    #   Constructors
    #################################################>
    FileCFG(){
        Write-Verbose "Class FileCFG::FileCFG() ENTER: ============================================="
        $this.filename=$PSCommandPath + $this.getExtensionForClass();
        $this.initFileCFG();
        Write-Verbose "Class FileCFG::FileCFG() EXIT: ============================================="
    }
    FileCFG([bool]$EaE){
        Write-Verbose "Class FileCFG::FileCFG(bool EaE) ============================================="
        $this.filename=$PSCommandPath + $this.getExtensionForClass();
        #$this.errorAsException=$EaE
        $this.errorAsException=$EaE
        $this.initFileCFG();
    }
    FileCFG([string]$FN){
        Write-Verbose "Class FileCFG::FileCFG(string FN) ============================================="
        $this.filename=$FN;
        $this.initFileCFG();
    }
    FileCFG([string]$FN, [bool]$EaE) {
        Write-Verbose "Class FileCFG::FileCFG(string FN, bool EaE) ============================================="
        $this.filename=$FN;
        #$this.errorAsException=$EaE
        $this.errorAsException=$EaE
        $this.initFileCFG();
    }

    FileCFG([string]$FN, [bool]$EaE, [Hashtable]$CFG) {
        Write-Verbose "Class FileCFG::FileCFG(string FN, bool EaE, Hashtable CFG) ============================================="
        #$FN = '_empty_';
        if ($null -ne $FN) {
            $this.filename = $FN;
        } else {
            $FN = '_empty_';
        }
        $this.errorAsException = $EaE
        $this.initFileCFG();
        $this.CFG += $CFG;
    }

    #FileCFG([Hashtable]$CFG) : base ($CFG){
    FileCFG([Hashtable]$CFG) : base (){
        Write-Verbose "Class FileCFG::FileCFG(Hashtable CFG) ENTER:============================================="
        # входящий hashtable:
        #   @{
        #       '_obj_'           =@{} - значения для свойств объекта базового класса
        #       '_obj_add_'       =@{} - значения для свойств объекта базового класса
        #       '_obj_add_value_' =@{} - значения для свойств объекта базового класса
        #       'cfg'             =@{} - значение для поля CFG, заменяют считанные из файла
        #       'cfg_add'         =@{} - значение для поля CFG, добавляются к считанным из файла
        #   }
        $this.filename = '_empty_';

        if ( $CFG.ContainsKey('Filename') -and ($CFG.Filename) ) {
            $this.filename = $CFG.Filename;
        }
        $objKey='_obj_'
        if ( $CFG.ContainsKey($objKey)  -and $CFG.$objKey.ContainsKey("filename") -and $CFG.$objKey.filename ) {
            $this.filename = $CFG.$objKey.filename;
        }
        if ( $CFG.ContainsKey($objKey)  -and $CFG.$objKey.ContainsKey("errorAsException") -and $CFG.$objKey.errorAsException ) {
            $this.errorAsException = $CFG.$objKey.errorAsException;
        }

        $objKey='_new_'
        if ( $CFG.ContainsKey($objKey)  -and $CFG.$objKey.ContainsKey("filename") -and $CFG.$objKey.filename ) {
            $this.filename = $CFG.$objKey.filename;
        }
        if ( $CFG.ContainsKey($objKey)  -and $CFG.$objKey.ContainsKey("errorAsException") -and $CFG.$objKey.errorAsException ) {
            $this.errorAsException = $CFG.$objKey.errorAsException;
        }

        # считать данные из файла
        $this.initFileCFG();
        # добавить данные из hashtable CFG
        $this.initFromHashtable($CFG);
        
        $keyCurrent='cfg';
        if ($CFG.Contains($keyCurrent) -and $this.isHashtable($CFG.$keyCurrent) )
        {
            $this.addHashtable($CFG.$keyCurrent, $this.CFG, [FlagAddHashtable]::Merge);
        }
        Write-Verbose "Class FileCFG::FileCFG(Hashtable CFG) EXIT:============================================="
    }

    static[System.Collections.Generic.List[String]] DefaultSecretKeys() {
        return [System.Collections.Generic.List[String]]  @(
                'password',
                'pass',
                'passwd',
                'pswd',
                'pwd',
                'secret',
                'token'
            )
    }

    <#################################################
    #   MEMBERS
    #################################################>
    [String] getExtensionForClass()
    {
        $type = $this.GetType();
        if (($type.Name.ToUpper() -eq "JsonCFG".ToUpper()))
        {
            $res = '.json';
        }
        elseif ($type.Name.ToUpper() -eq "INICFG".ToUpper())
        {
            $res = '.ini';
        }
        else
        {
            $res = '.cfg';
        }
        return $res;
    }
    <#
    #   Инициализация. Проверить существование файла, считать данные из
    #   файла в hashtable. Если имя файла = '_empty_', то пропуск метода.
    #   Exception, если не считали, или объект пустой
    #>
    [bool]initFileCFG() {
        $result=0;
        #if (!$this.filename) {$this.filename = '_EMPTY_'}
        if ($this.filename.ToUpper() -ne '_EMPTY_' )
        {
            # $this.filename != '_empty_';
            #$this.isExcept(!$this.filename, $true, "Not defined Filename for file configuration.");
            $this.isExcept(!$this.filename, "Not defined Filename for file configuration.");
            $isFile = Test-Path -Path "$($this.filename)" -PathType Leaf;
            #$this.isExcept(!$isFile, $true, "Not exists file configuration: $($this.filename)");
            $this.isExcept(!$isFile, "Not exists file configuration: $($this.filename)");
            $this.CFG=$this.importInifile($this.filename);
            $result=$this.CFG.Count;
            #$this.isExcept(!$result, "Error parsing file CFG: $($this.filename)")
        }
        return $result;
    }
    
    [Hashtable]importInifile([string]$filename){
        $this.currentSection = '.';
        return [ordered]@{}
    }

    [string]isExcept ([bool]$Value, [string]$Msg) {
        return $this.isExcept($Value, $this.errorAsException, $Msg)
    }

    [string]isExcept ([bool]$value, [bool]$EasE, [string]$msg) {
        if ( $EasE -and $value ) {
            throw($msg)
        }
        if ($value)
        {
            if ($this.isDebug) { $msg | Out-Host; }
            return $msg;
        } else { return ""; }
    }

    <######################### readSection ############################################
    #   Считать секцию
    #   Возврат:
    #       [Hashtable]@{
    #           code:   0 - секция есть и ее считали
    #                   1 - нет пути, т.е. какой-то элемента в section
    #                   2 - есть путь, но какой-то элемент в пути не
    #                       является [Hashtable]п
    #                   3 -
    #           result:   - считанная секция, т.е. ее ключи и значения
    #                       Список ключей и значений из секции.
    #       }
    #       Если секция не существует, то в зависимости от errorAsException,
    #       либо пустой список, либо формируется Exception
    #########################################################################>
    [String]
    normalizeSection ([String]$section)
    {
        $result = $section.trim();
        if (!$result) { $result = '.'; }
        $isRoot = $false;
        #while ( !$result -or ($result.Substring(0, 1) -eq '\') -or ($result.Substring(0, 1) -eq '/'))
        while ( !$result -or $result.StartsWith('\') -or $result.StartsWith('/'))
        {
            $isRoot = $true;
            $result = $result.Substring(1, $result.Length -1);
        }
        if (!$isRoot)
        {
            $result = $this.currentSection + '.' + $result;
        }
        #while (($result.Substring(0, 1) -eq '\') -or ($result.Substring(0, 1) -eq '/'))
        while ( $result.StartsWith('\') -or $result.StartsWith('/'))
        {
            $result = $result.Substring(1, $result.Length -1);
        }
        return $result;
    }

    [Hashtable]readSection([string]$section) {
        $result = @{};
        $code = 0;
        # массив из строки 'sec1.sec2.sec3...
        $section = $this.normalizeSection($section);
        $arrSections = $section.Split('.', [StringSplitOptions]::RemoveEmptyEntries);
        $path = $this.CFG;
        # проверить для каждого из массива, что существует ключ и его значение есть Hashtable:
        # как-то так
        # sec1=@{
        #           sec2=@{
        #                   sec3=@{
        #                       key1=val1
        #                       key2=val2
        #                           ...
        #                   }
        #           }
        # }
        $arrSections.ForEach({
            #if ( $path.Contains($_) -and $this.isHashtable($path[$_]) )
            if ( $path.Contains($_) )
            {
                #if ( ($path[$_] -is [Hashtable]) -or
                #     ($path[$_] -is [System.Collections.Specialized.OrderedDictionary])
                #    )
                if ($this.isHashtable($path[$_]))
                {
                    $path = $path[$_];
                }
                else
                {
                    # путь есть, но элемент не [Hashtable]
                    $path = @{};
                    $code = 2;
                }
            }
            else
            {
                # нет такого пути
                $path = @{};
                $code = 1;
            }
        });
        # ошибка и пустой Hashtable, если считанное значение не Hashtable.
        # Т.е. убрали считывание ключа, оставили только секцию
        #if (!($path -is [Hashtable]) -and
        #        !($path -is [System.Collections.Specialized.OrderedDictionary])
        #    )
        if ( !$this.isHashtable($path) )
        {
            # последний элемент в пути не является [Hashtable]
            $path = $null;
            $code = 2;
        }
        if ( $code -ne 0 ) { $path = $null; }
        # Если в секции нет значений и $this.ErrorAsException и $code <> 0, то породить Exception
        !$this.isExcept( ($path.Keys.Count -eq 0) -and ($code -ne 0), "Not found section name $($section) or is not Section type");
        $result = @{
            'code'=$code;
            'result'=$path;
        }
        # секция с заполненными значениями с учетом секций [default] [_always_]
        while ($section.StartsWith('.')) { $section=$section.Substring(1, $section.Length-1) }
        $pathDefs=$this.fillValues($path, $section)
        $result.Add('resultDefs', $pathDefs)
        <#
        $pathDefs=[ordered]@{};
        while ($section.StartsWith('.')) { $section=$section.Substring(1, $section.Length-1) }
        $path.Keys.foreach({
            $pathDefs.Add($_, $this.getKeyValueUseDefaultAlways($path, $section, $_))
        });
        $result.Add('resultDefs', $pathDefs)
        #>


        <# НЕ НАДО
        # секция с заполненными значениями с учетом секций [default] [_always_]
        # и с добавленными ключами из секции default вида section_key, section.key,
        # которых нет в секции section
        $pathDefsOnly=[ordered]@{};

        $result.Add('resultDefsOnly', $pathDefsOnly)
        #>
        return $result;
    }
    
    [hashtable] fillValues ([Hashtable]$path, [String]$section) {
        $result=[ordered]@{};
        $path.Keys.foreach({
            if ($this.isHashtable($path.$_)) {
                if ($section) {
                    $s="$($section).$($_)"
                } else {
                    $s="$($_)"
                }
                $result.Add($_, $this.fillValues($path.$_, $s))
            } else {
                $result.Add($_, $this.getKeyValueUseDefaultAlways($path, $section, $_))
            }
        });
        
        return $result
    }
    
    [hashtable] getSectionValues([String]$path, $section)
    {
        if ($section) { $path += ".$($section)"}
        return $this.readSection($path);
    }

    [hashtable] getSectionValues([String]$path)
    {
        return $this.getSectionValues($path, '');
    }

    [hashtable] getSection([String]$path, $section)
    {
        if ($section) { $path += ".$($section)"}
        $res = $this.readSection($path);
        if ($res.code -eq 0) { return $res.result; }
        else { return $null; }
    }
   
    [hashtable] getSection([String]$path)
    {
        return $this.getSection($path, '');
    }
<#
    [hashtable] getSectionProcessedKeys([String]$Path, $section)
    {
        result= @{};
        $readSection=$this.getSection($path, $section);

        return $result
    }

    [hashtable] getSectionProcessedKeys([String]$Path)
    {
        return $this.getSectionProcessedKeys($path, '');
    }
#>
    [hashtable] addSection([string]$path, [string]$section){
        $result = $null;
        if ($this.isReadOnly) { return $result; }
        $res = $true;
        # проверить каждый элемент в path и
        # если он есть и не hashtable
        #   то прервать с ошибкой
        # если он есть и hashtable
        #   то перейти к следующему элементу
        # если его нет
        #   то создать и перейти к следующему, если при создании не было ошибок
        $path = $this.normalizeSection($path);
        $arrPath = $path.Split('.', [StringSplitOptions]::RemoveEmptyEntries);
        $currentPath = $this.CFG;
        $arrPath.foreach({
            if ( $currentPath.Contains($_) -and $this.isHashtable($currentPath["$_"]) )
            {
                # взять следующий элемент пути
                $currentPath = $currentPath["$_"];
                $res = $true;
            }
            elseif (!$currentPath.Contains($_))
            {
                # создать новый ключ типа hashtable
                $currentPath.add($_, @{});
                # взять следующий элемент пути
                $currentPath = $currentPath["$_"];
                $res = $true;
            }
            elseif ( $currentPath.Contains($_) -and !$this.isHashtable($currentPath["$_"]) )
            {
                $res = $False;
                $this.isExcept(!$result, "Невозможно создать секцию по данному пути $($path). Уже есть ключ с таким именем.");
            }
            else
            {
                $res = $False;
                $this.isExcept(!$result, "неопределенная ошибка при создании секции по данному пути $($path).");
            }
        })
        # $result= $True, если путь подходит для создания новой секции,
        if ($res)
        {
            # проверить нет ли ключа в данной секции с таким именем $section
            # если нет, то создать новую секцию $section,
            # иначе Exception
            if (!$section)
            {
                $result = $currentPath;
            }
            elseif ( !$currentPath.Contains($section))
            {
                #создать секцию
                $currentPath.add($section, @{});
                $result = $currentPath["$section"];
            }
            elseif ($currentPath.Contains($section) -and $this.isHashtable($currentPath["$section"]))
            {
                $result = $currentPath["$section"];
            }
            else #if ( $currentPath.Contains($section) -and !$this.isHashtable($currentPath["$section"]) )
            {
                $result = $null;
                $this.isExcept(($null -eq $result), "Невозможно создать секцию по данному пути $($path). Уже есть ключ с таким именем.");
            }
        }
        return $result;
    }
    [hashtable] addSection([string]$path)
    {
        return $this.addSection([string]$path, '');
    }

    ########################## setKeyValue ################################
    # Записать значение ключа по пути.
    # Если ключ = '', то метод проверяет есть ли путь, и создает его если его нет.
    # и возвращает True,
    # если есть, или смог его создать только попытаться создать путь (секции), если его нет,
    # или вернуть
    # Вход:
    #   $path   - секция, куда добавить key=value, или изменить его
    #   $key    - ключ для которого менять значение
    #   $value  - значение, которое записать по пути
    #   о
    # Возврат:
    #   $true если запись удачно, иначе $false.
    #   Если key='': $true если путь есть или смогли создать, иначе $false
    ##########################################################
    [bool]  setKeyValue([string]$path, [string]$key, [Object]$value){
        $result = $false;
        $currentPath = $null;
        if (!$this.isReadOnly) {
            # здесь только если свойство isReadOnly != $True
            $r = $this.readSection($path);
            if ($r.code -ne 0)
            {
                if ($r.code -eq 1) {
                    # секции нет, создать ее
                    $currentPath = $this.addSection($Path, '');
                    $result = $true;
                }
                elseif ($r.code -eq 2)
                {
                    # путь есть, но это не секция, а значение
                    $this.isExcept($true,'Нельзя записать $($key) по пути $($path), т.к. путь не является секцией');
                    $result = $false;
                }
                else
                {
                    # неизвестная ошибка
                    $this.isExcept($true, 'Неопределенная ошибка при запсис $($key) по пути $($path)');
                    $result = $false;
                }
            }
            else
            {
                $currentPath = $r.result;
                $result = $true;
            }
            # записать значение, если присутствует key и он не равен ''
            if ($key -and $result)
            {
                $currentPath["$key"] = $value
                $result = $true;
            }
        }
        return $result;
    }
    [bool] setString([string]$path, [string]$key, [string]$value)
    {
        return $this.setKeyValue($path, $key, $value);
    }
    [bool] setInt([string]$path, [string]$key, [Int]$value)
    {
        return $this.setKeyValue($path, $key, $value);
    }

    <# ============================================================ #>
    [Object]hidden getKeyValueUseDefaultAlways([hashtable]$section, [string]$path, [string]$key)
    {
        $result=''
        if ($section.Contains($key) -and $section[$key])
        {
            $result=$section[$key]
        }
        else
        {
            # Нет в секции $section ключа $Key 
            # Будем получать значение из секции default
            if ($this.CFG.default.Contains($key)) {
                $result=$this.CFG.default[$key]
            }
            if ($this.CFG.default["${Path}_${key}"]) {
                $result=$this.CFG.default["${Path}_${key}"]
            }
            if ($this.CFG.default["${Path}.${key}"]) {
                $result=$this.CFG.default["${Path}.${key}"]
            }
        }
        # Обработка секции [_always_]
        if ($this.CFG.Contains('_always_') -and $this.isHashtable($this.CFG['_always_'])) {
            if ($this.CFG['_always_'].Contains($key))
            {
                $result = $this.CFG['_always_'][$key];
            }
            if ($this.CFG['_always_'].Contains("${Path}_${key}")) {
                $result = $this.CFG['_always_']["${Path}_${key}"];
            }
            if ($this.CFG['_always_'].Contains("${Path}.${key}")) {
                $result = $this.CFG['_always_']["${Path}.${key}"];
            }
        }
        $this.isExcept($result.Length -eq 0, "Not found key $($key) in section name $($path)");
        try
        {
            if ( ($result.gettype() -eq ''.gettype()) -and ($result.ToUpper() -eq '_empty_'.ToUpper()) ) { $result='' }
        }
        catch
        {
            $result=''
        };

        return $result;
    }
    <################################## getKeyValue ##########################################
    Считать значение ключа, учитывая секцию default
    Вход:
        [string]$Path - имя секции
        [string]$Key  - имя ключа
    Возврат:
        [string] Значение ключа.
                 Если секция $Path отсутствует, то ""
                 Если ключ есть в требуемой секции, то возвращается значение этого ключа.
                 Если ключа нет в требуемой секции,
                   то возврат ключа из секции [default] (при наличии секции default)
                 При наличии секции _always_, если ключ есть в ней, то берется значение из _always_
                 Если ключа нет ни в требуемой секции, ни в секции [default], ни в секции [_always_], то возврат ""
                 Если значение ключа = _empty_, то вернет пустую строку ''
    ###############################################################################>
    [Object]hidden getKeyValue([string]$path, [string]$key) {
        $result=''
        $section = $this.getSection($path, '');
        if ($null -eq $section) { return $result; }
        $result = $this.getKeyValueUseDefaultAlways($section, $path, $key)
        return $result;
    }

    [bool] getBool([string]$path, [string]$key) {
        return [bool]$this.getKeyValue($path, $key)
    }
    [string] getString([string]$path, [string]$key) {
        return [String]$this.getKeyValue($path, $key)
    }
    [Int] getInt([string]$path, [string]$key) {
        return  [int]$this.getKeyValue($path, $key)
    }
    [long] getLong([string]$path, [string]$key) {
        return [long]$this.getKeyValue($path, $key)
    }

    ################## saveToFile ###########################
    [Void] saveToFile()
    {
        $this.saveToFile($this.filename, $this.isOverwrite);
    }
    [Void] saveToFile([bool]$isOverwrite)
    {
        $this.saveToFile($this.filename, $isOverwrite);
    }
    [Void] saveToFile([string]$filename)
    {
        $this.saveToFile($filename, $this.isOverwrite);
    }
    [Void] saveToFile([string]$filename, [bool]$isOverwrite)
    {
    }

    ################## toJson ###########################
    <#
    [String] ToString()
    {
        #return $this.ToJson();
        return ($this | ConvertTo-Json -Depth 100);
    }
    #>
    hidden [void] ObjectToJson([ref]$Source, [bool]$HiddenSecret, [System.Collections.Generic.List[String]]$ArraySecrets) {
        Write-Verbose "Class FileCFG::ObjectToJson(Source, HiddenSecret) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "Source: $($Source.Value)"
        Write-Verbose "HiddenSecret: $($HiddenSecret)"
        Write-Verbose "ArraySecrets: $($ArraySecrets)"

        $HiddenSecret = $false #TODO Удалить. Сделано для пропуска убирания секретов, потому что пока не работает
        if ($HiddenSecret) {
            [System.Collections.Generic.List[String]]$ArSec = [FileCFG]::DefaultSecretKeys()
            if ($null -eq $ArraySecrets) {
                $ArSec += $this.SecretKeys
            } else {
                $ArSec = $ArraySecrets + $this.SecretKeys
            }
            if ( ($null -eq $ArSec) -or ($ArSec.Count -eq 0) -or ($ArSec -eq $null) ){
                $ArSec = [FileCFG]::DefaultSecretKeys()
            }
            for ($i=0; $i -lt $ArSec.Count; $i++)
            {
                $ArSec[$i] = $ArSec[$i].ToUpper()
            }
                Write-Verbose "Hidden secrets"
            <# спрятать все значения ключей начинающихся (регистронезависимое сравнение) с:
                1) secret
                2) token
                3) password
                4) hidden
            #>
            if ([avvBase]::isCompositeTypeStatic($Source.Value)) {
                (Get-Member -InputObject $Source.Value -MemberType Properties) | ForEach-Object {
                    #if ($_.Name.ToUpper() -eq 'SECRETKEYS') {
                    #    $Source.Value.($_.Name) = "$($_.Name.ToUpper())"
                    #}
                    Write-Verbose "_ : $_"
                    Write-Verbose "_.getType() : $_.gettype()"
                    Write-Verbose "_.Name : $_.Name"
                    Write-Verbose "_.Name asValue : $($Source.Value.($_.Name))"
                    #if (-not [avvBase]::isHashtableStatic($Source)) {
                        if ($ArSec.Contains($_.name.ToUpper())) {
                            # надо спрятать
                            $Source.Value.($_.Name) = "$($_.Name.ToUpper())"
                        } else {
                            # рекурсивный обход вниз по вложенным свойствам объекта
                            $this.ObjectToJson(([ref]$Source.Value.($_.Name)), $HiddenSecret, $ArraySecrets)
                        }
                    #}
                }
            } else {
                # простой тип
                Write-Verbose "_ : $_"
                Write-Verbose "_.Name : $_.Name"
                Write-Verbose "_.Name asValue : $($Source.Value.($_.Name))"
                if ($_.Name.ToUpper() -eq 'SECRETKEYS') {
                    $Source.Value.($_.Name) = "$($_.Name.ToUpper())"
                }
                if ($ArSec.Contains($_.name.ToUpper())) {
                    $Source.Value.($_.Name) = "$($_.Name.ToUpper())"
                }
            }
        }
        #$result = $Source;
        #return $result
    }

    [String] ToJson([bool]$HiddenSecret){
        Write-Verbose "Class FileCFG::ToJson([bool]HiddenSecret) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "HiddenSecret: $($HiddenSecret)"
        #$th = $this
        $th = $this.clone()
        $th.id=[string]$th.id+"-COPY"

        #return ($th | ConvertTo-Json -Depth 100);
        $this.ObjectToJson(([ref]$th), $HiddenSecret, $null)
        return ( $th | ConvertTo-Json -Depth 100);
    }

    [String] ToJson()
    {
        Write-Verbose "Class FileCFG::ToJson() ============================================="
        Write-Verbose "this: $($this)"
        return $this.ToJson($true);
    }

    [String] ToJson([string]$path)
    {
        Write-Verbose "Class FileCFG::ToJson() ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "path: $($path)"
        return $this.ToJson($path, $true);
    }

    [String] ToJson([string]$path, [bool]$HiddenSecret)
    {
        Write-Verbose "Class FileCFG::ToJson(path) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "path: $($path)"
        Write-Verbose "HiddenSecret: $($HiddenSecret)"
        $th = $this.getSection($path)
        #$th = $this.clone().getSection($path)
        #$th = $this
        <# спрятать все значения ключей начинающихся (регистронезависимое сравнение) с:
            1) secret
            2) token
            3) password
            4) hidden
        #>
        #return ($th | ConvertTo-Json -Depth 100);
        $this.ObjectToJson(([ref]$th), $HiddenSecret, $null)
        return ( $th | ConvertTo-Json -Depth 100);
    }

}

### +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#    [IniCFG]
#    Объект для работы с файлом форматов ini
### +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Class IniCFG : FileCFG {
    IniCFG() : base()
    {
    }
    IniCFG([bool]$EaE) : base($EaE)
    {
    }
    IniCFG([string]$FN) : base($FN)
    {
    }
    IniCFG([string]$FN, [bool]$EaE) : base($FN, $EaE)
    {
    }
    IniCFG([Hashtable]$CFG) : base($CFG)
    {
    }
    IniCFG([string]$FN, [bool]$EaE, [Hashtable]$CFG): base($FN, $EaE, $CFG)
    {
    }

    ###############################################################################
    # Считать из файла данные.
    # Строки [name] (SECTION) расцениваются как секция section. Т.е. в [hashtable] вставляется как
    # встроенная [hashtable]. 1-е условие в switch
    # Строки вида name=value (PARAMETER) расцениваются как параметр в секции key=value.
    # Т.е. вставляется как параметр(ключ) в [hashtable][section]. 2-е условие в switch
    # Строки начинающиеся с ';' ,'#', '*' (COMMENT) не обрабатываются,
    # т.е. используем для комментариев.  3-е условие в switch
    #
    # Если в строке типа PARAMETER указаны значения (value) как '$($str)', '"$str2"', то такие значения будут
    # вычислены, по правилам powershel, при чтении файла. Например в файле есть key1="nameVariable",
    # при обработке эnа строка будет вычислена, если в скрипте есть переменная и она в области видимости global
    # или данного класса (модуля)
    # $nameVariable=valueVariable. Если переменной нет, то будет пусто.
    # то в [hashtable][$section][$key] будет прописано значение valueVariable.
    ###############################################################################
    [Hashtable]importInifile([string]$filename){
        Write-Verbose "Class IniCFG::importInifile(filename) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "filename: $($filename)"

        ([FileCFG]$this).importInifile($filename);
        $iniObj = [ordered]@{}
        $this.isExcept(!$filename, "Not defined Filename for file configuration.")
        $isFile = Test-Path -Path "$($filename)" -PathType Leaf
        $this.isExcept(!$isFile, "Not exists file configuration: $($filename)")
        if ($isFile)
        {
            # если файл существует и он не каталог.
            $section = ""
            switch -regex -File $filename
            {
                "^\[(.+)\]$" {
                    # строки вида:
                    # [name]
                    $section = $matches[1]
                    $iniObj[$section] = [ordered]@{ }
                    #Continue
                }
                "(?<key>^[^\#\;\=]*)[=?](?<value>.+)" {
                    # строки вида:
                    # name=value, name=$(value), name="value",
                    # где value - вычисляемое выражение, переменная скрипта
                    $key = $matches.key.Trim()
                    $value = $matches.value.Trim()

                    if (($value -like '$(*)') -or ($value -like '"*"'))
                    {
                        $value = Invoke-Expression $value
                    }
                    if ($section)
                    {
                        $iniObj[$section][$key] = $value
                    }
                    else
                    {
                        $iniObj[$key] = $value
                    }
                    continue
                }
                "(?<key>^[^\#\;\=]*)[=?]" {
                    # строки вида:
                    # name=
                    # т.е. пустые
                    $key = $matches.key.Trim()
                    if ($section)
                    {
                        $iniObj[$section][$key] = ""
                    }
                    else
                    {
                        $iniObj[$key] = ""
                    }
                }
            } ### switch -regex -File $IniFile {
        } ## if ($isFile)
        return $iniObj
    }
    
    [Void] saveToFile([string]$filename, [bool]$isOverwrite){
        Write-Verbose "Class IniCFG::importInifile(filename) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "filename: $($filename)"
        Write-Verbose "isOverwrite: $($isOverwrite)"

        # если $this.filename = '_empty_' или пустой строке, то выход
        if (!$filename -or ($filename.ToUpper() -eq '_empty_'.ToUpper() ))
        {
            return;
        }
        # проверить что каталога с таким именем нет.
        if (Test-Path $filename -PathType Container){
            $msg = $this.isExcept($true, "Невозможно записать в файл, так как он является каталогом");
            Write-Host $msg;
            return;
            #throw "Невозможно записать в файл, так как он является каталогом";
        }
        # проверить что файл с таким именем есть и перезапись запрешена.
        if ( (Test-Path $filename -PathType Leaf) -and !$isOverwrite){
            $msg = $this.isExcept($true, "Файл существует, а перезапись запрещена");
            Write-Host $msg;
            return;
            #throw "Невозможно записать в файл, так как перезапись запрещена";
        }
        $sections=$this.readSection('.');
        #$sections=$this.readSection('.'); # аналогичный результат
        # проверить что смогли считать корневую секцию CFG
        $nameRootSection = '__root__';
        if ($sections.code -eq 0) {
            # считали секцию CFG
            $data2file=@{
                "$nameRootSection"=@()
            };
            $sections=$sections.result;
            foreach ($key in $sections.Keys){
                # цикл по всем ключам
                # значение текущего ключа
                $cSect = $sections[$key];
                if ($this.isHashtable($cSect))
                #if (
                #        ($cSect -is [Hashtable]) -or
                #        ($cSect -is [System.Collections.Specialized.OrderedDictionary])
                #    )
                {
                    # если тип значения текущего ключа есть Hashtable
                    #$data2file[$key] += "[$($Key)]";
                    $data2file[$key] = @()
                    $cSect.GetEnumerator() | ForEach-Object { #"{0}={1}" -f $_.key, $_.value }
                        $data2file[$key] += "$($_.key)=$($_.value)";
                    }
                }
                else {
                    # если тип значения текущего ключа не Hashtable,
                    # т.е. просто ключ=значение
                    $data2file.$nameRootSection += "$($key)=$($cSect)";
                }
            }
            # записать в файл, если в массиве есть данные
            <#
            if ($data2file.Count -gt 0) {
                $data2file | Out-File -FilePath $filename -Force -Encoding default;
            }
            #>
            # записать в файл
            $df = @();
            $data2file.$nameRootSection.foreach({
                $df += $_;
            })
            #if ($df.count -ne 0) { $df += ''; }
            foreach ( $key in $data2file.Keys) {
                #Write-Host $key;
            #
                if ($key -ne $nameRootSection) {
                    $df += '';
                    $df += "[$($key)]";
                    $data2file["$key"].foreach({
                        $df += $_;
                    })
                }
                ###$df += $_;
            #
            }
            $df | Out-File -FilePath $filename -Force -Encoding default;
        } ### если были секции в hashtable
    }
}

### +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#    [JsonCFG]
#    Объект для работы с файлом форматов json
### +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class JsonCFG : FileCFG
{
    JsonCFG(): base()
    {
        Write-Verbose "constructor JsonCFG::JsonCFG() ============================================="
        Write-Verbose "this: $($this)"
    }
    JsonCFG([bool]$EaE): base($EaE)
    {
        Write-Verbose "constructor JsonCFG::JsonCFG([bool] EaE) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "EaE: $($EaE) ============================================="
    }
    JsonCFG([string]$FN): base($FN)
    {
        Write-Verbose "constructor JsonCFG::JsonCFG([string] FN) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "FN: $($FN) ============================================="
    }
    JsonCFG([string]$FN, [bool]$EaE): base($FN, $EaE)
    {
        Write-Verbose "constructor JsonCFG::JsonCFG([string] FN, [bool] EaE) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "FN: $($FN) ============================================="
        Write-Verbose "EaE: $($EaE) ============================================="
    }
    JsonCFG([Hashtable]$CFG) : base($CFG) {
        Write-Verbose "constructor JsonCFG::JsonCFG([Hashtable] CFG) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "CFG: $($CFG) ============================================="
    }
    JsonCFG([string]$FN, [bool]$EaE, [Hashtable]$CFG) : base ($FN, $Eae, $CFG)
    {
        Write-Verbose "constructor JsonCFG::JsonCFG([string] FN, [bool] EaE, [Hashtable]$CFG) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "FN: $($FN) ============================================="
        Write-Verbose "EaE: $($EaE) ============================================="
        Write-Verbose "CFG: $($CFG) ============================================="
        <#
        if ($this.isHashtable($CFG)) { $FN = '_empty_'; }
        $this.filename = $FN;
        $this.errorAsException = $EaE
        $this.initFileCFG();
        if ($this.isHashtable($CFG)) { $this.CFG += $CFG; }
        #>
    }

    [Hashtable]
    importInifile([string]$filename) # : base($filename)
    {
        Write-Verbose "Class JsonCFG::importInifile($($filename)) ENTER: ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "filename: $($filename)"

        ([FileCFG]$this).importInifile($filename);
        $iniObj = [ordered]@{}
        if ($filename -or ($filename.ToUpper() -ne "_empty_".ToUpper()) )
        {
            # filename не пустой и не равен '_empty'
            #$majV = $avvVersion.Major;
            $json = (Get-Content -Path $filename -Raw);
            Write-Verbose "Содержимое файла $($filename) ::: $($json)"
            #$json = ( (Get-Content -Path $filename -Raw) | ConvertFrom-JsonToHashtable -casesensitive );
            #$majV = (Get-Version).PSVersion.Major;
            $majV = $global:PSVersionTable.PSVersion.Major;
            if ($majV -ge 6) {
                $iniObj = ( $json | ConvertFrom-Json -AsHashtable);
            }
            else
            {
                #$iniObj = ($json | ConvertFrom-Json | ConvertJsonToHash );
                $iniObj = [avvBase]::ConvertPSCustomObjectToHashtable(($json | ConvertFrom-Json));
            }
        }
        Write-Verbose "Class JsonCFG::importInifile($($filename)) EXIT: ============================================="
        return $iniObj;
    }

    [Void]
    saveToFile([string]$filename, [bool]$isOverwrite)
    {
        Write-Verbose "Class JsonCFG::importInifile(filename) ============================================="
        Write-Verbose "this: $($this)"
        Write-Verbose "filename: $($filename)"
        Write-Verbose "isOverwrite: $($isOverwrite)"

        # если $this.filename = '_empty_' или пустой строке, то выход
        if (!$filename -or ($filename.ToUpper() -eq '_empty_'.ToUpper() ))
        {
            return;
        }
        # проверить что каталога с таким именем нет.
        if (Test-Path $filename -PathType Container){
            $msg = $this.isExcept($true, "Невозможно записать в файл, так как он является каталогом");
            Write-Host $msg;
            return;
            #throw "Невозможно записать в файл, так как он является каталогом";
        }
        # проверить что файл с таким именем есть и перезапись запрешена.
        if ( (Test-Path $filename -PathType Leaf) -and !$isOverwrite){
            $msg = $this.isExcept($true, "Файл существует, а перезапись запрещена");
            Write-Host $msg;
            return;
            #throw "Невозможно записать в файл, так как перезапись запрещена";
        }
        # имя файла верное
        $this.CFG | ConvertTo-JSON -Depth 100 | Set-Content -Path $filename;
    }
}
