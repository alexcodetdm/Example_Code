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