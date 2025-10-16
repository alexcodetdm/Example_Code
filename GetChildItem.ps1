Вот несколько способов вывести список папок и файлов на диске в PowerShell:

1. Простой список файлов и папок
powershell
# Только в текущей папке
Get-ChildItem

# На конкретном диске
Get-ChildItem C:\

# С указанием пути
Get-ChildItem -Path "C:\Users"
2. Раздельный вывод папок и файлов
powershell
# Только папки
Get-ChildItem -Directory

# Только файлы
Get-ChildItem -File

# С ограничением глубины (PowerShell 5.0+)
Get-ChildItem -Recurse -Depth 2
3. Цветной вывод с разделением
powershell
function Show-Items {
    param([string]$Path = ".")
    
    $items = Get-ChildItem -Path $Path
    
    Write-Host "=== ПАПКИ ===" -ForegroundColor Green
    $items | Where-Object { $_.PSIsContainer } | ForEach-Object {
        Write-Host "📁 $($_.Name)" -ForegroundColor Cyan
    }
    
    Write-Host "`n=== ФАЙЛЫ ===" -ForegroundColor Yellow
    $items | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
        Write-Host "📄 $($_.Name) | $($_.Length) bytes" -ForegroundColor White
    }
}

# Использование
Show-Items -Path "C:\"
4. Детализированный список с информацией
powershell
# Подробная информация
Get-ChildItem | Format-Table Name, Length, LastWriteTime, Attributes

# С сортировкой по размеру (только файлы)
Get-ChildItem -File | Sort-Object Length -Descending | Format-Table Name, @{Name="Size(MB)"; Expression={[math]::Round($_.Length/1MB,2)}}, LastWriteTime
5. Рекурсивный обход всех вложенных папок
powershell
# Все файлы и папки рекурсивно
Get-ChildItem -Recurse | Select-Object FullName, @{Name="Type"; Expression={if($_.PSIsContainer){"Folder"}else{"File"}}}

# Только структура папок
Get-ChildItem -Recurse -Directory | Select-Object FullName
6. Вывод в виде дерева
powershell
# Простое дерево
tree C:\ /F

# Или через PowerShell
function Show-Tree {
    param([string]$Path = ".", [string]$Indent = "")
    
    $items = Get-ChildItem -Path $Path
    foreach ($item in $items) {
        if ($item.PSIsContainer) {
            Write-Host "$Indent📁 $($item.Name)" -ForegroundColor Cyan
            Show-Tree -Path $item.FullName -Indent "$Indent    "
        } else {
            Write-Host "$Indent📄 $($item.Name)" -ForegroundColor Gray
        }
    }
}

Show-Tree -Path "C:\MyFolder"
7. Поиск по маске
powershell
# Все exe файлы
Get-ChildItem -Recurse -Filter "*.exe"

# Файлы по маске в имени
Get-ChildItem -Recurse -File | Where-Object { $_.Name -like "*test*" }
8. С ограничением по количеству
powershell
# Первые 10 элементов
Get-ChildItem | Select-Object -First 10

# Самые большие файлы
Get-ChildItem -Recurse -File | Sort-Object Length -Descending | Select-Object -First 5
9. Экспорт в файл
powershell
# В текстовый файл
Get-ChildItem -Recurse | Out-File -FilePath "C:\filelist.txt"

# В CSV
Get-ChildItem -Recurse | Select-Object Name, Length, LastWriteTime, Attributes | Export-Csv -Path "C:\filelist.csv" -NoTypeInformation
10. Для системных дисков
powershell
# Список всех дисков
Get-PSDrive -PSProvider FileSystem

# Для каждого диска показать содержимое корня
Get-PSDrive -PSProvider FileSystem | ForEach-Object {
    Write-Host "=== ДИСК $($_.Root) ===" -ForegroundColor Magenta
    Get-ChildItem -Path $_.Root -ErrorAction SilentlyContinue | Select-Object -First 5
}
Самый простой вариант для начала:
powershell
# Просто показать всё в текущей папке
Get-ChildItem

# Или с цветами
Get-ChildItem | ForEach-Object {
    if ($_.PSIsContainer) {
        Write-Host "Папка: $($_.Name)" -ForegroundColor Cyan
    } else {
        Write-Host "Файл: $($_.Name)" -ForegroundColor Yellow
    }
}
Рекоменд