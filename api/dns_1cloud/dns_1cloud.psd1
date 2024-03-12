#
# Манифест модуля для модуля "classes".
#
# Создано: vovka
#
# Дата создания: 25.06.2022
#

@{

# Файл модуля сценария или двоичного модуля, связанный с этим манифестом.
    RootModule = 'dns_1cloud'
    ModuleVersion = '1.0.0'
    Author = 'Alexeev Vladimir'
    CompanyName = 'Home'
    Copyright = '(c) 2022-2024 Alexeev Vladimir. Все права защищены.'
    PowerShellVersion = '5.0'
    NestedModules = @(
    )
    #FunctionsToExport = @('Invoke-API')
    FunctionsToExport = '*'
}
