В PowerShell есть несколько способов запускать один скрипт из другого и получать результат. Вот основные методы:

1. Оператор вызова & (рекомендуется)
Скрипт 1 (запускающий):

powershell
# main.ps1
Write-Host "Запускаю дочерний скрипт..."

# Запуск скрипта и получение результата
$result = & "C:\Scripts\child.ps1"

Write-Host "Результат из дочернего скрипта: $result"
$result
Скрипт 2 (дочерний):

powershell
# child.ps1
$computername = $env:COMPUTERNAME
$timestamp = Get-Date

# Возвращаем объект
return @{
    ComputerName = $computername
    Time = $timestamp
    Status = "Success"
}
2. Использование Invoke-Expression
Скрипт 1:

powershell
# main.ps1
$scriptPath = "C:\Scripts\child.ps1"
$result = Invoke-Expression "& `"$scriptPath`""

Write-Host "Результат:"
$result | Format-Table
Скрипт 2:

powershell
# child.ps1
# Возвращаем несколько объектов
Get-Process | Select-Object -First 3 Name, CPU, WorkingSet
3. Запуск с параметрами
Скрипт 1:

powershell
# main.ps1
param(
    [string]$TargetComputer = "localhost"
)

$scriptPath = "C:\Scripts\child.ps1"

# Запуск с передачей параметров
$result = & $scriptPath -ComputerName $TargetComputer -Operation "CheckServices"

$result | Format-Table
Скрипт 2:

powershell
# child.ps1
param(
    [string]$ComputerName,
    [string]$Operation
)

switch ($Operation) {
    "CheckServices" {
        Get-Service | Where-Object Status -eq 'Running' | Select-Object -First 5
    }
    "CheckProcesses" {
        Get-Process | Select-Object -First 5 Name, CPU, Id
    }
    default {
        return "Unknown operation: $Operation"
    }
}
4. Получение сложных объектов
Скрипт 1:

powershell
# main.ps1
$scriptPath = "C:\Scripts\systemInfo.ps1"

# Запускаем скрипт и получаем результат
$systemData = & $scriptPath

Write-Host "Информация о системе:"
Write-Host "Компьютер: $($systemData.ComputerName)"
Write-Host "ОС: $($systemData.OS)"
Write-Host "Память: $($systemData.TotalMemory) GB"
Write-Host "Диски:"
$systemData.Disks | Format-Table
Скрипт 2:

powershell
# systemInfo.ps1
# Собираем информацию о системе
$computerName = $env:COMPUTERNAME
$os = (Get-CimInstance Win32_OperatingSystem).Caption
$memory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
$disks = Get-CimInstance Win32_LogicalDisk | Where-Object {$_.DriveType -eq 3} | Select-Object DeviceID, 
           @{Name="SizeGB"; Expression={[math]::Round($_.Size/1GB, 2)}},
           @{Name="FreeGB"; Expression={[math]::Round($_.FreeSpace/1GB, 2)}}

# Возвращаем структурированные данные
return [PSCustomObject]@{
    ComputerName = $computerName
    OS = $os
    TotalMemory = $memory
    Disks = $disks
    CollectionTime = Get-Date
}
5. Обработка ошибок
Скрипт 1:

powershell
# main.ps1
$scriptPath = "C:\Scripts\child.ps1"

try {
    # Запуск с обработкой ошибок
    $result = & $scriptPath -ErrorAction Stop
    
    Write-Host "Скрипт выполнен успешно"
    $result
    
} catch {
    Write-Error "Ошибка при выполнении скрипта: $($_.Exception.Message)"
    return $null
}
Скрипт 2:

powershell
# child.ps1
param()

try {
    # Имитация работы
    if (Test-Path "C:\Windows") {
        return "Windows directory exists"
    } else {
        throw "Windows directory not found"
    }
} catch {
    throw "Error in child script: $($_.Exception.Message)"
}
6. Запуск в отдельной области видимости
Скрипт 1:

powershell
# main.ps1
$scriptBlock = {
    param($Name)
    $result = "Hello, $Name! Current time: $(Get-Date)"
    return $result
}

# Запуск скрипт-блока
$result = & $scriptBlock -Name "World"
Write-Host $result
Практический пример
main.ps1:

powershell
# Основной скрипт
$scriptsFolder = "C:\Scripts"

Write-Host "=== СБОР ИНФОРМАЦИИ О СИСТЕМЕ ===" -ForegroundColor Green

# Запускаем различные скрипты
$systemInfo = & "$scriptsFolder\Get-SystemInfo.ps1"
$networkInfo = & "$scriptsFolder\Get-NetworkInfo.ps1" -ComputerName $env:COMPUTERNAME
$diskInfo = & "$scriptsFolder\Get-DiskInfo.ps1" -MinFreeGB 10

# Выводим результаты
Write-Host "`nСИСТЕМНАЯ ИНФОРМАЦИЯ:" -ForegroundColor Yellow
$systemInfo | Format-List

Write-Host "`nСЕТЕВЫЕ НАСТРОЙКИ:" -ForegroundColor Yellow
$networkInfo | Format-Table

Write-Host "`nИНФОРМАЦИЯ О ДИСКАХ:" -ForegroundColor Yellow
$diskInfo | Format-Table

# Сохраняем общий результат
$finalReport = @{
    System = $systemInfo
    Network = $networkInfo
    Disks = $diskInfo
    ReportDate = Get-Date
}

return $finalReport
Важные замечания:
& - оператор вызова, рекомендуется для запуска скриптов

Убедитесь, что политика выполнения позволяет запуск скриптов

Используйте полные пути к файлам для избежания ошибок

Обрабатывайте ошибки с помощью try/catch

Для передачи сложных данных используйте объекты PowerShell

Этот подход позволяет создавать модульные скрипты и эффективно обмениваться данными между ними.