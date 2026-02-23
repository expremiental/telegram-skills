# Telegram Skills

Готовый пакет для работы с Telegram через AI-агентов (Claude Code, Codex, Cursor). Один скрипт ставит всё: MCP-сервер, авторизацию, скиллы.

## Установка

```bash
curl -sSL https://raw.githubusercontent.com/expremiental/telegram-skills/main/setup.sh -o /tmp/setup-tg.sh && chmod +x /tmp/setup-tg.sh && open -a Terminal /tmp/setup-tg.sh
```

Или локально:

```bash
git clone https://github.com/expremiental/telegram-skills.git
cd telegram-skills
bash setup.sh
```

Скрипт сам:
- Установит telegram-mcp и зависимости
- Проведёт авторизацию в Telegram (телефон → код → 2FA)
- Зарегистрирует MCP в твоём агенте
- Скопирует скиллы

## Скиллы

| Команда | Что делает |
|---------|-----------|
| `/digest` | Дайджест непрочитанных сообщений |
| `/who-wrote-me` | Кто писал сегодня, ждут ли ответа |
| `/find-in-tg` | Поиск по чатам по ключевым словам |
| `/summarize-chat` | Саммари чата — темы, решения, вопросы |

Плюс фоновый скилл `telegram-agent` — агент автоматически знает как работать с Telegram MCP.

## Примеры

```
> покажи дайджест телеграма
> кто мне писал сегодня?
> найди в телеграме обсуждение про отпуск
> сделай саммари чата с Олей за последнюю неделю
```

## Поддерживаемые агенты

- Claude Code (CLI и VSCode extension)
- Codex (CLI и VSCode extension)
- Cursor (через Claude Code extension)

Если агент не найден — скрипт создаст конфигурацию для Claude Code.

## Требования

- Python 3.10+
- Git
- macOS / Linux
