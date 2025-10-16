В PowerShell есть несколько способов чтения JSON файлов. Вот основные методы:

1. Использование Get-Content и ConvertFrom-Json
powershell
# Чтение JSON файла
$jsonContent = Get-Content -Path "C:\путь\к\файлу.json" -Raw
$data = $jsonContent | ConvertFrom-Json

# Теперь можно работать с данными
$data.PropertyName
2. Более компактная запись
powershell
$data = Get-Content "C:\путь\к\файлу.json" -Raw | ConvertFrom-Json
3. Пример с реальным JSON файлом
Предположим, у нас есть файл config.json:

json
{
    "database": {
        "server": "localhost",
        "name": "mydb",
        "port": 5432
    },
    "settings": {
        "timeout": 30,
        "retries": 3
    }
}
Чтение и использование:

powershell
$config = Get-Content "config.json" -Raw | ConvertFrom-Json

# Доступ к свойствам
$server = $config.database.server
$timeout = $config.settings.timeout

Write-Host "Сервер: $server"
Write-Host "Таймаут: $timeout секунд"
4. Обработка ошибок
powershell
try {
    $data = Get-Content "config.json" -Raw | ConvertFrom-Json
    Write-Host "JSON успешно прочитан"
}
catch {
    Write-Error "Ошибка при чтении JSON: $_"
}
5. Чтение JSON из строки
powershell
$jsonString = '{"name": "John", "age": 30, "cities": ["Moscow", "SPb"]}'
$data = $jsonString | ConvertFrom-Json

$data.name    # John
$data.age     # 30
$data.cities  # Moscow, SPb
6. Для массивов JSON
Если JSON содержит массив:

json
[
    {"name": "John", "age": 30},
    {"name": "Alice", "age": 25}
]
powershell
$users = Get-Content "users.json" -Raw | ConvertFrom-Json

foreach ($user in $users) {
    Write-Host "Имя: $($user.name), Возраст: $($user.age)"
}
Важные моменты:
-Raw параметр в Get-Content читает файл как одну строку, что важно для корректного парсинга JSON

ConvertFrom-Json создает объекты PSCustomObject

Для работы с вложенными свойствами используйте точечную нотацию

JSON чувствителен к регистру символов

Это основные способы работы с JSON в PowerShell!

---------------------------------------------------------------------------------------

В PowerShell есть несколько способов проверить наличие свойства в JSON объекте:

1. Проверка с помощью Get-Member
powershell
$data = Get-Content "config.json" -Raw | ConvertFrom-Json

# Проверка наличия свойства
if ($data | Get-Member -Name "propertyName") {
    Write-Host "Свойство существует"
    $value = $data.propertyName
} else {
    Write-Host "Свойство не существует"
}
2. Проверка с помощью PSObject.Properties
powershell
if ($data.PSObject.Properties.Name -contains "propertyName") {
    Write-Host "Свойство существует"
}
3. Проверка для вложенных свойств
powershell
# Проверка вложенного свойства
if ($data.database.PSObject.Properties.Name -contains "server") {
    Write-Host "Вложенное свойство существует"
    $server = $data.database.server
}
4. Безопасное обращение с помощью ?
powershell
# Если свойство может не существовать
$value = $data?.propertyName

# Для вложенных свойств
$server = $data?.database?.server
5. Функция для проверки вложенных свойств
powershell
function Test-JsonProperty {
    param($Object, $PropertyPath)
    
    $properties = $PropertyPath -split '\.'
    $current = $Object
    
    foreach ($prop in $properties) {
        if ($current.PSObject.Properties.Name -contains $prop) {
            $current = $current.$prop
        } else {
            return $false
        }
    }
    return $true
}

# Использование
if (Test-JsonProperty -Object $data -PropertyPath "database.server") {
    Write-Host "Свойство database.server существует"
}
6. Try-Catch для безопасного доступа
powershell
try {
    $value = $data.database.server
    Write-Host "Свойство существует: $value"
} catch {
    Write-Host "Свойство не существует"
}
7. Проверка с значением по умолчанию
powershell
# Если свойство не существует, вернет $null
$value = $data.PSObject.Properties["propertyName"]?.Value

# Или с значением по умолчанию
$value = if ($data.PSObject.Properties.Name -contains "propertyName") {
    $data.propertyName
} else {
    "default value"
}
Полный пример
powershell
$config = Get-Content "config.json" -Raw | ConvertFrom-Json

# Проверяем несколько свойств
$requiredProperties = @("database", "settings", "database.server")

foreach ($prop in $requiredProperties) {
    if (Test-JsonProperty -Object $config -PropertyPath $prop) {
        Write-Host "✓ Свойство '$prop' существует" -ForegroundColor Green
    } else {
        Write-Host "✗ Свойство '$prop' отсутствует" -ForegroundColor Red
    }
}

# Безопасное получение значения
$server = if ($config.database.PSObject.Properties.Name -contains "server") {
    $config.database.server
} else {
    "localhost" # значение по умолчанию
}
Рекомендация: Для простых случаев используйте Get-Member или PSObject.Properties, для сложных вложенных структур - создайте функцию проверки.
---------------------------------------------------------------------------------------------------------------

1. Перебор свойств объекта с помощью PSObject.Properties
powershell
$data = Get-Content "config.json" -Raw | ConvertFrom-Json

# Перебор всех свойств верхнего уровня
foreach ($property in $data.PSObject.Properties) {
    Write-Host "Имя свойства: $($property.Name)"
    Write-Host "Значение: $($property.Value)"
    Write-Host "Тип: $($property.Value.GetType().Name)"
    Write-Host "---"
}
2. Перебор с помощью Get-Member
powershell
$data | Get-Member -MemberType NoteProperty | ForEach-Object {
    $propertyName = $_.Name
    $propertyValue = $data.$propertyName
    
    Write-Host "Свойство: $propertyName = $propertyValue"
}
3. Для объектов внутри свойств
powershell
foreach ($property in $data.PSObject.Properties) {
    Write-Host "Свойство: $($property.Name)"
    
    # Если значение является объектом (имеет вложенные свойства)
    if ($property.Value -is [PSCustomObject]) {
        Write-Host "  Вложенные свойства:"
        foreach ($nestedProp in $property.Value.PSObject.Properties) {
            Write-Host "    - $($nestedProp.Name): $($nestedProp.Value)"
        }
    } else {
        Write-Host "  Значение: $($property.Value)"
    }
}
4. Рекурсивный обход всех вложенных свойств
powershell
function Iterate-JsonProperties {
    param(
        $Object,
        [string]$Prefix = ""
    )
    
    foreach ($property in $Object.PSObject.Properties) {
        $fullPath = if ($Prefix) { "$Prefix.$($property.Name)" } else { $property.Name }
        
        if ($property.Value -is [PSCustomObject]) {
            Write-Host "$fullPath (объект)"
            Iterate-JsonProperties -Object $property.Value -Prefix $fullPath
        } elseif ($property.Value -is [Array]) {
            Write-Host "$fullPath (массив из $($property.Value.Count) элементов)"
            for ($i = 0; $i -lt $property.Value.Count; $i++) {
                if ($property.Value[$i] -is [PSCustomObject]) {
                    Iterate-JsonProperties -Object $property.Value[$i] -Prefix "$fullPath[$i]"
                } else {
                    Write-Host "  $fullPath[$i]: $($property.Value[$i])"
                }
            }
        } else {
            Write-Host "$fullPath: $($property.Value)"
        }
    }
}

# Использование
Iterate-JsonProperties -Object $data
5. Практический пример с config.json
json
{
    "app": "MyApp",
    "version": "1.0",
    "database": {
        "host": "localhost",
        "port": 5432,
        "credentials": {
            "username": "admin",
            "password": "secret"
        }
    },
    "features": ["auth", "logging", "api"]
}
powershell
$config = Get-Content "config.json" -Raw | ConvertFrom-Json

# Простой перебор
Write-Host "=== Все свойства ==="
foreach ($prop in $config.PSObject.Properties) {
    Write-Host "$($prop.Name) = $($prop.Value)"
}

Write-Host "`n=== Детальный перебор ==="
foreach ($prop in $config.PSObject.Properties) {
    Write-Host "`nСвойство: $($prop.Name)"
    
    switch ($prop.Value.GetType().Name) {
        "PSCustomObject" {
            Write-Host "  Тип: Объект"
            foreach ($nested in $prop.Value.PSObject.Properties) {
                Write-Host "    $($nested.Name): $($nested.Value)"
            }
        }
        "Object[]" {
            Write-Host "  Тип: Массив"
            Write-Host "  Элементы: $($prop.Value -join ', ')"
        }
        default {
            Write-Host "  Тип: Простое значение"
            Write-Host "  Значение: $($prop.Value)"
        }
    }
}
6. Фильтрация свойств по условию
powershell
# Только строковые свойства
$config.PSObject.Properties | Where-Object { 
    $_.Value -is [string] 
} | ForEach-Object {
    Write-Host "Строковое свойство: $($_.Name) = $($_.Value)"
}

# Свойства с числовыми значениями
$config.PSObject.Properties | Where-Object { 
    $_.Value -is [int] -or $_.Value -is [double] 
} | ForEach-Object {
    Write-Host "Числовое свойство: $($_.Name) = $($_.Value)"
}
7. Создание хэш-таблицы из свойств
powershell
$hash = @{}
$config.PSObject.Properties | ForEach-Object {
    $hash[$_.Name] = $_.Value
}

# Теперь можно работать как с обычной хэш-таблицей
$hash.Keys | ForEach-Object {
    Write-Host "$_ = $($hash[$_])"
}
Таким образом можно легко исследовать структуру JSON файла и обрабатывать его свойства в циклах!