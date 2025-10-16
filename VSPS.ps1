Вот несколько способов вызвать PowerShell скрипт из VBS:

1. Простой вызов через WScript.Shell
vbscript
Set WshShell = CreateObject("WScript.Shell")
' Запуск PowerShell скрипта
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -File C:\path\to\script.ps1", 0, True
2. С передачей параметров
vbscript
Set WshShell = CreateObject("WScript.Shell")
scriptPath = "C:\scripts\test.ps1"
param1 = "value1"
param2 = "value2"

command = "powershell.exe -ExecutionPolicy Bypass -File """ & scriptPath & """ -Param1 """ & param1 & """ -Param2 """ & param2 & """"
WshShell.Run command, 0, True
3. С выполнением команды напрямую
vbscript
Set WshShell = CreateObject("WScript.Shell")
psCommand = "Get-Process | Where-Object { $_.CPU -gt 100 }"

command = "powershell.exe -ExecutionPolicy Bypass -Command """ & psCommand & """"
WshShell.Run command, 0, True
4. С ожиданием завершения и получением выхода
vbscript
Set WshShell = CreateObject("WScript.Shell")
scriptPath = "C:\scripts\myScript.ps1"

' Запуск и ожидание завершения
Set oExec = WshShell.Exec("powershell.exe -ExecutionPolicy Bypass -File """ & scriptPath & """")

' Чтение вывода
Do While oExec.Status = 0
    WScript.Sleep 100
Loop

output = oExec.StdOut.ReadAll()
WScript.Echo "Output: " & output
5. С скрытым окном
vbscript
Set WshShell = CreateObject("WScript.Shell")
scriptPath = "C:\scripts\background.ps1"

' Запуск в скрытом режиме (0 - скрыто)
WshShell.Run "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & scriptPath & """", 0, False
6. Полный пример с обработкой ошибок
vbscript
On Error Resume Next

Set WshShell = CreateObject("WScript.Shell")
scriptPath = "C:\scripts\myScript.ps1"

If Err.Number <> 0 Then
    WScript.Echo "Error creating WScript.Shell: " & Err.Description
    WScript.Quit 1
End If

' Проверка существования файла
Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FileExists(scriptPath) Then
    WScript.Echo "Script file not found: " & scriptPath
    WScript.Quit 1
End If

' Запуск PowerShell скрипта
command = "powershell.exe -ExecutionPolicy Bypass -File """ & scriptPath & """"
returnCode = WshShell.Run(command, 0, True)

If Err.Number <> 0 Then
    WScript.Echo "Error running PowerShell script: " & Err.Description
Else
    WScript.Echo "PowerShell script completed with return code: " & returnCode
End If
Ключевые параметры PowerShell:
-ExecutionPolicy Bypass - обходит политику выполнения

-File - запуск файла скрипта

-Command - выполнение команды

-WindowStyle Hidden - скрытое окно

-NoProfile - запуск без загрузки профиля

Пример PowerShell скрипта (myScript.ps1):
powershell
param(
    [string]$Param1,
    [string]$Param2
)

Write-Output "PowerShell script started with parameters: $Param1, $Param2"
# Ваш код здесь

-----------------------------------------------------

1. Базовый исправленный код
vbscript
Dim WshShell
Set WshShell = CreateObject("WScript.Shell")

If Not WshShell Is Nothing Then
    WshShell.Run "powershell.exe -ExecutionPolicy Bypass -File C:\path\to\script.ps1", 0, True
Else
    WScript.Echo "Failed to create WScript.Shell object"
End If
2. С явным объявлением переменных
vbscript
Option Explicit

Dim WshShell, command, scriptPath
Set WshShell = CreateObject("WScript.Shell")

If WshShell Is Nothing Then
    WScript.Echo "Error: Cannot create WScript.Shell"
    WScript.Quit 1
End If

scriptPath = "C:\scripts\test.ps1"
command = "powershell.exe -ExecutionPolicy Bypass -File """ & scriptPath & """"

WshShell.Run command, 0, True
3. С проверкой создания объекта
vbscript
On Error Resume Next

Dim WshShell
Set WshShell = CreateObject("WScript.Shell")

If Err.Number <> 0 Then
    WScript.Echo "Error creating object: " & Err.Description & " (Error " & Err.Number & ")"
    WScript.Quit 1
End If

On Error Goto 0

' Теперь используем объект
WshShell.Run "powershell.exe -ExecutionPolicy Bypass -File C:\scripts\test.ps1", 0, True
4. Полный рабочий пример
vbscript
' Объявляем все переменные
Dim objShell, strCommand, strScriptPath
Dim intReturnCode

' Создаем объект
Set objShell = CreateObject("WScript.Shell")

' Проверяем успешность создания
If objShell Is Nothing Then
    WScript.Echo "ERROR: Cannot create WScript.Shell object"
    WScript.Quit 1
End If

' Указываем путь к скрипту
strScriptPath = "C:\scripts\example.ps1"

' Формируем команду
strCommand = "powershell.exe -ExecutionPolicy Bypass -File """ & strScriptPath & """"

WScript.Echo "Executing: " & strCommand

' Запускаем команду
intReturnCode = objShell.Run(strCommand, 0, True)

WScript.Echo "Script completed with return code: " & intReturnCode

' Освобождаем объект
Set objShell = Nothing
5. Для тестирования создайте простой PS скрипт:
test.ps1:

powershell
Write-Output "PowerShell script is running!"
Start-Sleep -Seconds 2
Write-Output "Script completed successfully!"
Основные причины ошибки 424:
Не объявлена переменная - используйте Dim

Объект не создан - проверьте CreateObject

Опечатка в имени объекта - проверьте написание

Объект не поддерживается - проверьте доступность WScript.Shell

Быстрое решение:
vbscript
Dim shell
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -Command ""Write-Output 'Hello from PowerShell!'""", 1, True

---------------------
-----------------------

Ошибка 70 означает "Permission denied" - недостаточно прав. Вот решения:

1. Запуск от имени администратора
vbscript
Dim objShell, strCommand, strScriptPath
Set objShell = CreateObject("WScript.Shell")

strScriptPath = "C:\scripts\example.ps1"
strCommand = "powershell.exe -ExecutionPolicy Bypass -File """ & strScriptPath & """"

' Запуск с повышенными правами
objShell.Run "powershell.exe -ExecutionPolicy Bypass -Command ""Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass -File """ & strScriptPath & """' -Verb RunAs""", 0, True
2. Проверка прав доступа к файлам
vbscript
Dim objShell, objFSO, strScriptPath
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

strScriptPath = "C:\scripts\example.ps1"

' Проверяем существование файла
If Not objFSO.FileExists(strScriptPath) Then
    MsgBox "File not found: " & strScriptPath, vbCritical, "Error"
    WScript.Quit 1
End If

' Проверяем доступ на чтение
On Error Resume Next
Dim testFile
Set testFile = objFSO.OpenTextFile(strScriptPath, 1)
If Err.Number <> 0 Then
    MsgBox "No read access to file: " & strScriptPath, vbCritical, "Error"
    WScript.Quit 1
End If
testFile.Close
On Error GoTo 0

' Запускаем PowerShell
objShell.Run "powershell.exe -ExecutionPolicy Bypass -File """ & strScriptPath & """", 0, True
3. Альтернативный способ через Exec
vbscript
Dim objShell, strCommand
Set objShell = CreateObject("WScript.Shell")

strCommand = "powershell.exe -ExecutionPolicy Bypass -Command ""Get-Date | Out-File 'C:\temp\test.txt'"""

' Используем Exec вместо Run
Dim oExec
Set oExec = objShell.Exec(strCommand)

Do While oExec.Status = 0
    WScript.Sleep 100
Loop

MsgBox "Command completed with exit code: " & oExec.ExitCode
4. Запуск из текущей директории
vbscript
Dim objShell, objFSO, currentDir, strScriptPath
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Получаем текущую директорию скрипта VBS
currentDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
strScriptPath = currentDir & "\example.ps1"

If objFSO.FileExists(strScriptPath) Then
    objShell.CurrentDirectory = currentDir
    objShell.Run "powershell.exe -ExecutionPolicy Bypass -File """ & strScriptPath & """", 0, True
Else
    MsgBox "Script not found: " & strScriptPath, vbCritical, "Error"
End If
5. Простой тест с базовой командой
vbscript
Dim objShell
Set objShell = CreateObject("WScript.Shell")

' Тестируем простую команду вместо файла
objShell.Run "powershell.exe -Command ""Write-Output 'Test' | Out-File 'C:\temp\output.txt'""", 0, True

MsgBox "Check C:\temp\output.txt for results"
6. Обход ограничений политики
vbscript
Dim objShell
Set objShell = CreateObject("WScript.Shell")

' Запуск с обходом политик и в отдельном процессе
objShell.Run "powershell.exe -NoProfile -ExecutionPolicy Unrestricted -Command ""& {'Hello World' | Out-File 'C:\temp\result.txt'}""", 0, True
7. Полное решение с обработкой ошибок
vbscript
On Error Resume Next

Dim objShell, objFSO
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Создаем временную папку если нет
If Not objFSO.FolderExists("C:\temp") Then
    objFSO.CreateFolder("C:\temp")
End If

' Простая команда для теста
Dim testCommand
testCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""'Test successful at ' + (Get-Date).ToString() | Out-File 'C:\temp\test_result.txt'"""

' Пробуем выполнить
objShell.Run testCommand, 0, True

If Err.Number = 70 Then
    MsgBox "Permission denied. Try running as Administrator.", vbCritical, "Error"
ElseIf Err.Number <> 0 Then
    MsgBox "Error " & Err.Number & ": " & Err.Description, vbCritical, "Error"
Else
    MsgBox "Command executed successfully! Check C:\temp\test_result.txt", vbInformation, "Success"
End If
Быстрое решение для тестирования:
vbscript
' Сохраните как test.vbs и запустите
CreateObject("WScript.Shell").Run "powershell.exe -Command ""'Test' > C:\temp\test.txt""", 0, True
MsgBox "Check if C:\temp\test.txt was created"
Рекомендую начать с варианта №5 - он самый простой и покажет, работает ли вообще запуск PowerShell из VBS.