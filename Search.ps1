��� ��������� ��������� �������� PowerShell ��� ������ ������ �� �������:

������� �������
powershell
# ����� ������ � ������� �����
Get-ChildItem -Filter "*.txt"

# ����� � ���������� ��������
Get-ChildItem -Path "C:\MyFolder" -Filter "*.pdf" -Recurse

# ����� �� ����� �����
Get-ChildItem -Path "C:\MyFolder" -Filter "report*.*" -Recurse
����������� ������ � �����������
powershell
param(
    [string]$Path = ".",
    [string]$Filter = "*.*",
    [switch]$Recurse,
    [switch]$ShowDetails
)

Write-Host "����� ������ �: $Path" -ForegroundColor Green
Write-Host "������: $Filter" -ForegroundColor Yellow

if ($Recurse) {
    $files = Get-ChildItem -Path $Path -Filter $Filter -Recurse -File
} else {
    $files = Get-ChildItem -Path $Path -Filter $Filter -File
}

if ($files.Count -eq 0) {
    Write-Host "����� �� �������." -ForegroundColor Red
} else {
    Write-Host "������� ������: $($files.Count)" -ForegroundColor Green
    
    if ($ShowDetails) {
        $files | Format-Table Name, Directory, Length, LastWriteTime -AutoSize
    } else {
        $files | Select-Object -ExpandProperty FullName
    }
}
������ � ����������� ����������� ������ �����
powershell
Add-Type -AssemblyName System.Windows.Forms

# ������ ������ �����
$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$folderBrowser.Description = "�������� ����� ��� ������"
$folderBrowser.RootFolder = [System.Environment+SpecialFolder]::Desktop

if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedPath = $folderBrowser.SelectedPath
    
    # ������ ������� � ������������
    $filter = Read-Host "������� ������ ������ (��������: *.txt ��� report*.docx)"
    
    # ����� ������
    $files = Get-ChildItem -Path $selectedPath -Filter $filter -Recurse -File
    
    if ($files.Count -gt 0) {
        Write-Host "`n������� ������: $($files.Count)" -ForegroundColor Green
        $files | ForEach-Object {
            Write-Host "� $($_.FullName)" -ForegroundColor Cyan
        }
        
        # ���������� ����������� � ����
        $save = Read-Host "`n��������� ���������� � ����? (y/n)"
        if ($save -eq 'y') {
            $outputFile = "search_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
            $files | Select-Object FullName, Length, LastWriteTime | Out-File $outputFile
            Write-Host "���������� ��������� �: $outputFile" -ForegroundColor Green
        }
    } else {
        Write-Host "����� �� �������." -ForegroundColor Red
    }
} else {
    Write-Host "����� �� �������." -ForegroundColor Yellow
}
������� ��� ������������� �������������
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
    
    # ��������� ������
    $filter = if ($Extension -eq "*") {
        $NamePattern
    } else {
        "$NamePattern.$Extension"
    }
    
    # �������� �����
    $params = @{
        Path = $Path
        Filter = $filter
        File = $true
    }
    
    if ($Recurse) { $params.Recurse = $true }
    
    $files = Get-ChildItem @params
    
    # �������������� �������
    if ($DaysOld) {
        $cutoffDate = (Get-Date).AddDays(-$DaysOld)
        $files = $files | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    }
    
    if ($LargeFiles) {
        $files = $files | Where-Object { $_.Length -gt 10MB }
    }
    
    return $files
}

# ������� ������������� �������:
# Find-Files -Path "C:\Projects" -NamePattern "report" -Extension "xlsx" -Recurse
# Find-Files -Path "D:\Backups" -DaysOld 30 -LargeFiles
���������� � �������������
��������� ����� �� �������� � ���� � ����������� .ps1 (��������, FindFiles.ps1)

��������� �� PowerShell:

powershell
.\FindFiles.ps1 -Path "C:\MyFolder" -Filter "*.docx" -Recurse
��� ��� ������� � �����������:

powershell
.\FindFiles.ps1 -Path "C:\Documents" -Filter "invoice*.*" -ShowDetails
��� ������� ������������� ������ ����������� ��� ������ ������ � ���������� ��������� � �������.