# Infra Monitoring Project

Учебный проект по мониторингу инфраструктуры: bash-скрипты для проверки доступности API и анализа логов, плюс docker-compose-стенд с nginx-прокси.

## Что есть в проекте

- `check_api.sh` — проверка доступности API: делает HTTP-запрос через `curl`, возвращает код 0, если ответ 200, и 1 в остальных случаях
- `analyze_logs.sh` — генерирует тестовый `access.log` (350 строк) и выводит статистику: общее число запросов, топ-3 IP, количество ответов 4xx/5xx
- `docker-compose.yml` + `nginx.conf` — стенд из двух контейнеров: `api` (hashicorp/http-echo, отвечает «Monitoring Service Active» на порту 8080) и `proxy` (nginx:alpine, проксирует порт 80 на `api:8080`), связанных внутренней сетью Docker
- `.github/workflows/ci.yml` — CI-пайплайн на Pull Request: проверка синтаксиса скриптов (`bash -n`) и тест `check_api.sh` по адресу https://httpbin.org/status/200 с ожиданием кода возврата 0

## Технологический стек

- **Скрипты:** Bash, curl, awk/grep/sort
- **Контейнеры:** Docker Compose (hashicorp/http-echo, nginx:alpine)
- **CI:** GitHub Actions

## Структура проекта

```
infra-monitoring-project/
├── README.md               # Описание проекта (этот файл)
├── .gitignore              # Исключения для git
├── check_api.sh            # Проверка доступности API
├── analyze_logs.sh         # Генерация и анализ тестового access.log
├── access.log              # Пример лога (генерируется скриптом)
├── docker-compose.yml      # Стенд: api (http-echo) + proxy (nginx)
├── nginx.conf              # Проксирование :80 -> api:8080
└── .github/workflows/
    └── ci.yml              # CI-пайплайн для Pull Request
```

## Быстрый старт

```bash
# Клонировать репозиторий
git clone https://github.com/MarkelovMR/infra-monitoring-project.git
cd infra-monitoring-project

# Проверить доступность API
./check_api.sh https://httpbin.org/status/200

# Сгенерировать и разобрать тестовый лог
./analyze_logs.sh

# Поднять docker-compose-стенд
docker compose up -d
curl http://localhost:80   # -> Monitoring Service Active
```

## Безопасная передача файлов на удалённый сервер

Деплой проекта выполняется по SSH без паролей — с использованием ключевой пары.

### 1. Генерация SSH-ключей

```bash
# Современный алгоритм Ed25519 (рекомендуется)
ssh-keygen -t ed25519 -C "deploy@infra-monitoring" -f ~/.ssh/id_ed25519

# Альтернатива, если сервер старый и не поддерживает Ed25519
ssh-keygen -t rsa -b 4096 -C "deploy@infra-monitoring" -f ~/.ssh/id_rsa
```

Закрытый ключ (`id_ed25519`) никуда не копируется и не передаётся; на сервер отправляется только публичный (`id_ed25519.pub`).

### 2. Копирование публичного ключа на сервер

```bash
# Ключ добавится в ~/.ssh/authorized_keys на сервере
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@server.example.com

# Если ssh-copy-id недоступен (Windows/Git Bash) — эквивалент вручную:
cat ~/.ssh/id_ed25519.pub | ssh user@server.example.com \
  "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Проверка подключения по ключу (пароль больше не запрашивается)
ssh user@server.example.com "echo OK"
```

### 3. Передача архива проекта

Вариант A — через `scp`:

```bash
# Создать архив проекта (без .git и служебных файлов)
tar --exclude=.git -czf infra-monitoring-project.tar.gz .

# Передать архив на сервер
scp -i ~/.ssh/id_ed25519 infra-monitoring-project.tar.gz user@server.example.com:/opt/

# Распаковать на сервере
ssh user@server.example.com "mkdir -p /opt/infra-monitoring && \
  tar -xzf /opt/infra-monitoring-project.tar.gz -C /opt/infra-monitoring"
```

Вариант B — потоковая передача `tar + ssh` без промежуточного файла:

```bash
tar --exclude=.git -czf - . | ssh user@server.example.com \
  "mkdir -p /opt/infra-monitoring && tar -xzf - -C /opt/infra-monitoring"
```

### Пример полного цикла деплоя

```bash
# 1. Передать свежую версию проекта
tar --exclude=.git -czf - . | ssh user@server.example.com \
  "mkdir -p /opt/infra-monitoring && tar -xzf - -C /opt/infra-monitoring"

# 2. Перезапустить стек на сервере
ssh user@server.example.com "cd /opt/infra-monitoring && \
  docker compose pull && docker compose up -d"

# 3. Проверить, что сервис отвечает
ssh user@server.example.com "curl -s http://localhost:80"
# Ожидаемый ответ: Monitoring Service Active
```

### Рекомендации по безопасности

- Отключите вход по паролю на сервере (`PasswordAuthentication no` в `/etc/ssh/sshd_config`) после настройки ключей
- Используйте отдельный ключ для деплоя и храните его с парольной фразой (passphrase)
- Ограничьте права deploy-пользователя на сервере (без root, docker-группа по необходимости)

## Ветвление

- `main` — защищённая ветка, изменения попадают только через Pull Request
- `feature/monitoring` — рабочая ветка для разработки

