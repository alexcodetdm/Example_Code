import subprocess
import re
from collections import defaultdict
import os
from datetime import datetime

# ---------- КОНФИГУРАЦИЯ ----------
# Укажите URL вашего Jira
JIRA_BASE_URL = "https://your-company.atlassian.net/browse/"  # Замените на ваш URL

# ---------- ЗАЯВЛЕННЫЕ ЗАДАЧИ В РЕЛИЗЕ ----------
# Укажите список номеров задач, которые должны быть в релизе
RELEASE_TASKS = [
    "PROJ-123",
    "PROJ-456",
    "PROJ-789",
    "PROJ-101",
    "PROJ-202"
]
# Если список задач хранится в отдельном файле, можно загрузить его:
# with open('release_tasks.txt', 'r') as f:
#     RELEASE_TASKS = [line.strip() for line in f if line.strip()]

# ---------- Вспомогательные функции ----------

def get_merge_base(branch1, branch2):
    result = subprocess.run(
        ['git', 'merge-base', branch1, branch2],
        capture_output=True, text=True, check=True
    )
    return result.stdout.strip()

def get_changed_files(base, target):
    result = subprocess.run(
        ['git', 'diff', '--name-only', base, target],
        capture_output=True, text=True, check=True
    )
    return [f for f in result.stdout.strip().split('\n') if f]

def get_changed_line_numbers(base, target, file_path):
    diff = subprocess.run(
        ['git', 'diff', '-U0', base, target, '--', file_path],
        capture_output=True, text=True, check=True
    ).stdout
    
    line_numbers = []
    for line in diff.split('\n'):
        if line.startswith('@@'):
            match = re.search(r'\+(\d+)(?:,(\d+))?', line)
            if match:
                start = int(match.group(1))
                count = int(match.group(2)) if match.group(2) else 1
                line_numbers.extend(range(start, start + count))
    
    return line_numbers

def get_blame_for_file(target_branch, file_path):
    """
    Возвращает словарь {номер_строки: хеш_коммита} для всего файла.
    Используем --line-porcelain для надёжного парсинга.
    """
    try:
        output = subprocess.run(
            ['git', 'blame', '--line-porcelain', target_branch, '--', file_path],
            capture_output=True, text=True, check=True
        ).stdout
    except subprocess.CalledProcessError:
        # Файл мог быть удалён или переименован
        return {}
    
    blame_map = {}
    lines = output.split('\n')
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        if line and not line.startswith('\t') and not line.startswith(' '):
            parts = line.split()
            if len(parts) >= 3:
                commit_hash = parts[0]
                final_line_num = int(parts[2])
                
                i += 1
                while i < len(lines) and not lines[i].startswith('\t'):
                    i += 1
                
                if i < len(lines) and lines[i].startswith('\t'):
                    blame_map[final_line_num] = commit_hash
        
        i += 1
    
    return blame_map

def extract_task_id(text):
    # Ищем паттерн типа TASK-123, PROJ-456 и т.д.
    match = re.search(r'([A-Z]+-\d+)', text)
    return match.group(1) if match else None

def get_commit_info(commit_hash):
    """Получает информацию о коммите: автор, дата, сообщение"""
    output = subprocess.run(
        ['git', 'log', '-1', '--format=%an|%ad|%s', '--date=short', commit_hash],
        capture_output=True, text=True, check=True
    ).stdout.strip()
    
    parts = output.split('|')
    if len(parts) >= 3:
        return {
            'author': parts[0],
            'date': parts[1],
            'subject': parts[2]
        }
    return {'author': 'Unknown', 'date': 'Unknown', 'subject': 'No message'}

# ---------- Генерация HTML-отчёта ----------

def generate_html_report(results, commit_cache, output_file='release_report.html'):
    """
    Генерирует интерактивный HTML-отчёт с раскрывающимися группами по задачам.
    """
    
    # Получаем информацию о репозитории
    repo_url = subprocess.run(
        ['git', 'config', '--get', 'remote.origin.url'],
        capture_output=True, text=True
    ).stdout.strip()
    
    # Пытаемся определить URL для GitLab
    gitlab_url = None
    if 'gitlab' in repo_url:
        if repo_url.startswith('git@'):
            gitlab_url = repo_url.replace('git@', 'https://').replace(':', '/').replace('.git', '')
        elif repo_url.startswith('https://'):
            gitlab_url = repo_url.replace('.git', '')
    
    html = f"""
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Отчёт по релизу - Анализ задач</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: #f5f7fa;
            padding: 20px;
            color: #1f2d3d;
        }}
        
        .container {{
            max-width: 1400px;
            margin: 0 auto;
        }}
        
        .header {{
            background: white;
            border-radius: 8px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }}
        
        .header h1 {{
            font-size: 28px;
            font-weight: 600;
            margin-bottom: 10px;
            color: #1f2d3d;
        }}
        
        .header .meta {{
            color: #6b7a8d;
            font-size: 14px;
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }}
        
        .header .meta span {{
            background: #f0f2f5;
            padding: 4px 12px;
            border-radius: 12px;
        }}
        
        .summary {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 30px;
        }}
        
        .summary-card {{
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            text-align: center;
            transition: transform 0.2s;
        }}
        
        .summary-card:hover {{
            transform: translateY(-2px);
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }}
        
        .summary-card .number {{
            font-size: 32px;
            font-weight: 700;
            color: #1f2d3d;
        }}
        
        .summary-card .label {{
            font-size: 14px;
            color: #6b7a8d;
            margin-top: 5px;
        }}
        
        .summary-card .number.green {{ color: #2ecc71; }}
        .summary-card .number.orange {{ color: #f39c12; }}
        .summary-card .number.red {{ color: #e74c3c; }}
        .summary-card .number.blue {{ color: #3498db; }}
        .summary-card .number.purple {{ color: #9b59b6; }}
        
        .status-section {{
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }}
        
        .status-section h2 {{
            font-size: 20px;
            margin-bottom: 15px;
        }}
        
        .status-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }}
        
        .status-list {{
            background: #f8f9fa;
            border-radius: 6px;
            padding: 15px;
        }}
        
        .status-list h3 {{
            font-size: 16px;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 10px;
        }}
        
        .status-list .count {{
            font-weight: 600;
            padding: 2px 10px;
            border-radius: 12px;
            font-size: 14px;
        }}
        
        .status-list .count.green {{ background: #d5f5e3; color: #27ae60; }}
        .status-list .count.red {{ background: #fadbd8; color: #e74c3c; }}
        .status-list .count.orange {{ background: #fdebd0; color: #e67e22; }}
        
        .status-item {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 6px 12px;
            background: white;
            border-radius: 4px;
            margin-bottom: 4px;
            font-size: 14px;
        }}
        
        .status-item a {{
            color: #1f2d3d;
            text-decoration: none;
            font-weight: 500;
        }}
        
        .status-item a:hover {{
            color: #3498db;
            text-decoration: underline;
        }}
        
        .status-item .status-badge {{
            font-size: 12px;
            padding: 2px 8px;
            border-radius: 4px;
        }}
        
        .status-item .status-badge.found {{ background: #d5f5e3; color: #27ae60; }}
        .status-item .status-badge.not-found {{ background: #fadbd8; color: #e74c3c; }}
        .status-item .status-badge.extra {{ background: #fdebd0; color: #e67e22; }}
        
        .task-group {{
            background: white;
            border-radius: 8px;
            margin-bottom: 10px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            overflow: hidden;
            transition: box-shadow 0.2s;
        }}
        
        .task-group:hover {{
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }}
        
        .task-header {{
            padding: 15px 20px;
            cursor: pointer;
            display: flex;
            justify-content: space-between;
            align-items: center;
            transition: background 0.2s;
            user-select: none;
        }}
        
        .task-header:hover {{
            background: #f8f9fa;
        }}
        
        .task-header .task-id {{
            font-weight: 600;
            font-size: 18px;
            color: #1f2d3d;
            display: flex;
            align-items: center;
            gap: 10px;
        }}
        
        .task-header .task-id a {{
            color: #1f2d3d;
            text-decoration: none;
        }}
        
        .task-header .task-id a:hover {{
            color: #3498db;
            text-decoration: underline;
        }}
        
        .task-header .task-id .badge {{
            display: inline-block;
            color: white;
            padding: 2px 10px;
            border-radius: 12px;
            font-size: 12px;
            margin-left: 5px;
        }}
        
        .task-header .task-id .badge.found {{ background: #27ae60; }}
        .task-header .task-id .badge.not-found {{ background: #e74c3c; }}
        .task-header .task-id .badge.extra {{ background: #e67e22; }}
        
        .task-header .task-id .jira-icon {{
            display: inline-block;
            background: #0052CC;
            color: white;
            padding: 2px 8px;
            border-radius: 4px;
            font-size: 11px;
            font-weight: 600;
            margin-left: 5px;
        }}
        
        .task-header .task-info {{
            display: flex;
            align-items: center;
            gap: 20px;
            font-size: 14px;
            color: #6b7a8d;
        }}
        
        .task-header .toggle-icon {{
            font-size: 20px;
            transition: transform 0.3s;
            color: #6b7a8d;
        }}
        
        .task-header .toggle-icon.open {{
            transform: rotate(180deg);
        }}
        
        .task-body {{
            display: none;
            padding: 20px;
            border-top: 1px solid #e9ecef;
            background: #fafbfc;
        }}
        
        .task-body.open {{
            display: block;
        }}
        
        .file-section {{
            margin-bottom: 15px;
        }}
        
        .file-section .file-name {{
            font-weight: 500;
            color: #1f2d3d;
            padding: 8px 12px;
            background: white;
            border-radius: 4px;
            border-left: 3px solid #3498db;
            margin-bottom: 8px;
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
        }}
        
        .file-section .file-name a {{
            color: #3498db;
            text-decoration: none;
        }}
        
        .file-section .file-name a:hover {{
            text-decoration: underline;
        }}
        
        .file-section .file-name .file-badge {{
            font-weight: 400;
            color: #6b7a8d;
            font-size: 12px;
        }}
        
        .commit-list {{
            padding-left: 20px;
        }}
        
        .commit-item {{
            display: flex;
            align-items: center;
            gap: 15px;
            padding: 6px 12px;
            margin-bottom: 4px;
            background: white;
            border-radius: 4px;
            font-size: 13px;
            transition: background 0.2s;
            flex-wrap: wrap;
        }}
        
        .commit-item:hover {{
            background: #f0f4ff;
        }}
        
        .commit-item .commit-hash {{
            font-family: 'Courier New', monospace;
            font-size: 12px;
            color: #6b7a8d;
            min-width: 80px;
        }}
        
        .commit-item .commit-hash a {{
            color: #6b7a8d;
            text-decoration: none;
            font-weight: 600;
        }}
        
        .commit-item .commit-hash a:hover {{
            color: #3498db;
            text-decoration: underline;
        }}
        
        .commit-item .commit-author {{
            color: #1f2d3d;
            font-weight: 500;
            min-width: 120px;
        }}
        
        .commit-item .commit-date {{
            color: #6b7a8d;
            font-size: 12px;
            min-width: 100px;
        }}
        
        .commit-item .commit-subject {{
            color: #1f2d3d;
            flex: 1;
            min-width: 150px;
        }}
        
        .commit-item .line-numbers {{
            color: #6b7a8d;
            font-size: 12px;
            background: #f0f2f5;
            padding: 2px 8px;
            border-radius: 4px;
            white-space: nowrap;
        }}
        
        .commit-item .line-numbers a {{
            color: #6b7a8d;
            text-decoration: none;
        }}
        
        .commit-item .line-numbers a:hover {{
            color: #3498db;
            text-decoration: underline;
        }}
        
        .empty-state {{
            text-align: center;
            padding: 20px;
            color: #6b7a8d;
        }}
        
        .footer {{
            margin-top: 30px;
            text-align: center;
            color: #6b7a8d;
            font-size: 12px;
        }}
        
        .footer a {{
            color: #3498db;
            text-decoration: none;
            cursor: pointer;
        }}
        
        .footer a:hover {{
            text-decoration: underline;
        }}
        
        @media (max-width: 768px) {{
            .task-header {{
                flex-direction: column;
                align-items: flex-start;
                gap: 10px;
            }}
            
            .commit-item {{
                flex-direction: column;
                align-items: flex-start;
                gap: 5px;
                padding: 10px;
            }}
            
            .commit-item .commit-hash,
            .commit-item .commit-author,
            .commit-item .commit-date,
            .commit-item .commit-subject,
            .commit-item .line-numbers {{
                min-width: unset;
                width: 100%;
            }}
            
            .summary {{
                grid-template-columns: 1fr 1fr;
            }}
            
            .status-grid {{
                grid-template-columns: 1fr;
            }}
            
            .task-header .task-info {{
                flex-wrap: wrap;
            }}
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Отчёт по анализу релизной ветки</h1>
            <div class="meta">
                <span>🔀 Ветка: <strong>release/R001</strong></span>
                <span>📅 Дата: <strong>{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</strong></span>
                <span>📁 Файлов изменено: <strong>{len(results.get('files', []))}</strong></span>
                <span>📋 Заявлено задач: <strong>{len(results.get('declared_tasks', []))}</strong></span>
                <span>🔗 Jira: <strong>{JIRA_BASE_URL}</strong></span>
            </div>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <div class="number blue">{len(results.get('tasks', {}))}</div>
                <div class="label">📌 Найдено в коде</div>
            </div>
            <div class="summary-card">
                <div class="number green">{len(results.get('status', {}).get('found', []))}</div>
                <div class="label">✅ Совпадают с заявленными</div>
            </div>
            <div class="summary-card">
                <div class="number red">{len(results.get('status', {}).get('not_found', []))}</div>
                <div class="label">❌ Заявлены, но не найдены</div>
            </div>
            <div class="summary-card">
                <div class="number orange">{len(results.get('status', {}).get('extra', []))}</div>
                <div class="label">⚠️ Лишние (не заявлены)</div>
            </div>
        </div>
        
        <div class="status-section">
            <h2>📋 Статус задач</h2>
            <div class="status-grid">
                <div class="status-list">
                    <h3>✅ Найдены <span class="count green">{len(results.get('status', {}).get('found', []))}</span></h3>
"""
    
    # Найденные задачи
    found_tasks = results.get('status', {}).get('found', [])
    if found_tasks:
        for task_id in sorted(found_tasks):
            jira_url = f"{JIRA_BASE_URL}{task_id}"
            html += f"""
                    <div class="status-item">
                        <a href="{jira_url}" target="_blank">{task_id}</a>
                        <span class="status-badge found">✓ Найдена</span>
                    </div>
"""
    else:
        html += """
                    <div class="empty-state">Нет найденных задач</div>
"""
    
    html += """
                </div>
                <div class="status-list">
                    <h3>❌ Не найдены <span class="count red">""" + str(len(results.get('status', {}).get('not_found', []))) + """</span></h3>
"""
    
    # Не найденные задачи
    not_found_tasks = results.get('status', {}).get('not_found', [])
    if not_found_tasks:
        for task_id in sorted(not_found_tasks):
            jira_url = f"{JIRA_BASE_URL}{task_id}"
            html += f"""
                    <div class="status-item">
                        <a href="{jira_url}" target="_blank">{task_id}</a>
                        <span class="status-badge not-found">✗ Не найдена</span>
                    </div>
"""
    else:
        html += """
                    <div class="empty-state">Все заявленные задачи найдены! 🎉</div>
"""
    
    html += """
                </div>
                <div class="status-list">
                    <h3>⚠️ Лишние <span class="count orange">""" + str(len(results.get('status', {}).get('extra', []))) + """</span></h3>
"""
    
    # Лишние задачи
    extra_tasks = results.get('status', {}).get('extra', [])
    if extra_tasks:
        for task_id in sorted(extra_tasks):
            jira_url = f"{JIRA_BASE_URL}{task_id}"
            html += f"""
                    <div class="status-item">
                        <a href="{jira_url}" target="_blank">{task_id}</a>
                        <span class="status-badge extra">⚠️ Не заявлена</span>
                    </div>
"""
    else:
        html += """
                    <div class="empty-state">Нет лишних задач 👍</div>
"""
    
    html += """
                </div>
            </div>
        </div>
        
        <h2 style="margin-bottom:15px;">📂 Детали по задачам</h2>
"""
    
    # Группы по задачам (все найденные в коде)
    if results.get('tasks'):
        for task_id, task_data in sorted(results['tasks'].items()):
            # Определяем статус задачи
            if task_id in results.get('status', {}).get('found', []):
                status_class = 'found'
                status_text = 'Заявлена'
            elif task_id in results.get('status', {}).get('extra', []):
                status_class = 'extra'
                status_text = 'Лишняя'
            else:
                status_class = 'found'  # fallback
            
            # Собираем уникальные коммиты для этой задачи
            commits_in_task = {}
            for file_change in task_data['files']:
                for change in file_change['changes']:
                    commit_hash = change['commit']
                    if commit_hash not in commits_in_task:
                        commits_in_task[commit_hash] = {
                            'info': commit_cache.get(commit_hash, {}),
                            'files': defaultdict(list)
                        }
                    commits_in_task[commit_hash]['files'][file_change['file']].append(change['line'])
            
            # Ссылка на Jira
            jira_url = f"{JIRA_BASE_URL}{task_id}"
            
            html += f"""
        <div class="task-group">
            <div class="task-header" onclick="toggleTask(this)">
                <div class="task-id">
                    <a href="{jira_url}" target="_blank" onclick="event.stopPropagation();">
                        {task_id}
                    </a>
                    <span class="jira-icon">Jira</span>
                    <span class="badge {status_class}">{status_text}</span>
                    <span class="badge" style="background:#6b7a8d;">{len(commits_in_task)} коммитов</span>
                </div>
                <div class="task-info">
                    <span>📄 {len(task_data['files'])} файлов</span>
                    <span class="toggle-icon">▼</span>
                </div>
            </div>
            <div class="task-body">
"""
            
            # Группируем по файлам
            for file_change in task_data['files']:
                file_path = file_change['file']
                # Собираем уникальные коммиты для этого файла
                file_commits = {}
                for change in file_change['changes']:
                    commit_hash = change['commit']
                    if commit_hash not in file_commits:
                        file_commits[commit_hash] = {
                            'info': commit_cache.get(commit_hash, {}),
                            'lines': []
                        }
                    file_commits[commit_hash]['lines'].append(change['line'])
                
                # Ссылка на файл (если есть GitLab URL)
                file_url = None
                if gitlab_url:
                    file_url = f"{gitlab_url}/-/blob/release/R001/{file_path}"
                
                html += f"""
                <div class="file-section">
                    <div class="file-name">
                        📄 {'🔗 <a href="' + file_url + '" target="_blank">' if file_url else ''}{file_path}{'</a>' if file_url else ''}
                        <span class="file-badge">({len(file_commits)} коммитов)</span>
                    </div>
                    <div class="commit-list">
"""
                
                for commit_hash, commit_data in sorted(file_commits.items(), key=lambda x: x[1]['info'].get('date', ''), reverse=True):
                    info = commit_data['info']
                    commit_url = None
                    if gitlab_url:
                        commit_url = f"{gitlab_url}/-/commit/{commit_hash}"
                    
                    lines_str = ', '.join(map(str, sorted(commit_data['lines'])))
                    
                    html += f"""
                        <div class="commit-item">
                            <span class="commit-hash">
                                {'🔗 <a href="' + commit_url + '" target="_blank">' if commit_url else ''}{commit_hash[:8]}{'</a>' if commit_url else ''}
                            </span>
                            <span class="commit-author">👤 {info.get('author', 'Unknown')}</span>
                            <span class="commit-date">📅 {info.get('date', 'Unknown')}</span>
                            <span class="commit-subject">📝 {info.get('subject', 'No message')}</span>
                            <span class="line-numbers">
                                строки: {lines_str}
                            </span>
                        </div>
"""
                
                html += """
                    </div>
                </div>
"""
            
            html += """
            </div>
        </div>
"""
    
    # Коммиты без задачи
    if results.get('unlinked_commits'):
        html += """
        <div class="status-section" style="border-left: 4px solid #e74c3c;">
            <h2 style="color:#e74c3c;">⚠️ Коммиты без номера задачи</h2>
            <p style="color:#6b7a8d;margin-bottom:10px;font-size:14px;">
                Эти коммиты изменили код в релизе, но не содержат номера задачи в сообщении.
                Рекомендуется проверить их вручную.
            </p>
"""
        for commit_hash in results['unlinked_commits']:
            info = commit_cache.get(commit_hash, {})
            commit_url = None
            if gitlab_url:
                commit_url = f"{gitlab_url}/-/commit/{commit_hash}"
            
            html += f"""
            <div class="commit-item" style="border-left: 3px solid #e74c3c; padding-left: 15px;">
                <span class="commit-hash">
                    {'🔗 <a href="' + commit_url + '" target="_blank">' if commit_url else ''}{commit_hash[:8]}{'</a>' if commit_url else ''}
                </span>
                <span class="commit-author">👤 {info.get('author', 'Unknown')}</span>
                <span class="commit-date">📅 {info.get('date', 'Unknown')}</span>
                <span class="commit-subject">📝 {info.get('subject', 'No message')}</span>
            </div>
"""
        
        html += """
        </div>
"""
    
    html += f"""
        <div class="footer">
            Отчёт сгенерирован {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} | 
            <a href="#" onclick="openAll(); return false;">Открыть все</a> | 
            <a href="#" onclick="closeAll(); return false;">Закрыть все</a>
        </div>
    </div>
    
    <script>
        function toggleTask(header) {{
            const body = header.nextElementSibling;
            const icon = header.querySelector('.toggle-icon');
            
            if (body.classList.contains('open')) {{
                body.classList.remove('open');
                icon.classList.remove('open');
            }} else {{
                body.classList.add('open');
                icon.classList.add('open');
            }}
        }}
        
        function openAll() {{
            document.querySelectorAll('.task-body').forEach(body => body.classList.add('open'));
            document.querySelectorAll('.toggle-icon').forEach(icon => icon.classList.add('open'));
        }}
        
        function closeAll() {{
            document.querySelectorAll('.task-body').forEach(body => body.classList.remove('open'));
            document.querySelectorAll('.toggle-icon').forEach(icon => icon.classList.remove('open'));
        }}
        
        // По умолчанию все группы закрыты
        document.addEventListener('DOMContentLoaded', function() {{
            // Раскомментировать, чтобы открыть все по умолчанию
            // openAll();
        }});
    </script>
</body>
</html>
"""
    
    # Сохраняем файл
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"\n✅ HTML-отчёт сохранён: {output_file}")
    return output_file

# ---------- Основной алгоритм ----------

def analyze_release_with_cache():
    print("🔍 Анализ релизной ветки release/R001...")
    print(f"📋 Заявленных задач в релизе: {len(RELEASE_TASKS)}")
    if RELEASE_TASKS:
        print(f"   {', '.join(RELEASE_TASKS[:10])}{'...' if len(RELEASE_TASKS) > 10 else ''}")
    print()
    
    # Шаг 1: Точка ответвления
    base = get_merge_base('master', 'release/R001')
    print(f"✅ Точка ответвления: {base[:8]}")
    
    # Шаг 2: Все изменённые файлы
    files = get_changed_files(base, 'release/R001')
    print(f"📁 Найдено изменённых файлов: {len(files)}")
    
    # Шаг 3: Собираем строки, которые нужно проверить
    lines_to_check = {}
    for file in files:
        line_numbers = get_changed_line_numbers(base, 'release/R001', file)
        if line_numbers:
            lines_to_check[file] = line_numbers
    
    total_lines = sum(len(lines) for lines in lines_to_check.values())
    print(f"📝 Всего строк для проверки: {total_lines}")
    
    # Шаг 4: Получаем blame для каждого файла (ОДИН раз на файл)
    file_blame_cache = {}
    for idx, file in enumerate(lines_to_check.keys(), 1):
        print(f"  ⏳ [{idx}/{len(lines_to_check)}] Загружаем blame для: {file}")
        file_blame_cache[file] = get_blame_for_file('release/R001', file)
    
    # Шаг 5: Собираем ВСЕ уникальные хеши коммитов
    all_commit_hashes = set()
    for file, blame_map in file_blame_cache.items():
        for line_num in lines_to_check[file]:
            commit_hash = blame_map.get(line_num)
            if commit_hash:
                all_commit_hashes.add(commit_hash)
    
    print(f"🔑 Найдено уникальных коммитов: {len(all_commit_hashes)}")
    
    # Шаг 6: Кэш для информации о коммитах (ОДИН запрос на уникальный хеш)
    commit_cache = {}
    for commit_hash in all_commit_hashes:
        msg = subprocess.run(
            ['git', 'log', '-1', '--format=%B', commit_hash],
            capture_output=True, text=True, check=True
        ).stdout
        task_id = extract_task_id(msg)
        
        # Получаем дополнительную информацию
        info = get_commit_info(commit_hash)
        
        commit_cache[commit_hash] = {
            'message': msg.strip(),
            'task_id': task_id,
            'author': info['author'],
            'date': info['date'],
            'subject': info['subject']
        }
    
    # Шаг 7: Формируем финальный результат для HTML
    result = {
        'tasks': defaultdict(lambda: {'files': []}),
        'commits': [],
        'files': list(lines_to_check.keys()),
        'unlinked_commits': [],
        'declared_tasks': RELEASE_TASKS,
        'status': {
            'found': [],      # Заявлены и найдены в коде
            'not_found': [],  # Заявлены, но не найдены в коде
            'extra': []       # Найдены в коде, но не заявлены
        }
    }
    
    # Группируем изменения по задачам
    tasks_data = defaultdict(lambda: defaultdict(list))
    found_in_code = set()
    
    for file, blame_map in file_blame_cache.items():
        for line_num in lines_to_check[file]:
            commit_hash = blame_map.get(line_num)
            if commit_hash and commit_hash in commit_cache:
                task_id = commit_cache[commit_hash]['task_id']
                if task_id:
                    found_in_code.add(task_id)
                    tasks_data[task_id][file].append({
                        'line': line_num,
                        'commit': commit_hash
                    })
                else:
                    # Коммит без задачи
                    if commit_hash not in result['unlinked_commits']:
                        result['unlinked_commits'].append(commit_hash)
    
    # Анализируем статус задач
    declared_set = set(RELEASE_TASKS)
    
    # Найденные (пересечение заявленных и найденных в коде)
    found_tasks = declared_set & found_in_code
    result['status']['found'] = list(found_tasks)
    
    # Не найденные (заявлены, но отсутствуют в коде)
    not_found_tasks = declared_set - found_in_code
    result['status']['not_found'] = list(not_found_tasks)
    
    # Лишние (найдены в коде, но не заявлены)
    extra_tasks = found_in_code - declared_set
    result['status']['extra'] = list(extra_tasks)
    
    # Формируем структуру для HTML
    for task_id, files_data in tasks_data.items():
        task_files = []
        for file_path, changes in files_data.items():
            task_files.append({
                'file': file_path,
                'changes': changes
            })
        result['tasks'][task_id] = {'files': task_files}
    
    # Собираем список всех уникальных коммитов
    result['commits'] = list(all_commit_hashes)
    
    # Шаг 8: Генерируем HTML-отчёт
    html_file = generate_html_report(result, commit_cache)
    
    # Шаг 9: Вывод в консоль
    print("\n" + "="*60)
    print("📊 РЕЗУЛЬТАТЫ АНАЛИЗА")
    print("="*60)
    
    print(f"\n📋 Заявлено задач: {len(RELEASE_TASKS)}")
    print(f"🔍 Найдено в коде: {len(found_in_code)}")
    
    print(f"\n✅ Найдены (заявлены + есть в коде): {len(result['status']['found'])}")
    if result['status']['found']:
        for task_id in sorted(result['status']['found']):
            print(f"   ✓ {task_id} → {JIRA_BASE_URL}{task_id}")
    
    print(f"\n❌ Не найдены (заявлены, но нет в коде): {len(result['status']['not_found'])}")
    if result['status']['not_found']:
        for task_id in sorted(result['status']['not_found']):
            print(f"   ✗ {task_id} → {JIRA_BASE_URL}{task_id}")
    
    print(f"\n⚠️ Лишние (есть в коде, но не заявлены): {len(result['status']['extra'])}")
    if result['status']['extra']:
        for task_id in sorted(result['status']['extra']):
            print(f"   ⚠ {task_id} → {JIRA_BASE_URL}{task_id}")
    
    if result['unlinked_commits']:
        print(f"\n⚠️ Коммитов без номера задачи: {len(result['unlinked_commits'])}")
        for commit_hash in result['unlinked_commits'][:5]:
            print(f"   - {commit_hash[:8]}: {commit_cache.get(commit_hash, {}).get('subject', 'No message')}")
    
    # Итоговый вердикт
    print("\n" + "="*60)
    print("📌 ИТОГОВЫЙ ВЕРДИКТ")
    print("="*60)
    
    if not result['status']['not_found'] and not result['status']['extra'] and not result['unlinked_commits']:
        print("✅ ВСЕ ЗАДАЧИ НАЙДЕНЫ! Релиз соответствует заявленному списку.")
        print("   Нет лишних задач и нет коммитов без номера задачи.")
    else:
        issues = []
        if result['status']['not_found']:
            issues.append(f"❌ {len(result['status']['not_found'])} задач не найдены в коде")
        if result['status']['extra']:
            issues.append(f"⚠️ {len(result['status']['extra'])} лишних задач в коде")
        if result['unlinked_commits']:
            issues.append(f"⚠️ {len(result['status']['unlinked_commits'])} коммитов без номера задачи")
        print(f"⚠️ Обнаружены проблемы: {', '.join(issues)}")
        print("   Рекомендуется проверить отчёт для деталей.")
    
    print(f"\n📄 HTML-отчёт сохранён в файл: {html_file}")
    print(f"   Откройте его в браузере для просмотра.")
    
    return result

# Запуск
if __name__ == "__main__":
    # Проверяем конфигурацию Jira
    if JIRA_BASE_URL == "https://your-company.atlassian.net/browse/":
        print("⚠️ ВНИМАНИЕ: Укажите правильный URL вашего Jira в переменной JIRA_BASE_URL")
        print("   Пример: JIRA_BASE_URL = 'https://mycompany.atlassian.net/browse/'")
        print()
    
    # Проверяем, что список задач не пуст
    if not RELEASE_TASKS:
        print("⚠️ ВНИМАНИЕ: Список задач RELEASE_TASKS пуст!")
        print("   Укажите номера задач, которые должны быть в релизе.")
        print("   Пример: RELEASE_TASKS = ['PROJ-123', 'PROJ-456', 'PROJ-789']")
        print()
    
    analyze_release_with_cache()