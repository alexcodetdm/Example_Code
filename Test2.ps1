1. ������������� �������� � ��������������
powershell
# ����������� � ���� ������ � ���������� �������
$connectionString = "Server=your_server;Database=your_db;Integrated Security=True"
$query = "SELECT Field1, Field2, Field3, Field4 FROM YourTable"

$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
$command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
$adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
$dataset = New-Object System.Data.DataSet

$adapter.Fill($dataset) | Out-Null
$connection.Close()

# �������� ������� � ���������� ������
$resultArray = @()

foreach ($row in $dataset.Tables[0].Rows) {
    # ��������� ������ � ������� ������
    $line = "$($row.Field1),$($row.Field2),$($row.Field3),$($row.Field4)"
    $resultArray += $line
}

# ����� ����������
$resultArray
2. ������������� PSCustomObject
powershell
# ����� ����������������� ������
$resultArray = @()

foreach ($row in $dataset.Tables[0].Rows) {
    $obj = [PSCustomObject]@{
        Field1 = $row.Field1
        Field2 = $row.Field2
        Field3 = $row.Field3
        Field4 = $row.Field4
    }
    $resultArray += $obj
}

# ����� � ���� ������ � �������������
$resultArray | ForEach-Object {
    "$($_.Field1)|$($_.Field2)|$($_.Field3)|$($_.Field4)"
}
3. ������������� Join ��� ��������������
powershell
$resultArray = @()

foreach ($row in $dataset.Tables[0].Rows) {
    $fields = @($row.Field1, $row.Field2, $row.Field3, $row.Field4)
    $line = $fields -join ","
    $resultArray += $line
}

$resultArray
4. ���������� ������ � Invoke-SqlCmd
powershell
# ���� � ��� ���� ������ SqlServer
Import-Module SqlServer

$resultArray = @()
$results = Invoke-SqlCmd -ServerInstance "your_server" -Database "your_db" -Query "SELECT Field1, Field2, Field3, Field4 FROM YourTable"

foreach ($row in $results) {
    $line = "$($row.Field1);$($row.Field2);$($row.Field3);$($row.Field4)"
    $resultArray += $line
}

$resultArray
5. � ���������� NULL ��������
powershell
$resultArray = @()

foreach ($row in $dataset.Tables[0].Rows) {
    # �������� NULL �������� �� ������ ������
    $f1 = if ([DBNull]::Value.Equals($row.Field1)) { "" } else { $row.Field1 }
    $f2 = if ([DBNull]::Value.Equals($row.Field2)) { "" } else { $row.Field2 }
    $f3 = if ([DBNull]::Value.Equals($row.Field3)) { "" } else { $row.Field3 }
    $f4 = if ([DBNull]::Value.Equals($row.Field4)) { "" } else { $row.Field4 }
    
    $line = "$f1,$f2,$f3,$f4"
    $resultArray += $line
}

$resultArray
������ ������:
text
value1,value2,value3,value4
test1,test2,test3,test4
data1,data2,data3,data4
�������� ������, ������� ����� ����� �������� ��� ����� ����. ������ ������� �������� ������� � ������, ������ ������������� ������ �������� ��� ���������� ��������� ������.

Microsoft.SqlServer.Management.Smo.Server
��� ��������� �������� �������� ������ � �������� �� � ������:

1. ������� ������ � Datatable
powershell
# ���������� SMO assembly
Add-Type -AssemblyName "Microsoft.SqlServer.Smo, Version=15.0.0.0, Culture=neutral, PublicKeyToken=89845dcd8080cc91"

# ������� ������ �������
$server = New-Object Microsoft.SqlServer.Management.Smo.Server "your_server_name"
$database = $server.Databases["your_database_name"]

# ��������� ������
$result = $database.ExecuteWithResults("SELECT Field1, Field2, Field3, Field4 FROM YourTable")

# ������� ������ � ��������� ������
$resultArray = @()

foreach ($row in $result.Tables[0].Rows) {
    $line = "$($row.Field1),$($row.Field2),$($row.Field3),$($row.Field4)"
    $resultArray += $line
}

# ������� ���������
$resultArray
2. ������������� Invoke-SqlCmd ����� SMO
powershell
# �������������� ������ � Datatable
$dataTable = New-Object System.Data.DataTable
$dataTable = $database.ExecuteWithResults("SELECT Field1, Field2, Field3, Field4 FROM YourTable").Tables[0]

$resultArray = @()

foreach ($row in $dataTable.Rows) {
    $fields = @(
        $row["Field1"],
        $row["Field2"], 
        $row["Field3"],
        $row["Field4"]
    )
    $line = $fields -join "|"
    $resultArray += $line
}

$resultArray
3. � ���������� NULL ��������
powershell
$resultArray = @()
$result = $database.ExecuteWithResults("SELECT Field1, Field2, Field3, Field4 FROM YourTable")

foreach ($row in $result.Tables[0].Rows) {
    # ������� ��� ��������� NULL ��������
    function Get-ValueOrEmpty {
        param($value)
        if ([DBNull]::Value.Equals($value)) { "" } else { $value }
    }
    
    $line = "{0},{1},{2},{3}" -f `
        (Get-ValueOrEmpty $row.Field1),
        (Get-ValueOrEmpty $row.Field2),
        (Get-ValueOrEmpty $row.Field3),
        (Get-ValueOrEmpty $row.Field4)
    
    $resultArray += $line
}

$resultArray
4. ���������� ������ � Select-Object
powershell
$result = $database.ExecuteWithResults("SELECT Field1, Field2, Field3, Field4 FROM YourTable")

$resultArray = $result.Tables[0].Rows | ForEach-Object {
    "$($_.Field1);$($_.Field2);$($_.Field3);$($_.Field4)"
}

$resultArray
5. �������� ������� � ���������� ����������
powershell
$resultArray = @()
$result = $database.ExecuteWithResults("SELECT Field1, Field2, Field3, Field4 FROM YourTable")

foreach ($row in $result.Tables[0].Rows) {
    $item = New-Object PSObject -Property @{
        Combined = "$($row.Field1)-$($row.Field2)-$($row.Field3)-$($row.Field4)"
        Field1 = $row.Field1
        Field2 = $row.Field2
        Field3 = $row.Field3
        Field4 = $row.Field4
    }
    $resultArray += $item.Combined
}

$resultArray
6. ��� ������ � �������� �������� ������ (����� ����������)
powershell
# ���������� ArrayList ��� ������ ������������������ ��� ������� ������� ������
$resultList = [System.Collections.ArrayList]@()
$result = $database.ExecuteWithResults("SELECT Field1, Field2, Field3, Field4 FROM YourTable")

foreach ($row in $result.Tables[0].Rows) {
    $line = "{0}|{1}|{2}|{3}" -f $row.Field1, $row.Field2, $row.Field3, $row.Field4
    [void]$resultList.Add($line)
}

# ������������ ������� � ������� ������ ���� �����
$resultArray = @($resultList)
$resultArray
������ ������������� � �����������:
powershell
# ����������� � �������
$serverName = "SQLSERVER01"
$dbName = "AdventureWorks"
$query = "SELECT FirstName, LastName, Email, Phone FROM Customers WHERE City = 'London'"

$server = New-Object Microsoft.SqlServer.Management.Smo.Server $serverName
$database = $server.Databases[$dbName]

$resultArray = @()
$data = $database.ExecuteWithResults($query)

foreach ($row in $data.Tables[0].Rows) {
    $line = "$($row.FirstName) $($row.LastName) - $($row.Email) - $($row.Phone)"
    $resultArray += $line
}

# ����� �����������
$resultArray | ForEach-Object { Write-Output $_ }

� PowerShell ���� ��������� �������� �������� �������� ������ �� ����� � ������:

1. ������� ������ � Get-ChildItem
powershell
# �������� ������ ����� ������ (��� ������� ����)
$fileNames = Get-ChildItem -Path "C:\Your\Folder" -File | Select-Object -ExpandProperty Name

# ������� ���������
$fileNames
2. �������� ������ � ������� ������
powershell
# �������� ������ ���� � ������
$filePaths = Get-ChildItem -Path "C:\Your\Folder" -File | Select-Object -ExpandProperty FullName

$filePaths
3. ������ ��� ������������� ���� ������
powershell
# ������ txt �����
$txtFiles = Get-ChildItem -Path "C:\Your\Folder" -Filter "*.txt" | Select-Object -ExpandProperty Name

# ������ excel �����
$excelFiles = Get-ChildItem -Path "C:\Your\Folder" -Filter "*.xlsx" | Select-Object -ExpandProperty Name
4. � �������������� ForEach-Object
powershell
$fileNames = @()
Get-ChildItem -Path "C:\Your\Folder" -File | ForEach-Object {
    $fileNames += $_.Name
}

$fileNames
5. ����� ����������� ������ � ArrayList
powershell
# ��� ������� ����� ����� ������������ ArrayList
$fileList = [System.Collections.ArrayList]@()
Get-ChildItem -Path "C:\Your\Folder" -File | ForEach-Object {
    [void]$fileList.Add($_.Name)
}

# ������������ � ������� ������ ���� �����
$fileNames = @($fileList)
$fileNames
6. � ����������� ������� (������� ��������)
powershell
# ������ �� ���� ���������
$allFiles = Get-ChildItem -Path "C:\Your\Folder" -File -Recurse | Select-Object -ExpandProperty Name

$allFiles
7. � ����������� �� ���������
powershell
# ������ ������� �����
$hiddenFiles = Get-ChildItem -Path "C:\Your\Folder" -File -Hidden | Select-Object -ExpandProperty Name

# ������ ��������� �����
$systemFiles = Get-ChildItem -Path "C:\Your\Folder" -File -System | Select-Object -ExpandProperty Name
8. � �����������
powershell
# ������������� �� �����
$sortedFiles = Get-ChildItem -Path "C:\Your\Folder" -File | 
               Sort-Object Name | 
               Select-Object -ExpandProperty Name

# ������������� �� ���� ��������� (������� �����)
$newestFiles = Get-ChildItem -Path "C:\Your\Folder" -File | 
               Sort-Object LastWriteTime -Descending | 
               Select-Object -ExpandProperty Name
9. ���������� ������
powershell
# ����� �������� �������
$files = (Get-ChildItem -Path "C:\Your\Folder" -File).Name
$files
10. ������ ������ � ���������� ������
powershell
try {
    $folderPath = "C:\Your\Folder"
    
    # ��������� ������������� �����
    if (Test-Path $folderPath -PathType Container) {
        $fileNames = Get-ChildItem -Path $folderPath -File -ErrorAction Stop | 
                    Select-Object -ExpandProperty Name
        
        Write-Host "������� ������: $($fileNames.Count)"
        $fileNames
    }
    else {
        Write-Warning "����� $folderPath �� ����������!"
    }
}
catch {
    Write-Error "������ ��� ��������� ������ ������: $($_.Exception.Message)"
}
11. ���������� � ����
powershell
# �������� ����� ������ � ��������� � ��������� ����
$fileNames = Get-ChildItem -Path "C:\Your\Folder" -File | Select-Object -ExpandProperty Name
$fileNames | Out-File -FilePath "C:\file_list.txt"

# ��� ����� �������
(Get-ChildItem -Path "C:\Your\Folder" -File).Name | Out-File "C:\file_list.txt"
������ ������:
text
file1.txt
document.docx
image.jpg
script.ps1
data.xlsx
�����: ��� ������ � �������� ������� ����������� ������� � ArrayList (����� 5), ��� ��� �� ����� ���������� �� ������.

�������� ��� ������� System.Collections.ArrayList � ������� �������
� PowerShell ���� ��������� �������� �������� ��� ArrayList � ����� �������. ��� �������� ������:

1. ������������� Compare-Object (����� ������� ������)
powershell
# ������� ��� ArrayList ��� �������
$list1 = [System.Collections.ArrayList]@('file1.txt', 'file2.txt', 'file3.txt', 'file5.txt')
$list2 = [System.Collections.ArrayList]@('file2.txt', 'file3.txt', 'file4.txt', 'file6.txt')

# ���������� � ������� �������
$differences = Compare-Object -ReferenceObject $list1 -DifferenceObject $list2

# ������� ���������
$differences
2. ����� ���������������� ���������
powershell
$comparison = Compare-Object -ReferenceObject $list1 -DifferenceObject $list2

Write-Host "=== �������� ����� ��������� ===" -ForegroundColor Yellow

foreach ($item in $comparison) {
    if ($item.SideIndicator -eq '=>') {
        Write-Host "������ �� ������ �������: $($item.InputObject)" -ForegroundColor Green
    }
    elseif ($item.SideIndicator -eq '<=') {
        Write-Host "������ � ������ �������: $($item.InputObject)" -ForegroundColor Red
    }
}
3. ���������� �� ��������� ������� ��������
powershell
$comparison = Compare-Object -ReferenceObject $list1 -DifferenceObject $list2

# �������� ������ � ������ �������
$onlyInFirst = $comparison | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject

# �������� ������ �� ������ �������
$onlyInSecond = $comparison | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject

# ����� ��������
$commonItems = $list1 | Where-Object { $list2 -contains $_ }

Write-Host "������ � ������ �������: $($onlyInFirst -join ', ')" -ForegroundColor Red
Write-Host "������ �� ������ �������: $($onlyInSecond -join ', ')" -ForegroundColor Green
Write-Host "����� ��������: $($commonItems -join ', ')" -ForegroundColor Blue
4. � �������������� ������� .NET
powershell
# �������� ������ � ������ �������
$onlyInFirst = $list1 | Where-Object { $list2 -notcontains $_ }

# �������� ������ �� ������ �������
$onlyInSecond = $list2 | Where-Object { $list1 -notcontains $_ }

# ����� ��������
$commonItems = $list1 | Where-Object { $list2 -contains $_ }

Write-Host "=== ���������� ��������� ===" -ForegroundColor Yellow
Write-Host "������ � list1 ($($onlyInFirst.Count)): " -NoNewline -ForegroundColor Red
Write-Host ($onlyInFirst -join ', ')
Write-Host "������ � list2 ($($onlyInSecond.Count)): " -NoNewline -ForegroundColor Green
Write-Host ($onlyInSecond -join ', ')
Write-Host "����� �������� ($($commonItems.Count)): " -NoNewline -ForegroundColor Blue
Write-Host ($commonItems -join ', ')
5. ������� ��� �������� ���������
powershell
function Compare-ArrayLists {
    param(
        [System.Collections.ArrayList]$FirstList,
        [System.Collections.ArrayList]$SecondList,
        [string]$FirstName = "������ ������",
        [string]$SecondName = "������ ������"
    )
    
    $comparison = Compare-Object -ReferenceObject $FirstList -DifferenceObject $SecondList
    
    $onlyInFirst = $comparison | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    $onlyInSecond = $comparison | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
    $commonItems = $FirstList | Where-Object { $SecondList -contains $_ }
    
    Write-Host "`n=== ���������: $FirstName vs $SecondName ===" -ForegroundColor Yellow
    Write-Host "��������� � $FirstName`: $($FirstList.Count)" -ForegroundColor Gray
    Write-Host "��������� � $SecondName`: $($SecondList.Count)" -ForegroundColor Gray
    Write-Host "����� ���������: $($commonItems.Count)" -ForegroundColor Blue
    Write-Host "���������� � $FirstName`: $($onlyInFirst.Count)" -ForegroundColor Red
    Write-Host "���������� � $SecondName`: $($onlyInSecond.Count)" -ForegroundColor Green
    
    if ($onlyInFirst) {
        Write-Host "`n������ � $FirstName`: " -ForegroundColor Red -NoNewline
        Write-Host ($onlyInFirst -join ', ')
    }
    
    if ($onlyInSecond) {
        Write-Host "������ � $SecondName`: " -ForegroundColor Green -NoNewline
        Write-Host ($onlyInSecond -join ', ')
    }
    
    return @{
        OnlyInFirst = $onlyInFirst
        OnlyInSecond = $onlyInSecond
        Common = $commonItems
    }
}

# ������������� �������
$result = Compare-ArrayLists -FirstList $list1 -SecondList $list2 -FirstName "�������� �����" -SecondName "����� �����"
6. ��������� ��� ����� ��������
powershell
# ���� ����� ��������� ��� ����� ��������
$caseInsensitiveCompare = Compare-Object -ReferenceObject $list1 -DifferenceObject $list2 -CaseSensitive:$false
$caseInsensitiveCompare
7. ���������� ��������� � ���������
powershell
# ��� ��������� �� �������� (���� ������� �����)
for ($i = 0; $i -lt [Math]::Max($list1.Count, $list2.Count); $i++) {
    $item1 = if ($i -lt $list1.Count) { $list1[$i] } else { "��� ��������" }
    $item2 = if ($i -lt $list2.Count) { $list2[$i] } else { "��� ��������" }
    
    if ($item1 -ne $item2) {
        Write-Host "�������� � ������� $i : $item1 != $item2" -ForegroundColor Yellow
    }
}
8. ������� ����������� � ����
powershell
$comparison = Compare-Object -ReferenceObject $list1 -DifferenceObject $list2

$report = @"
=== ����� � ��������� �������� ===
���� ���������: $(Get-Date)
������ ������� �������: $($list1.Count)
������ ������� �������: $($list2.Count)

�������� ������ � ������ �������:
$($comparison | Where-Object { $_.SideIndicator -eq '<=' } | ForEach-Object { "  - $($_.InputObject)" } | Out-String)

�������� ������ �� ������ �������:
$($comparison | Where-Object { $_.SideIndicator -eq '=>' } | ForEach-Object { "  - $($_.InputObject)" } | Out-String)
"@

$report | Out-File -FilePath "comparison_report.txt"
Write-Host "����� �������� � comparison_report.txt"
������ ������:
text
InputObject SideIndicator
----------- -------------
file1.txt   <=
file5.txt   <=
file4.txt   =>
file6.txt   =>
������������:

����������� Compare-Object ��� ����������� ������� - ��� ����� �������� �����

��� ������� �������� ����� � -notcontains ����� ���� ���������

������� Compare-ArrayLists ������������� �������� �������� ���������

��� ��������� �������� �������� ����� ������ �� ����� � System.Collections.ArrayList:

1. ������� ������ (����� �������)
powershell
# ������� ArrayList
$fileList = [System.Collections.ArrayList]@()

# �������� ����� ������ � ��������� � ArrayList
Get-ChildItem -Path "C:\Your\Folder" -File | ForEach-Object {
    [void]$fileList.Add($_.Name)
}

# ������� ���������
$fileList
2. ���������� ������
powershell
$fileList = [System.Collections.ArrayList]@(
    (Get-ChildItem -Path "C:\Your\Folder" -File).Name
)

$fileList
3. � ���������� ������
powershell
$folderPath = "C:\Your\Folder"
$fileList = [System.Collections.ArrayList]@()

try {
    if (Test-Path $folderPath -PathType Container) {
        $files = Get-ChildItem -Path $folderPath -File -ErrorAction Stop
        
        foreach ($file in $files) {
            [void]$fileList.Add($file.Name)
        }
        
        Write-Host "��������� ������: $($fileList.Count)" -ForegroundColor Green
    }
    else {
        Write-Warning "����� $folderPath �� ����������!"
    }
}
catch {
    Write-Error "������: $($_.Exception.Message)"
}

$fileList
4. � ����������� ������� (������� ��������)
powershell
$fileList = [System.Collections.ArrayList]@()

Get-ChildItem -Path "C:\Your\Folder" -File -Recurse | ForEach-Object {
    [void]$fileList.Add($_.Name)
}

$fileList
5. � ����������� �� ����������
powershell
$fileList = [System.Collections.ArrayList]@()

# ������ txt �����
Get-ChildItem -Path "C:\Your\Folder" -Filter "*.txt" -File | ForEach-Object {
    [void]$fileList.Add($_.Name)
}

$fileList
6. � �������������� ����������� � ������
powershell
$fileList = [System.Collections.ArrayList]@()

Get-ChildItem -Path "C:\Your\Folder" -File | ForEach-Object {
    # ������� ������ � ����������� � �����
    $fileInfo = @{
        Name = $_.Name
        Size = $_.Length
        LastModified = $_.LastWriteTime
        Extension = $_.Extension
    }
    
    [void]$fileList.Add($fileInfo)
}

# ������� ���������
$fileList | ForEach-Object {
    Write-Host "����: $($_.Name), ������: $($_.Size) ����, ����������: $($_.Extension)"
}
7. � ����������� �� �����
powershell
$fileList = [System.Collections.ArrayList]@()

Get-ChildItem -Path "C:\Your\Folder" -File | 
Sort-Object Name | 
ForEach-Object {
    [void]$fileList.Add($_.Name)
}

$fileList
8. ������������� �������
powershell
function Get-FileListToArrayList {
    param(
        [string]$Path = ".",
        [switch]$Recursive,
        [string]$Filter = "*",
        [switch]$FullName
    )
    
    $fileList = [System.Collections.ArrayList]@()
    $params = @{
        Path = $Path
        Filter = $Filter
        File = $true
    }
    
    if ($Recursive) {
        $params.Recurse = $true
    }
    
    try {
        $files = Get-ChildItem @params -ErrorAction Stop
        
        foreach ($file in $files) {
            if ($FullName) {
                [void]$fileList.Add($file.FullName)
            }
            else {
                [void]$fileList.Add($file.Name)
            }
        }
    }
    catch {
        Write-Error "������ ��� ��������� ������ ������: $($_.Exception.Message)"
    }
    
    return $fileList
}

# ������������� �������
$files = Get-FileListToArrayList -Path "C:\Your\Folder" -Recursive
$files
9. � ����������� ������������ ������
powershell
$fileList = [System.Collections.ArrayList]@()
$excludeExtensions = @('.tmp', '.log', '.bak')

Get-ChildItem -Path "C:\Your\Folder" -File | ForEach-Object {
    if ($excludeExtensions -notcontains $_.Extension) {
        [void]$fileList.Add($_.Name)
    }
}

$fileList
10. � ������������ �� ���������� ������
powershell
$fileList = [System.Collections.ArrayList]@()
$maxFiles = 100
$count = 0

Get-ChildItem -Path "C:\Your\Folder" -File | ForEach-Object {
    if ($count -lt $maxFiles) {
        [void]$fileList.Add($_.Name)
        $count++
    }
}

Write-Host "��������� $count ������ �� $((Get-ChildItem -Path "C:\Your\Folder" -File).Count)"
$fileList
11. ���������� � ����
powershell
$fileList = [System.Collections.ArrayList]@()

Get-ChildItem -Path "C:\Your\Folder" -File | ForEach-Object {
    [void]$fileList.Add($_.Name)
}

# ��������� � ����
$fileList | Out-File -FilePath "C:\file_list.txt"

Write-Host "������ ������ �������� � C:\file_list.txt"
������ ������:
text
Count Capacity
----- --------
   25       32

# ��� ��������� �����������:
$fileList | Format-Table -AutoSize
������������ ������������� ArrayList:

������� �������� � �������� ������������ ������

����� ��������� � ������� ��������

������������ ��� ������ ��������� .NET

�����: ����������� [void] ����� $fileList.Add() ����� �������� ����� ������ ������� ��� ���������� ���������.

��� ������ ������� ��� �������� ������ � ��������������:

1. ������ ������ � ��������������
powershell
# ������� ������ � ������� ��� ��������
$filesToDelete = [System.Collections.ArrayList]@(
    "C:\temp\file1.txt",
    "C:\temp\old_file.log",
    "C:\temp\backup.bak",
    "C:\temp\temp_data.tmp"
)

function Remove-FilesWithConfirmation {
    param(
        [System.Collections.ArrayList]$FileList
    )
    
    Write-Host "=== ������ �������� ������ ===" -ForegroundColor Yellow
    Write-Host "������� ������ ��� ��������: $($FileList.Count)" -ForegroundColor Cyan
    
    # ���������� ������ ������
    Write-Host "`n������ ������ ��� ��������:" -ForegroundColor Green
    for ($i = 0; $i -lt $FileList.Count; $i++) {
        Write-Host "$($i+1). $($FileList[$i])" -ForegroundColor Gray
    }
    
    # ������ �������������
    Write-Host "`n" -NoNewline
    $confirmation = Read-Host "�� �������, ��� ������ ������� ��� �����? (y/N)"
    
    if ($confirmation -ne 'y' -and $confirmation -ne 'Y' -and $confirmation -ne '�' -and $confirmation -ne '�') {
        Write-Host "�������� ��������." -ForegroundColor Red
        return
    }
    
    # ������������� ��� ������� �����
    $confirmEach = Read-Host "������������ �������� ������� ����� ��������? (y/N)"
    $confirmIndividual = ($confirmEach -eq 'y' -or $confirmEach -eq 'Y' -or $confirmEach -eq '�' -or $confirmEach -eq '�')
    
    $deletedCount = 0
    $failedCount = 0
    $skippedCount = 0
    
    # ������� �����
    foreach ($filePath in $FileList) {
        if (-not (Test-Path $filePath -PathType Leaf)) {
            Write-Host "���� �� ������: $filePath" -ForegroundColor Yellow
            $skippedCount++
            continue
        }
        
        $fileInfo = Get-Item $filePath
        $fileSize = "{0:N2} MB" -f ($fileInfo.Length / 1MB)
        
        if ($confirmIndividual) {
            Write-Host "`n����: $($fileInfo.Name)" -ForegroundColor Cyan
            Write-Host "������: $fileSize" -ForegroundColor Gray
            Write-Host "����: $filePath" -ForegroundColor Gray
            
            $confirmFile = Read-Host "������� ���� ����? (y/N)"
            if ($confirmFile -ne 'y' -and $confirmFile -ne 'Y' -and $confirmFile -ne '�' -and $confirmFile -ne '�') {
                Write-Host "���������� ����: $filePath" -ForegroundColor Yellow
                $skippedCount++
                continue
            }
        }
        
        try {
            Remove-Item -Path $filePath -Force -ErrorAction Stop
            Write-Host "�������: $filePath" -ForegroundColor Green
            $deletedCount++
        }
        catch {
            Write-Host "������ ��� �������� $filePath : $($_.Exception.Message)" -ForegroundColor Red
            $failedCount++
        }
    }
    
    # ����� �����������
    Write-Host "`n=== ���������� �������� ===" -ForegroundColor Yellow
    Write-Host "������� �������: $deletedCount" -ForegroundColor Green
    Write-Host "�� ������� �������: $failedCount" -ForegroundColor Red
    Write-Host "���������: $skippedCount" -ForegroundColor Yellow
    Write-Host "����� ����������: $($FileList.Count)" -ForegroundColor Cyan
}

# ��������� ������� ��������
Remove-FilesWithConfirmation -FileList $filesToDelete
2. ���������� ������
powershell
# ������ ������ ��� ��������
$filesToDelete = [System.Collections.ArrayList]@(
    "C:\temp\file1.txt",
    "C:\temp\file2.log",
    "C:\temp\file3.tmp"
)

Write-Host "��������� ����� ����� �������:" -ForegroundColor Red
$filesToDelete | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }

$confirm = Read-Host "`n���������� ��������? (y/N)"

if ($confirm -eq 'y' -or $confirm -eq 'Y') {
    $successCount = 0
    $errorCount = 0
    
    foreach ($file in $filesToDelete) {
        if (Test-Path $file) {
            try {
                Remove-Item $file -Force -ErrorAction Stop
                Write-Host "������: $file" -ForegroundColor Green
                $successCount++
            }
            catch {
                Write-Host "������: $file - $($_.Exception.Message)" -ForegroundColor Red
                $errorCount++
            }
        }
        else {
            Write-Host "���� �� ������: $file" -ForegroundColor Yellow
            $errorCount++
        }
    }
    
    Write-Host "`n�������: $successCount, ������: $errorCount" -ForegroundColor Cyan
}
else {
    Write-Host "�������� ��������." -ForegroundColor Green
}
3. ������ � ������������
powershell
$filesToDelete = [System.Collections.ArrayList]@(
    "C:\temp\file1.txt",
    "C:\temp\file2.log"
)

$logFile = "C:\temp\deletion_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-Log {
    param($Message, $Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

Write-Log "=== ������ ��������� �������� ===" "Yellow"

# ���������� �����
Write-Log "����� ��� ��������:" "Cyan"
$filesToDelete | ForEach-Object { Write-Log "  - $_" "Gray" }

# �������������
$confirm = Read-Host "`n����������� �������� (y/N)"

if ($confirm -ne 'y' -and $confirm -ne 'Y') {
    Write-Log "�������� �������� �������������." "Green"
    exit
}

# ������� ��������
foreach ($file in $filesToDelete) {
    if (Test-Path $file -PathType Leaf) {
        try {
            $fileInfo = Get-Item $file
            $size = "{0:N2} MB" -f ($fileInfo.Length / 1MB)
            
            Remove-Item $file -Force -ErrorAction Stop
            Write-Log "�����: $file ($size)" "Green"
        }
        catch {
            Write-Log "������: $file - $($_.Exception.Message)" "Red"
        }
    }
    else {
        Write-Log "�� ������: $file" "Yellow"
    }
}

Write-Log "=== ��������� �������� ��������� ===" "Yellow"
Write-Log "��� �������� �: $logFile" "Cyan"
4. ������� ��� ������������� �������������
powershell
function Invoke-SafeFileDeletion {
    param(
        [System.Collections.ArrayList]$FilePaths,
        [switch]$ConfirmEachFile,
        [string]$LogPath = ""
    )
    
    # ������� ��� ���� ���� ������
    if ($LogPath) {
        $logStream = [System.IO.StreamWriter]::new($LogPath, $true)
        $logStream.WriteLine("$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - ������ �������� ������")
    }
    
    try {
        Write-Host "������� ������: $($FilePaths.Count)" -ForegroundColor Cyan
        
        # ����� �������������
        Write-Host "`n����� ��� ��������:" -ForegroundColor Yellow
        $FilePaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        
        $confirm = Read-Host "`n���������� ��������? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "��������." -ForegroundColor Green
            if ($LogPath) { $logStream.WriteLine("�������� �������������") }
            return
        }
        
        $results = @{
            Deleted = 0
            Failed = 0
            Skipped = 0
        }
        
        # �������� ������
        foreach ($file in $FilePaths) {
            if (-not (Test-Path $file -PathType Leaf)) {
                $msg = "���� �� ������: $file"
                Write-Host $msg -ForegroundColor Yellow
                if ($LogPath) { $logStream.WriteLine($msg) }
                $results.Skipped++
                continue
            }
            
            if ($ConfirmEachFile) {
                $fileConfirm = Read-Host "������� ���� '$file'? (y/N)"
                if ($fileConfirm -ne 'y' -and $fileConfirm -ne 'Y') {
                    $msg = "��������: $file"
                    Write-Host $msg -ForegroundColor Yellow
                    if ($LogPath) { $logStream.WriteLine($msg) }
                    $results.Skipped++
                    continue
                }
            }
            
            try {
                Remove-Item $file -Force -ErrorAction Stop
                $msg = "������: $file"
                Write-Host $msg -ForegroundColor Green
                if ($LogPath) { $logStream.WriteLine($msg) }
                $results.Deleted++
            }
            catch {
                $msg = "������: $file - $($_.Exception.Message)"
                Write-Host $msg -ForegroundColor Red
                if ($LogPath) { $logStream.WriteLine($msg) }
                $results.Failed++
            }
        }
        
        # �����
        $summary = "����: ������� $($results.Deleted), ������ $($results.Failed), ��������� $($results.Skipped)"
        Write-Host "`n$summary" -ForegroundColor Cyan
        if ($LogPath) { $logStream.WriteLine($summary) }
        
    }
    finally {
        if ($LogPath) {
            $logStream.WriteLine("$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - ����������")
            $logStream.Close()
            Write-Host "��� ��������: $LogPath" -ForegroundColor Gray
        }
    }
}

# ������������� �������
$files = [System.Collections.ArrayList]@("C:\temp\test1.txt", "C:\temp\test2.txt")
Invoke-SafeFileDeletion -FilePaths $files -ConfirmEachFile -LogPath "C:\temp\deletion_log.txt"
5. ������ � ��������� ������� �� �����
powershell
# �������� ����� �� ����� ��� ��������
$folderPath = "C:\temp\old_files"
$filesToDelete = [System.Collections.ArrayList]@()

if (Test-Path $folderPath) {
    Get-ChildItem $folderPath -File | ForEach-Object {
        [void]$filesToDelete.Add($_.FullName)
    }
}

if ($filesToDelete.Count -gt 0) {
    Write-Host "������� ������ � $folderPath : $($filesToDelete.Count)" -ForegroundColor Cyan
    
    $confirm = Read-Host "������� ��� ��� �����? (y/N)"
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        foreach ($file in $filesToDelete) {
            try {
                Remove-Item $file -Force
                Write-Host "������: $(Split-Path $file -Leaf)" -ForegroundColor Green
            }
            catch {
                Write-Host "������ ��� �������� $file" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host "�������� ��������" -ForegroundColor Yellow
    }
}
else {
    Write-Host "����� ��� �������� �� �������" -ForegroundColor Yellow
}


--------------------------------------------------------------------------
�������! ��� ������ �������, ������� ������� ����� �� ������� $comparison ��� SideIndicator -eq '=>' � ��������������:

1. �������� ������ ��������
powershell
# �����������, ��� $comparison ��� �������� ���������� ���������
# $comparison = Compare-Object -ReferenceObject $list1 -DifferenceObject $list2

function Remove-FilesFromComparison {
    param(
        $ComparisonResult,
        [string]$BasePath = "",
        [switch]$ConfirmEachFile
    )
    
    # ��������� ����� ��� �������� (������ ��, ��� ���� �� ������ �������)
    $filesToDelete = $ComparisonResult | 
                    Where-Object { $_.SideIndicator -eq '=>' } | 
                    Select-Object -ExpandProperty InputObject
    
    if ($filesToDelete.Count -eq 0) {
        Write-Host "��� ������ ��� ��������." -ForegroundColor Green
        return
    }
    
    Write-Host "=== ����� ��� �������� ===" -ForegroundColor Red
    Write-Host "������� ������ ��� ��������: $($filesToDelete.Count)" -ForegroundColor Yellow
    
    # ���������� ������ ������
    $filesToDelete | ForEach-Object { 
        $filePath = if ($BasePath) { Join-Path $BasePath $_ } else { $_ }
        Write-Host "  - $filePath" -ForegroundColor Gray 
    }
    
    # ������ ������ �������������
    Write-Host "`n" -NoNewline
    $confirm = Read-Host "�� �������, ��� ������ ������� ��� �����? (y/N)"
    
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "�������� ��������." -ForegroundColor Green
        return
    }
    
    $results = @{
        Deleted = 0
        Failed = 0
        Skipped = 0
    }
    
    # ������� ��������
    foreach ($fileName in $filesToDelete) {
        # ��������� ������ ���� � �����
        $filePath = if ($BasePath) { Join-Path $BasePath $fileName } else { $fileName }
        
        # ��������� ������������� �����
        if (-not (Test-Path $filePath -PathType Leaf)) {
            Write-Host "���� �� ������: $filePath" -ForegroundColor Yellow
            $results.Skipped++
            continue
        }
        
        # ������������� ��� ������� ����� ���� ��������
        if ($ConfirmEachFile) {
            $fileInfo = Get-Item $filePath
            $fileSize = "{0:N2} MB" -f ($fileInfo.Length / 1MB)
            
            Write-Host "`n����: $fileName" -ForegroundColor Cyan
            Write-Host "������: $fileSize" -ForegroundColor Gray
            Write-Host "����: $filePath" -ForegroundColor Gray
            
            $fileConfirm = Read-Host "������� ���� ����? (y/N)"
            if ($fileConfirm -ne 'y' -and $fileConfirm -ne 'Y') {
                Write-Host "���������: $filePath" -ForegroundColor Yellow
                $results.Skipped++
                continue
            }
        }
        
        # ������� ����
        try {
            Remove-Item -Path $filePath -Force -ErrorAction Stop
            Write-Host "�������: $filePath" -ForegroundColor Green
            $results.Deleted++
        }
        catch {
            Write-Host "������: $filePath - $($_.Exception.Message)" -ForegroundColor Red
            $results.Failed++
        }
    }
    
    # ����� �����������
    Write-Host "`n=== ���������� �������� ===" -ForegroundColor Yellow
    Write-Host "������� �������: $($results.Deleted)" -ForegroundColor Green
    Write-Host "�� ������� �������: $($results.Failed)" -ForegroundColor Red
    Write-Host "���������: $($results.Skipped)" -ForegroundColor Yellow
    Write-Host "����� ����������: $($filesToDelete.Count)" -ForegroundColor Cyan
}

# ������������� �������
Remove-FilesFromComparison -ComparisonResult $comparison -BasePath "C:\Your\Folder" -ConfirmEachFile
2. ���������� ������
powershell
# �������� ����� ��� �������� �� ���������
$filesToDelete = $comparison | 
                Where-Object { $_.SideIndicator -eq '=>' } | 
                Select-Object -ExpandProperty InputObject

if ($filesToDelete.Count -eq 0) {
    Write-Host "��� ������ ��� ��������." -ForegroundColor Green
    exit
}

Write-Host "����� ������� ��������� �����:" -ForegroundColor Red
$filesToDelete | ForEach-Object { 
    $fullPath = Join-Path "C:\Your\Folder" $_
    Write-Host "  - $fullPath" -ForegroundColor Yellow 
}

$confirm = Read-Host "`n����������� �������� (y/N)"

if ($confirm -eq 'y' -or $confirm -eq 'Y') {
    $success = 0
    $errors = 0
    
    foreach ($file in $filesToDelete) {
        $fullPath = Join-Path "C:\Your\Folder" $file
        
        if (Test-Path $fullPath) {
            try {
                Remove-Item $fullPath -Force
                Write-Host "������: $fullPath" -ForegroundColor Green
                $success++
            }
            catch {
                Write-Host "������: $fullPath" -ForegroundColor Red
                $errors++
            }
        }
        else {
            Write-Host "�� ������: $fullPath" -ForegroundColor Yellow
            $errors++
        }
    }
    
    Write-Host "`n�������: $success, ������: $errors" -ForegroundColor Cyan
}
else {
    Write-Host "�������� ��������." -ForegroundColor Green
}
3. ������ � ������������
powershell
function Remove-ComparationFilesWithLog {
    param(
        $ComparisonResult,
        [string]$TargetFolder,
        [string]$LogFile = "deletion_log.txt"
    )
    
    $filesToDelete = $ComparisonResult | 
                    Where-Object { $_.SideIndicator -eq '=>' } | 
                    Select-Object -ExpandProperty InputObject
    
    if ($filesToDelete.Count -eq 0) {
        Write-Host "��� ������ ��� ��������." -ForegroundColor Green
        return
    }
    
    # ������� ���
    $logContent = @()
    $logContent += "=== ��� �������� ������ ==="
    $logContent += "����: $(Get-Date)"
    $logContent += "�����: $TargetFolder"
    $logContent += "������ ��� ��������: $($filesToDelete.Count)"
    $logContent += ""
    
    Write-Host "������� ������ ��� ��������: $($filesToDelete.Count)" -ForegroundColor Yellow
    
    # �������������
    $filesToDelete | ForEach-Object { 
        $fullPath = Join-Path $TargetFolder $_
        Write-Host "  - $fullPath" -ForegroundColor Gray 
    }
    
    $confirm = Read-Host "`n���������� ��������? (y/N)"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        $logContent += "�������� �������� �������������"
        $logContent | Out-File $LogFile -Encoding UTF8
        Write-Host "��������." -ForegroundColor Green
        return
    }
    
    # �������� ������
    $results = @{ Deleted = 0; Failed = 0 }
    
    foreach ($file in $filesToDelete) {
        $fullPath = Join-Path $TargetFolder $file
        
        if (Test-Path $fullPath -PathType Leaf) {
            try {
                Remove-Item $fullPath -Force -ErrorAction Stop
                $msg = "�������: $fullPath"
                Write-Host $msg -ForegroundColor Green
                $logContent += $msg
                $results.Deleted++
            }
            catch {
                $msg = "������: $fullPath - $($_.Exception.Message)"
                Write-Host $msg -ForegroundColor Red
                $logContent += $msg
                $results.Failed++
            }
        }
        else {
            $msg = "�� ������: $fullPath"
            Write-Host $msg -ForegroundColor Yellow
            $logContent += $msg
            $results.Failed++
        }
    }
    
    # ���������� ����
    $logContent += ""
    $logContent += "����: ������� $($results.Deleted), ������ $($results.Failed)"
    $logContent | Out-File $LogFile -Encoding UTF8
    
    Write-Host "`n��� �������� �: $LogFile" -ForegroundColor Cyan
    Write-Host "�������: $($results.Deleted), ������: $($results.Failed)" -ForegroundColor Yellow
}

# �������������
Remove-ComparationFilesWithLog -ComparisonResult $comparison -TargetFolder "C:\Your\Folder" -LogFile "deletion_results.log"
4. ������ ������ workflow
powershell
# ������ ������� workflow �� ��������� ������ �� ��������
$folderPath = "C:\Your\Folder"

# �������� ������� ����� � �����
$currentFiles = [System.Collections.ArrayList]@(
    (Get-ChildItem $folderPath -File).Name
)

# �����������, � ��� ���� ������ ������, ������� ������ ��������
$requiredFiles = [System.Collections.ArrayList]@('important.txt', 'config.ini', 'data.json')

# ����������
$comparison = Compare-Object -ReferenceObject $requiredFiles -DifferenceObject $currentFiles

Write-Host "=== ������ ������ � ����� ===" -ForegroundColor Yellow
Write-Host "��������� �����: $($requiredFiles.Count)" -ForegroundColor Green
Write-Host "������� �����: $($currentFiles.Count)" -ForegroundColor Cyan

# ����� ��� �������� (���� � �����, �� �� � required)
$filesToDelete = $comparison | 
                Where-Object { $_.SideIndicator -eq '=>' } | 
                Select-Object -ExpandProperty InputObject

if ($filesToDelete.Count -gt 0) {
    Write-Host "`n����� ��� ��������: $($filesToDelete.Count)" -ForegroundColor Red
    $filesToDelete | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    
    $confirm = Read-Host "`n������� ������ �����? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        foreach ($file in $filesToDelete) {
            $fullPath = Join-Path $folderPath $file
            try {
                Remove-Item $fullPath -Force
                Write-Host "������: $file" -ForegroundColor Green
            }
            catch {
                Write-Host "������ ��� �������� $file" -ForegroundColor Red
            }
        }
    }
}
else {
    Write-Host "��� ������ ������ ��� ��������." -ForegroundColor Green
}
-----------------------------------------------------------------------

------------------------------------------------------------------------
1. ������� ��� ��������� � ���������� VersionList.txt
powershell
function Update-VersionListFile {
    param(
        [System.Collections.ArrayList]$CurrentFileList,
        [string]$VersionListPath = "VersionList.txt",
        [switch]$BackupOriginal,
        [switch]$WhatIf
    )
    
    Write-Host "=== ���������� ����� VersionList.txt ===" -ForegroundColor Yellow
    
    # ��������� ������������� ����� VersionList.txt
    if (-not (Test-Path $VersionListPath -PathType Leaf)) {
        Write-Host "���� $VersionListPath �� ������. ������� �����..." -ForegroundColor Yellow
        $CurrentFileList | Out-File -FilePath $VersionListPath -Encoding UTF8
        Write-Host "������ ����� ���� $VersionListPath � $($CurrentFileList.Count) �������" -ForegroundColor Green
        return
    }
    
    # ������ ������� ������ �� �����
    $versionListContent = Get-Content $VersionListPath -Encoding UTF8 -ErrorAction Stop
    $versionListFiles = [System.Collections.ArrayList]@($versionListContent | Where-Object { $_ -and $_.Trim() -ne '' })
    
    Write-Host "������ � VersionList.txt: $($versionListFiles.Count)" -ForegroundColor Cyan
    Write-Host "������� ������ � �����: $($CurrentFileList.Count)" -ForegroundColor Cyan
    
    # ���������� �������
    $comparison = Compare-Object -ReferenceObject $versionListFiles -DifferenceObject $CurrentFileList
    
    $filesToAdd = $comparison | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
    $filesToRemove = $comparison | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    
    if ($filesToAdd.Count -eq 0 -and $filesToRemove.Count -eq 0) {
        Write-Host "���� VersionList.txt ��������. ��������� �� ���������." -ForegroundColor Green
        return
    }
    
    # ���������� ���������
    if ($filesToAdd.Count -gt 0) {
        Write-Host "`n����� ��������� ����� ($($filesToAdd.Count)):" -ForegroundColor Green
        $filesToAdd | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
    }
    
    if ($filesToRemove.Count -gt 0) {
        Write-Host "`n����� ������� ����� ($($filesToRemove.Count)):" -ForegroundColor Red
        $filesToRemove | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    
    # ������ �������������
    if (-not $WhatIf) {
        Write-Host "`n" -NoNewline
        $confirm = Read-Host "�������� ���� VersionList.txt? (y/N)"
        
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "���������� ��������." -ForegroundColor Yellow
            return
        }
    }
    
    # ������� backup ���� �����
    if ($BackupOriginal -and -not $WhatIf) {
        $backupPath = "VersionList_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        Copy-Item -Path $VersionListPath -Destination $backupPath -Force
        Write-Host "������ backup: $backupPath" -ForegroundColor Gray
    }
    
    if ($WhatIf) {
        Write-Host "`n[WHATIF] ���� VersionList.txt ����� ��������:" -ForegroundColor Magenta
        Write-Host "���������: $($filesToAdd.Count) ������" -ForegroundColor Green
        Write-Host "�������: $($filesToRemove.Count) ������" -ForegroundColor Red
        return
    }
    
    # ��������� ����
    try {
        $CurrentFileList | Sort-Object | Out-File -FilePath $VersionListPath -Encoding UTF8 -Force
        Write-Host "`n���� VersionList.txt ������� ��������!" -ForegroundColor Green
        Write-Host "��������� ������: $($filesToAdd.Count)" -ForegroundColor Green
        Write-Host "������� ������: $($filesToRemove.Count)" -ForegroundColor Red
        Write-Host "����� � �����: $($CurrentFileList.Count) ������" -ForegroundColor Cyan
        
    }
    catch {
        Write-Host "������ ��� ���������� �����: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ������������� �������
$currentFiles = [System.Collections.ArrayList]@((Get-ChildItem -Path "C:\Your\Folder" -File).Name)
Update-VersionListFile -CurrentFileList $currentFiles -BackupOriginal
2. ����������� ������ � ��������������� �������
powershell
function Sync-VersionList {
    param(
        [string]$SourceFolder,
        [string]$VersionListPath = "VersionList.txt",
        [switch]$IncludeSubfolders,
        [switch]$Force,
        [switch]$DryRun,
        [string[]]$ExcludeExtensions = @('.tmp', '.log', '.bak')
    )
    
    Write-Host "=== ������������� VersionList.txt ===" -ForegroundColor Yellow
    
    # �������� ������� �����
    $getChildItemParams = @{
        Path = $SourceFolder
        File = $true
    }
    
    if ($IncludeSubfolders) {
        $getChildItemParams.Recurse = $true
    }
    
    $allFiles = Get-ChildItem @getChildItemParams
    $currentFiles = [System.Collections.ArrayList]@()
    
    foreach ($file in $allFiles) {
        $relativePath = if ($IncludeSubfolders) {
            $file.FullName.Substring($SourceFolder.Length).Trim('\')
        } else {
            $file.Name
        }
        
        # ���������� ����������� ����������
        if ($ExcludeExtensions -contains $file.Extension) {
            continue
        }
        
        [void]$currentFiles.Add($relativePath)
    }
    
    # ��������� ��� consistency
    $currentFiles = [System.Collections.ArrayList]@($currentFiles | Sort-Object)
    
    # ���������/������� VersionList.txt
    if (-not (Test-Path $VersionListPath)) {
        Write-Host "���� $VersionListPath �� ������. �������..." -ForegroundColor Yellow
        $currentFiles | Out-File -FilePath $VersionListPath -Encoding UTF8
        Write-Host "������ ����� ���� � $($currentFiles.Count) �������" -ForegroundColor Green
        return @{ Status = "Created"; FileCount = $currentFiles.Count }
    }
    
    # ������ ������������ ������
    $versionListContent = Get-Content $VersionListPath -Encoding UTF8
    $versionListFiles = [System.Collections.ArrayList]@($versionListContent | Where-Object { $_ -and $_.Trim() -ne '' } | Sort-Object)
    
    # ����������
    $comparison = Compare-Object -ReferenceObject $versionListFiles -DifferenceObject $currentFiles
    
    $filesToAdd = $comparison | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
    $filesToRemove = $comparison | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    
    # ���� ��� ���������
    if ($filesToAdd.Count -eq 0 -and $filesToRemove.Count -eq 0) {
        Write-Host "VersionList.txt ��������. ��������� �� ���������." -ForegroundColor Green
        return @{ Status = "NoChanges"; FileCount = $currentFiles.Count }
    }
    
    # ���������� ���������
    Write-Host "`n���������� ���������:" -ForegroundColor Cyan
    Write-Host "������ � VersionList.txt: $($versionListFiles.Count)" -ForegroundColor Gray
    Write-Host "������ � �����: $($currentFiles.Count)" -ForegroundColor Gray
    
    if ($filesToAdd.Count -gt 0) {
        Write-Host "`n����� ����� ($($filesToAdd.Count)):" -ForegroundColor Green
        $filesToAdd | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
    }
    
    if ($filesToRemove.Count -gt 0) {
        Write-Host "`n��������� ����� ($($filesToRemove.Count)):" -ForegroundColor Red
        $filesToRemove | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    
    # Dry run mode
    if ($DryRun) {
        Write-Host "`n[DRY RUN] ����� �������������. ���� �� ����� �������." -ForegroundColor Magenta
        return @{
            Status = "DryRun"
            FilesToAdd = $filesToAdd
            FilesToRemove = $filesToRemove
            CurrentCount = $currentFiles.Count
        }
    }
    
    # ������ ������������� (���� �� �������������� �����)
    if (-not $Force) {
        Write-Host "`n" -NoNewline
        $confirm = Read-Host "�������� VersionList.txt? (y/N)"
        
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "������������� ��������." -ForegroundColor Yellow
            return @{ Status = "Cancelled" }
        }
    }
    
    # ������� backup
    $backupPath = "VersionList_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    Copy-Item -Path $VersionListPath -Destination $backupPath -Force
    Write-Host "������ backup: $backupPath" -ForegroundColor Gray
    
    # ��������� ����
    try {
        $currentFiles | Out-File -FilePath $VersionListPath -Encoding UTF8 -Force
        Write-Host "`nVersionList.txt ������� ��������!" -ForegroundColor Green
        Write-Host "���������: $($filesToAdd.Count) ������" -ForegroundColor Green
        Write-Host "�������: $($filesToRemove.Count) ������" -ForegroundColor Red
        Write-Host "�����: $($currentFiles.Count) ������" -ForegroundColor Cyan
        
        return @{
            Status = "Updated"
            Added = $filesToAdd.Count
            Removed = $filesToRemove.Count
            Total = $currentFiles.Count
            Backup = $backupPath
        }
    }
    catch {
        Write-Host "������ ��� ����������: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Status = "Error"; Error = $_.Exception.Message }
    }
}

# �������������
$result = Sync-VersionList -SourceFolder "C:\Your\Folder" -VersionListPath "VersionList.txt" -Force
3. ������� ��� �������� �����������
powershell
function Test-VersionListConsistency {
    param(
        [string]$FolderPath,
        [string]$VersionListPath = "VersionList.txt"
    )
    
    if (-not (Test-Path $VersionListPath)) {
        Write-Host "���� VersionList.txt �� ������!" -ForegroundColor Red
        return $false
    }
    
    # �������� ������� �����
    $currentFiles = [System.Collections.ArrayList]@((Get-ChildItem -Path $FolderPath -File).Name)
    $versionListFiles = [System.Collections.ArrayList]@((Get-Content $VersionListPath) | Where-Object { $_ -and $_.Trim() -ne '' })
    
    # ����������
    $comparison = Compare-Object -ReferenceObject $versionListFiles -DifferenceObject $currentFiles
    
    $missingInList = $comparison | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
    $missingInFolder = $comparison | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    
    $isConsistent = ($missingInList.Count -eq 0 -and $missingInFolder.Count -eq 0)
    
    if ($isConsistent) {
        Write-Host "? VersionList.txt ��������" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "? ���������� �����������:" -ForegroundColor Red
        
        if ($missingInList.Count -gt 0) {
            Write-Host "����� � �����, �� ����������� � VersionList.txt ($($missingInList.Count)):" -ForegroundColor Yellow
            $missingInList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        }
        
        if ($missingInFolder.Count -gt 0) {
            Write-Host "����� � VersionList.txt, �� ����������� � ����� ($($missingInFolder.Count)):" -ForegroundColor Yellow
            $missingInFolder | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
        }
        
        return $false
    }
}

# �������� consistency
$isConsistent = Test-VersionListConsistency -FolderPath "C:\Your\Folder"
if (-not $isConsistent) {
    $update = Read-Host "������ ��������� �����������? (y/N)"
    if ($update -eq 'y' -or $update -eq 'Y') {
        $currentFiles = [System.Collections.ArrayList]@((Get-ChildItem -Path "C:\Your\Folder" -File).Name)
        Update-VersionListFile -CurrentFileList $currentFiles -BackupOriginal
    }
}
4. ���������� � ���������� �������� ��������
powershell
# ������ workflow: ��������� + �������� + ���������� VersionList.txt
$folderPath = "C:\Your\Folder"
$versionListPath = "VersionList.txt"

# 1. �������� ������� �����
$currentFiles = [System.Collections.ArrayList]@((Get-ChildItem -Path $folderPath -File).Name)

# 2. ������ VersionList.txt (���� ����������)
if (Test-Path $versionListPath) {
    $versionListFiles = [System.Collections.ArrayList]@((Get-Content $versionListPath) | Where-Object { $_ -and $_.Trim() -ne '' })
    
    # 3. ���������� ��� �������� ������ ������
    $comparison = Compare-Object -ReferenceObject $versionListFiles -DifferenceObject $currentFiles
    $filesToDelete = $comparison | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
    
    # 4. ������� ������ �����
    if ($filesToDelete.Count -gt 0) {
        Write-Host "������� ������ ������: $($filesToDelete.Count)" -ForegroundColor Red
        $confirm = Read-Host "������� ������ �����? (y/N)"
        
        if ($confirm -eq 'y' -or $confirm -eq 'Y') {
            foreach ($file in $filesToDelete) {
                $fullPath = Join-Path $folderPath $file
                try {
                    Remove-Item $fullPath -Force
                    Write-Host "������: $file" -ForegroundColor Green
                }
                catch {
                    Write-Host "������ ��� �������� $file" -ForegroundColor Red
                }
            }
        }
    }
}

# 5. ��������� VersionList.txt
Update-VersionListFile -CurrentFileList $currentFiles -BackupOriginal


-------------
-------------
-------------
1. ������������ ������ � ����������� .txt ������
powershell
# ������������ ������ (�������� ���):
# $versionListFiles = [System.Collections.ArrayList]@($versionListContent | Where-Object { $_ -and $_.Trim() -ne '' })

# ������������ ������:
$versionListFiles = [System.Collections.ArrayList]@(
    $versionListContent | 
    Where-Object { $_ -and $_.Trim() -ne '' } |
    ForEach-Object {
        if ($_ -match '^(.*?\.txt)') {
            $matches[1]  # ����� ������ ����� �� .txt (������� .txt)
        }
    } |
    Where-Object { $_ }  # ������� ������ ��������
)
2. ������ ������������ ��� �������
powershell
function Update-VersionListFile {
    param(
        [System.Collections.ArrayList]$CurrentFileList,
        [string]$VersionListPath = "VersionList.txt",
        [switch]$BackupOriginal,
        [switch]$WhatIf
    )
    
    Write-Host "=== ���������� ����� VersionList.txt ===" -ForegroundColor Yellow
    
    # ��������� ������������� ����� VersionList.txt
    if (-not (Test-Path $VersionListPath -PathType Leaf)) {
        Write-Host "���� $VersionListPath �� ������. ������� �����..." -ForegroundColor Yellow
        
        # ��������� ������ .txt ����� ��� ������ �����
        $txtFilesOnly = $CurrentFileList | Where-Object { $_ -like '*.txt' }
        $txtFilesOnly | Out-File -FilePath $VersionListPath -Encoding UTF8
        
        Write-Host "������ ����� ���� $VersionListPath � $($txtFilesOnly.Count) .txt �������" -ForegroundColor Green
        return
    }
    
    # ������ ������� ������ �� �����
    $versionListContent = Get-Content $VersionListPath -Encoding UTF8 -ErrorAction Stop
    
    # ���������� ������ - ����� ������ �������� �� .txt
    $versionListFiles = [System.Collections.ArrayList]@(
        $versionListContent | 
        Where-Object { $_ -and $_.Trim() -ne '' } |
        ForEach-Object {
            if ($_ -match '^(.*?\.txt)') {
                $matches[1]  # ����� ������ ����� �� .txt (������� .txt)
            }
        } |
        Where-Object { $_ }  # ������� ������ ��������
    )
    
    Write-Host "������ � VersionList.txt: $($versionListFiles.Count)" -ForegroundColor Cyan
    Write-Host "������� ������ � �����: $($CurrentFileList.Count)" -ForegroundColor Cyan
    
    # ���������� �������
    $comparison = Compare-Object -ReferenceObject $versionListFiles -DifferenceObject $CurrentFileList
    
    $filesToAdd = $comparison | Where-Object { $_.SideIndicator -eq '=>' } | Select-Object -ExpandProperty InputObject
    $filesToRemove = $comparison | Where-Object { $_.SideIndicator -eq '<=' } | Select-Object -ExpandProperty InputObject
    
    if ($filesToAdd.Count -eq 0 -and $filesToRemove.Count -eq 0) {
        Write-Host "���� VersionList.txt ��������. ��������� �� ���������." -ForegroundColor Green
        return
    }
    
    # ���������� ���������
    if ($filesToAdd.Count -gt 0) {
        Write-Host "`n����� ��������� ����� ($($filesToAdd.Count)):" -ForegroundColor Green
        $filesToAdd | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
    }
    
    if ($filesToRemove.Count -gt 0) {
        Write-Host "`n����� ������� ����� ($($filesToRemove.Count)):" -ForegroundColor Red
        $filesToRemove | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    
    # ������ �������������
    if (-not $WhatIf) {
        Write-Host "`n" -NoNewline
        $confirm = Read-Host "�������� ���� VersionList.txt? (y/N)"
        
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "���������� ��������." -ForegroundColor Yellow
            return
        }
    }
    
    # ������� backup ���� �����
    if ($BackupOriginal -and -not $WhatIf) {
        $backupPath = "VersionList_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        Copy-Item -Path $VersionListPath -Destination $backupPath -Force
        Write-Host "������ backup: $backupPath" -ForegroundColor Gray
    }
    
    if ($WhatIf) {
        Write-Host "`n[WHATIF] ���� VersionList.txt ����� ��������:" -ForegroundColor Magenta
        Write-Host "���������: $($filesToAdd.Count) ������" -ForegroundColor Green
        Write-Host "�������: $($filesToRemove.Count) ������" -ForegroundColor Red
        return
    }
    
    # ��������� ���� (������ .txt �����)
    try {
        $txtFilesOnly = $CurrentFileList | Where-Object { $_ -like '*.txt' }
        $txtFilesOnly | Sort-Object | Out-File -FilePath $VersionListPath -Encoding UTF8 -Force
        
        Write-Host "`n���� VersionList.txt ������� ��������!" -ForegroundColor Green
        Write-Host "��������� ������: $($filesToAdd.Count)" -ForegroundColor Green
        Write-Host "������� ������: $($filesToRemove.Count)" -ForegroundColor Red
        Write-Host "����� � �����: $($txtFilesOnly.Count) .txt ������" -ForegroundColor Cyan
        
    }
    catch {
        Write-Host "������ ��� ���������� �����: $($_.Exception.Message)" -ForegroundColor Red
    }
}
3. �������������� �������� ����������
������� A: ������ ������ ���������� .txt
powershell
$versionListFiles = [System.Collections.ArrayList]@(
    $versionListContent | 
    Where-Object { $_ -and $_.Trim() -ne '' } |
    Where-Object { $_ -like '*.txt' }  # ������ ������, ��������������� �� .txt
)
������� B: ����� ������ ����� �� .txt (���� ���� ������ �������)
powershell
$versionListFiles = [System.Collections.ArrayList]@(
    $versionListContent | 
    Where-Object { $_ -and $_.Trim() -ne '' } |
    ForEach-Object {
        if ($_ -match '^([^\.]+\.txt)') {
            $matches[1]  # ����� ������ ���_�����.txt
        }
    } |
    Where-Object { $_ }
)
������� C: ���������� �� ����� � ������ ������ �����
powershell
$versionListFiles = [System.Collections.ArrayList]@(
    $versionListContent | 
    Where-Object { $_ -and $_.Trim() -ne '' } |
    ForEach-Object {
        $parts = $_ -split '\.'
        if ($parts -contains 'txt') {
            $index = [array]::IndexOf($parts, 'txt')
            if ($index -gt 0) {
                $parts[0..($index)] -join '.'  # ���������� ����� �� .txt �������
            }
        }
    } |
    Where-Object { $_ }
)
4. ������ �������������
powershell
# ������ ����������� VersionList.txt:
# file1.txt
# file2.txt backup
# file3.txt.old
# readme.md
# data.json

# ����� ��������� � ������ ������� ������:
# file1.txt
# file2.txt (����� �� " backup" �������������)
# file3.txt (����� �� ".old" �������������)

$versionListContent = @"
file1.txt
file2.txt backup
file3.txt.old
readme.md
data.json
script.ps1
"@ -split "`n"

# ��������� ������
$versionListFiles = [System.Collections.ArrayList]@(
    $versionListContent | 
    Where-Object { $_ -and $_.Trim() -ne '' } |
    ForEach-Object {
        if ($_ -match '^(.*?\.txt)') {
            $matches[1]  # ����� ������ ����� �� .txt (������� .txt)
        }
    } |
    Where-Object { $_ }
)

Write-Host "��������������� �����:"
$versionListFiles | ForEach-Object { Write-Host "  - $_" }