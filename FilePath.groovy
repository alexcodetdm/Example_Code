Вариант 1: Простой список файлов
groovy
import java.nio.file.Paths
import java.nio.file.Files

def getFilesList() {
    def folderPath = "/path/to/your/folder" // Укажите путь к вашей папке
    def folder = new File(folderPath)
    
    if (folder.exists() && folder.isDirectory()) {
        return folder.listFiles()
                .findAll { it.isFile() }
                .collect { it.name }
                .sort()
    } else {
        return ["Папка не найдена или недоступна"]
    }
}

return getFilesList()
Вариант 2: С указанием расширений
groovy
import java.nio.file.Paths
import java.nio.file.Files

def getFilesByExtension() {
    def folderPath = "/opt/files" // Укажите ваш путь
    def extensions = [".txt", ".json", ".yaml", ".yml"] // Нужные расширения
    
    def folder = new File(folderPath)
    
    if (folder.exists() && folder.isDirectory()) {
        return folder.listFiles()
                .findAll { file -> 
                    file.isFile() && extensions.any { file.name.toLowerCase().endsWith(it) }
                }
                .collect { it.name }
                .sort()
    } else {
        return ["ERROR: Directory not found - ${folderPath}"]
    }
}

return getFilesByExtension()
Вариант 3: С относительными путями (для workspace)
groovy
def getWorkspaceFiles() {
    // Для использования в jenk pipeline
    def workspacePath = "${WORKSPACE}" // Автоматически подставится workspace
    
    try {
        def folder = new File(workspacePath)
        if (folder.exists() && folder.isDirectory()) {
            def files = folder.listFiles()
                    .findAll { it.isFile() }
                    .collect { it.name }
                    .sort()
            
            return files ?: ["В папке нет файлов"]
        } else {
            return ["Workspace не доступен"]
        }
    } catch (Exception e) {
        return ["Ошибка: ${e.message}"]
    }
}

return getWorkspaceFiles()
Вариант 4: С подпапками
groovy
def getFilesRecursive() {
    def folderPath = "/var/lib/jenk/files"
    def folder = new File(folderPath)
    def filesList = []
    
    def collectFiles = { file ->
        if (file.isDirectory()) {
            file.eachFile { collectFiles(it) }
        } else if (file.isFile()) {
            filesList << file.name
        }
    }
    
    if (folder.exists() && folder.isDirectory()) {
        collectFiles(folder)
        return filesList.sort()
    } else {
        return ["Директория не найдена"]
    }
}

return getFilesRecursive()

--------------------------------------------------------------------------------------
Пример с параметром для пути:
groovy
// Этот скрипт можно использовать, если путь передается как параметр
def basePath = FOLDER_PATH ?: "/default/path" // FOLDER_PATH - другой параметр

def folder = new File(basePath)
if (folder.exists() && folder.isDirectory()) {
    return folder.listFiles()
            .findAll { it.isFile() }
            .collect { it.name }
            .sort()
} else {
    return ["Invalid path: ${basePath}"]
}
Для Windows:
groovy
def getWindowsFiles() {
    def folderPath = "C:\\jenk\\files" // Windows путь
    def folder = new File(folderPath)
    
    if (folder.exists() && folder.isDirectory()) {
        return folder.listFiles()
                .findAll { it.isFile() }
                .collect { it.name }
                .sort()
    } else {
        return ["Папка не найдена: ${folderPath}"]
    }
}

return getWindowsFiles()