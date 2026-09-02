# ---------- Шаг 3: Собираем строки, которые нужно проверить ----------
lines_to_check = {}
skipped_files = []  # Массив для пропущенных файлов

# Расширения бинарных файлов
BINARY_EXTENSIONS = {
    '.dll', '.exe', '.so', '.dylib', '.bin',
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.webp', '.svg',
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.zip', '.tar', '.gz', '.rar', '.7z',
    '.pyc', '.pyo', '.class', '.jar',
    '.db', '.sqlite', '.mdb',
    '.ttf', '.woff', '.woff2', '.eot',
    '.mp3', '.mp4', '.avi', '.mov', '.wav'
}

for file in files:
    # Проверяем расширение файла
    ext = os.path.splitext(file)[1].lower()
    if ext in BINARY_EXTENSIONS:
        skipped_files.append({
            'file': file,
            'reason': 'Бинарный файл (расширение)'
        })
        print(f"  ⏭️ Пропускаем бинарный файл: {file}")
        continue
    
    line_numbers = get_changed_line_numbers(base, 'release/R001', file)
    
    if not line_numbers:
        skipped_files.append({
            'file': file,
            'reason': 'Нет изменённых строк'
        })
        print(f"  ℹ️ Нет изменений в файле: {file}")
        continue
    
    lines_to_check[file] = line_numbers

print(f"📝 Всего файлов для проверки: {len(lines_to_check)}")
print(f"⏭️ Пропущено файлов: {len(skipped_files)}")
2. Добавить skipped_files в результат
В разделе формирования result добавьте:

python
# Шаг 7: Формируем финальный результат для HTML
result = {
    'tasks': defaultdict(lambda: {'files': []}),
    'commits': [],
    'files': list(lines_to_check.keys()),
    'unlinked_commits': [],
    'declared_tasks': RELEASE_TASKS,
    'skipped_files': skipped_files,  # <-- ДОБАВИТЬ ЭТУ СТРОКУ
    'status': {
        'found': [],
        'not_found': [],
        'extra': []
    }
}

python
# Пропущенные файлы
if results.get('skipped_files'):
    html += """
    <div class="status-section" style="border-left: 4px solid #f39c12; margin-top: 20px;">
        <h2 style="color:#f39c12;">⏭️ Пропущенные файлы</h2>
        <p style="color:#6b7a8d;margin-bottom:10px;font-size:14px;">
            Эти файлы были пропущены при анализе (бинарные или без изменений).
        </p>
        <div style="background:#f8f9fa;border-radius:6px;padding:10px;">
"""
    
    for skipped in results['skipped_files']:
        file_path = skipped['file']
        reason = skipped['reason']
        
        # Ссылка на файл в GitLab
        file_url = None
        if gitlab_url:
            file_url = f"{gitlab_url}/-/blob/release/R001/{file_path}"
        
        html += f"""
        <div style="display:flex;align-items:center;gap:10px;padding:4px 0;border-bottom:1px solid #e9ecef;font-size:13px;">
            <span style="color:#f39c12;">⏭️</span>
            <span style="font-weight:500;">
                {'🔗 <a href="' + file_url + '" target="_blank" style="color:#3498db;text-decoration:none;">' if file_url else ''}
                {file_path}
                {'</a>' if file_url else ''}
            </span>
            <span style="color:#6b7a8d;font-size:12px;background:#f0f2f5;padding:2px 8px;border-radius:4px;">
                {reason}
            </span>
        </div>
"""
    
    html += """
        </div>
    </div>
"""

4. Full Update
python
# ---------- Шаг 3: Собираем строки, которые нужно проверить ----------
lines_to_check = {}
skipped_files = []  # Массив для пропущенных файлов

# Расширения бинарных файлов (можно дополнить)
BINARY_EXTENSIONS = {
    '.dll', '.exe', '.so', '.dylib', '.bin',
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.ico', '.webp', '.svg',
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx',
    '.zip', '.tar', '.gz', '.rar', '.7z',
    '.pyc', '.pyo', '.class', '.jar',
    '.db', '.sqlite', '.mdb',
    '.ttf', '.woff', '.woff2', '.eot',
    '.mp3', '.mp4', '.avi', '.mov', '.wav'
}

for file in files:
    # Проверяем расширение файла
    ext = os.path.splitext(file)[1].lower()
    if ext in BINARY_EXTENSIONS:
        skipped_files.append({
            'file': file,
            'reason': 'Бинарный файл (расширение)'
        })
        print(f"  ⏭️ Пропускаем бинарный файл: {file}")
        continue
    
    line_numbers = get_changed_line_numbers(base, 'release/R001', file)
    
    if not line_numbers:
        skipped_files.append({
            'file': file,
            'reason': 'Нет изменённых строк'
        })
        print(f"  ℹ️ Нет изменений в файле: {file}")
        continue
    
    lines_to_check[file] = line_numbers

print(f"📝 Всего файлов для проверки: {len(lines_to_check)}")
print(f"⏭️ Пропущено файлов: {len(skipped_files)}")

5. Добавить skipped_files в сводку в HTML
В верхней части отчёта, в блоке .summary, можно добавить ещё одну карточку:

python
html += f"""
<div class="summary-card">
    <div class="number orange">{len(results.get('skipped_files', []))}</div>
    <div class="label">⏭️ Пропущено файлов</div>
</div>
"""