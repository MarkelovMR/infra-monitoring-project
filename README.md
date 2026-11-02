# Infra Monitoring Project

Система мониторинга инфраструктуры: сбор метрик, логов и состояния сервисов с централизованным дашбордом и алертингом.

## Возможности

- Сбор метрик с серверов, контейнеров и сетевого оборудования
- Агрегация и хранение временных рядов
- Визуализация состояния инфраструктуры на дашбордах
- Алертинг по порогам и аномалиям (уведомления в мессенджеры и почту)
- Централизованный сбор и поиск по логам

## Архитектура

```
┌─────────────┐   ┌─────────────┐   ┌─────────────┐
│  Экспортеры │──▶│  Коллектор  │──▶│   Хранилище │
│  метрик     │   │  (агенты)   │   │  (TSDB)     │
└─────────────┘   └─────────────┘   └──────┬──────┘
                                           │
                                    ┌──────▼──────┐
                                    │ Дашборды /  │
                                    │ Алертинг    │
                                    └─────────────┘
```

## Технологический стек

- **Сбор метрик:** Prometheus / exporters (node_exporter, blackbox_exporter)
- **Визуализация:** Grafana
- **Логи:** Loki + Promtail
- **Алертинг:** Alertmanager
- **Развёртывание:** Docker Compose

## Структура проекта

```
infra-monitoring-project/
├── README.md            # Описание проекта (этот файл)
├── .gitignore           # Исключения для git
├── docker-compose.yml   # Оркестрация сервисов мониторинга
├── prometheus/          # Конфигурация Prometheus
├── grafana/             # Дашборды и provisioning Grafana
├── alertmanager/        # Конфигурация алертинга
└── docs/                # Дополнительная документация
```

## Быстрый старт

```bash
# Клонировать репозиторий
git clone https://github.com/MarkelovMR/infra-monitoring-project.git
cd infra-monitoring-project

# Запустить стек (появится по мере развития проекта)
docker compose up -d
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

## Лицензия

MIT (уточняется)
