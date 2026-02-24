# Telegram Skills

Готовый пакет для работы с Telegram через AI-агентов (Claude Code, Codex, Cursor). Один скрипт ставит всё: MCP-сервер, авторизацию, скиллы.

## Установка

### Через агента (рекомендуется)

Скопируй это в чат с агентом (Claude Code, Codex, Cursor):

```
Выполни эту команду: curl -sSL https://raw.githubusercontent.com/expremiental/telegram-skills/main/setup.sh -o /tmp/setup-tg.sh && chmod +x /tmp/setup-tg.sh && open -a Terminal /tmp/setup-tg.sh
```

Откроется окно Terminal. Следуй инструкциям:
1. Введи номер телефона
2. Введи код из Telegram
3. Если есть 2FA — введи пароль

После завершения перезапусти агент и всё работает.

### Вручную

```bash
curl -sSL https://raw.githubusercontent.com/expremiental/telegram-skills/main/setup.sh -o /tmp/setup-tg.sh && bash /tmp/setup-tg.sh
```

Или из клона:

```bash
git clone https://github.com/expremiental/telegram-skills.git
cd telegram-skills
bash setup.sh
```

### Что делает скрипт

- Ставит telegram-mcp и зависимости
- Проводит авторизацию в Telegram (телефон → код → 2FA)
- Регистрирует MCP в найденных агентах
- Копирует скиллы

## Что умеет

После установки агент понимает запросы про Telegram на естественном языке:

```
> покажи дайджест телеграма
> кто мне писал сегодня?
> найди в телеграме обсуждение про отпуск
> сделай саммари чата с Олей за последнюю неделю
> о чём мы договорились с Витей в декабре?
```

Один скилл `telegram-agent` — агент сам определяет что делать по запросу.

## Поддерживаемые агенты

- Claude Code (CLI и VSCode extension)
- Codex (CLI и VSCode extension)
- Cursor (через Claude Code extension)

Если агент не найден — скрипт создаст конфигурацию для Claude Code.

## Безопасность

- Телефон, код и пароль используются **один раз** для входа и **не сохраняются** — ни на диск, ни в логи
- На диск пишется только session token (в `~/.telegram-mcp/.env`) — он нужен MCP-серверу для работы
- Агент работает в **read-only** режиме — читает сообщения, но не может отправлять без твоей явной команды
- Чтобы отключить: `claude mcp remove telegram -s user && rm -rf ~/.telegram-mcp`

## Требования

- Python 3.10+
- Git
- macOS / Linux
