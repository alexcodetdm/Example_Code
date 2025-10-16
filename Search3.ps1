Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Создаем главную форму
$form = New-Object System.Windows.Forms.Form
$form.Text = "Поиск файлов (результаты в консоль)"
$form.Size = New-Object System.Drawing.Size(500, 250)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Метка для выбора папки
$labelPath = New-Object System.Windows.Forms.Label
$labelPath.Location = New-Object System.Drawing.Point(10, 20)
$labelPath.Size = New-Object System.Drawing.Size(200, 20)
$labelPath.Text = "Выберите папку для поиска:"
$form.Controls.Add($labelPath)

# Поле для отображения выбранной папки
$textBoxPath = New-Object System.Windows.Forms.TextBox
$textBoxPath.Location = New-Object System.Drawing.Point(10, 40)
$textBoxPath.Size = New-Object System.Drawing.Size(350, 20)
$textBoxPath.ReadOnly = $true
$form.Controls.Add($textBoxPath)

# Кнопка выбора папки
$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Location = New-Object System.Drawing.Point(370, 40)
$buttonBrowse.Size = New-Object System.Drawing.Size(100, 23)
$buttonBrowse.Text = "Обзор..."
$form.Controls.Add($buttonBrowse)

# Метка для выбора типа файлов
$labelFilter = New-Object System.Windows.Forms.Label
$labelFilter.Location = New-Object System.Drawing.Point(10, 80)
$labelFilter.Size = New-Object System.Drawing.Size(200, 20)
$labelFilter.Text = "Выберите тип файлов:"
$form.Controls.Add($labelFilter)

# Выпадающий список фильтров
$comboBoxFilter = New-Object System.Windows.Forms.ComboBox
$comboBoxFilter.Location = New-Object System.Drawing.Point(10, 100)
$comboBoxFilter.Size = New-Object System.Drawing.Size(200, 20)
$comboBoxFilter.DropDownStyle = "DropDownList"
# Добавляем популярные фильтры
$comboBoxFilter.Items.AddRange(@(
    "Все файлы (*.*)",
    "Текстовые файлы (*.txt)",
    "Документы Word (*.docx, *.doc)",
    "Таблицы Excel (*.xlsx, *.xls)",
    "PDF документы (*.pdf)",
    "Изображения (*.jpg, *.png, *.gif)",
    "Архивы (*.zip, *.rar, *.7z)",
    "Скрипты (*.ps1, *.bat, *.sh)",
    "Видео файлы (*.mp4, *.avi, *.mkv)",
    "Пользовательский фильтр..."
))
$comboBoxFilter.SelectedIndex = 0
$form.Controls.Add($comboBoxFilter)

# Поле для пользовательского фильтра
$textBoxCustomFilter = New-Object System.Windows.Forms.TextBox
$textBoxCustomFilter.Location = New-Object System.Drawing.Point(220, 100)
$textBoxCustomFilter.Size = New-Object System.Drawing.Size(150, 20)
$textBoxCustomFilter.Visible = $false
$textBoxCustomFilter.Text = "*.ext"
$form.Controls.Add($textBoxCustomFilter)

# Чекбокс для поиска в подпапках
$checkBoxRecurse = New-Object System.Windows.Forms.CheckBox
$checkBoxRecurse.Location = New-Object System.Drawing.Point(10, 140)
$checkBoxRecurse.Size = New-Object System.Drawing.Size(200, 20)
$checkBoxRecurse.Text = "Искать в подпапках"
$checkBoxRecurse.Checked = $true
$form.Controls.Add($checkBoxRecurse)

# Кнопка поиска
$buttonSearch = New-Object System.Windows.Forms.Button
$buttonSearch.Location = New-Object System.Drawing.Point(10, 170)
$buttonSearch.Size = New-Object System.Drawing.Size(100, 30)
$buttonSearch.Text = "Поиск"
$buttonSearch.Enabled = $false
$form.Controls.Add($buttonSearch)

# Кнопка отмены
$buttonCancel = New-Object System.Windows.Forms.Button
$buttonCancel.Location = New-Object System.Drawing.Point(120, 170)
$buttonCancel.Size = New-Object System.Drawing.Size(100, 30)
$buttonCancel.Text = "Отмена"
$form.Controls.Add($buttonCancel)

# Метка для статуса
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Location = New-Object System.Drawing.Point(230, 170)
$labelStatus.Size = New-Object System.Drawing.Size(200, 30)
$labelStatus.Text = ""
$form.Controls.Add($labelStatus)

# Обработчик выбора папки
$buttonBrowse.Add_Click({
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Выберите папку для поиска"
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::Desktop
    
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxPath.Text = $folderBrowser.SelectedPath
        $buttonSearch.Enabled = $true
    }
})

# Обработчик изменения выбора фильтра
$comboBoxFilter.Add_SelectedIndexChanged({
    if ($comboBoxFilter.SelectedItem -eq "Пользовательский фильтр...") {
        $textBoxCustomFilter.Visible = $true
    } else {
        $textBoxCustomFilter.Visible = $false
    }
})

# Функция для получения фильтра на основе выбора
function Get-FilterPattern {
    param($selectedItem)
    
    switch ($selectedItem) {
        "Все файлы (*.*)" { return "*.*" }
        "Текстовые файлы (*.txt)" { return "*.txt" }
        "Документы Word (*.docx, *.doc)" { return "*.doc*" }
        "Таблицы Excel (*.xlsx, *.xls)" { return "*.xls*" }
        "PDF документы (*.pdf)" { return "*.pdf" }
        "Изображения (*.jpg, *.png, *.gif)" { return "*.jpg", "*.png", "*.gif" }
        "Архивы (*.zip, *.rar, *.7z)" { return "*.zip", "*.rar", "*.7z" }
        "Скрипты (*.ps1, *.bat, *.sh)" { return "*.ps1", "*.bat", "*.sh" }
        "Видео файлы (*.mp4, *.avi, *.mkv)" { return "*.mp4", "*.avi", "*.mkv" }
        "Пользовательский фильтр..." { return $textBoxCustomFilter.Text }
        default { return "*.*" }
    }
}

# Функция для вывода результатов в консоль
function Write-ResultsToConsole {
    param($files, $filterPattern, $path, $recurse)
    
    Write-Host "`n" + "="*60 -ForegroundColor Green
    Write-Host "РЕЗУЛЬТАТЫ ПОИСКА" -ForegroundColor Green
    Write-Host "="*60 -ForegroundColor Green
    Write-Host "Папка: $path" -ForegroundColor Yellow
    Write-Host "Фильтр: $($filterPattern -join ', ')" -ForegroundColor Yellow
    Write-Host "Поиск в подпапках: $recurse" -ForegroundColor Yellow
    Write-Host "-"*60 -ForegroundColor Gray
    
    if ($files -and $files.Count -gt 0) {
        Write-Host "Найдено файлов: $($files.Count)" -ForegroundColor Green
        Write-Host "-"*60 -ForegroundColor Gray
        
        foreach ($file in $files) {
            $size = if ($file.Length -ge 1GB) {
                "{0:N2} GB" -f ($file.Length / 1GB)
            } elseif ($file.Length -ge 1MB) {
                "{0:N2} MB" -f ($file.Length / 1MB)
            } elseif ($file.Length -ge 1KB) {
                "{0:N2} KB" -f ($file.Length / 1KB)
            } else {
                "$($file.Length) B"
            }
            
            Write-Host "• $($file.Name)" -ForegroundColor Cyan -NoNewline
            Write-Host " ($size)" -ForegroundColor White -NoNewline
            Write-Host " - $($file.LastWriteTime.ToString('dd.MM.yyyy HH:mm'))" -ForegroundColor Gray
            Write-Host "  Путь: $($file.Directory)" -ForegroundColor DarkGray
            Write-Host ""
        }
        
        # Сводная информация
        $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
        $totalSizeFormatted = if ($totalSize -ge 1GB) {
            "{0:N2} GB" -f ($totalSize / 1GB)
        } elseif ($totalSize -ge 1MB) {
            "{0:N2} MB" -f ($totalSize / 1MB)
        } elseif ($totalSize -ge 1KB) {
            "{0:N2} KB" -f ($totalSize / 1KB)
        } else {
            "$totalSize B"
        }
        
        Write-Host "-"*60 -ForegroundColor Gray
        Write-Host "Общий размер: $totalSizeFormatted" -ForegroundColor Green
        Write-Host "Последний измененный: $($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | ForEach-Object { $_.LastWriteTime.ToString('dd.MM.yyyy HH:mm') })" -ForegroundColor Green
        
    } else {
        Write-Host "Файлы не найдены по заданным критериям." -ForegroundColor Red
    }
    
    Write-Host "="*60 -ForegroundColor Green
    Write-Host "`n"
}

# Обработчик кнопки поиска
$buttonSearch.Add_Click({
    $labelStatus.Text = "Поиск..."
    $form.Refresh()
    
    $path = $textBoxPath.Text
    $filterPattern = Get-FilterPattern $comboBoxFilter.SelectedItem
    $recurse = $checkBoxRecurse.Checked
    
    try {
        # Очищаем консоль перед новым поиском
        Clear-Host
        
        Write-Host "Запуск поиска..." -ForegroundColor Yellow
        Write-Host "Папка: $path" -ForegroundColor White
        Write-Host "Фильтр: $($filterPattern -join ', ')" -ForegroundColor White
        
        if ($filterPattern -is [array]) {
            # Если несколько фильтров
            $allFiles = @()
            foreach ($filter in $filterPattern) {
                Write-Host "Поиск по фильтру: $filter" -ForegroundColor Gray
                if ($recurse) {
                    $files = Get-ChildItem -Path $path -Filter $filter -Recurse -File -ErrorAction SilentlyContinue
                } else {
                    $files = Get-ChildItem -Path $path -Filter $filter -File -ErrorAction SilentlyContinue
                }
                $allFiles += $files
            }
            $files = $allFiles | Sort-Object FullName -Unique
        } else {
            # Если один фильтр
            Write-Host "Поиск по фильтру: $filterPattern" -ForegroundColor Gray
            if ($recurse) {
                $files = Get-ChildItem -Path $path -Filter $filterPattern -Recurse -File -ErrorAction SilentlyContinue
            } else {
                $files = Get-ChildItem -Path $path -Filter $filterPattern -File -ErrorAction SilentlyContinue
            }
        }
        
        # Выводим результаты в консоль
        Write-ResultsToConsole -files $files -filterPattern $filterPattern -path $path -recurse $recurse
        
        $labelStatus.Text = "Готово! См. консоль"
        
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Host "Ошибка при поиске: $errorMsg" -ForegroundColor Red
        $labelStatus.Text = "Ошибка!"
    }
})

# Обработчик кнопки отмены
$buttonCancel.Add_Click({
    $form.Close()
})

# Обработчик закрытия формы
$form.Add_FormClosing({
    Write-Host "`nПоиск завершен. Форма закрывается." -ForegroundColor Yellow
})

# Показываем форму
Write-Host "Запуск графического интерфейса поиска файлов..." -ForegroundColor Green
Write-Host "Результаты будут отображаться в этой консоли." -ForegroundColor Yellow
Write-Host "`n"

[void]$form.ShowDialog()

Write-Host "Работа скрипта завершена." -ForegroundColor Green