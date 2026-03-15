# Контекст проекта для продолжения работы в Claude Code

> Скопируй этот файл в свой репо и скажи Claude Code: "Прочитай HANDOFF.md и продолжи работу"

---

## Репозиторий

- **GitHub**: `911work/dashboard`
- **Ветка разработки**: `claude/setup-aidebator-ZkIMS`
- **Основная ветка**: `main`

```bash
git clone https://github.com/911work/dashboard.git
cd dashboard
git checkout claude/setup-aidebator-ZkIMS
```

---

## Что сделано

### 1. AIDebator — платформа для AI-дебатов

Создан проект `AIDebator/` — система для проведения автоматических дебатов между LLM (GPT, Claude, и др.). Находится в папке `AIDebator/`.

**Ключевые компоненты:**
- `src/debate/` — ядро системы (engine, models, participants)
- `debate_cli.py` — CLI-интерфейс для запуска дебатов
- `debate_sl.py` — Streamlit веб-интерфейс
- `debate_report.html` — HTML-отчёт с результатами дебатов (автономный, с аналитикой)

**Архитектура:**
- **Session** (`src/debate/engine/session.py`) — движок дебатов, управляет раундами
- **Participants** — Organizer, Debater (Supporter/Opposer), Judge
- **Scoring** — взвешенная система оценки (Evidence Quality — 40% веса)
- **Валидация** — автоматическое завершение при падении качества аргументов
- Поддержка 20+ LLM-провайдеров через **litellm**

**Зависимости:** `requirements.txt` (litellm, streamlit, pydantic, rich)

### 2. Проведённые дебаты

Тема: **"Миграция affiliate-платформы с монолита на микросервисы"**

| Файл | Участники | Раунды |
|------|-----------|--------|
| `debate_result_migration_v2.json` | Claude Opus 4.6 vs GPT-4.1 | 3 |
| `debate_result_migration_v4.json` | Claude Opus 4.6 vs GPT-5.2 | 3 |

### 3. HTML-отчёт (`debate_report.html`)

Полностью автономный HTML-файл с:
- Аналитическим дашбордом (радарные диаграммы, bar-чарты)
- Полными текстами аргументов обоих дебатов
- Оценками судьи по раундам
- Сравнительным анализом моделей

**Просмотр:** открыть локально в браузере или через:
`https://htmlpreview.github.io/?https://github.com/911work/dashboard/blob/claude/setup-aidebator-ZkIMS/AIDebator/debate_report.html`

### 4. GitHub Pages

- Ветка `gh-pages` содержит `index.html` со ссылкой на отчёт
- Создан `index.html` в корне ветки разработки

### 5. Исправления

- Фикс совместимости с GPT-5+ reasoning-моделями: пропуск `max_tokens` и `temperature` для моделей, не поддерживающих эти параметры (`e3a4b13`)

---

## Структура файлов

```
dashboard/
├── index.html                          # Страница для GitHub Pages
└── AIDebator/
    ├── src/debate/                      # Ядро платформы
    │   ├── engine/session.py            # Движок дебатов
    │   ├── models/                      # Pydantic-модели (Config, Entities)
    │   └── participants/                # Organizer, Debater, Judge
    ├── debate_cli.py                    # CLI
    ├── debate_sl.py                     # Streamlit UI
    ├── debate_report.html               # Финальный HTML-отчёт
    ├── debate_result_migration_v2.json  # Результаты: Opus vs GPT-4.1
    ├── debate_result_migration_v4.json  # Результаты: Opus vs GPT-5.2
    ├── docs/                            # Документация
    ├── Makefile                         # Команды сборки/запуска
    ├── requirements.txt                 # Python-зависимости
    └── test_debate_features.py          # Тесты
```

---

## Git-история (хронологически)

```
f3635b6 Create index.html
5988732 Update index.html
8a9735d Add AIDebator project - AI debate simulation framework
7e1410f Add migration affiliate platform debate results (Opus 4.6 vs GPT-4.1)
e3a4b13 Fix GPT-5+ compatibility: skip max_tokens and temperature for reasoning models
0774bc5 Add professional HTML analytics report for migration affiliate platform
64130b6 Add Opus 4.6 vs GPT-5.2 debate results and update HTML report
05c19ca Update HTML report with full v4 debate content (Opus 4.6 vs GPT-5.2)
9b74e47 Add index.html for GitHub Pages deployment
```

---

## Как запустить дебат

```bash
cd AIDebator
pip install -r requirements.txt

# CLI
python debate_cli.py --topic "Your topic" --rounds 3 \
  --supporter-model "claude-opus-4-6" \
  --opposer-model "gpt-4.1"

# Streamlit UI
streamlit run debate_sl.py
```

Нужны API-ключи: `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` (через переменные окружения).

---

## Что можно делать дальше

- Запустить новые дебаты на другие темы
- Добавить новые модели (Gemini, Llama, и т.д.)
- Улучшить HTML-отчёт (больше визуализаций)
- Настроить CI/CD для автоматического деплоя на GitHub Pages
- Добавить поддержку экспорта в PDF
- Расширить систему скоринга
