# Самый простой вариант - использует системный динамик
function Play-SimpleTone {
    param(
        [int]$Frequency,
        [int]$DurationMs
    )
    
    # Проверяем поддерживаемый диапазон частот (37-32767 Гц)
    if ($Frequency -lt 37 -or $Frequency -gt 32767) {
        Write-Warning "Частота $Frequency Hz вне диапазона (37-32767 Hz)"
        return
    }
    
    [Console]::Beep($Frequency, $DurationMs)
}

# Проиграть простую мелодию
Write-Host "Играем 'В траве сидел кузнечик'..." -ForegroundColor Green

$melody = @(
    @{Freq=392; Dur=200},  # G
    @{Freq=440; Dur=200},  # A
    @{Freq=392; Dur=200},  # G
    @{Freq=349; Dur=200},  # F
    @{Freq=330; Dur=200},  # E
    @{Freq=294; Dur=200},  # D
    @{Freq=330; Dur=200},  # E
    @{Freq=349; Dur=200},  # F
    @{Freq=392; Dur=400},  # G
    @{Freq=392; Dur=200},  # G
    @{Freq=392; Dur=600}   # G (длинная)
)

foreach ($note in $melody) {
    Play-SimpleTone -Frequency $note.Freq -DurationMs $note.Dur
}

Write-Host "Мелодия завершена!" -ForegroundColor Green