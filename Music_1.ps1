# Простой синтезатор с использованием системного динамика
function Play-Note {
    param(
        [int]$Frequency,
        [int]$Duration = 500
    )
    [Console]::Beep($Frequency, $Duration)
}

# Ноты и их частоты (в Гц)
$notes = @{
    'C'  = 261
    'D'  = 293
    'E'  = 329
    'F'  = 349
    'G'  = 392
    'A'  = 440
    'B'  = 493
    'C2' = 523
}

# Проиграть простую мелодию
Write-Host "Играем мелодию..." -ForegroundColor Green

Play-Note -Frequency $notes['C'] -Duration 300
Play-Note -Frequency $notes['D'] -Duration 300
Play-Note -Frequency $notes['E'] -Duration 300
Play-Note -Frequency $notes['F'] -Duration 300
Play-Note -Frequency $notes['G'] -Duration 600
Play-Note -Frequency $notes['G'] -Duration 600

Play-Note -Frequency $notes['A'] -Duration 300
Play-Note -Frequency $notes['A'] -Duration 300
Play-Note -Frequency $notes['A'] -Duration 300
Play-Note -Frequency $notes['A'] -Duration 300
Play-Note -Frequency $notes['G'] -Duration 1000