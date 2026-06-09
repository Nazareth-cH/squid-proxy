# Squid Proxy Server

Корпоративный прокси-сервер с аутентификацией, фильтрацией контента и прозрачным режимом, развёрнутый в Docker.

## О проекте

Проект реализует прокси-сервер [Squid](http://www.squid-cache.org/) для контроля доступа в интернет. Решает задачи ограничения доступа к нежелательным сайтам, кэширования часто запрашиваемого контента для экономии трафика и аудита действий пользователей.

**Основные возможности:**
- Контейнеризация (Docker, Docker Compose)
- Аутентификация пользователей (HTTP Basic Auth)
- ACL: блокировка по доменам, типам файлов, времени суток
- Прозрачный режим (опционально, правила nftables)
- Кэширование статического контента
- Автоматическое тестирование работоспособности
- Парсер логов для аналитики

## Технологический стек

- **Сервис**: Squid 6.9 на Alpine Linux
- **Оркестрация**: Docker, Docker Compose
- **Автоматизация**: Bash (bootstrap.sh, healthcheck.sh, тесты)
- **Анализ логов**: Python 3 (re, collections)
- **Сетевая безопасность**: nftables (прозрачный режим)
- **Хостовая ОС**: Debian 12 (LTS) / Ubuntu

## Состав команды и зоны ответственности

| Роль | ФИО | Основной вклад |
|------|-----|----------------|
| **DevOps/IaC Engineer** | Чугаев Н.Э. | Dockerfile, docker-compose.yml, bootstrap.sh, .env, структура репозитория |
| **System Administrator / SRE** | Величко В.Э. | Конфигурация squid.conf, healthcheck.sh, тесты (test_squid.sh, test_edge_cases.sh), настройка отказоустойчивости |
| **Security/Monitoring Engineer** | Хачатрян М.С. | Правила nftables, парсер логов (parse_squid_logs.py), настройка UFW, ротация логов |

Все изменения фиксируются в Git с осмысленными коммитами, проходят ревью через Pull Request.

## Архитектура решения

- Контейнер Squid изолирован в сети `squid_net` (bridge).
- Для прямого доступа открыт порт `3128`.
- Прозрачный режим: правила nftables перенаправляют трафик с портов 80/443 на порт `3129` контейнера (требуется `network_mode: host`).
- Межсетевой экран хоста (UFW) разрешает только SSH и порт прокси.

## Быстрый старт

### Предварительные требования

- Хост с Debian 12/Ubuntu 22.04+.
- Установленные Git, Docker, Docker Compose (скрипт `bootstrap.sh` установит автоматически).
- Права sudo.

### Установка и запуск

1. **Клонируйте репозиторий**
   ```bash
   git clone https://github.com/Nazareth-cH/squid-proxy.git
   cd squid-proxy
   
2. **Настройте переменные окружения**
   cp .env.example .env
# при необходимости отредактируйте SQUID_PORT и другие параметры

3. **Выполните подготовку хоста**
   sudo bash deploy/scripts/bootstrap.sh
   
Скрипт установит Docker, Docker Compose, настроит UFW (разрешит порты 22 и 3128) и включит IP forwarding.

4. **Создайте пользователя для аутентификации**
Будет запрошен пароль (например, student123).
sudo htpasswd -c config/squid/passwords student
sudo chown 1000:1000 config/squid/passwords
sudo chmod 644 config/squid/passwords

5. **Запустите контейнер**
cd deploy
docker compose up -d

6. **Проверьте статус контейнера**
docker compose ps
Статус при включении Up, спустя время healthy

7. **Проверьте работу прокси**
curl -x http://localhost:3128 -U student:student123 http://example.com -v

При успешной проверке HTTP-ответ 200 OK и HTML-страница example.com.

8. **Проверьте блокировку запрещённого домена**
curl -x http://localhost:3128 -U student:student123 http://facebook.com -v

В случае правильной работы должна быть ошибка 403 или 407

### Остановка проекта
cd deploy
docker compose down

## Тестирование

### Функциональные тесты
bash deploy/scripts/tests/test_squid.sh

Проверяют доступ к разрешённому сайту, блокировку запрещённого домена и работу кэша (если включён).

### Тесты граничных условий
bash deploy/scripts/tests/test_edge_cases.sh

Проверяют поведение healthcheck и обработку ошибочных подключений.

## Прозрачный режим
Изначально отключен. Для активации выполните:
sudo nft -f config/nftables/squid.nft

В файле deploy/docker-compose.yml измените сетевой режим на network_mode: host и добавьте порт 3129.

Перезапустите контейнер: docker compose restart

## Мониторинг, логирование и безопасность

### Healthcheck
Docker проверяет состояние сервиса каждые 30 секунд через команду squidclient -h localhost mgr:info.

### Логи
Логи контейнера доступны через docker logs squid-proxy. Ротация логов на хосте не требуется, т.к. в production-сценарии можно настроить logrotate.

### Парсер логов
Скрипт deploy/scripts/parse_squid_logs.py анализирует access-логи и выводит топ-10 доменов, количество заблокированных запросов.
Пример запуска:
docker exec squid-proxy cat /var/log/squid/access.log | python3 deploy/scripts/parse_squid_logs.py

### Безопасность

-Межсетевой экран UFW: разрешены только порты SSH и 3128.
-Контейнер запускается от непривилегированного пользователя squid (UID 1000).
-Файл паролей config/squid/passwords не хранится в репозитории (добавлен в .gitignore).
-Прозрачный режим требует ручного включения.

© 2026, Чугаев Н.Э., Величко В.Э., Хачатрян М.С.
