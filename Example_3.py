1. Update get_blame_for_file
python
def get_blame_for_file(target_branch, file_path):
    """
    Возвращает словарь {номер_строки: (хеш_коммита, is_moved)}
    Используем --line-porcelain с опциями -M и -C для обнаружения перемещений.
    """
    try:
        # Используем -M и -C для обнаружения перемещений и копирований
        output = subprocess.run(
            ['git', 'blame', '--line-porcelain', '-M', '-C', '-w', target_branch, '--', file_path],
            capture_output=True, text=True, check=True,
            encoding='utf-8', errors='replace'
        ).stdout
    except subprocess.CalledProcessError:
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
                
                # Ищем информацию об оригинальном коммите и строке
                origin_commit = commit_hash
                origin_line = final_line_num
                is_moved = False
                is_boundary = False
                
                # Пропускаем мета-поля
                i += 1
                while i < len(lines) and not lines[i].startswith('\t'):
                    meta_line = lines[i]
                    if meta_line.startswith('previous '):
                        parts_prev = meta_line.split()
                        if len(parts_prev) >= 2:
                            origin_commit = parts_prev[1]
                    elif meta_line.startswith('orig-line '):
                        parts_orig = meta_line.split()
                        if len(parts_orig) >= 2:
                            origin_line = int(parts_orig[1])
                    elif meta_line.startswith('boundary'):
                        is_boundary = True
                    i += 1
                
                # Определяем, является ли строка перемещённой
                # Если это перемещение (разные коммиты) и не boundary
                if commit_hash != origin_commit and not is_boundary:
                    is_moved = True
                elif commit_hash == origin_commit and origin_line != final_line_num:
                    # Обычно это не перемещение, а просто изменение в том же коммите
                    is_moved = False
                
                if i < len(lines) and lines[i].startswith('\t'):
                    blame_map[final_line_num] = {
                        'commit': commit_hash,
                        'is_moved': is_moved  # True, если строка была перемещена
                    }
        
        i += 1
    
    return blame_map
    
2. Update Шаг 4 (сбор blame)
python
# ---------- Шаг 4: Получаем blame для каждого файла ----------
file_blame_cache = {}
for idx, file in enumerate(lines_to_check.keys(), 1):
    print(f"  ⏳ [{idx}/{len(lines_to_check)}] Загружаем blame для: {file}")
    file_blame_cache[file] = get_blame_for_file('release/R001', file)
3. Обновлённый Шаг 7 (фильтрация перемещённых строк)
python
# ---------- Шаг 7: Формируем финальный результат (ИСКЛЮЧАЯ перемещённые строки) ----------
tasks_data = defaultdict(lambda: defaultdict(list))
found_in_code = set()
moved_count = 0
new_count = 0

for file, blame_map in file_blame_cache.items():
    for line_num in lines_to_check[file]:
        blame_info = blame_map.get(line_num)
        if not blame_info:
            continue
        
        commit_hash = blame_info['commit']
        is_moved = blame_info.get('is_moved', False)
        
        # ⚠️ ИСКЛЮЧАЕМ перемещённые строки из анализа
        if is_moved:
            moved_count += 1
            continue  # Пропускаем эту строку
        
        new_count += 1
        
        if commit_hash not in commit_cache:
            continue
        
        task_id = commit_cache[commit_hash]['task_id']
        
        if not task_id:
            # Коммит без задачи
            if commit_hash not in result['unlinked_commits']:
                result['unlinked_commits'].append(commit_hash)
            continue
        
        found_in_code.add(task_id)
        tasks_data[task_id][file].append({
            'line': line_num,
            'commit': commit_hash
        })

print(f"📊 Исключено перемещённых строк: {moved_count}")
print(f"📊 Оставлено для анализа: {new_count}")

📋 Update Шаг 7 с контекстом
python
# ---------- Шаг 7: Формируем финальный результат ----------
result = {
    'tasks': defaultdict(lambda: {'files': []}),
    'commits': [],
    'files': list(lines_to_check.keys()),
    'unlinked_commits': [],
    'declared_tasks': RELEASE_TASKS,
    'skipped_files': skipped_files,
    'status': {
        'found': [],
        'not_found': [],
        'extra': []
    },
    'stats': {
        'moved_lines': 0,
        'analyzed_lines': 0
    }
}

# Группируем изменения по задачам
tasks_data = defaultdict(lambda: defaultdict(list))
found_in_code = set()
moved_count = 0
analyzed_count = 0

for file, blame_map in file_blame_cache.items():
    for line_num in lines_to_check[file]:
        blame_info = blame_map.get(line_num)
        if not blame_info:
            continue
        
        commit_hash = blame_info['commit']
        is_moved = blame_info.get('is_moved', False)
        
        # ⚠️ ИСКЛЮЧАЕМ перемещённые строки из анализа
        if is_moved:
            moved_count += 1
            continue
        
        analyzed_count += 1
        
        if commit_hash not in commit_cache:
            continue
        
        task_id = commit_cache[commit_hash]['task_id']
        
        if not task_id:
            # Коммит без задачи
            if commit_hash not in result['unlinked_commits']:
                result['unlinked_commits'].append(commit_hash)
            continue
        
        found_in_code.add(task_id)
        tasks_data[task_id][file].append({
            'line': line_num,
            'commit': commit_hash
        })

# Сохраняем статистику
result['stats']['moved_lines'] = moved_count
result['stats']['analyzed_lines'] = analyzed_count

# Формируем структуру для HTML
for task_id, files_data in tasks_data.items():
    task_files = []
    for file_path, changes in files_data.items():
        task_files.append({
            'file': file_path,
            'changes': changes
        })
    result['tasks'][task_id] = {'files': task_files}
🎨 Обновлённый HTML-отчёт (добавляем статистику по перемещениям)
В сводку сверху добавляем карточку:

python
html += f"""
<div class="summary-card">
    <div class="number orange">{results.get('stats', {}).get('moved_lines', 0)}</div>
    <div class="label">📦 Исключено перемещений</div>
</div>
<div class="summary-card">
    <div class="number green">{results.get('stats', {}).get('analyzed_lines', 0)}</div>
    <div class="label">✅ Проанализировано строк</div>
</div>
"""