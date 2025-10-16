Да, у Bitbucket есть REST API, который позволяет получить содержимое файла из конкретной ветки, включая мастер.

Основной метод API
text
GET /2.0/repositories/{workspace}/{repo_slug}/src/{branch}/{file_path}
Пример запроса
bash
curl -X GET \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  "https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/src/master/path/to/file.txt"
Параметры
{workspace} - имя рабочего пространства или пользователя

{repo_slug} - идентификатор репозитория

{branch} - имя ветки (например, master, main)

{file_path} - путь к файлу относительно корня репозитория

Аутентификация
Вы можете использовать:

Личный access token

OAuth

Basic auth (username:password)

Пример на Python
python
import requests

def get_file_content(workspace, repo_slug, branch, file_path, token):
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/src/{branch}/{file_path}"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    response = requests.get(url, headers=headers)
    
    if response.status_code == 200:
        return response.text
    else:
        raise Exception(f"Error: {response.status_code} - {response.text}")

# Использование
content = get_file_content(
    "your-workspace",
    "your-repo",
    "master", 
    "README.md",
    "your-access-token"
)
print(content)
Альтернативный метод
Также можно использовать метод для получения конкретного файла по хешу коммита:

text
GET /2.0/repositories/{workspace}/{repo_slug}/raw/{file_path}?at={branch}
Этот метод возвращает сырое содержимое файла без дополнительной информации.

выводит только 1500 строк а в файле больше
Да, у Bitbucket API есть ограничение на количество возвращаемых строк. Это известное ограничение. Вот несколько способов обойти его:

1. Использование параметра pagination
Bitbucket API использует пагинацию. Проверьте заголовки ответа или тело ответа на наличие ссылок на следующую страницу:

python
import requests

def get_large_file_content(workspace, repo_slug, branch, file_path, token):
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/src/{branch}/{file_path}"
    headers = {"Authorization": f"Bearer {token}"}
    
    all_content = []
    while url:
        response = requests.get(url, headers=headers)
        if response.status_code != 200:
            raise Exception(f"Error: {response.status_code} - {response.text}")
        
        # Добавляем содержимое текущей страницы
        all_content.append(response.text)
        
        # Проверяем наличие следующей страницы
        if 'next' in response.links:
            url = response.links['next']['url']
        else:
            url = None
    
    return ''.join(all_content)
2. Использование raw endpoint (рекомендуется)
Для больших файлов лучше использовать raw endpoint, который не имеет ограничений на размер:

python
import requests

def get_file_content_raw(workspace, repo_slug, branch, file_path, token):
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/src/{branch}/{file_path}"
    
    # Добавляем параметр для raw content
    params = {'format': 'meta'}  # или используйте raw endpoint ниже
    
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(url, headers=headers, params=params)
    return response.text
3. Альтернативный raw endpoint
python
def get_file_direct_raw(workspace, repo_slug, branch, file_path, token):
    # Этот endpoint возвращает чистое содержимое файла
    url = f"https://bitbucket.org/{workspace}/{repo_slug}/raw/{branch}/{file_path}"
    
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(url, headers=headers)
    return response.text
4. Использование Git команды (если возможно)
Если у вас есть доступ к репозиторию через Git:

bash
git clone https://x-token-auth:{token}@bitbucket.org/{workspace}/{repo_slug}.git
cd {repo_slug}
git checkout {branch}
cat {file_path}
5. Проверка размера файла перед загрузкой
python
def get_file_with_size_check(workspace, repo_slug, branch, file_path, token):
    # Сначала получаем информацию о файле
    info_url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/src/{branch}/{file_path}?format=meta"
    headers = {"Authorization": f"Bearer {token}"}
    
    info_response = requests.get(info_url, headers=headers)
    file_info = info_response.json()
    
    print(f"Размер файла: {file_info.get('size', 'Unknown')} bytes")
    
    # Затем загружаем содержимое
    return get_file_direct_raw(workspace, repo_slug, branch, file_path, token)
Рекомендую использовать метод №3 с raw endpoint - он наиболее надежен для больших файлов и не имеет ограничений на количество строк.

есть ли API для получения кодов tags из bitbucket ?
Да, у Bitbucket есть несколько API для работы с тегами (tags). Вот основные методы:

1. Получение списка всех тегов
text
GET /2.0/repositories/{workspace}/{repo_slug}/refs/tags
Пример:

python
import requests

def get_tags(workspace, repo_slug, token):
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/refs/tags"
    headers = {"Authorization": f"Bearer {token}"}
    
    tags = []
    while url:
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = response.json()
            tags.extend(data['values'])
            url = data.get('next')
        else:
            raise Exception(f"Error: {response.status_code}")
    
    return tags

# Использование
tags = get_tags("your-workspace", "your-repo", "your-token")
for tag in tags:
    print(f"Tag: {tag['name']}, Commit: {tag['target']['hash']}")
2. Получение информации о конкретном теге
text
GET /2.0/repositories/{workspace}/{repo_slug}/refs/tags/{tag_name}
Пример:

python
def get_tag_info(workspace, repo_slug, tag_name, token):
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/refs/tags/{tag_name}"
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response.json()
    else:
        raise Exception(f"Error: {response.status_code}")

tag_info = get_tag_info("workspace", "repo", "v1.0.0", "token")
3. Получение содержимого файла из конкретного тега
text
GET /2.0/repositories/{workspace}/{repo_slug}/src/{tag_name}/{file_path}
Пример:

python
def get_file_from_tag(workspace, repo_slug, tag_name, file_path, token):
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/src/{tag_name}/{file_path}"
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response.text
    else:
        raise Exception(f"Error: {response.status_code}")

# Получить README.md из тега v1.0.0
content = get_file_from_tag("workspace", "repo", "v1.0.0", "README.md", "token")
4. Raw содержимое файла из тега
text
GET /2.0/repositories/{workspace}/{repo_slug}/raw/{file_path}?at=refs%2Ftags%2F{tag_name}
Пример:

python
def get_raw_file_from_tag(workspace, repo_slug, tag_name, file_path, token):
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/raw/{file_path}"
    params = {'at': f'refs/tags/{tag_name}'}
    headers = {"Authorization": f"Bearer {token}"}
    
    response = requests.get(url, headers=headers, params=params)
    if response.status_code == 200:
        return response.text
    else:
        raise Exception(f"Error: {response.status_code}")

content = get_raw_file_from_tag("workspace", "repo", "v1.0.0", "package.json", "token")
5. Создание нового тега
text
POST /2.0/repositories/{workspace}/{repo_slug}/refs/tags
Пример:

python
def create_tag(workspace, repo_slug, tag_name, commit_hash, token):
    url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}/refs/tags"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    data = {
        "name": tag_name,
        "target": {
            "hash": commit_hash
        }
    }
    
    response = requests.post(url, headers=headers, json=data)
    return response.status_code == 201
6. Полный пример работы с тегами
python
import requests

class BitbucketTags:
    def __init__(self, workspace, repo_slug, token):
        self.workspace = workspace
        self.repo_slug = repo_slug
        self.token = token
        self.base_url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo_slug}"
    
    def get_all_tags(self):
        """Получить все теги репозитория"""
        url = f"{self.base_url}/refs/tags"
        headers = {"Authorization": f"Bearer {self.token}"}
        
        tags = []
        while url:
            response = requests.get(url, headers=headers)
            if response.status_code == 200:
                data = response.json()
                tags.extend(data['values'])
                url = data.get('next')
            else:
                raise Exception(f"Error: {response.status_code}")
        
        return tags
    
    def get_file_from_tag(self, tag_name, file_path):
        """Получить содержимое файла из конкретного тега"""
        url = f"{self.base_url}/src/{tag_name}/{file_path}"
        headers = {"Authorization": f"Bearer {self.token}"}
        
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            return response.text
        else:
            raise Exception(f"Error: {response.status_code}")
    
    def get_latest_tag(self):
        """Получить последний тег (по дате создания)"""
        tags = self.get_all_tags()
        if tags:
            # Сортируем по дате создания
            sorted_tags = sorted(tags, key=lambda x: x['date'], reverse=True)
            return sorted_tags[0]
        return None

# Использование
bb_tags = BitbucketTags("your-workspace", "your-repo", "your-token")

# Получить все теги
all_tags = bb_tags.get_all_tags()
for tag in all_tags:
    print(f"Tag: {tag['name']}")

# Получить файл из конкретного тега
content = bb_tags.get_file_from_tag("v1.0.0", "src/main.py")
Эти API позволяют полностью управлять тегами в Bitbucket и получать код из конкретных версий проекта.

приведи пример для получения tags из PowerShell
Вот примеры получения тегов из Bitbucket с использованием PowerShell:

1. Базовый пример - получение списка тегов
powershell
# Получение списка всех тегов
function Get-BitbucketTags {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    $allTags = @()
    
    do {
        Write-Host "Fetching: $url"
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
        
        $allTags += $response.values
        
        # Проверяем наличие следующей страницы
        if ($response.next) {
            $url = $response.next
        } else {
            $url = $null
        }
    } while ($url)
    
    return $allTags
}

# Использование
$tags = Get-BitbucketTags -Workspace "your-workspace" -RepoSlug "your-repo" -Token "your-token"

# Вывод результатов
$tags | ForEach-Object {
    Write-Host "Tag: $($_.name)" -ForegroundColor Green
    Write-Host "  Commit: $($_.target.hash)" -ForegroundColor Yellow
    Write-Host "  Date: $($_.date)" -ForegroundColor Cyan
    Write-Host "---"
}
2. Получение информации о конкретном теге
powershell
function Get-BitbucketTag {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$TagName,
        [string]$Token
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags/$TagName"
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
        return $response
    }
    catch {
        Write-Error "Error getting tag: $($_.Exception.Message)"
        return $null
    }
}

# Использование
$tagInfo = Get-BitbucketTag -Workspace "your-workspace" -RepoSlug "your-repo" -TagName "v1.0.0" -Token "your-token"
if ($tagInfo) {
    Write-Host "Tag Info:" -ForegroundColor Green
    $tagInfo | ConvertTo-Json -Depth 3
}
3. Получение файла из конкретного тега
powershell
function Get-FileFromTag {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$TagName,
        [string]$FilePath,
        [string]$Token
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/src/$TagName/$FilePath"
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
        return $response
    }
    catch {
        Write-Error "Error getting file: $($_.Exception.Message)"
        return $null
    }
}

# Использование
$fileContent = Get-FileFromTag -Workspace "your-workspace" -RepoSlug "your-repo" -TagName "v1.0.0" -FilePath "README.md" -Token "your-token"
if ($fileContent) {
    Write-Host "File content:" -ForegroundColor Green
    $fileContent
}
4. Полный пример с обработкой ошибок и выводом
powershell
# Полный скрипт для работы с тегами
function Get-BitbucketTagsDetailed {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Workspace,
        
        [Parameter(Mandatory=$true)]
        [string]$RepoSlug,
        
        [Parameter(Mandatory=$true)]
        [string]$Token,
        
        [string]$OutputFormat = "table"
    )
    
    # Базовая настройка
    $baseUrl = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug"
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    Write-Host "Fetching tags from $Workspace/$RepoSlug..." -ForegroundColor Yellow
    
    # Получаем все теги
    $url = "$baseUrl/refs/tags"
    $allTags = @()
    
    try {
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
            $allTags += $response.values
            $url = $response.next
        } while ($url)
        
        Write-Host "Found $($allTags.Count) tags" -ForegroundColor Green
        
        # Форматируем вывод
        $formattedTags = $allTags | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.name
                Commit = $_.target.hash.Substring(0, 12)
                Date = ([DateTime]$_.date).ToString("yyyy-MM-dd HH:mm:ss")
                Author = $_.target.author.raw
                Message = if ($_.target.message) { $_.target.message.Substring(0, 50) + "..." } else { "N/A" }
            }
        }
        
        # Вывод в зависимости от формата
        switch ($OutputFormat) {
            "table" { 
                $formattedTags | Format-Table -AutoSize 
            }
            "list" { 
                $formattedTags | Format-List 
            }
            "json" { 
                $formattedTags | ConvertTo-Json -Depth 2 
            }
            "csv" { 
                $formattedTags | Export-Csv -Path "tags.csv" -NoTypeInformation
                Write-Host "Tags exported to tags.csv" -ForegroundColor Green
            }
            default { 
                $formattedTags | Format-Table -AutoSize 
            }
        }
        
        return $formattedTags
    }
    catch {
        Write-Error "Failed to get tags: $($_.Exception.Message)"
        return $null
    }
}

# Использование
$tags = Get-BitbucketTagsDetailed -Workspace "your-workspace" -RepoSlug "your-repo" -Token "your-token" -OutputFormat "table"
5. Пример с Basic Authentication
powershell
# Если используете логин/пароль вместо токена
function Get-BitbucketTagsWithAuth {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Username,
        [string]$Password
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    
    # Создаем Basic Auth header
    $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$Username`:$Password"))
    $headers = @{
        "Authorization" = "Basic $base64Auth"
    }
    
    $allTags = @()
    
    do {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
        $allTags += $response.values
        $url = $response.next
    } while ($url)
    
    return $allTags
}

# Использование с логином/паролем
$tags = Get-BitbucketTagsWithAuth -Workspace "your-workspace" -RepoSlug "your-repo" -Username "your-username" -Password "your-password"
6. Экспорт тегов в файл
powershell
function Export-BitbucketTags {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [string]$OutputPath = "bitbucket_tags.json"
    )
    
    $tags = Get-BitbucketTags -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token
    
    # Экспортируем в JSON
    $tags | ConvertTo-Json -Depth 4 | Out-File -FilePath $OutputPath -Encoding UTF8
    
    Write-Host "Tags exported to $OutputPath" -ForegroundColor Green
    Write-Host "Total tags: $($tags.Count)" -ForegroundColor Yellow
}

# Использование
Export-BitbucketTags -Workspace "your-workspace" -RepoSlug "your-repo" -Token "your-token" -OutputPath "my_tags.json"
Запуск скрипта
Сохраните нужные функции в файл .ps1 и выполните:

powershell
# Точка входа скрипта
$workspace = "your-workspace"
$repo = "your-repository"
$token = "your-access-token"

# Получаем теги
$tags = Get-BitbucketTagsDetailed -Workspace $workspace -RepoSlug $repo -Token $token

# Выводим последние 5 тегов
$tags | Sort-Object Date -Descending | Select-Object -First 5 | Format-Table
Эти примеры покрывают основные сценарии работы с тегами Bitbucket через PowerShell с поддержкой пагинации и обработкой ошибок.

-----------------------------------------------------------------------------------------
Ошибка 404 означает, что ресурс не найден. Давайте разберем возможные причины и решения:

1. Проверка базовых параметров
powershell
function Test-BitbucketConnection {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token
    )
    
    # Проверяем существование репозитория
    $repoUrl = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug"
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    try {
        Write-Host "Проверяем репозиторий: $Workspace/$RepoSlug" -ForegroundColor Yellow
        $repoResponse = Invoke-RestMethod -Uri $repoUrl -Headers $headers -Method GET
        Write-Host "✅ Репозиторий найден: $($repoResponse.name)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Репозиторий не найден или нет доступа" -ForegroundColor Red
        Write-Host "Ошибка: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
2. Исправленная версия функции для получения тегов
powershell
function Get-BitbucketTagsFixed {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Workspace,
        
        [Parameter(Mandatory=$true)]
        [string]$RepoSlug,
        
        [Parameter(Mandatory=$true)]
        [string]$Token
    )
    
    # Сначала проверяем соединение
    if (-not (Test-BitbucketConnection -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token)) {
        return $null
    }
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    $allTags = @()
    
    try {
        Write-Host "Получаем теги..." -ForegroundColor Yellow
        
        do {
            Write-Host "Запрос: $url" -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
            
            if ($response.values) {
                $allTags += $response.values
                Write-Host "Получено $($response.values.Count) тегов" -ForegroundColor Green
            }
            
            # Проверяем наличие следующей страницы
            if ($response.next) {
                $url = $response.next
            } else {
                $url = $null
            }
        } while ($url)
        
        Write-Host "Всего получено тегов: $($allTags.Count)" -ForegroundColor Green
        return $allTags
    }
    catch {
        Write-Host "❌ Ошибка при получении тегов: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Статус код: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
        return $null
    }
}
3. Диагностика проблемы
powershell
function Debug-BitbucketAccess {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token
    )
    
    $baseUrl = "https://api.bitbucket.org/2.0/repositories"
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    Write-Host "=== ДИАГНОСТИКА BITBUCKET API ===" -ForegroundColor Cyan
    
    # 1. Проверяем список репозиториев в workspace
    try {
        $workspaceUrl = "$baseUrl/$Workspace"
        Write-Host "`n1. Проверяем workspace: $Workspace" -ForegroundColor Yellow
        $workspaceResponse = Invoke-RestMethod -Uri $workspaceUrl -Headers $headers
        Write-Host "✅ Workspace доступен" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Workspace не найден: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 2. Проверяем конкретный репозиторий
    try {
        $repoUrl = "$baseUrl/$Workspace/$RepoSlug"
        Write-Host "`n2. Проверяем репозиторий: $RepoSlug" -ForegroundColor Yellow
        $repoResponse = Invoke-RestMethod -Uri $repoUrl -Headers $headers
        Write-Host "✅ Репозиторий найден: $($repoResponse.name)" -ForegroundColor Green
        Write-Host "   Full Name: $($repoResponse.full_name)" -ForegroundColor Gray
        Write-Host "   Is Private: $($repoResponse.is_private)" -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Репозиторий не найден: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 3. Проверяем теги
    try {
        $tagsUrl = "$baseUrl/$Workspace/$RepoSlug/refs/tags"
        Write-Host "`n3. Проверяем endpoint тегов" -ForegroundColor Yellow
        $tagsResponse = Invoke-RestMethod -Uri $tagsUrl -Headers $headers
        Write-Host "✅ Endpoint тегов доступен" -ForegroundColor Green
        Write-Host "   Найдено тегов: $($tagsResponse.values.Count)" -ForegroundColor Gray
        Write-Host "   Pagination: $($tagsResponse.pagelen)" -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Endpoint тегов недоступен: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 4. Проверяем права доступа
    try {
        $userUrl = "https://api.bitbucket.org/2.0/user"
        Write-Host "`n4. Проверяем аутентификацию" -ForegroundColor Yellow
        $userResponse = Invoke-RestMethod -Uri $userUrl -Headers $headers
        Write-Host "✅ Аутентификация успешна" -ForegroundColor Green
        Write-Host "   Пользователь: $($userResponse.display_name)" -ForegroundColor Gray
        Write-Host "   Username: $($userResponse.username)" -ForegroundColor Gray
    }
    catch {
        Write-Host "❌ Ошибка аутентификации: $($_.Exception.Message)" -ForegroundColor Red
    }
}
4. Практическое использование с обработкой ошибок
powershell
# Основной скрипт
$Workspace = "your-workspace"  # Имя workspace/team, а не email!
$RepoSlug = "your-repository"  # Имя репозитория (slug)
$Token = "your-token"

Write-Host "Начинаем диагностику..." -ForegroundColor Cyan

# Запускаем диагностику
Debug-BitbucketAccess -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token

# Если диагностика прошла успешно, получаем теги
Write-Host "`nПолучаем теги..." -ForegroundColor Cyan
$tags = Get-BitbucketTagsFixed -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token

if ($tags) {
    Write-Host "`n=== НАЙДЕННЫЕ ТЕГИ ===" -ForegroundColor Green
    $tags | ForEach-Object {
        Write-Host "🏷️  $($_.name)" -ForegroundColor Yellow
        Write-Host "   📍 Commit: $($_.target.hash)" -ForegroundColor Gray
        Write-Host "   📅 Date: $($_.date)" -ForegroundColor Gray
        Write-Host "---"
    }
} else {
    Write-Host "❌ Теги не найдены или произошла ошибка" -ForegroundColor Red
}
5. Частые причины ошибки 404:
powershell
function Check-CommonIssues {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token
    )
    
    Write-Host "`n=== ПРОВЕРКА ЧАСТЫХ ПРОБЛЕМ ===" -ForegroundColor Cyan
    
    # 1. Проверяем формат workspace
    if ($Workspace -contains "@") {
        Write-Host "❌ Workspace не должен быть email!" -ForegroundColor Red
        Write-Host "   Используйте имя workspace/team, а не email" -ForegroundColor Yellow
    }
    
    # 2. Проверяем чувствительность к регистру
    Write-Host "`nПроверяем регистр символов..." -ForegroundColor Yellow
    Write-Host "   Workspace: $Workspace" -ForegroundColor Gray
    Write-Host "   Repo Slug: $RepoSlug" -ForegroundColor Gray
    
    # 3. Проверяем специальные символы
    if ($RepoSlug -match "[^a-zA-Z0-9\-_]") {
        Write-Host "❌ Repo slug содержит недопустимые символы" -ForegroundColor Red
    }
    
    # 4. Предлагаем получить список всех репозиториев
    Write-Host "`nЧтобы увидеть все доступные репозитории, выполните:" -ForegroundColor Yellow
    Write-Host "  Get-BitbucketRepos -Workspace `"$Workspace`" -Token `"***`"" -ForegroundColor White
}

# Функция для получения списка репозиториев
function Get-BitbucketRepos {
    param(
        [string]$Workspace,
        [string]$Token
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace"
    $headers = @{ "Authorization" = "Bearer $Token" }
    
    try {
        $repos = @()
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers
            $repos += $response.values
            $url = $response.next
        } while ($url)
        
        Write-Host "`nДоступные репозитории в $Workspace :" -ForegroundColor Green
        $repos | ForEach-Object {
            Write-Host "  📁 $($_.name) (slug: $($_.slug))" -ForegroundColor Yellow
        }
        
        return $repos
    }
    catch {
        Write-Host "❌ Ошибка: $($_.Exception.Message)" -ForegroundColor Red
    }
}
Запустите диагностику:
powershell
# Замените на ваши реальные данные
$Workspace = "your-actual-workspace-name"
$RepoSlug = "your-actual-repo-name" 
$Token = "your-actual-token"

# Сначала диагностика
Debug-BitbucketAccess -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token

# Если репозиторий не найден, посмотрите список доступных
Get-BitbucketRepos -Workspace $Workspace -Token $Token
Основные причины 404:

Неправильное имя workspace (используйте имя команды, а не email)

Неправильное имя репозитория (slug)

Нет прав доступа к репозиторию

Репозиторий не существует

Опечатки в URL
--------------------------------------------------------------------------------
---------------------------------------------------------------------------------


в Bitbucket API можно использовать различные параметры для фильтрации тегов. Вот основные способы:

1. Параметры пагинации и сортировки
powershell
function Get-BitbucketTagsWithPagination {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [int]$PageLen = 50,
        [int]$Page = 1,
        [string]$SortBy = "name"
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    
    $queryParams = @{
        "pagelen" = $PageLen
        "page" = $Page
        "sort" = $SortBy
    }
    
    $headers = @{
        "Authorization" = "Bearer $Token"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Body $queryParams
        return $response
    }
    catch {
        Write-Error "Ошибка: $($_.Exception.Message)"
        return $null
    }
}

# Использование
$tags = Get-BitbucketTagsWithPagination -Workspace "workspace" -RepoSlug "repo" -Token "token" -PageLen 100 -SortBy "-name"
2. Фильтрация по имени тега (шаблоны)
powershell
function Get-BitbucketTagsFiltered {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [string]$NameFilter = "*",
        [string]$StartsWith,
        [string]$EndsWith
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    $headers = @{ "Authorization" = "Bearer $Token" }
    
    $allTags = @()
    
    try {
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers
            $allTags += $response.values
            $url = $response.next
        } while ($url)
        
        # Применяем фильтры
        $filteredTags = $allTags
        
        if ($NameFilter -ne "*") {
            $filteredTags = $filteredTags | Where-Object { $_.name -like $NameFilter }
        }
        
        if ($StartsWith) {
            $filteredTags = $filteredTags | Where-Object { $_.name -like "$StartsWith*" }
        }
        
        if ($EndsWith) {
            $filteredTags = $filteredTags | Where-Object { $_.name -like "*$EndsWith" }
        }
        
        return $filteredTags
    }
    catch {
        Write-Error "Ошибка: $($_.Exception.Message)"
        return $null
    }
}

# Примеры использования
$v1Tags = Get-BitbucketTagsFiltered -Workspace "w" -RepoSlug "r" -Token "t" -StartsWith "v1"
$releaseTags = Get-BitbucketTagsFiltered -Workspace "w" -RepoSlug "r" -Token "t" -EndsWith "-release"
$specificTags = Get-BitbucketTagsFiltered -Workspace "w" -RepoSlug "r" -Token "t" -NameFilter "v1.2.*"
3. Фильтрация по дате
powershell
function Get-BitbucketTagsByDate {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [datetime]$FromDate,
        [datetime]$ToDate,
        [switch]$NewestFirst
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    $headers = @{ "Authorization" = "Bearer $Token" }
    
    $allTags = @()
    
    try {
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers
            $allTags += $response.values
            $url = $response.next
        } while ($url)
        
        # Фильтрация по дате
        if ($FromDate) {
            $allTags = $allTags | Where-Object { [datetime]$_.date -ge $FromDate }
        }
        
        if ($ToDate) {
            $allTags = $allTags | Where-Object { [datetime]$_.date -le $ToDate }
        }
        
        # Сортировка
        if ($NewestFirst) {
            $allTags = $allTags | Sort-Object { [datetime]$_.date } -Descending
        } else {
            $allTags = $allTags | Sort-Object { [datetime]$_.date }
        }
        
        return $allTags
    }
    catch {
        Write-Error "Ошибка: $($_.Exception.Message)"
        return $null
    }
}

# Использование
$recentTags = Get-BitbucketTagsByDate -Workspace "w" -RepoSlug "r" -Token "t" -FromDate (Get-Date).AddDays(-30) -NewestFirst
4. Поиск тегов по шаблону (регулярные выражения)
powershell
function Get-BitbucketTagsByPattern {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [string]$Pattern,
        [switch]$CaseSensitive
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    $headers = @{ "Authorization" = "Bearer $Token" }
    
    $allTags = @()
    
    try {
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers
            $allTags += $response.values
            $url = $response.next
        } while ($url)
        
        # Фильтрация по регулярному выражению
        if ($Pattern) {
            if ($CaseSensitive) {
                $allTags = $allTags | Where-Object { $_.name -cmatch $Pattern }
            } else {
                $allTags = $allTags | Where-Object { $_.name -match $Pattern }
            }
        }
        
        return $allTags
    }
    catch {
        Write-Error "Ошибка: $($_.Exception.Message)"
        return $null
    }
}

# Примеры использования
$semverTags = Get-BitbucketTagsByPattern -Workspace "w" -RepoSlug "r" -Token "t" -Pattern "^v?\d+\.\d+\.\d+$"
$hotfixTags = Get-BitbucketTagsByPattern -Workspace "w" -RepoSlug "r" -Token "t" -Pattern "hotfix"
$rcTags = Get-BitbucketTagsByPattern -Workspace "w" -RepoSlug "r" -Token "t" -Pattern "-rc\d+$"
5. Комплексная фильтрация с параметрами
powershell
function Get-BitbucketTagsAdvanced {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [string]$NameFilter,
        [string]$Author,
        [datetime]$FromDate,
        [datetime]$ToDate,
        [string]$SortBy = "name",
        [switch]$Descending,
        [int]$Limit = 0
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    $headers = @{ "Authorization" = "Bearer $Token" }
    
    $allTags = @()
    
    try {
        Write-Host "Получение тегов..." -ForegroundColor Yellow
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers
            $allTags += $response.values
            $url = $response.next
        } while ($url)
        
        Write-Host "Найдено тегов: $($allTags.Count)" -ForegroundColor Green
        
        # Применяем фильтры
        $filteredTags = $allTags
        
        # Фильтр по имени
        if ($NameFilter) {
            $filteredTags = $filteredTags | Where-Object { $_.name -like $NameFilter }
            Write-Host "После фильтра по имени: $($filteredTags.Count)" -ForegroundColor Gray
        }
        
        # Фильтр по автору
        if ($Author) {
            $filteredTags = $filteredTags | Where-Object { $_.target.author.raw -like "*$Author*" }
            Write-Host "После фильтра по автору: $($filteredTags.Count)" -ForegroundColor Gray
        }
        
        # Фильтр по дате
        if ($FromDate) {
            $filteredTags = $filteredTags | Where-Object { [datetime]$_.date -ge $FromDate }
            Write-Host "После фильтра FromDate: $($filteredTags.Count)" -ForegroundColor Gray
        }
        
        if ($ToDate) {
            $filteredTags = $filteredTags | Where-Object { [datetime]$_.date -le $ToDate }
            Write-Host "После фильтра ToDate: $($filteredTags.Count)" -ForegroundColor Gray
        }
        
        # Сортировка
        $sortDirection = if ($Descending) { "Descending" } else { "Ascending" }
        
        switch ($SortBy.ToLower()) {
            "name" { 
                $filteredTags = $filteredTags | Sort-Object name -$sortDirection 
            }
            "date" { 
                $filteredTags = $filteredTags | Sort-Object { [datetime]$_.date } -$sortDirection 
            }
            "author" { 
                $filteredTags = $filteredTags | Sort-Object { $_.target.author.raw } -$sortDirection 
            }
            default { 
                $filteredTags = $filteredTags | Sort-Object name -$sortDirection 
            }
        }
        
        # Лимит
        if ($Limit -gt 0 -and $filteredTags.Count -gt $Limit) {
            $filteredTags = $filteredTags[0..($Limit-1)]
        }
        
        return $filteredTags
    }
    catch {
        Write-Error "Ошибка: $($_.Exception.Message)"
        return $null
    }
}
6. Примеры использования фильтров
powershell
# Установите ваши данные
$Workspace = "your-workspace"
$RepoSlug = "your-repo" 
$Token = "your-token"

# 1. Получить последние 10 тегов
$latestTags = Get-BitbucketTagsAdvanced -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -SortBy "date" -Descending -Limit 10

# 2. Получить теги версий 2.x
$v2Tags = Get-BitbucketTagsAdvanced -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -NameFilter "v2.*"

# 3. Получить теги за последний месяц
$recentTags = Get-BitbucketTagsAdvanced -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -FromDate (Get-Date).AddDays(-30) -SortBy "date" -Descending

# 4. Получить теги конкретного автора
$authorTags = Get-BitbucketTagsAdvanced -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -Author "john.doe"

# 5. Комплексный пример
$complexFilter = Get-BitbucketTagsAdvanced -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -NameFilter "release-*" -FromDate (Get-Date).AddDays(-90) -SortBy "date" -Descending -Limit 5

# Вывод результатов
if ($complexFilter) {
    Write-Host "`n=== РЕЗУЛЬТАТЫ ФИЛЬТРАЦИИ ===" -ForegroundColor Green
    $complexFilter | ForEach-Object {
        Write-Host "🏷️  $($_.name)" -ForegroundColor Yellow
        Write-Host "   📅 $([datetime]$_.date)" -ForegroundColor Gray
        Write-Host "   👤 $($_.target.author.raw)" -ForegroundColor Gray
        Write-Host "---"
    }
}
7. Параметры сортировки через API
powershell
function Get-BitbucketTagsWithQueryParams {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [string]$Query = "",
        [string]$Sort = "-name",
        [int]$PageLen = 100
    )
    
    $baseUrl = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    
    # Строим URL с параметрами
    $queryParams = @{
        "pagelen" = $PageLen
        "sort" = $Sort
    }
    
    if ($Query) {
        $queryParams["q"] = $Query
    }
    
    $url = $baseUrl + "?" + ($queryParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
    
    $headers = @{ "Authorization" = "Bearer $Token" }
    
    Write-Host "URL: $url" -ForegroundColor Gray
    
    try {
        $allTags = @()
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers
            $allTags += $response.values
            $url = $response.next
        } while ($url)
        
        return $allTags
    }
    catch {
        Write-Error "Ошибка: $($_.Exception.Message)"
        return $null
    }
}
Доступные параметры сортировки:

name - по имени (возрастание)

-name - по имени (убывание)

target.date - по дате коммита

-target.date - по дате коммита (новые сначала)

Примечание: Bitbucket API не поддерживает прямую фильтрацию через query parameters для тегов, поэтому фильтрация выполняется на стороне PowerShell после получения всех данных.

---------------------------------------------
-----------------------------------------------
----------------------------------------------

2. Фильтрация по имени тега с поиском последнего тега
powershell
function Get-LatestVersionTag {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [string]$Pattern = "V\d+\.\d+"
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    $headers = @{ "Authorization" = "Bearer $Token" }
    
    $allTags = @()
    
    try {
        Write-Host "Получение тегов из Bitbucket..." -ForegroundColor Yellow
        
        # Получаем все теги с пагинацией
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers
            $allTags += $response.values
            Write-Host "Получено $($response.values.Count) тегов..." -ForegroundColor Gray
            $url = $response.next
        } while ($url)
        
        Write-Host "Всего получено тегов: $($allTags.Count)" -ForegroundColor Green
        
        # Фильтруем теги по шаблону (только V323.00, V323.01 и т.д.)
        $versionTags = $allTags | Where-Object { $_.name -match "^$Pattern\.\d+$" }
        
        Write-Host "Найдено версионных тегов: $($versionTags.Count)" -ForegroundColor Green
        
        if ($versionTags.Count -eq 0) {
            Write-Host "❌ Теги по шаблону '$Pattern' не найдены" -ForegroundColor Red
            return $null
        }
        
        # Создаем массив только с ID тегов
        $tagIds = $versionTags | ForEach-Object { $_.name }
        
        Write-Host "`n🔍 Все найденные версионные теги:" -ForegroundColor Cyan
        $tagIds | Sort-Object | ForEach-Object { Write-Host "   📋 $_" -ForegroundColor Gray }
        
        # Сортируем теги как версии и находим последний
        $latestTag = $tagIds | Sort-Object { 
            # Преобразуем "V323.00" в версию для правильной сортировки
            if ($_ -match "^V(\d+)\.(\d+)$") {
                [version]"$($matches[1]).$($matches[2])"
            } else {
                [version]"0.0"
            }
        } | Select-Object -Last 1
        
        Write-Host "`n🎯 Самый последний тег: $latestTag" -ForegroundColor Green
        
        # Возвращаем массив ID и последний тег
        return @{
            AllVersionTags = $tagIds | Sort-Object
            LatestTag = $latestTag
            LatestTagInfo = $versionTags | Where-Object { $_.name -eq $latestTag } | Select-Object -First 1
        }
    }
    catch {
        Write-Error "❌ Ошибка: $($_.Exception.Message)"
        return $null
    }
}
Альтернативная версия с расширенными возможностями
powershell
function Get-VersionTagsAdvanced {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [string]$VersionPrefix = "V",
        [switch]$IncludeDetails
    )
    
    $url = "https://api.bitbucket.org/2.0/repositories/$Workspace/$RepoSlug/refs/tags"
    $headers = @{ "Authorization" = "Bearer $Token" }
    
    $allTags = @()
    
    try {
        Write-Host "🔄 Загрузка тегов из $Workspace/$RepoSlug..." -ForegroundColor Yellow
        
        # Получаем все теги
        do {
            $response = Invoke-RestMethod -Uri $url -Headers $headers
            $allTags += $response.values
            $url = $response.next
        } while ($url)
        
        Write-Host "✅ Получено тегов: $($allTags.Count)" -ForegroundColor Green
        
        # Фильтруем теги по шаблону VXXX.XX
        $versionTags = $allTags | Where-Object { 
            $_.name -match "^${VersionPrefix}\d+\.\d+$"
        }
        
        if ($versionTags.Count -eq 0) {
            Write-Host "❌ Теги формата '${VersionPrefix}XXX.XX' не найдены" -ForegroundColor Red
            
            # Показываем какие теги вообще есть
            $otherTags = $allTags | Select-Object -First 10 | ForEach-Object { $_.name }
            Write-Host "📋 Первые 10 тегов в репозитории:" -ForegroundColor Yellow
            $otherTags | ForEach-Object { Write-Host "   📝 $_" -ForegroundColor Gray }
            
            return $null
        }
        
        # Создаем массив только с ID тегов
        $tagIds = $versionTags | ForEach-Object { $_.name }
        
        # Сортируем как версии
        $sortedTags = $tagIds | Sort-Object { 
            if ($_ -match "^${VersionPrefix}(\d+)\.(\d+)$") {
                [version]"$($matches[1]).$($matches[2])"
            } else {
                [version]"0.0"
            }
        }
        
        $latestTag = $sortedTags | Select-Object -Last 1
        
        Write-Host "`n📊 Статистика версионных тегов:" -ForegroundColor Cyan
        Write-Host "   Всего версионных тегов: $($sortedTags.Count)" -ForegroundColor White
        Write-Host "   Первый тег: $($sortedTags[0])" -ForegroundColor Gray
        Write-Host "   Последний тег: $latestTag" -ForegroundColor Green
        Write-Host "   Диапазон: $($sortedTags[0]) - $latestTag" -ForegroundColor Gray
        
        Write-Host "`n📋 Все версионные теги (отсортированные):" -ForegroundColor Cyan
        $sortedTags | ForEach-Object { Write-Host "   🏷️  $_" -ForegroundColor Gray }
        
        # Формируем результат
        $result = @{
            AllVersionTags = $sortedTags
            LatestTag = $latestTag
            Count = $sortedTags.Count
        }
        
        # Добавляем детальную информацию если нужно
        if ($IncludeDetails) {
            $result.LatestTagInfo = $versionTags | Where-Object { $_.name -eq $latestTag } | Select-Object -First 1
            $result.AllTagDetails = $versionTags
        }
        
        return $result
    }
    catch {
        Write-Error "❌ Ошибка при получении тегов: $($_.Exception.Message)"
        return $null
    }
}
Функция для сравнения версий и поиска следующего тега
powershell
function Get-NextVersionTag {
    param(
        [string]$Workspace,
        [string]$RepoSlug,
        [string]$Token,
        [string]$VersionPrefix = "V"
    )
    
    # Получаем текущие теги
    $currentTags = Get-VersionTagsAdvanced -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -VersionPrefix $VersionPrefix
    
    if (-not $currentTags) {
        Write-Host "❌ Не удалось получить теги или они не найдены" -ForegroundColor Red
        return $null
    }
    
    $latestTag = $currentTags.LatestTag
    
    # Парсим последний тег
    if ($latestTag -match "^${VersionPrefix}(\d+)\.(\d+)$") {
        $major = [int]$matches[1]
        $minor = [int]$matches[2]
        
        # Предлагаем следующий тег
        $nextMinor = $minor + 1
        $nextTag = "${VersionPrefix}${major}.$($nextMinor.ToString("00"))"
        
        Write-Host "`n🎯 Следующий предлагаемый тег: $nextTag" -ForegroundColor Yellow
        Write-Host "   На основе последнего тега: $latestTag" -ForegroundColor Gray
        
        return @{
            CurrentLatest = $latestTag
            NextSuggested = $nextTag
            MajorVersion = $major
            MinorVersion = $minor
            AllTags = $currentTags.AllVersionTags
        }
    }
    
    return $null
}
Примеры использования
powershell
# Установите ваши данные
$Workspace = "your-workspace"
$RepoSlug = "your-repo"
$Token = "your-token"

# 1. Простой поиск последнего тега
Write-Host "=== ПРОСТОЙ ПОИСК ===" -ForegroundColor Cyan
$result = Get-LatestVersionTag -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token

if ($result) {
    Write-Host "`n📋 Все теги: $($result.AllVersionTags -join ', ')" -ForegroundColor Gray
    Write-Host "🎯 Последний тег: $($result.LatestTag)" -ForegroundColor Green
    
    # Детали последнего тега
    if ($result.LatestTagInfo) {
        Write-Host "`n📅 Дата создания: $($result.LatestTagInfo.date)" -ForegroundColor Gray
        Write-Host "🔗 Коммит: $($result.LatestTagInfo.target.hash)" -ForegroundColor Gray
    }
}

# 2. Расширенный поиск
Write-Host "`n=== РАСШИРЕННЫЙ ПОИСК ===" -ForegroundColor Cyan
$advancedResult = Get-VersionTagsAdvanced -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -IncludeDetails

if ($advancedResult) {
    Write-Host "`n🎯 Результаты:" -ForegroundColor Green
    Write-Host "   Последний тег: $($advancedResult.LatestTag)" -ForegroundColor Yellow
    Write-Host "   Всего тегов: $($advancedResult.Count)" -ForegroundColor Gray
    
    # Показываем последние 5 тегов
    Write-Host "`n📈 Последние 5 тегов:" -ForegroundColor Cyan
    $advancedResult.AllVersionTags | Select-Object -Last 5 | ForEach-Object { 
        Write-Host "   🏷️  $_" -ForegroundColor Gray 
    }
}

# 3. Поиск следующего тега
Write-Host "`n=== ПОИСК СЛЕДУЮЩЕГО ТЕГА ===" -ForegroundColor Cyan
$nextTag = Get-NextVersionTag -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token

if ($nextTag) {
    Write-Host "`n🎯 Рекомендация по версионированию:" -ForegroundColor Green
    Write-Host "   Текущий последний: $($nextTag.CurrentLatest)" -ForegroundColor Gray
    Write-Host "   Следующий тег: $($nextTag.NextSuggested)" -ForegroundColor Yellow
}
Для разных паттернов тегов
powershell
# Для тегов типа "RELEASE-1.2.3"
$result1 = Get-LatestVersionTag -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -Pattern "RELEASE-\d+"

# Для тегов типа "v1.2.3"  
$result2 = Get-LatestVersionTag -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -Pattern "v\d+"

# Для тегов типа "build-123"
$result3 = Get-LatestVersionTag -Workspace $Workspace -RepoSlug $RepoSlug -Token $Token -Pattern "build-\d+"
Ключевые особенности:

✅ Фильтрует только теги по заданному шаблону (V323.00, V323.01 и т.д.)

✅ Создает массив только с ID тегов

✅ Сортирует теги как версии (не как строки)

✅ Находит самый последний тег

✅ Возвращает как массив всех тегов, так и последний тег

✅ Поддерживает разные паттерны именования


-------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
---------------------------------------------------------------

Для определения принадлежности тега к ветке через Bitbucket API есть несколько подходов:

1. Получить коммит тега и найти ветки, содержащие его
bash
# Получить информацию о теге
curl -u username:password "https://api.bitbucket.org/2.0/repositories/{workspace}/{repo}/refs/tags/{tag_name}"
Затем использовать полученный хеш коммита:

bash
# Найти ветки, содержащие этот коммит
curl -u username:password "https://api.bitbucket.org/2.0/repositories/{workspace}/{repo/commit/{commit_hash}/branches"
2. Использование GraphQL API (рекомендуется)
graphql
query {
  repository(slug: "repo-name", owner: "workspace") {
    refs(prefix: "refs/tags/", query: "tag-name") {
      nodes {
        name
        target {
          ... on Commit {
            hash
            branches {
              nodes {
                name
              }
            }
          }
        }
      }
    }
  }
}
3. Полный пример на Python
python
import requests
import base64

def get_tag_branches(workspace, repo, tag_name, username, password):
    # Аутентификация
    auth = base64.b64encode(f"{username}:{password}".encode()).decode()
    headers = {"Authorization": f"Basic {auth}"}
    
    base_url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo}"
    
    try:
        # 1. Получить информацию о теге
        tag_response = requests.get(f"{base_url}/refs/tags/{tag_name}", headers=headers)
        tag_response.raise_for_status()
        tag_data = tag_response.json()
        
        # 2. Получить хеш коммита тега
        commit_hash = tag_data['target']['hash']
        
        # 3. Найти ветки, содержащие этот коммит
        branches_response = requests.get(
            f"{base_url}/commit/{commit_hash}/branches", 
            headers=headers
        )
        branches_response.raise_for_status()
        branches_data = branches_response.json()
        
        # 4. Вернуть список веток
        branches = [branch['name'] for branch in branches_data['values']]
        return branches
        
    except requests.exceptions.RequestException as e:
        print(f"Ошибка: {e}")
        return []

# Использование
workspace = "your-workspace"
repo = "your-repo"
tag_name = "v1.0.0"
username = "your-username"
password = "your-password"  # или использовать app password

branches = get_tag_branches(workspace, repo, tag_name, username, password)
print(f"Тег {tag_name} находится в ветках: {branches}")
4. Использование App Passwords (безопаснее)
python
import os
import requests

def get_tag_branches_app_password(workspace, repo, tag_name):
    # Использование переменных окружения
    username = os.getenv('BITBUCKET_USERNAME')
    app_password = os.getenv('BITBUCKET_APP_PASSWORD')
    
    auth = (username, app_password)
    base_url = f"https://api.bitbucket.org/2.0/repositories/{workspace}/{repo}"
    
    # Получить тег
    tag_response = requests.get(f"{base_url}/refs/tags/{tag_name}", auth=auth)
    tag_data = tag_response.json()
    
    commit_hash = tag_data['target']['hash']
    
    # Получить ветки
    branches_response = requests.get(
        f"{base_url}/commit/{commit_hash}/branches", 
        auth=auth
    )
    branches_data = branches_response.json()
    
    return [branch['name'] for branch in branches_data['values']]
5. Использование библиотеки bitbucket-api
python
from bitbucket import Bitbucket

bb = Bitbucket('username', 'app_password')
workspace = 'your-workspace'
repo_slug = 'your-repo'

# Получить тег
tag = bb.get_tag(workspace, repo_slug, 'tag-name')
commit_hash = tag.target.hash

# Получить ветки, содержащие коммит
branches = bb.get_branches_containing_commit(workspace, repo_slug, commit_hash)
6. Через Bitbucket CLI (альтернатива)
bash
# Установить Bitbucket CLI
pip install bitbucket-cli

# Использование
bb repositories tags get --workspace {workspace} --repo_slug {repo} --tag {tag_name}