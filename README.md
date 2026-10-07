# wp-sage-starter

Стартовый шаблон для разработки сайтов на WordPress: локальный Docker-стек, тема [Sage 11](https://roots.io/sage/) (Vite, Acorn, Blade, Tailwind) и набор плагинов по умолчанию — [OpenFields](https://wordpress.org/plugins/codeideal-open-fields/), [Contact Form 7](https://wordpress.org/plugins/contact-form-7/), [Modern Image Formats](https://wordpress.org/plugins/webp-uploads/).

PHP и Node на хосте не нужны — всё запускается в Docker.

## Стек

| Сервис | Назначение | Порт |
| --- | --- | --- |
| WordPress (`php8.3-apache` + Composer) | Сайт и админка | `8080` |
| MariaDB 11 | База данных | только внутри сети |
| Node 22 | Vite HMR / сборка темы | `5173` |
| Mailpit | Перехват исходящей почты | UI `8025` |
| phpMyAdmin | Просмотр БД | `8081` |
| WP-CLI | Управление WP из контейнера | по запросу |

## Требования

- Docker и Docker Compose v2 (`docker compose`)
- Make
- Python 3 (для патча `vite.config.js` при установке темы)

## Новый сайт из шаблона

1. На GitHub: **Use this template → Create a new repository**, затем склонировать:

   ```bash
   git clone git@github.com:<owner>/<my-site>.git
   cd my-site
   cp .env.example .env
   ```

2. Отредактировать `.env`:

   - `COMPOSE_PROJECT_NAME` — уникальное имя стека (префикс контейнеров и тома БД);
   - `THEME_SLUG` / `THEME_NAME` — каталог и название темы;
   - `WP_TITLE`, `WP_LOCALE`, `DB_*`;
   - порты (`WP_PORT`, `VITE_PORT`, `PMA_PORT`, `MAILPIT_PORT`) и `WP_HOME`, если на машине уже запущен другой проект;
   - `WP_PLUGINS` — список плагинов с wordpress.org через пробел.

3. Установить:

   ```bash
   make install
   ```

   Команда поднимает контейнеры, копирует ядро WordPress в `./wordpress`, создаёт тему Sage в `wordpress/wp-content/themes/<THEME_SLUG>`, собирает ассеты, ставит WordPress, язык и плагины, активирует тему и включает ЧПУ `/%postname%/`.

4. Закоммитить созданную тему:

   ```bash
   git add wordpress/wp-content/themes
   git commit -m "Add Sage theme"
   ```

5. Если плагины в `WP_PLUGINS` менялись — поправить список в `.gitignore`, чтобы вендорные плагины не попали в git.

После установки:

- Сайт: http://localhost:8080
- Админка: http://localhost:8080/wp-admin (`WP_ADMIN_USER` / `WP_ADMIN_PASSWORD`, по умолчанию `admin` / `admin`)
- Mailpit: http://localhost:8025
- phpMyAdmin: http://localhost:8081
- Vite (после `make dev`): http://localhost:5173

## Ежедневная работа

```bash
make up                 # сайт, БД, Mailpit, phpMyAdmin
make dev                # Vite HMR для темы
make build              # production-сборка ассетов
make down               # остановить контейнеры
make clean              # остановить и удалить контейнеры вместе с БД
make logs               # логи основных сервисов

make wp cmd="plugin list"
make composer cmd="require vendor/package"
make npm cmd="install"
```

`make composer` и `make npm` выполняются в каталоге темы (`/var/www/html/wp-content/themes/<THEME_SLUG>` в контейнере).

## Структура

```
.
├── compose.yaml
├── Makefile
├── docker/                 # образ WordPress + php.ini
├── scripts/                # установка WordPress и темы Sage
└── wordpress/              # = /var/www/html в контейнере
    ├── wp-admin/ …         # ядро, не в git (копируется образом)
    └── wp-content/
        ├── mu-plugins/     # local-config, Mailpit SMTP
        ├── plugins/        # плагины из WP_PLUGINS ставятся скриптом
        └── themes/         # тема Sage (создаётся при make install)
```

В git попадают тема, mu-plugins и собственные плагины. Ядро WordPress, `uploads`, `languages`, `vendor`, `node_modules`, `public/build` и плагины из `WP_PLUGINS` не коммитятся. Ядро лежит в `./wordpress`, чтобы IDE видела исходники WP-функций.

Обновлять ядро лучше через WP-CLI, а не пересборкой образа:

```bash
make wp cmd="core update"
```

## OpenFields

1. В админке: **Open Fields** → создать группу полей и привязать к записям/страницам.
2. Экспорт/импорт групп — JSON в интерфейсе плагина; описания групп удобно хранить в теме (например, `resources/openfields/*.json`).
3. Значения читать в PHP (View Composer Sage), а не в Blade:

```php
// wordpress/wp-content/themes/<THEME_SLUG>/app/View/Composers/App.php
'hero' => function_exists('get_field') ? get_field('hero_title') : null,
```

В шаблоне: `{{ $hero }}`. API совместим с ACF (`get_field()`, `have_rows()`, `get_sub_field()`).

Документация: https://openfields.codeideal.com/docs

## Troubleshooting

**`public/build/manifest.json` cannot be found**
Тема ещё не собрана. Выполните `make build` или `make install`.

**HMR не подхватывает CSS/JS**
Запустите `make dev`. В `vite.config.js` должны быть `server.host = '0.0.0.0'` и `origin: 'http://localhost:5173'`. Порт `5173` не должен быть занят.

**Нет прав на загрузку файлов / кэш Acorn**
`uploads` и `wp-content/cache` должны быть доступны на запись пользователю `www-data` (uid 33). `make install` выставляет права сам.

**IDE ругается на WP-функции**
Дождитесь первого старта контейнера, чтобы в `./wordpress` появилось ядро. В `.vscode/settings.json` включены Intelephense stubs `wordpress`. Логику держите в `app/` — Blade Intelephense не анализирует.

**Письма не приходят в Mailpit**
Mu-plugin активен только при `WP_ENVIRONMENT_TYPE=local`. Проверьте http://localhost:8025 и SMTP-хост `mailpit:1025`.
