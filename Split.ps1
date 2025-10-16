Вот обработка для PowerShell, которая разбивает переменную data на части длиной не более 614 символов, разбивая только по символу |:

powershell
function Split-DataByDelimiter {
    param(
        [string]$data,
        [int]$maxLength = 614,
        [char]$delimiter = '|'
    )
    
    $result = @()
    $currentChunk = ""
    
    # Разбиваем исходную строку на элементы по разделителю
    $elements = $data.Split($delimiter)
    
    foreach ($element in $elements) {
        # Если элемент сам по себе превышает максимальную длину
        if ($element.Length -ge $maxLength) {
            throw "Элемент '$element' превышает максимальную длину $maxLength символов"
        }
        
        # Если текущий чанк пустой, просто добавляем элемент
        if ($currentChunk -eq "") {
            $currentChunk = $element
        }
        # Проверяем, не превысит ли добавление нового элемента максимальную длину
        elseif (($currentChunk.Length + $delimiter.Length + $element.Length) -le $maxLength) {
            $currentChunk += $delimiter + $element
        }
        else {
            # Добавляем текущий чанк в результат и начинаем новый
            $result += $currentChunk
            $currentChunk = $element
        }
    }
    
    # Добавляем последний чанк, если он не пустой
    if ($currentChunk -ne "") {
        $result += $currentChunk
    }
    
    return $result
}

# Пример использования
$data = "501|502|504"

# Разбиваем данные
$chunks = Split-DataByDelimiter -data $data -maxLength 614

# Выводим результат
Write-Host "Исходная строка: $data"
Write-Host "`nРазбиение на части (макс. 614 символов):"
for ($i = 0; $i -lt $chunks.Count; $i++) {
    Write-Host "Часть $($i + 1): '$($chunks[$i])' (длина: $($chunks[$i].Length))"
}

# Сохраняем в отдельные переменные
for ($i = 0; $i -lt $chunks.Count; $i++) {
    Set-Variable -Name "chunk$($i + 1)" -Value $chunks[$i]
    Write-Host "`$chunk$($i + 1) = '$($chunks[$i])'"
}
А вот упрощенная версия без функции:

powershell
$data = "501|502|504"
$maxLength = 614

$result = @()
$currentPart = ""

$elements = $data -split "\|"

foreach ($element in $elements) {
    if ($currentPart -eq "") {
        $currentPart = $element
    }
    elseif (($currentPart.Length + 1 + $element.Length) -le $maxLength) {
        $currentPart += "|" + $element
    }
    else {
        $result += $currentPart
        $currentPart = $element
    }
}

if ($currentPart -ne "") {
    $result += $currentPart
}

# Вывод результата
Write-Host "Полученные части:"
$result | ForEach-Object { 
    Write-Host "Длина: $($_.Length), Содержимое: $_" 
}

# Сохранение в переменные
for ($i = 0; $i -lt $result.Count; $i++) {
    New-Variable -Name "part$($i + 1)" -Value $result[$i] -Force
}
Особенности обработки:

Разбиение только по | - элементы никогда не разрываются посередине

Контроль длины - каждая часть не превышает 614 символов

Обработка крайних случаев - пустые строки, очень длинные элементы

Сохранение разделителей - в результирующих строках разделители сохраняются

Пример работы:

text
Исходная строка: 501|502|504
Часть 1: '501|502|504' (длина: 11)
Для более длинных строк функция автоматически разобьет данные на несколько частей.

