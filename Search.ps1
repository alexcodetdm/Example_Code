Вот несколько вариантов скриптов PowerShell для поиска файлов по фильтру:

Базовый вариант
powershell
# Поиск файлов в текущей папке
Get-ChildItem -Filter "*.txt"

# Поиск с включением подпапок
Get-ChildItem -Path "C:\MyFolder" -Filter "*.pdf" -Recurse

# Поиск по маске имени
Get-ChildItem -Path "C:\MyFolder" -Filter "report*.*" -Recurse
Расширенный скрипт с параметрами
powershell
param(
    [string]$Path = ".",
    [string]$Filter = "*.*",
    [switch]$Recurse,
    [switch]$ShowDetails
)

Write-Host "Поиск файлов в: $Path" -ForegroundColor Green
Write-Host "Фильтр: $Filter" -ForegroundColor Yellow

if ($Recurse) {
    $files = Get-ChildItem -Path $Path -Filter $Filter -Recurse -File
} else {
    $files = Get-ChildItem -Path $Path -Filter $Filter -File
}

if ($files.Count -eq 0) {
    Write-Host "Файлы не найдены." -ForegroundColor Red
} else {
    Write-Host "Найдено файлов: $($files.Count)" -ForegroundColor Green
    
    if ($ShowDetails) {
        $files | Format-Table Name, Directory, Length, LastWriteTime -AutoSize
    } else {
        $files | Select-Object -ExpandProperty FullName
    }
}
Скрипт с графическим интерфейсом выбора папки
powershell
Add-Type -AssemblyName System.Windows.Forms

# Диалог выбора папки
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "Выберите папку для поиска"
$folderBrowser.RootFolder = [System.Environment+SpecialFolder]::Desktop

if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedPath = $folderBrowser.SelectedPath
    
    # Запрос фильтра у пользователя
    $filter = Read-Host "Введите фильтр файлов (например: *.txt или report*.docx)"
    
    # Поиск файлов
    $files = Get-ChildItem -Path $selectedPath -Filter $filter -Recurse -File
    
    if ($files.Count -gt 0) {
        Write-Host "`nНайдено файлов: $($files.Count)" -ForegroundColor Green
        $files | ForEach-Object {
            Write-Host "• $($_.FullName)" -ForegroundColor Cyan
        }
        
        # Сохранение результатов в файл
        $save = Read-Host "`nСохранить результаты в файл? (y/n)"
        if ($save -eq 'y') {
            $outputFile = "search_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            $files | Select-Object FullName, Length, LastWriteTime | Out-File $outputFile
            Write-Host "Результаты сохранены в: $outputFile" -ForegroundColor Green
        }
    } else {
        Write-Host "Файлы не найдены." -ForegroundColor Red
    }
} else {
    Write-Host "Папка не выбрана." -ForegroundColor Yellow
}
Функция для многократного использования
powershell
function Find-Files {
    param(
        [string]$Path = ".",
        [string]$NamePattern = "*",
        [string]$Extension = "*",
        [switch]$Recurse,
        [int]$DaysOld,
        [switch]$LargeFiles
    )
    
    # Формируем фильтр
    $filter = if ($Extension -eq "*") {
        $NamePattern
    } else {
        "$NamePattern.$Extension"
    }
    
    # Получаем файлы
    $params = @{
        Path = $Path
        Filter = $filter
        File = $true
    }
    
    if ($Recurse) { $params.Recurse = $true }
    
    $files = Get-ChildItem @params
    
    # Дополнительные фильтры
    if ($DaysOld) {
        $cutoffDate = (Get-Date).AddDays(-$DaysOld)
        $files = $files | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    }
    
    if ($LargeFiles) {
        $files = $files | Where-Object { $_.Length -gt 10MB }
    }
    
    return $files
}

# Примеры использования функции:
# Find-Files -Path "C:\Projects" -NamePattern "report" -Extension "xlsx" -Recurse
# Find-Files -Path "D:\Backups" -DaysOld 30 -LargeFiles
Сохранение и использование
Сохраните любой из скриптов в файл с расширением .ps1 (например, FindFiles.ps1)

Запустите из PowerShell:

powershell
.\FindFiles.ps1 -Path "C:\MyFolder" -Filter "*.docx" -Recurse
Или для скрипта с параметрами:

powershell
.\FindFiles.ps1 -Path "C:\Documents" -Filter "invoice*.*" -ShowDetails
Эти скрипты предоставляют гибкие возможности для поиска файлов с различными фильтрами и опциями.