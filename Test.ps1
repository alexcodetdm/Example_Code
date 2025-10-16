Add-Type -TypeDefinition @"
using System;
using System.IO;

public class FileReader
{
    public static void ReadFile()
    {
        string filePath = @"C:\Temp\1.txt";
        
        try
        {
            if (File.Exists(filePath))
            {
                string content = File.ReadAllText(filePath);
                Console.WriteLine("Содержимое файла:");
                Console.WriteLine(content);
            }
            else
            {
                Console.WriteLine("Файл " + filePath + " не найден!");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine("Ошибка: " + ex.Message);
        }
    }
}
"@ -Language CSharp

[FileReader]::ReadFile()