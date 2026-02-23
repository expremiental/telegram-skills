#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Telegram Skills — установка MCP + скиллов для AI-агентов
# Использование: bash setup.sh
# ============================================================

API_ID="35091485"
API_HASH="43ac0285e9db4a51b9f84ce3dc6244d6"
MCP_REPO_URL="https://github.com/chigwell/telegram-mcp"
SKILLS_REPO_URL="https://github.com/expremiental/telegram-skills"
INSTALL_DIR="$HOME/.telegram-mcp"
SKILLS_REPO_DIR="$HOME/.telegram-skills"
SERVER_SCRIPT="main.py"
MCP_NAME="telegram"

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}→${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}!${NC} $1"; }
fail()  { echo -e "${RED}✗${NC} $1"; exit 1; }

echo ""
echo "========================================"
echo "  Telegram Skills — установка"
echo "========================================"
echo ""

# ----------------------------------------------------------
# Шаг 1: Проверка зависимостей
# ----------------------------------------------------------
info "Проверяю зависимости..."

# Python
if ! command -v python3 &>/dev/null; then
    fail "Python 3 не найден. Установи: https://python.org"
fi

PY_VERSION=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)

if [ "$PY_MAJOR" -lt 3 ] || ([ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 10 ]); then
    fail "Нужен Python 3.10+, найден $PY_VERSION"
fi
ok "Python $PY_VERSION"

# Git
if ! command -v git &>/dev/null; then
    fail "Git не найден. Установи его."
fi
ok "Git"

# uv
if ! command -v uv &>/dev/null; then
    info "Устанавливаю uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if ! command -v uv &>/dev/null; then
        fail "Не удалось установить uv. Установи вручную: https://docs.astral.sh/uv/"
    fi
fi
ok "uv"

# ----------------------------------------------------------
# Шаг 2: Определяю агентов
# ----------------------------------------------------------
echo ""
info "Ищу AI-агентов..."

AGENTS=()        # массив найденных агентов: "claude-cli", "claude-ext", "codex-cli", "codex-ext", "fallback"
SKILLS_DIRS=()   # куда ставить скиллы для каждого агента

# Claude Code CLI
if command -v claude &>/dev/null; then
    AGENTS+=("claude-cli")
    SKILLS_DIRS+=("$HOME/.claude/skills")
    ok "Claude Code (CLI)"
fi

# Claude Code VSCode extension
if [ -f "$HOME/.claude.json" ] && ! printf '%s\n' "${AGENTS[@]}" 2>/dev/null | grep -q "claude-cli"; then
    AGENTS+=("claude-ext")
    SKILLS_DIRS+=("$HOME/.claude/skills")
    ok "Claude Code (VSCode extension)"
fi

# Codex CLI
if command -v codex &>/dev/null; then
    AGENTS+=("codex-cli")
    SKILLS_DIRS+=("$HOME/.codex/skills")
    ok "Codex (CLI)"
fi

# Codex VSCode extension
if [ -f "$HOME/.codex/config.toml" ] && ! printf '%s\n' "${AGENTS[@]}" 2>/dev/null | grep -q "codex-cli"; then
    AGENTS+=("codex-ext")
    SKILLS_DIRS+=("$HOME/.codex/skills")
    ok "Codex (VSCode extension)"
fi

# Ничего не найдено — fallback на Claude
if [ ${#AGENTS[@]} -eq 0 ]; then
    warn "AI-агент не найден. Создам конфигурацию для Claude Code."
    AGENTS+=("fallback")
    SKILLS_DIRS+=("$HOME/.claude/skills")
fi

# ----------------------------------------------------------
# Шаг 3: Клонирование репозиториев
# ----------------------------------------------------------
echo ""

# 3a: telegram-mcp (MCP-сервер)
if [ -d "$INSTALL_DIR" ] && [ -f "$INSTALL_DIR/$SERVER_SCRIPT" ]; then
    ok "telegram-mcp уже есть: $INSTALL_DIR"
else
    if [ -d "$INSTALL_DIR" ]; then
        warn "Директория существует, но выглядит неправильно. Удаляю..."
        rm -rf "$INSTALL_DIR"
    fi
    info "Клонирую telegram-mcp..."
    git clone --quiet "$MCP_REPO_URL" "$INSTALL_DIR"
    ok "telegram-mcp → $INSTALL_DIR"
fi

# 3b: telegram-skills (скиллы)
if [ -d "$SKILLS_REPO_DIR" ] && [ -d "$SKILLS_REPO_DIR/skills" ]; then
    info "Обновляю скиллы..."
    git -C "$SKILLS_REPO_DIR" pull --quiet 2>/dev/null || true
    ok "telegram-skills обновлён"
else
    if [ -d "$SKILLS_REPO_DIR" ]; then
        rm -rf "$SKILLS_REPO_DIR"
    fi
    info "Клонирую telegram-skills..."
    git clone --quiet "$SKILLS_REPO_URL" "$SKILLS_REPO_DIR"
    ok "telegram-skills → $SKILLS_REPO_DIR"
fi

SKILLS_SRC="$SKILLS_REPO_DIR/skills"

# ----------------------------------------------------------
# Шаг 4: Установка зависимостей
# ----------------------------------------------------------
info "Устанавливаю зависимости..."
cd "$INSTALL_DIR"
uv sync --quiet 2>/dev/null || uv sync
ok "Зависимости установлены"

# ----------------------------------------------------------
# Шаг 5: Создание .env
# ----------------------------------------------------------
if [ -f "$INSTALL_DIR/.env" ] && grep -q "TELEGRAM_SESSION_STRING=." "$INSTALL_DIR/.env" 2>/dev/null; then
    ok "Сессия уже есть — пропускаю авторизацию"
    SKIP_AUTH=true
else
    cat > "$INSTALL_DIR/.env" <<EOF
TELEGRAM_API_ID=$API_ID
TELEGRAM_API_HASH=$API_HASH
TELEGRAM_SESSION_NAME=telegram_session
EOF
    ok ".env создан"
    SKIP_AUTH=false
fi

# ----------------------------------------------------------
# Шаг 6: Авторизация в Telegram
# ----------------------------------------------------------
if [ "$SKIP_AUTH" = false ]; then
    echo ""
    echo "========================================"
    echo "  Авторизация в Telegram"
    echo "========================================"
    echo ""
    echo "Нужно войти в твой аккаунт Telegram."
    echo "Код подтверждения придёт в приложение Telegram."
    echo ""
    echo "Телефон, код и пароль используются один раз и НЕ сохраняются."
    echo ""

    cat > "$INSTALL_DIR/_auth.py" <<'PYEOF'
import os, sys, asyncio
from telethon import TelegramClient
from telethon.sessions import StringSession
from telethon.errors import (
    SessionPasswordNeededError,
    FloodWaitError,
    PhoneNumberBannedError,
    ApiIdInvalidError,
)
from dotenv import load_dotenv

load_dotenv()

API_ID = int(os.getenv("TELEGRAM_API_ID"))
API_HASH = os.getenv("TELEGRAM_API_HASH")


async def main():
    client = TelegramClient(StringSession(), API_ID, API_HASH)
    await client.connect()

    phone = input("Введите номер телефона (например +79991234567): ").strip()
    if not phone:
        print("ОШИБКА: Номер телефона обязателен")
        sys.exit(1)

    try:
        result = await client.send_code_request(phone)
    except FloodWaitError as e:
        print(f"ОШИБКА: Слишком много попыток. Подожди {e.seconds} секунд и попробуй снова.")
        sys.exit(1)
    except ApiIdInvalidError:
        print("ОШИБКА: Неверные API-ключи. Обратись к автору.")
        sys.exit(1)
    except PhoneNumberBannedError:
        print("ОШИБКА: Этот номер заблокирован Telegram.")
        sys.exit(1)
    except Exception as e:
        print(f"ОШИБКА: {e}")
        sys.exit(1)

    code = input("Введите код из Telegram: ").strip()

    try:
        await client.sign_in(phone, code, phone_code_hash=result.phone_code_hash)
    except SessionPasswordNeededError:
        for attempt in range(3):
            password = input("У тебя включена 2FA. Введите пароль Telegram: ").strip()
            try:
                await client.sign_in(password=password)
                break
            except Exception as e:
                if attempt < 2:
                    print(f"Неверный пароль, попробуй ещё ({2 - attempt} попыток осталось)")
                else:
                    print(f"ОШИБКА: 3 неудачных попытки: {e}")
                    await client.disconnect()
                    sys.exit(1)
    except Exception as e:
        print(f"ОШИБКА: Не удалось войти: {e}")
        await client.disconnect()
        sys.exit(1)

    session_string = client.session.save()
    await client.disconnect()

    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    with open(env_path, "r") as f:
        lines = f.readlines()

    found = False
    for i, line in enumerate(lines):
        if line.startswith("TELEGRAM_SESSION_STRING="):
            lines[i] = f"TELEGRAM_SESSION_STRING={session_string}\n"
            found = True
            break

    if not found:
        lines.append(f"TELEGRAM_SESSION_STRING={session_string}\n")

    with open(env_path, "w") as f:
        f.writelines(lines)

    print("")
    print("SESSION_OK")


asyncio.run(main())
PYEOF

    cd "$INSTALL_DIR"
    if uv run _auth.py; then
        ok "Сессия Telegram сохранена"
    else
        rm -f "$INSTALL_DIR/_auth.py"
        fail "Авторизация не удалась. Запусти скрипт ещё раз."
    fi

    rm -f "$INSTALL_DIR/_auth.py"
fi

# ----------------------------------------------------------
# Шаг 7: Регистрация MCP в агентах
# ----------------------------------------------------------
echo ""
info "Регистрирую MCP..."

for i in "${!AGENTS[@]}"; do
    agent="${AGENTS[$i]}"

    case "$agent" in
        claude-cli)
            claude mcp remove "$MCP_NAME" -s user 2>/dev/null || true
            claude mcp add "$MCP_NAME" -s user -- uv --directory "$INSTALL_DIR" run "$SERVER_SCRIPT"
            ok "MCP зарегистрирован в Claude Code (CLI)"
            ;;
        claude-ext|fallback)
            # Записываем напрямую в ~/.claude.json
            CLAUDE_JSON="$HOME/.claude.json"
            MCP_CMD="uv --directory $INSTALL_DIR run $SERVER_SCRIPT"
            if [ -f "$CLAUDE_JSON" ]; then
                # Если файл существует, пробуем добавить MCP через jq или вручную
                if command -v jq &>/dev/null; then
                    TMP_JSON=$(mktemp)
                    jq --arg name "$MCP_NAME" --arg dir "$INSTALL_DIR" --arg script "$SERVER_SCRIPT" \
                        '.mcpServers[$name] = {"command": "uv", "args": ["--directory", $dir, "run", $script]}' \
                        "$CLAUDE_JSON" > "$TMP_JSON" && mv "$TMP_JSON" "$CLAUDE_JSON"
                else
                    warn "jq не найден — не могу обновить $CLAUDE_JSON автоматически"
                    warn "Добавь MCP вручную: claude mcp add $MCP_NAME -s user -- uv --directory $INSTALL_DIR run $SERVER_SCRIPT"
                fi
            else
                # Создаём файл с нуля
                cat > "$CLAUDE_JSON" <<JSONEOF
{
  "mcpServers": {
    "$MCP_NAME": {
      "command": "uv",
      "args": ["--directory", "$INSTALL_DIR", "run", "$SERVER_SCRIPT"]
    }
  }
}
JSONEOF
            fi
            if [ "$agent" = "fallback" ]; then
                ok "MCP зарегистрирован в ~/.claude.json (Claude Code не найден, конфигурация создана)"
            else
                ok "MCP зарегистрирован в Claude Code (VSCode extension)"
            fi
            ;;
        codex-cli)
            codex mcp add "$MCP_NAME" -- uv --directory "$INSTALL_DIR" run "$SERVER_SCRIPT" 2>/dev/null || \
                warn "Не удалось зарегистрировать MCP в Codex CLI. Добавь вручную."
            ok "MCP зарегистрирован в Codex"
            ;;
        codex-ext)
            warn "Codex extension найден, но автоматическая регистрация MCP не поддерживается."
            warn "Добавь MCP вручную в конфигурацию Codex."
            ;;
    esac
done

# ----------------------------------------------------------
# Шаг 8: Установка скиллов
# ----------------------------------------------------------
echo ""
info "Устанавливаю скиллы..."

if [ ! -d "$SKILLS_SRC" ]; then
    warn "Директория со скиллами не найдена: $SKILLS_SRC"
    warn "Скиллы можно установить позже, скопировав файлы из skills/ в ~/.claude/skills/"
else
    # Дедупликация директорий (bash 3.2 совместимо)
    UNIQUE_DIRS=""
    for dir in "${SKILLS_DIRS[@]}"; do
        if ! echo "$UNIQUE_DIRS" | grep -qF "$dir"; then
            UNIQUE_DIRS="$UNIQUE_DIRS $dir"
        fi
    done

    for skills_target in $UNIQUE_DIRS; do
        mkdir -p "$skills_target"

        for skill_dir in "$SKILLS_SRC"/*/; do
            skill_name=$(basename "$skill_dir")
            target_dir="$skills_target/telegram-$skill_name"
            mkdir -p "$target_dir"
            cp "$skill_dir/SKILL.md" "$target_dir/SKILL.md"
        done

        ok "Скиллы установлены в $skills_target"
    done
fi

# ----------------------------------------------------------
# Готово
# ----------------------------------------------------------
echo ""
echo "========================================"
echo -e "  ${GREEN}Готово!${NC}"
echo "========================================"
echo ""
echo "Что дальше:"
echo "  1. Перезапусти агент (в Claude Code: Cmd+R или закрой и открой)"
echo "  2. Попробуй: «покажи дайджест телеграма»"
echo ""
echo "Доступные команды:"
echo "  /digest          — дайджест непрочитанного"
echo "  /who-wrote-me    — кто писал сегодня"
echo "  /find-in-tg      — поиск по чатам"
echo "  /summarize-chat  — саммари чата"
echo ""

read -n 1 -s -r -p "Нажми любую клавишу чтобы закрыть..."
echo ""
