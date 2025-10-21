Пример процедуры для парсинга JSON-подобного файла и извлечения значений по ключу:

Основная процедура
vbscript
Function GetValueFromJsonFile(filePath, keyName)
    On Error Resume Next
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    ' Проверяем существование файла
    If Not fso.FileExists(filePath) Then
        GetValueFromJsonFile = "Файл не найден"
        Exit Function
    End If
    
    ' Читаем файл
    Set file = fso.OpenTextFile(filePath, 1)
    fileContent = file.ReadAll()
    file.Close
    
    ' Ищем ключ и его значение
    GetValueFromJsonFile = FindJsonValue(fileContent, keyName)
End Function

Function FindJsonValue(jsonText, keyName)
    ' Создаем шаблон для поиска: "key": "value"
    pattern = """" & keyName & """:\s*""([^""]*)"""
    
    Set regEx = CreateObject("VBScript.RegExp")
    regEx.Pattern = pattern
    regEx.IgnoreCase = True
    regEx.Global = True
    
    Set matches = regEx.Execute(jsonText)
    
    If matches.Count > 0 Then
        ' Извлекаем значение из первой группы
        FindJsonValue = matches(0).SubMatches(0)
    Else
        FindJsonValue = "Ключ не найден"
    End If
End Function

Расширенная версия с поддержкой разных типов значений
vbscript
Function GetJsonValue(filePath, keyName)
    On Error Resume Next
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    If Not fso.FileExists(filePath) Then
        GetJsonValue = "Файл не найден"
        Exit Function
    End If
    
    Set file = fso.OpenTextFile(filePath, 1)
    fileContent = file.ReadAll()
    file.Close
    
    GetJsonValue = ExtractJsonValue(fileContent, keyName)
End Function

Function ExtractJsonValue(jsonText, keyName)
    ' Паттерны для разных типов значений
    patterns = Array( _
        """" & keyName & """:\s*""([^""]*)""",     ' Строки в кавычках
        """" & keyName & """:\s*(\d+)",            ' Числа
        """" & keyName & """:\s*(true|false)",     ' Булевы значения
        """" & keyName & """:\s*null"              ' Null значения
    )
    
    Set regEx = CreateObject("VBScript.RegExp")
    regEx.IgnoreCase = True
    
    For Each pattern In patterns
        regEx.Pattern = pattern
        Set matches = regEx.Execute(jsonText)
        
        If matches.Count > 0 Then
            If matches(0).SubMatches.Count > 0 Then
                ' Если есть подматч (для строк и чисел)
                ExtractJsonValue = matches(0).SubMatches(0)
            Else
                ' Для true/false/null
                If InStr(pattern, "true|false") > 0 Then
                    ExtractJsonValue = LCase(matches(0))
                Else
                    ExtractJsonValue = "null"
                End If
            End If
            Exit Function
        End If
    Next
    
    ExtractJsonValue = "Ключ не найден"
End Function
Пример использования
vbscript
' Пример JSON файла (data.json)
' {
'     "name": "Иван Иванов",
'     "age": 30,
'     "email": "ivan@example.com",
'     "active": true
' }

' Использование процедуры
filePath = "data.json"

' Получаем значения по разным ключам
name = GetJsonValue(filePath, "name")
age = GetJsonValue(filePath, "age")
email = GetJsonValue(filePath, "email")
active = GetJsonValue(filePath, "active")
city = GetJsonValue(filePath, "city") ' Несуществующий ключ

' Выводим результаты
WScript.Echo "Имя: " & name
WScript.Echo "Возраст: " & age
WScript.Echo "Email: " & email
WScript.Echo "Активен: " & active
WScript.Echo "Город: " & city
Версия с обработкой вложенных объектов
vbscript
Function GetJsonValueAdvanced(filePath, keyName)
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    If Not fso.FileExists(filePath) Then
        GetJsonValueAdvanced = "Файл не найден"
        Exit Function
    End If
    
    Set file = fso.OpenTextFile(filePath, 1)
    jsonText = file.ReadAll()
    file.Close
    
    ' Используем более сложный regex для обработки разных случаев
    Set regEx = CreateObject("VBScript.RegExp")
    regEx.Pattern = """" & keyName & """:\s*(""[^""]*""|\d+|true|false|null|[{\[].*?[}\]])"
    regEx.IgnoreCase = True
    regEx.Global = False
    
    Set matches = regEx.Execute(jsonText)
    
    If matches.Count > 0 Then
        value = Trim(Replace(matches(0), """" & keyName & """:", ""))
        value = Trim(value)
        
        ' Убираем кавычки для строк
        If Left(value, 1) = """" And Right(value, 1) = """" Then
            value = Mid(value, 2, Len(value) - 2)
        End If
        
        GetJsonValueAdvanced = value
    Else
        GetJsonValueAdvanced = "Ключ не найден"
    End If
End Function
Простой тестовый скрипт
vbscript
' Сохраните этот код в test.vbs и запустите
' Создаем тестовый JSON файл
Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.CreateTextFile("test.json", True)
file.WriteLine "{"
file.WriteLine "    ""firstName"": ""Иван"","
file.WriteLine "    ""lastName"": ""Иванов"","
file.WriteLine "    ""age"": 30,"
file.WriteLine "    ""isEmployed"": true"
file.WriteLine "}"
file.Close

' Тестируем нашу функцию
WScript.Echo "Тестирование парсера JSON:"
WScript.Echo "Имя: " & GetJsonValue("test.json", "firstName")
WScript.Echo "Фамилия: " & GetJsonValue("test.json", "lastName")
WScript.Echo "Возраст: " & GetJsonValue("test.json", "age")
WScript.Echo "Работает: " & GetJsonValue("test.json", "isEmployed")
WScript.Echo "Несуществующий ключ: " & GetJsonValue("test.json", "city")

-------------------------------------------------------------------------------

function Get-ValueFromJsonFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [string]$Key
    )
    
    try {
        # Преобразуем JSON-файл в объект PowerShell
        $jsonObject = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        
        # Получаем значение свойства
        return $jsonObject.$Key
        
    } catch {
        Write-Error "Ошибка при чтении JSON-файла: $_"
        return $null
    }
}