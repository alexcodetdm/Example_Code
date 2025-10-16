powershell
# Чтение данных из файлов
$idFiltersPath = "IdFilters.json"
$ncSalesPath = "NC_Sales.json"

# Проверяем существование файлов
if (-not (Test-Path $idFiltersPath)) {
    Write-Error "Файл $idFiltersPath не найден"
    exit 1
}

if (-not (Test-Path $ncSalesPath)) {
    Write-Error "Файл $ncSalesPath не найден"
    exit 1
}

# Читаем JSON файлы
$idFilters = Get-Content $idFiltersPath | ConvertFrom-Json
$ncSales = Get-Content $ncSalesPath | ConvertFrom-Json

# Функция для удаления значений из строки с разделителем |
function Remove-ValuesFromString {
    param(
        [string]$sourceString,
        [string]$valuesToRemove
    )
    
    if ([string]::IsNullOrEmpty($sourceString)) {
        return ""
    }
    
    if ([string]::IsNullOrEmpty($valuesToRemove)) {
        return $sourceString.Trim('|')
    }
    
    # Разбиваем строки на массивы чисел
    $sourceArray = $sourceString.Trim('|') -split '\|' | Where-Object { $_ -ne "" }
    $removeArray = $valuesToRemove.Trim('|') -split '\|' | Where-Object { $_ -ne "" }
    
    # Удаляем значения которые есть во втором массиве
    $resultArray = $sourceArray | Where-Object { $_ -notin $removeArray }
    
    # Собираем обратно в строку с разделителем | (без | в конце)
    if ($resultArray.Count -eq 0) {
        return ""
    } else {
        return $resultArray -join '|'
    }
}

# Обрабатываем каждое свойство
$result = @{}

# Получаем все свойства из обоих объектов
$allProperties = ($idFilters.PSObject.Properties.Name + $ncSales.PSObject.Properties.Name) | Select-Object -Unique

foreach ($property in $allProperties) {
    $sourceValue = $idFilters.$property
    $removeValue = $ncSales.$property
    
    if ($null -eq $sourceValue) {
        $sourceValue = ""
    }
    if ($null -eq $removeValue) {
        $removeValue = ""
    }
    
    $result[$property] = Remove-ValuesFromString -sourceString $sourceValue -valuesToRemove $removeValue
}

# Сохраняем результат
$output = New-Object PSObject -Property $result
$output | ConvertTo-Json | Set-Content "Filtered_Result.json"

Write-Host "Обработка завершена. Результат сохранен в Filtered_Result.json"
Write-Host "Исходные данные из IdFilters.json:"
$idFilters | ConvertTo-Json
Write-Host "Данные для удаления из NC_Sales.json:"
$ncSales | ConvertTo-Json
Write-Host "Результат:"
$output | ConvertTo-Json
И компактная версия:

powershell
# Компактная версия с удалением | в конце
$idFilters = Get-Content "IdFilters.json" | ConvertFrom-Json
$ncSales = Get-Content "NC_Sales.json" | ConvertFrom-Json

$result = @{}

foreach ($property in $idFilters.PSObject.Properties.Name) {
    $sourceValues = ($idFilters.$property.Trim('|') -split '\|' | Where-Object { $_ }) -as [int[]]
    $removeValues = ($ncSales.$property.Trim('|') -split '\|' | Where-Object { $_ }) -as [int[]]
    
    $filteredValues = $sourceValues | Where-Object { $_ -notin $removeValues }
    
    if ($filteredValues.Count -gt 0) {
        $result[$property] = $filteredValues -join '|'
    } else {
        $result[$property] = ""
    }
}

$result | ConvertTo-Json | Set-Content "Filtered_Result.json"
Write-Host "Готово! Проверьте файл Filtered_Result.json"
Пример работы с обновленным скриптом:

Если в IdFilters.json:

json
{"Table":"1|20|30|","Codeunit": "55|65|85|"}
И в NC_Sales.json:

json
{"Table":"20|","Codeunit": "65|85|"}
То результат в Filtered_Result.json будет:

json
{"Table":"1|30","Codeunit": "55"}
Что изменилось:

В функции Remove-ValuesFromString убрано добавление | в конце строки

Используется Trim('|') для удаления разделителей в начале и конце при разборе

Результат содержит значения, разделенные |, но без | в конце строки

Если остается только одно значение, оно будет без | в конце

-----------------------------------------------------------------
--------------------------------------------------------------------
добавлено сохранение порядка свойств
# Компактная версия с сохранением порядка свойств
$idFilters = Get-Content "IdFilters.json" | ConvertFrom-Json
$ncSales = Get-Content "NC_Sales.json" | ConvertFrom-Json

# Используем OrderedDictionary для сохранения порядка
$result = [ordered]@{}

foreach ($property in $idFilters.PSObject.Properties.Name) {
    $sourceValues = ($idFilters.$property.Trim('|') -split '\|' | Where-Object { $_ }) -as [int[]]
    $removeValues = ($ncSales.$property.Trim('|') -split '\|' | Where-Object { $_ }) -as [int[]]
    
    $filteredValues = $sourceValues | Where-Object { $_ -notin $removeValues }
    
    if ($filteredValues.Count -gt 0) {
        $result[$property] = $filteredValues -join '|'
    } else {
        $result[$property] = ""
    }
}

$result | ConvertTo-Json | Set-Content "Filtered_Result.json"
Write-Host "Готово! Проверьте файл Filtered_Result.json"