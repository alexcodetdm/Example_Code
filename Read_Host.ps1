Нужно проверить, что строка соответствует одному из двух шаблонов:

master, V303.00

V303.00, V303.00

Вот решение:

1. Проверка с помощью регулярного выражения
powershell
function Test-InputFormat {
    param([string]$InputString)
    
    $pattern = '^(master,\s*V\d{3}\.\d{2}|V\d{3}\.\d{2},\s*V\d{3}\.\d{2})$'
    return $InputString -match $pattern
}
2. Разбор и валидация с извлечением значений
powershell
function Read-AndValidateInput {
    $input = Read-Host "Введите данные (master,V303.00 или V303.00,V303.00)"
    
    # Проверка формата
    if ($input -match '^(?:(master)|(V\d{3}\.\d{2})),\s*(V\d{3}\.\d{2})$') {
        $firstPart = if ($matches[1]) { $matches[1] } else { $matches[2] }
        $secondPart = $matches[3]
        
        return @{
            IsValid = $true
            FirstValue = $firstPart
            SecondValue = $secondPart
        }
    } else {
        return @{
            IsValid = $false
            FirstValue = $null
            SecondValue = $null
        }
    }
}
3. Полный пример с циклом проверки
powershell
do {
    Write-Host "Введите данные в формате: " -NoNewline
    Write-Host "master, V303.00" -ForegroundColor Yellow -NoNewline
    Write-Host " или " -NoNewline
    Write-Host "V303.00, V303.00" -ForegroundColor Cyan
    
    $userInput = Read-Host
    
    # Проверка шаблона
    if ($userInput -match '^(?:(master)|(V\d{3}\.\d{2})),\s*(V\d{3}\.\d{2})$') {
        $firstValue = if ($matches[1]) { $matches[1] } else { $matches[2] }
        $secondValue = $matches[3]
        
        Write-Host "✓ Корректный формат!" -ForegroundColor Green
        Write-Host "  Первое значение: $firstValue" -ForegroundColor Gray
        Write-Host "  Второе значение: $secondValue" -ForegroundColor Gray
        
        # Выход из цикла
        break
    } else {
        Write-Host "✗ Неверный формат! Попробуйте снова." -ForegroundColor Red
        Write-Host ""
    }
} while ($true)
4. Альтернативная проверка по частям
powershell
function Test-InputPattern {
    param([string]$Input)
    
    # Разделяем по запятой
    $parts = $Input -split ',' | ForEach-Object { $_.Trim() }
    
    if ($parts.Count -ne 2) {
        return $false
    }
    
    # Проверяем возможные комбинации
    $validPattern1 = ($parts[0] -eq 'master') -and ($parts[1] -match '^V\d{3}\.\d{2}$')
    $validPattern2 = ($parts[0] -match '^V\d{3}\.\d{2}$') -and ($parts[1] -match '^V\d{3}\.\d{2}$')
    
    return $validPattern1 -or $validPattern2
}
5. Использование в скрипте
powershell
# Пример использования
$inputData = Read-Host "Введите данные"

if (Test-InputPattern -Input $inputData) {
    $parts = $inputData -split ',' | ForEach-Object { $_.Trim() }
    
    Write-Host "Первое значение: $($parts[0])" -ForegroundColor Green
    Write-Host "Второе значение: $($parts[1])" -ForegroundColor Green
    
    # Дальнейшая обработка...
    if ($parts[0] -eq 'master') {
        Write-Host "Режим: MASTER" -ForegroundColor Yellow
    } else {
        Write-Host "Режим: ВЕРСИИ" -ForegroundColor Cyan
    }
} else {
    Write-Host "Ошибка: неверный формат ввода!" -ForegroundColor Red
}
Объяснение регулярного выражения:
text
^                           # начало строки
(?:                         # не capturing группа
    (master)                # либо "master" (группа 1)
    |                       # или
    (V\d{3}\.\d{2})         # версия VXXX.XX (группа 2)
)
,\s*                        # запятая с пробелами
(V\d{3}\.\d{2})             # версия VXXX.XX (группа 3)
$                           # конец строки
Рекомендую использовать вариант №3 с циклом проверки - он самый удобный для пользователя.

а можно ли вывести вопрос с предложенными значениями при вводе и в этой же строке дать возможность их исправлять ?
Да, это можно сделать с помощью Read-Host с подсказкой, но с некоторыми ограничениями. Вот несколько способов:

1. Read-Host с подсказкой по умолчанию
powershell
$defaultValue = "master, V303.00"
$input = Read-Host "Введите данные [$defaultValue]"
if ([string]::IsNullOrWhiteSpace($input)) {
    $input = $defaultValue
}
2. Более продвинутый вариант с цветами
powershell
function Read-HostWithSuggestion {
    param(
        [string]$Prompt,
        [string]$Suggestion,
        [ConsoleColor]$PromptColor = "White",
        [ConsoleColor]$SuggestionColor = "Gray"
    )
    
    Write-Host $Prompt -ForegroundColor $PromptColor -NoNewline
    Write-Host " [$Suggestion]" -ForegroundColor $SuggestionColor -NoNewline
    Write-Host ": " -NoNewline
    
    $result = Read-Host
    if ([string]::IsNullOrWhiteSpace($result)) {
        return $Suggestion
    }
    return $result
}

# Использование:
$userInput = Read-HostWithSuggestion -Prompt "Введите данные" -Suggestion "master, V303.00" -PromptColor Yellow -SuggestionColor DarkGray
3. Вариант с возможностью редактирования по умолчанию
powershell
function Read-HostEditable {
    param(
        [string]$Message,
        [string]$DefaultValue
    )
    
    # Выводим сообщение с подсказкой серым цветом
    Write-Host $Message -ForegroundColor Cyan -NoNewline
    Write-Host " [" -NoNewline
    Write-Host $DefaultValue -ForegroundColor DarkGray -NoNewline
    Write-Host "]" -NoNewline
    Write-Host ": " -NoNewline
    
    $input = Read-Host
    return if ([string]::IsNullOrWhiteSpace($input)) { $DefaultValue } else { $input }
}

# Использование:
$data = Read-HostEditable -Message "Версии" -DefaultValue "master, V303.00"
4. Интерактивный вариант с валидацией
powershell
function Get-ValidatedInput {
    $suggestions = @("master, V303.00", "V303.00, V303.00")
    $default = $suggestions[0]
    
    do {
        Write-Host "Введите данные " -NoNewline -ForegroundColor White
        Write-Host "[" -NoNewline
        Write-Host $default -ForegroundColor DarkYellow -NoNewline
        Write-Host "]" -NoNewline
        Write-Host ": " -NoNewline
        
        $input = Read-Host
        if ([string]::IsNullOrWhiteSpace($input)) {
            $input = $default
        }
        
        # Проверка формата
        if ($input -match '^(?:(master)|(V\d{3}\.\d{2})),\s*(V\d{3}\.\d{2})$') {
            Write-Host "✓ Принято: $input" -ForegroundColor Green
            return $input
        } else {
            Write-Host "✗ Неверный формат! Примеры: " -ForegroundColor Red -NoNewline
            Write-Host ($suggestions -join " или ") -ForegroundColor Yellow
        }
    } while ($true)
}

# Использование:
$userData = Get-ValidatedInput
5. С отображением доступных шаблонов
powershell
function Read-FormattedInput {
    Write-Host "Доступные форматы:" -ForegroundColor Cyan
    Write-Host "  • " -NoNewline -ForegroundColor Gray
    Write-Host "master, V303.00" -ForegroundColor Yellow
    Write-Host "  • " -NoNewline -ForegroundColor Gray
    Write-Host "V303.00, V303.00" -ForegroundColor Yellow
    Write-Host ""
    
    $default = "master, V303.00"
    Write-Host "Ввод " -NoNewline -ForegroundColor White
    Write-Host "[" -NoNewline
    Write-Host $default -ForegroundColor DarkGray -NoNewline
    Write-Host "]" -NoNewline
    Write-Host ": " -NoNewline
    
    $input = Read-Host
    return if ([string]::IsNullOrWhiteSpace($input)) { $default } else { $input }
}
Результат будет выглядеть так:
text
Введите данные [master, V303.00]: █
Пользователь может:

Нажать Enter - будет использовано значение по умолчанию

Ввести свое значение - заменит значение по умолчанию

Редактировать значение по умолчанию (Backspace, стрелки и т.д.)

Рекомендую вариант №2 или №4 - они самые удобные и информативные для пользователя.