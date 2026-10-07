# CLAUDE.md

Указания для Claude Code при работе в этом репозитории.

## Что это

Локальный Docker-стек WordPress с темой Sage 11. Вся разработка ведётся в теме
`wordpress/wp-content/themes/<THEME_SLUG>` (слаг — в `.env`); остальное — ядро WP и инфраструктура.

Стек: WordPress (php8.3-apache) + MariaDB 11 + Node 22 (Vite) + Mailpit + phpMyAdmin + WP-CLI.
PHP и Node на хосте не нужны — всё через `make`.

## Команды

Все команды выполняются из корня репозитория:

```bash
make up                      # поднять wordpress, db, mailpit, phpmyadmin
make down                    # остановить
make clean                   # остановить и удалить БД
make logs                    # логи
make install                 # первичная установка (ядро, Sage, плагины, язык, активация темы)

make dev                     # Vite HMR на :5173 (профиль dev)
make build                   # production-сборка ассетов темы

make wp       cmd="plugin list"
make composer cmd="require vendor/package"     # cwd = тема
make npm      cmd="install"                    # cwd = тема
```

PHP-скрипты темы запускаются через WP-CLI:

```bash
make wp cmd="eval-file wp-content/themes/<THEME_SLUG>/scripts/<script>.php"
```

Адреса: сайт http://localhost:8080, админка `/wp-admin` (admin/admin по `.env`),
Mailpit http://localhost:8025, phpMyAdmin http://localhost:8081.

Ядро WP лежит в `./wordpress` только для IDE/Intelephense — его не коммитят и не правят.
Обновление ядра: `make wp cmd="core update"`, не пересборкой образа.

## Архитектура темы

```
themes/<THEME_SLUG>/
├── app/
│   ├── setup.php              # theme supports, меню, CPT, хуки
│   ├── filters.php
│   ├── helpers.php            # функции namespace App\
│   └── View/Composers/        # данные для Blade
├── resources/
│   ├── views/                 # Blade: layouts, sections, partials, components
│   └── css/, js/, images/, fonts/
└── vite.config.js
```

### Ключевые правила

- **Логика — в PHP, не в Blade.** Данные собираются во View Composers (`app/View/Composers/`)
  и отдаются в шаблон готовыми массивами. Blade Intelephense не анализирует, поэтому
  вызовы `get_field()` и вычисления в шаблонах не нужны.
- Поля OpenFields читать через хелперы в `app/helpers.php`, которые нормализуют
  image/repeater/group в массивы; прямой `get_field()` возвращает сырые id/скаляры.
- Группы полей OpenFields лучше описывать JSON-ом в теме и синхронизировать кодом,
  а не настраивать кликами в админке.
- Синтаксическая ошибка в любом композере ломает регистрацию всех композеров (500 на всех страницах).
- Ассеты темы — через Vite-манифест (`Vite::asset()`), не прямыми путями.

## Чего не делать

- Не править файлы ядра WordPress в `wordpress/` (кроме `wp-content/`).
- Не редактировать вендорные плагины из `WP_PLUGINS` (OpenFields, CF7, Modern Image Formats).
- Не коммитить `vendor/`, `node_modules/`, `public/build/`, `uploads/`, `.env`.
